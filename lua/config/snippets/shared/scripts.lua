---Script factories shared by LaTeX and Typst.
---
---wrap/edit build editable script nodes; fixed owns the shared exponent rules;
---auto builds suffix-replacement autosnippets that never fire unchanged text.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local operand = require("config.snippets.shared.operand")

local s = ls.snippet
local t = ls.text_node
local f = ls.function_node

local capture = nodes.capture
local captured_insert = nodes.captured_insert
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

-- Auto patterns scan the same cursor-bounded suffix as operand recognition.
local SUFFIX_WINDOW = operand.OPERAND_WINDOW

---@class SnipScriptSyntax
---@field open string Opening bracket for an explicit script.
---@field close string Closing bracket for an explicit script.
---@field command_prefix? string Command prefix absorbed into operands, such as LaTeX `\`.
---@field render fun(content: string): string Render script content with the language's grouping.
---@field priority? integer Default priority for generated script snippets.
---@field boundary? string Default preceding-byte boundary for auto rules.

---@class SnipScriptTrigger
---@field text string
---@field auto? boolean

---@class SnipScriptValue
---@field latex? string
---@field typst? string

---@class SnipFixedRule
---@field name string
---@field marker "_"|"^"
---@field trigger (string|SnipScriptTrigger)[]
---@field value string|SnipScriptValue

-- Fixed exponent behaviors; the value is shared and rendered per language.
---@type SnipFixedRule[]
local FIXED = {
  { name = "square", marker = "^", trigger = { "sq" }, value = "2" },
  { name = "cube", marker = "^", trigger = { "cb" }, value = "3" },
  { name = "inverse", marker = "^", trigger = { "inv" }, value = "-1" },
  {
    name = "transpose",
    marker = "^",
    trigger = { "trp", { text = "^tt", auto = true } },
    value = { latex = [[\intercal]], typst = "top" },
  },
}

-- Comma and quote mirror the direct entry keys; the base precedes the marker.
---@type { name: string, pattern: string, render: fun(captures: string[]): string }[]
local QUICK_SCRIPTS = {
  {
    name = "quick subscript",
    pattern = ",([%a%d])$",
    render = function(captures)
      return "_" .. captures[1]
    end,
  },
  {
    name = "quick superscript",
    pattern = "'([%a%d%-])$",
    render = function(captures)
      return "^" .. captures[1]
    end,
  },
}

---Resolve a shared value against the language field.
---@param value string|SnipScriptValue
---@param language "latex"|"typst"
---@return string
local function resolve(value, language)
  if type(value) ~= "table" then
    return value --[[@as string]]
  end
  local resolved = value[language]
  assert(resolved, "missing " .. language .. " value")
  return resolved
end

---Strip one outer group written in the syntax's own brackets.
---@param syntax SnipScriptSyntax
---@param value string
---@return string
local function unwrap(syntax, value)
  local open, close = syntax.open, syntax.close
  if value:sub(1, #open) == open and value:sub(-#close) == close then
    return value:sub(#open + 1, -#close - 1)
  end
  return value
end

---Split an operand at the top-level marker, keeping nested groups intact.
---Captures are the base, the edited content and the untouched trailing script.
---@param syntax SnipScriptSyntax
---@param matcher SnipTriggerMatcher
---@param marker "_"|"^"
---@param line string
---@return string?, string[]?
local function split(syntax, matcher, marker, line)
  local full, captures = matcher(line)
  if not full then
    return nil
  end

  ---@diagnostic disable-next-line: need-check-nil
  local value = captures[1]
  local depth, start, finish = 0, nil, #value
  for index = 1, #value do
    local char = value:sub(index, index)
    if char == "(" or char == "[" or char == "{" then
      depth = depth + 1
    elseif char == ")" or char == "]" or char == "}" then
      depth = depth - 1
    elseif depth == 0 and (char == "_" or char == "^") then
      if start then
        finish = index - 1
        break
      end
      if char == marker then
        start = index
      end
    end
  end

  if start then
    return full, { value:sub(1, start - 1), unwrap(syntax, value:sub(start + 1, finish)), value:sub(finish + 1) }
  end
  return full, { value, "", "" }
end

---Build the operand-splitting engine used by edit and fixed snippets.
---@param syntax SnipScriptSyntax
---@param marker "_"|"^"
---@return SnipTriggerEngine
local function engine(syntax, marker)
  local operand_syntax = syntax.command_prefix and { command_prefix = syntax.command_prefix } or nil
  return function(trigger)
    local matcher = operand.engine(trigger, operand_syntax)
    return function(line)
      return split(syntax, matcher, marker, line)
    end
  end
end

---Wrap the selection or typed content as an editable script.
---@param syntax SnipScriptSyntax
---@param trig string
---@param name string
---@param marker "_"|"^"
---@param condition SnipCondition
---@return LuaSnip.Snippet
function M.wrap(syntax, trig, name, marker, condition)
  return s(
    with_condition({
      trig = trig,
      name = name,
      wordTrig = false,
      priority = syntax.priority,
    }, condition),
    { t(marker .. syntax.open), visual_insert(1), t(syntax.close) }
  )
end

---Edit the script already attached to the preceding operand.
---@param syntax SnipScriptSyntax
---@param trig string
---@param name string
---@param marker "_"|"^"
---@param condition SnipCondition
---@return LuaSnip.Snippet
function M.edit(syntax, trig, name, marker, condition)
  return s(
    with_condition({
      trig = trig,
      name = name,
      trigEngine = engine(syntax, marker),
      wordTrig = false,
      priority = syntax.priority,
    }, condition),
    {
      capture(1),
      t(marker .. syntax.open),
      captured_insert(1, 2, ""),
      t(syntax.close),
      capture(3),
    }
  )
end

---Build the fixed exponent snippets for one automatic/manual entry list.
---@param syntax SnipScriptSyntax
---@param language "latex"|"typst"
---@param condition SnipCondition
---@param auto boolean
---@return LuaSnip.Snippet[]
function M.fixed(syntax, language, condition, auto)
  local out = {}
  for _, rule in ipairs(FIXED) do
    local value = resolve(rule.value, language)
    for _, entry in ipairs(rule.trigger) do
      local trigger
      if type(entry) == "table" then
        trigger = entry
      else
        trigger = { text = entry }
      end
      if (trigger.auto or false) == auto then
        out[#out + 1] = s(
          with_condition({
            trig = trigger.text,
            name = rule.name,
            trigEngine = engine(syntax, rule.marker),
            wordTrig = false,
            priority = syntax.priority,
            snippetType = auto and "autosnippet" or "snippet",
          }, condition),
          { capture(1), t(rule.marker .. syntax.render(value)), capture(3) }
        )
      end
    end
  end
  return out
end

---Build one suffix-replacement autosnippet for the given syntax.
---Only fires when render changes the matched suffix.
---@param syntax SnipScriptSyntax
---@param name string
---@param pattern string Lua pattern anchored at the cursor.
---@param render fun(captures: string[], full: string): string Replacement for the matched suffix.
---@param condition SnipCondition
---@param boundary? string|false Overrides syntax.boundary; false disables it.
---@return LuaSnip.Snippet
function M.auto(syntax, name, pattern, render, condition, boundary)
  if boundary == nil then
    boundary = syntax.boundary
  elseif boundary == false then
    boundary = nil
  end

  return s(
    with_condition({
      trig = pattern,
      name = name,
      trigEngine = function()
        return function(line)
          local offset = math.max(0, #line - SUFFIX_WINDOW)
          local tail = offset > 0 and line:sub(-SUFFIX_WINDOW) or line
          local found = { tail:find(pattern) }
          local start, stop = found[1], found[2]
          if not start then
            return nil
          end
          if start == 1 and offset > 0 then
            return nil -- The match may be truncated by the window.
          end
          if boundary and tail:sub(start - 1, start - 1):match(boundary) then
            return nil
          end
          local full = tail:sub(start, stop)
          local rendered = render({ unpack(found, 3) }, full)
          if rendered == full then
            return nil
          end
          return full, { rendered }
        end
      end,
      wordTrig = false,
      priority = syntax.priority,
      snippetType = "autosnippet",
    }, condition),
    { f(function(_, snip)
      return snip.captures[1]
    end) }
  )
end

---Build the shared comma/quote entry snippets for the given syntax.
---@param syntax SnipScriptSyntax
---@param condition SnipCondition
---@return LuaSnip.Snippet[]
function M.quick_scripts(syntax, condition)
  local out = {}
  for _, rule in ipairs(QUICK_SCRIPTS) do
    out[#out + 1] = M.auto(syntax, rule.name, rule.pattern, rule.render, condition, false)
  end
  return out
end

return M

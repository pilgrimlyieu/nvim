---LaTeX wrappers; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local nodes = require("config.snippets.core.nodes")
local syntax = require("config.snippets.latex.math.syntax")
local postfix = require("config.snippets.shared.math_postfix")
local triggers = require("config.snippets.core.triggers")
local utils = require("config.snippets.core.utils")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local capture_nonempty = nodes.capture_nonempty
local literal_snippet = constructors.literal_snippet
local text_choices = nodes.text_choices
local text_choices_insert = nodes.text_choices_insert
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local capture = nodes.capture
local whole_operand_engine = postfix.whole(syntax)
local unescaped_word_engine = triggers.unescaped_word_engine
local table_extend = utils.table_extend

---@class MathWrapperRule
---@field name string Entry name.
---@field template string fmta template; one `<>` per editable field.
---@field manual? string[] Ordinary visual-wrapper triggers.
---@field auto? string[] Autosnippet visual-wrapper triggers.
---@field postfix? string Whole-operand postfix trigger.
---@field condition? SnipCondition  Overrides the default (conditions.math).
---@field opts? SnipOptions Extra snippet opts merged into the context (e.g. trigEngine).
---@field content_index? integer Defaults to 1; the index of the editable field for the captured content.
---@field nodes? fun(): table<integer, LuaSnip.Node> Fresh node factory per template position.

local ANNOTATION_POSTFIX_WINDOW = 80 -- label plus `%^` / `%_` annotation suffix.
local ANNOTATION_LABEL_CHAR = "[%w^\\]"
local ANGLE_CONTENT_WINDOW = 80 -- one-line `<content>` delimiter shorthand.
local MATH_DELIMITER_PAIRS = {
  ["("] = ")",
  ["["] = "]",
  ["\\{"] = "\\}",
  ["\\lbrace"] = "\\rbrace",
  ["\\langle"] = "\\rangle",
  ["\\lvert"] = "\\rvert",
  ["\\lVert"] = "\\rVert",
  ["|"] = "|",
}

---An automatic empty root must not preempt its manual postfix after a group.
local function root_prefix_engine(trigger)
  local operand_match = whole_operand_engine(trigger)
  local word_match = unescaped_word_engine(trigger)
  return function(line)
    if not operand_match(line) then
      return word_match(line)
    end
  end
end

---Return the right delimiter matching the first insert node.
---@param args SnipNodeArgs
---@return string
local function matching_right_delimiter(args)
  local left = args[1] and args[1][1] or ""
  return MATH_DELIMITER_PAIRS[left] or left
end

---Match `<content>` so it can be converted to angle delimiters.
---@return SnipTriggerEngine
local function angle_content_engine()
  return function()
    return function(line_to_cursor)
      if not vim.endswith(line_to_cursor, ">") then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ANGLE_CONTENT_WINDOW))
      local match, content = text:match("(<([^<>]+)>)$")
      if match then
        return match, { content }
      end
      return nil
    end
  end
end

---@type MathWrapperRule[]
local wrapper_rules = {
  { name = "text", template = [[\text{<>}]], manual = { "txt", "text", "tt" } },
  {
    name = "parentheses",
    template = [[\left( <> \right)]],
    manual = { "()" },
    auto = { [[\)]], [[\bb]] },
    opts = { wordTrig = false },
  },
  {
    name = "brackets",
    template = [=[\left[ <> \right]]=],
    manual = { "[]" },
    auto = { [=[\]]=] },
    opts = { wordTrig = false },
  },
  {
    name = "braces",
    template = [[\left\lbrace <> \right\rbrace]],
    manual = { "{}" },
    auto = { [[\}]] },
    opts = { wordTrig = false },
  },
  {
    name = "angle brackets",
    template = [[\left\langle <> \right\rangle]],
    auto = { [[\>]] },
    opts = { wordTrig = false },
  },
  {
    name = "norm",
    template = [[\left\lVert <> \right\rVert]],
    manual = { "||" },
    opts = { wordTrig = false },
  },
  {
    name = "absolute value",
    template = [[\left\lvert <> \right\rvert]],
    manual = { "abs" },
    postfix = "abs",
  },
  {
    name = "ceil",
    template = [[\left\lceil <> \right\rceil]],
    manual = { "ceil", "cil" },
    postfix = "cil",
  },
  {
    name = "floor",
    template = [[\left\lfloor <> \right\rfloor]],
    manual = { "floor", "flr" },
    postfix = "flr",
  },
  { name = "boxed", template = [[\boxed{<>}]], manual = { "boxed" } },
  { name = "phantom wrapper", template = [[\phantom{<>}]], manual = { "pha" } },
  { name = "horizontal phantom", template = [[\hphantom{<>}]], manual = { "hpha" } },
  {
    name = "square root",
    template = [[\sqrt{<>}]],
    auto = { "gen" },
    postfix = "gen",
    opts = { trigEngine = root_prefix_engine }, -- this is for auto, and will be overridden by postfix trigEngine
  },
  {
    name = "root",
    template = [[\sqrt[<>]{<>}]],
    auto = { "sqrt" },
    postfix = "sqrt",
    opts = { trigEngine = root_prefix_engine },
    content_index = 2,
    nodes = function()
      return { [1] = i(1, "3") }
    end,
  },
  {
    name = "smash",
    template = [[\smash[<>]{<>}]],
    manual = { "smash" },
    content_index = 2,
    nodes = function()
      return { [1] = text_choices(1, { "t", "b", " " }) }
    end,
  },
  {
    name = "left right delimiters", -- TODO: support auto pair correction
    template = [[\left<> <> \right<>]],
    manual = { "LR" },
    content_index = 2,
    nodes = function()
      return { [1] = i(1, "("), [3] = f(matching_right_delimiter, { 1 }) }
    end,
  },
  {
    name = "text color",
    template = [[\textcolor{<>}{<>}]],
    manual = { "clr" },
    content_index = 2,
    nodes = function()
      return { [1] = text_choices_insert(1, { "ff0099", "da6904", "05aa94" }) }
    end,
  },
  {
    name = "theorem box",
    template = [[\fcolorbox{#FF69B4}{transparent}{$<>$}]],
    manual = { "cbox" },
    condition = conditions.display_math,
  },
  {
    name = "angle brackets around content",
    template = [[\left\langle <> \right\rangle]],
    manual = { "angle-content" },
    wordTrig = false,
    opts = { trigEngine = angle_content_engine() },
    nodes = function()
      return { [1] = capture_nonempty(1) }
    end,
  },
  { name = "cancel", template = [[\cancel{<>}]], auto = { "cancel" } },
  { name = "complement", template = [[\complement_{<>}]], auto = { "buji" } },
}

---Build annotation autosnippets like overbrace/underbrace with captured label.
---@param name string
---@param suffix_text string
---@param command string
---@param marker string
---@return LuaSnip.Snippet
local function annotation_autosnippet(name, suffix_text, command, marker)
  local pattern = "(" .. ANNOTATION_LABEL_CHAR .. "*)" .. vim.pesc(suffix_text) .. "$"
  return s(
    with_condition({
      trig = name,
      trigEngine = function()
        return function(line_to_cursor)
          if not vim.endswith(line_to_cursor, suffix_text) then
            return nil
          end

          local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ANNOTATION_POSTFIX_WINDOW))
          local label = text:match(pattern)
          if label ~= nil then
            local before = #line_to_cursor - #suffix_text - #label
            if before > 0 and line_to_cursor:sub(before, before):match(ANNOTATION_LABEL_CHAR) then
              return nil
            end
            return label .. suffix_text, { label }
          end
          return nil
        end
      end,
      wordTrig = false,
      name = name,
      snippetType = "autosnippet",
    }, conditions.math),
    fmta(command .. [[{<>}]] .. marker .. [[{<>}]], { visual_insert(1), capture_nonempty(1) })
  )
end

---@param context SnipContext
---@param condition SnipCondition
---@param template string One fmta placeholder for the editable field.
---@param template_nodes? LuaSnip.Node[] Extra nodes to insert after the wrapper. Indexing starts at 2.
---@return LuaSnip.Snippet
local function wrapper(context, condition, template, template_nodes)
  return s(with_condition(context, condition), fmta(template, template_nodes))
end

---Build fmta nodes: content at `content_index`, extras at their declared positions.
---@param rule MathWrapperRule
---@param content_fun fun(index: integer): LuaSnip.Node
---@return LuaSnip.Node[]
local function expand(rule, content_fun)
  local ci = rule.content_index or 1
  local template_nodes = rule.nodes and rule.nodes() or {}
  if not template_nodes[ci] then
    template_nodes[ci] = content_fun(ci)
  end
  return template_nodes
end

---Expand wrapper_rules into ordinary, autosnippet and postfix entries.
---@param condition SnipCondition
---@return LuaSnip.Snippet[] manual, LuaSnip.Snippet[] auto, LuaSnip.Snippet[] postfixes
local function expand_wrapper_rules(condition)
  local manual, auto, postf = {}, {}, {}
  for _, rule in ipairs(wrapper_rules) do
    local cond = rule.condition or condition
    for _, trig in ipairs(rule.manual or {}) do
      local ctx = table_extend({ trig = trig, name = rule.name }, rule.opts)
      manual[#manual + 1] = wrapper(ctx, cond, rule.template, expand(rule, visual_insert))
    end
    for _, trig in ipairs(rule.auto or {}) do
      local ctx = table_extend({ trig = trig, name = rule.name, snippetType = "autosnippet" }, rule.opts)
      auto[#auto + 1] = wrapper(ctx, cond, rule.template, expand(rule, visual_insert))
    end
    if rule.postfix then
      local ctx = table_extend({ trig = rule.postfix, name = rule.name .. " postfix", priority = 1100 }, rule.opts)
      ctx.trigEngine = whole_operand_engine
      ctx.wordTrig = false
      postf[#postf + 1] = wrapper(
        ctx,
        cond,
        rule.template,
        expand(rule, function()
          return capture(1)
        end)
      )
    end
  end
  return manual, auto, postf
end

function M.snippets()
  local condition = conditions.math
  local wrappers, _, wrapper_postfix = expand_wrapper_rules(condition)

  local snippets = {
    literal_snippet("dis", [[\displaystyle ]], "display style", condition),
    literal_snippet("tes", [[\textstyle ]], "text style", condition),
  }
  vim.list_extend(snippets, wrappers)
  vim.list_extend(snippets, wrapper_postfix)

  return snippets
end

function M.autosnippets()
  local condition = conditions.math
  local _, wrappers, _ = expand_wrapper_rules(condition)

  local autos = {
    annotation_autosnippet("overbrace postfix", "%^", [[\overbrace]], "^"),
    annotation_autosnippet("underbrace postfix", "%_", [[\underbrace]], "_"),
  }
  vim.list_extend(autos, wrappers)

  return autos
end

return M

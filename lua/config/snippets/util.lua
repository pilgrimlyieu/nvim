---Shared LuaSnip constructors and visual selection.

local M = {}
local ls = require("luasnip")
local conditions = require("config.snippets.conditions")
local triggers = require("config.snippets.triggers")

local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

---Return whether a string or line list contains any text.
---@param value string|string[]?
---@return boolean
local function has_text(value)
  if type(value) == "string" then
    return value ~= ""
  end

  if type(value) == "table" then
    return #value > 1 or (value[1] ~= nil and value[1] ~= "")
  end

  return false
end

---Return the last LuaSnip visual selection as lines, with an optional fallback.
---@param snip SnipSnippet
---@param default? string|string[]
---@return string[]
function M.selected_lines(snip, default)
  local env = snip.snippet.env
  local selected = env.LS_SELECT_RAW or env.TM_SELECTED_TEXT

  if has_text(selected) then
    if type(selected) == "table" then
      return selected
    end
    ---@diagnostic disable-next-line: param-type-mismatch -- `has_text` already checks for non-string tables.
    return vim.split(selected, "\n", { plain = true })
  end

  if type(default) == "table" then
    return default
  end

  if type(default) == "string" and default ~= "" then
    return vim.split(default, "\n", { plain = true })
  end

  return { "" }
end

---Create an editable node seeded from the last captured visual selection.
---
---Use this instead of directly translating UltiSnips' visual placeholder. The selection
---is populated by LuaSnip's visual-mode selection key and falls back to `default`
---for ordinary non-visual expansion.
---@param index integer
---@param default? string|string[]
---@return SnipNode
function M.visual_insert(index, default)
  return d(index, function(_, snip)
    return sn(nil, { i(1, M.selected_lines(snip, default)) })
  end)
end

---Create an editable node from a transformed visual selection.
---
---Use this when a visual placeholder needs an explicit Lua line transform.
---@param index integer
---@param transform fun(lines: string[], snip: SnipSnippet): string|string[]
---@param default? string|string[]
---@return SnipNode
function M.visual_transform_insert(index, transform, default)
  return d(index, function(_, snip)
    return sn(nil, { i(1, transform(M.selected_lines(snip, default), snip)) })
  end)
end

---Merge optional fields into a freshly-created context table.
---@generic T: SnipContext|SnipContextExtra
---@param context T
---@param extra? SnipContextExtra
---@return T context
function M.extend(context, extra)
  if extra == nil then
    return context
  end

  for key, value in pairs(extra) do
    context[key] = value
  end
  return context
end

---Read a trigger capture in a function node.
---@param n integer
---@param default? string
---@return SnipNode
function M.capture(n, default)
  return f(function(_, snip)
    return snip.captures[n] or default or ""
  end)
end

---Read a trigger capture, treating an empty capture as missing.
---@param n integer
---@param default? string
---@return SnipNode
function M.capture_nonempty(n, default)
  return f(function(_, snip)
    local value = snip.captures[n]
    if value == nil or value == "" then
      return default or ""
    end
    return value
  end)
end

---Build a dynamic-node callback seeded from a trigger capture.
---@param n integer
---@param default string
---@return fun(args: SnipNodeArgs, snip: SnipSnippet): SnipNode
function M.captured_insert(n, default)
  return function(_, snip)
    local value = snip.captures[n]
    if value == nil or value == "" then
      value = default
    end

    return sn(nil, { i(1, value) })
  end
end

---Return the next value in a fixed cycle.
---@param current string
---@param values string[]
---@return string
function M.choose_next(current, values)
  for index, value in ipairs(values) do
    if value == current then
      return values[index % #values + 1]
    end
  end
  return values[1]
end

---Escape a literal string for use inside Lua pattern matching.
---@param value string
---@return string
function M.escape_lua_pattern(value)
  return (value:gsub("([^%w])", "%%%1"))
end

---Return a copy ordered by descending byte length for longest-match scans.
---@param values string[]
---@return string[]
function M.sorted_longest_first(values)
  local ordered = {}
  for index, value in ipairs(values) do
    ordered[index] = value
  end

  table.sort(ordered, function(left, right)
    return #left > #right
  end)
  return ordered
end

---Build a literal text snippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.literal_snippet(trigger, output, name, condition, extra)
  return s(conditions.with_condition(M.extend({ trig = trigger, name = name }, extra), condition), t(output))
end

---Build a literal autosnippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.literal_autosnippet(trigger, output, name, condition, extra)
  return M.literal_snippet(trigger, output, name, condition, M.extend({ snippetType = "autosnippet" }, extra))
end

---Build an unescaped-word autosnippet from literal text or LuaSnip nodes.
---@param trigger string
---@param body string|SnipNodeBody
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.word_autosnippet(trigger, body, name, condition, extra)
  if type(body) == "string" then
    body = t(body)
  end
  return s(
    conditions.with_condition(
      M.extend({
        trig = trigger,
        trigEngine = triggers.unescaped_word_engine,
        wordTrig = false,
        name = name,
        snippetType = "autosnippet",
      }, extra),
      condition
    ),
    body
  )
end

---Match one of several exact suffixes.
---@param values string[]
---@return SnipTriggerEngine
function M.exact_cycle_engine(values)
  local matches = M.sorted_longest_first(values)
  return function()
    return function(line_to_cursor)
      for _, value in ipairs(matches) do
        if line_to_cursor:sub(-#value) == value then
          return value, { value }
        end
      end
      return nil
    end
  end
end

return M

---Generic choice, capture and selection nodes; feature-specific nodes stay with their feature.
local M = {}

local ls = require("luasnip")

local selection = require("config.snippets.core.selection")

local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local c = ls.choice_node

local selected_lines = selection.lines

---Indent continuation lines to the placeholder's line, including template indent.
---
---LuaSnip normally only inherits the indent at the trigger, so a literal indent
---before a dynamic node (e.g. an admonition on body) would only affect its first line.
---@param parent SnipParent
---@param index integer
---@param text string|string[]
---@return LuaSnip.Node
local function indented_visual(parent, index, text)
  local mark = parent.insert_nodes[index].mark
  local indent = parent.indentstr
  -- Completion previews evaluate dynamic nodes before buffer marks exist.
  if mark then
    local pos = mark:pos_begin_end()
    local line = vim.api.nvim_buf_get_lines(0, pos[1], pos[1] + 1, false)[1]
    indent = line:sub(1, pos[2]):match("^%s*")
  end
  return isn(nil, { i(1, text) }, indent)
end

---Build a LuaSnip choice node from fixed text alternatives.
---@param index integer Jump index of the choice node.
---@param values string[] Fixed choices in display order.
---@return LuaSnip.ChoiceNode node A LuaSnip choice node containing text-node choices.
function M.text_choices(index, values)
  local choices = {}

  for _, value in ipairs(values) do
    choices[#choices + 1] = t(value)
  end

  return c(index, choices)
end

---Build a modifiable LuaSnip choice node from fixed text alternatives.
---@param index integer Jump index of the choice node.
---@param values string[] Fixed choices in display order.
---@return LuaSnip.ChoiceNode node A LuaSnip choice node containing text-node choices.
function M.text_choices_insert(index, values)
  local choices = {}

  for _, value in ipairs(values) do
    choices[#choices + 1] = i(nil, value)
  end

  return c(index, choices)
end

---Create an editable node seeded from the last captured visual selection.
---
---Use this instead of directly translating UltiSnips' visual placeholder. The selection
---is populated by LuaSnip's visual-mode selection key and falls back to `default`
---for ordinary non-visual expansion.
---@param index integer
---@param default? string|string[]
---@return LuaSnip.Node
function M.visual_insert(index, default)
  return d(index, function(_, snip)
    return indented_visual(snip, index, selected_lines(snip, default))
  end)
end

---Create an editable node from a transformed visual selection.
---
---Use this when a visual placeholder needs an explicit Lua line transform.
---@param index integer
---@param transform fun(lines: string[], snip: SnipParent): string|string[]
---@param default? string|string[]
---@return LuaSnip.Node
function M.visual_transform_insert(index, transform, default)
  return d(index, function(_, snip)
    return indented_visual(snip, index, transform(selected_lines(snip, default), snip))
  end)
end

---Read a trigger capture in a function node.
---@param n integer
---@param default? string
---@return LuaSnip.Node
function M.capture(n, default)
  return f(function(_, snip)
    return snip.captures[n] or default or ""
  end)
end

---Read a trigger capture, treating an empty capture as missing.
---@param n integer
---@param default? string
---@return LuaSnip.Node
function M.capture_nonempty(n, default)
  return f(function(_, snip)
    local value = snip.captures[n]
    if value == nil or value == "" then
      return default or ""
    end
    return value
  end)
end

---Create an editable placeholder whose initial value is evaluated at expansion.
---The producer receives the dynamic node's parent; previews also evaluate it.
---@param index integer
---@param value fun(parent: SnipParent): string|string[]
---@return LuaSnip.Node
function M.computed_insert(index, value)
  return d(index, function(_, parent)
    return sn(nil, { i(1, value(parent)) })
  end)
end

---Seed an editable field from a capture; missing and empty captures use default.
---@param index integer Jump position of the dynamic node.
---@param n integer Capture position, independent of the jump position.
---@param default string
---@return LuaSnip.Node
function M.captured_insert(index, n, default)
  return M.computed_insert(index, function(parent)
    local value = parent.captures[n]
    return (value == nil or value == "") and default or value
  end)
end

---Evaluate a formatted date when expanded, rather than when the collection loads.
---@param format string An os.date format producing text.
---@return LuaSnip.Node
function M.date(format)
  return f(function()
    return os.date(format)
  end)
end

return M

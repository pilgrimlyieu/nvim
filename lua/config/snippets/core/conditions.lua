---LuaSnip condition pairs and their composition.
---Syntax and caching belong to scope.lua; this module loads with LuaSnip.
local M = {}

local expand = require("luasnip.extras.conditions.expand")
local make = require("luasnip.extras.conditions").make_condition

local scope = require("config.snippets.core.scope")

local get_scope = scope.get
local in_tex_list = scope.in_tex_list

---@alias MarkdownTeXPredicate fun(value: SnipScope): boolean

---@class MarkdownTeXPredicates
---@field math MarkdownTeXPredicate
---@field text MarkdownTeXPredicate
---@field frontmatter MarkdownTeXPredicate
---@field display_math MarkdownTeXPredicate
---@field chem MarkdownTeXPredicate
---@field not_chem MarkdownTeXPredicate
---@field not_unit MarkdownTeXPredicate
---@field pure_math MarkdownTeXPredicate
---@field tex_list MarkdownTeXPredicate
local predicates = {
  math = function(value)
    return value.kind == "math"
  end,
  text = function(value)
    return value.kind == "text"
  end,
  frontmatter = function(value)
    return value.kind == "frontmatter"
  end,
  display_math = function(value)
    return value.kind == "math" and value.layout == "display"
  end,
  chem = function(value)
    return value.kind == "math" and value.command == "\\ce"
  end,
  not_chem = function(value)
    return value.kind == "math" and value.command ~= "\\ce"
  end,
  not_unit = function(value)
    return value.kind == "math" and value.command ~= "\\pu"
  end,
  pure_math = function(value)
    return value.kind == "math" and value.command ~= "\\ce" and value.command ~= "\\pu"
  end,
  tex_list = function(value)
    return value.kind == "text" and in_tex_list()
  end,
}

for name, predicate in pairs(predicates) do
  local condition = make(function()
    return predicate(get_scope())
  end)
  M[name] = { condition = condition, show_condition = condition }
end

---Attach expansion and completion rules to a fresh snippet context.
---@param context SnipContext
---@param condition SnipCondition
---@return SnipContext
function M.with_condition(context, condition)
  context.condition = condition.condition
  context.show_condition = condition.show_condition
  return context
end

---@param ... SnipCondition
---@return SnipCondition
function M.or_conditions(...)
  local values = { ... }
  local condition, show = values[1].condition, values[1].show_condition
  for index = 2, #values do
    condition = condition + values[index].condition
    show = show + values[index].show_condition
  end
  return { condition = condition, show_condition = show }
end

---Expansion knows the matched trigger; completion only knows the typed prefix.
---@param condition SnipCondition
---@return SnipCondition
function M.with_line_begin(condition)
  local first_token = make(function(line)
    return (line or ""):match("^%s*%S*$") ~= nil
  end)
  return {
    condition = condition.condition * expand.line_begin,
    show_condition = condition.show_condition * first_token,
  }
end

---@param condition SnipCondition
---@param column integer Display column where the trigger starts.
---@return SnipCondition
function M.with_trigger_column(condition, column)
  local at_column = make(function(line, trigger)
    return vim.fn.strdisplaywidth(line) - vim.fn.strdisplaywidth(trigger) == column
  end)
  local show_column = make(function(line)
    local prefix, token = (line or ""):match("^(%s*)(%S*)$")
    return prefix ~= nil and token ~= "" and vim.fn.strdisplaywidth(prefix) == column
  end)
  return {
    condition = condition.condition * at_column,
    show_condition = condition.show_condition * show_column,
  }
end

---@param condition SnipCondition
---@return SnipCondition
function M.at_buffer_start(condition)
  local first_line = make(function()
    return vim.api.nvim_win_get_cursor(0)[1] == 1
  end)
  local start = M.with_trigger_column(condition, 0)
  return {
    condition = start.condition * first_line,
    show_condition = start.show_condition * first_line,
  }
end

return M

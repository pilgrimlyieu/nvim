---Concrete prose-to-math entries; typography and lifecycle belong to prose/spacing.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local prose = require("config.snippets.shared.prose")
local triggers = require("config.snippets.core.triggers")
local utils = require("config.snippets.core.utils")

local s = ls.snippet
local t = ls.text_node

local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin
local token_postfix_engine = triggers.token_postfix_engine
local table_extend = utils.table_extend

---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.inline(left, right, opts)
  return prose.wrap("lm", "inline math", left, right, table_extend({ snippetType = "autosnippet" }, opts))
end

---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.capture_math(left, right, opts)
  return prose.capture(",,", "inline captured math", function()
    return token_postfix_engine({ ",,", "，，" }, "([A-Za-z0-9_^+=%%%.<>%-]+)$")
  end, left, right, opts)
end

---Create a display math snippet, with spacing managed entirely by the shared factory.
---@param left string
---@param right string
---@return LuaSnip.Snippet
function M.display(left, right)
  return s(
    with_condition(
      { trig = "dm", name = "display math", snippetType = "autosnippet" },
      with_line_begin(conditions.text)
    ),
    {
      t({ left, "" }),
      visual_insert(1),
      t({ "", right, "" }),
    }
  )
end

return M

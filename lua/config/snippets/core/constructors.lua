---Small snippet constructors; language features supply rules and nodes.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local triggers = require("config.snippets.core.triggers")
local utils = require("config.snippets.core.utils")

local s = ls.snippet
local t = ls.text_node

local unescaped_word_engine = triggers.unescaped_word_engine
local with_condition = conditions.with_condition
local table_extend = utils.table_extend

---Build a literal text snippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipOptions
---@return LuaSnip.Snippet
function M.literal_snippet(trigger, output, name, condition, extra)
  return s(with_condition(table_extend({ trig = trigger, name = name }, extra), condition), t(output))
end

---Build a literal autosnippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipOptions
---@return LuaSnip.Snippet
function M.literal_autosnippet(trigger, output, name, condition, extra)
  return M.literal_snippet(trigger, output, name, condition, table_extend({ snippetType = "autosnippet" }, extra))
end

---Build an unescaped-word autosnippet from literal text or LuaSnip nodes.
---@param trigger string
---@param body string|SnipNodeBody
---@param name string
---@param condition SnipCondition
---@param extra? SnipOptions
---@return LuaSnip.Snippet
function M.word_autosnippet(trigger, body, name, condition, extra)
  if type(body) == "string" then
    body = t(body)
  end
  return s(
    with_condition(
      table_extend({
        trig = trigger,
        name = name,
        trigEngine = unescaped_word_engine,
        wordTrig = false,
        snippetType = "autosnippet",
      }, extra),
      condition
    ),
    body
  )
end

return M

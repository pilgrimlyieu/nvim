---Inline prose factories shared by math and code. Each opts.spacing can disable before/after independently.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local spacing = require("config.snippets.core.spacing")
local triggers = require("config.snippets.core.triggers")
local utils = require("config.snippets.core.utils")

local t = ls.text_node

local spaced_snippet = spacing.snippet
local capture = nodes.capture
local word_suffix_engine = triggers.word_suffix_engine
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local table_extend = utils.table_extend

---@class SnipProseOptions: SnipOptions
---@field spacing? false|SnipSpacing

---Return a prose snippet context with a word boundary and text-mode condition.
---@param trigger string
---@param name string
---@param opts? SnipProseOptions
local function context(trigger, name, opts)
  local extra = table_extend({}, opts)
  extra.spacing = nil
  return with_condition(
    table_extend({ trig = trigger, name = name, trigEngine = word_suffix_engine, wordTrig = false }, extra),
    conditions.text
  )
end

---Wrap an editable body, with spacing managed entirely by the shared factory.
---@param trigger string
---@param name string
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.wrap(trigger, name, left, right, opts)
  return spaced_snippet(context(trigger, name, opts), {
    t(left),
    visual_insert(1),
    t(right),
  }, opts and opts.spacing)
end

---Create a symbol snippet, with spacing managed entirely by the shared factory.
---@param trigger string
---@param name string
---@param value string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.symbol(trigger, name, value, opts)
  return spaced_snippet(context(trigger, name, opts), { t(value) }, opts and opts.spacing)
end

---Create a snippet that captures the preceding token and wraps it in delimiters.
---The engine decides which token is captured; captures[1] sits between left and right.
---@param trigger string
---@param name string
---@param engine SnipTriggerEngine
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.capture(trigger, name, engine, left, right, opts)
  return spaced_snippet(
    context(trigger, name, table_extend({ snippetType = "autosnippet", trigEngine = engine }, opts)),
    { t(left), capture(1), t(right) },
    opts and opts.spacing
  )
end

return M

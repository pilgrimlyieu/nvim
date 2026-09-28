---Prose math factories. Each opts.spacing can disable before/after independently.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local spacing = require("config.snippets.core.spacing")
local triggers = require("config.snippets.core.triggers")
local utils = require("config.snippets.core.utils")

local s = ls.snippet
local t = ls.text_node

local spaced_snippet = spacing.snippet
local capture = nodes.capture
local inline_math_postfix_engine = triggers.inline_math_postfix_engine
local short_math_word_engine = triggers.short_math_word_engine
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin
local extend = utils.extend

---@class SnipProseOptions: SnipOptions
---@field spacing? false|SnipSpacing

---Return a snippet context for prose math, with the shared short-math-word engine and text-mode condition.
---@param trigger string
---@param name string
---@param opts? SnipProseOptions
local function context(trigger, name, opts)
  local extra = extend({}, opts)
  extra.spacing = nil
  return with_condition(
    extend({ trig = trigger, name = name, trigEngine = short_math_word_engine, wordTrig = false }, extra),
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

---Create an inline math snippet, with spacing managed entirely by the shared factory.
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.inline(left, right, opts)
  return M.wrap("lm", "inline math", left, right, extend({ snippetType = "autosnippet" }, opts))
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
    context(trigger, name, extend({ snippetType = "autosnippet", trigEngine = engine }, opts)),
    { t(left), capture(1), t(right) },
    opts and opts.spacing
  )
end

---Create an inline math snippet that captures the preceding token.
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.capture_math(left, right, opts)
  return M.capture(",,", "inline captured math", inline_math_postfix_engine, left, right, opts)
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

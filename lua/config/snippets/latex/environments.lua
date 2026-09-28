---LaTeX environments shared by math-zone and prose factories.
local M = {}

local ls = require("luasnip")
local rep = require("luasnip.extras").rep

local nodes = require("config.snippets.core.nodes")
local scope = require("config.snippets.core.scope")

local sn = ls.snippet_node
local d = ls.dynamic_node
local t = ls.text_node
local i = ls.insert_node

local get_scope = scope.get
local visual_insert = nodes.visual_insert

local DISPLAY_INDENT = "    "

---@class MathEnvironmentRule
---@field trigger string The trigger for the snippet.
---@field name string The name of the snippet.
---@field open string The opening LaTeX code for the environment.
---@field close string The closing LaTeX code for the environment.

---@type MathEnvironmentRule[]
M.rules = {
  {
    trigger = "case",
    name = "brace aligned",
    open = [[\left\lbrace\begin{aligned}]],
    close = [[\end{aligned}\right.]],
  },
  { trigger = "cases", name = "cases", open = [[\begin{cases}]], close = [[\end{cases}]] },
  { trigger = "align", name = "aligned equations", open = [[\begin{aligned}]], close = [[\end{aligned}]] },
}
---@type table<string, MathEnvironmentRule>
local by_trigger = {}
for _, rule in ipairs(M.rules) do
  by_trigger[rule.trigger] = rule
end

---Build the body for a generic LaTeX environment snippet.
---@param with_option boolean
---@param inline boolean
---@return LuaSnip.Node[]
local function environment_body(with_option, inline)
  local body = {
    t([[\begin{]]),
    i(1, "environment"),
  }
  local body_index = 2

  if with_option then
    body[#body + 1] = t([[}{]])
    body[#body + 1] = i(2, "option")
    body_index = 3
  end

  if inline then
    vim.list_extend(body, {
      t([[} ]]),
      visual_insert(body_index),
      t([[ \end{]]),
      rep(1),
      t("}"),
    })
  else
    vim.list_extend(body, {
      t({ "}", DISPLAY_INDENT }),
      visual_insert(body_index),
      t({ "", [[\end{]] }),
      rep(1),
      t("}"),
    })
  end

  return body
end

---Build an environment snippet node, adapting line breaks to math layout.
---@param index integer
---@param with_option boolean
---@return LuaSnip.Node
function M.environment_node(index, with_option)
  return d(index, function()
    return sn(nil, environment_body(with_option, get_scope().layout == "inline"))
  end)
end

---Build case/cases/align nodes, adapting line breaks to math layout.
---@param index integer
---@param kind "case"|"cases"|"align"
---@return LuaSnip.Node
function M.math_environment_node(index, kind)
  return d(index, function()
    local rule = by_trigger[kind]
    local inline = get_scope().layout == "inline"
    local open = inline and (rule.open .. " ") or { rule.open, DISPLAY_INDENT }
    local close = inline and (" " .. rule.close) or { "", rule.close }
    return sn(nil, { t(open), visual_insert(1), t(close) })
  end)
end

return M

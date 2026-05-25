---Algorithm-course snippets shared by Markdown and LaTeX text buffers.
---
---The old `tex_course/data-structures-and-algorithms.snippets` file mixed
---course-specific helpers with normal TeX snippets.  Keeping them in this
---small module makes the migrated collection easier to disable or expand later.
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local nodes = require("config.snippets.nodes")
local with_condition = require("config.snippets.util").with_condition

local s = ls.snippet
local t = ls.text_node

local M = {}

---Build a Big-O/Omega/Theta snippet with a common complexity choice node.
---@param trigger string
---@param command string
---@param name string
---@param condition SnipCondition
---@return SnipNode
local function complexity_snippet(trigger, command, name, condition)
  return s(
    with_condition({ trig = trigger, name = name }, condition),
    fmt("${}({})$ ", {
      t(command),
      nodes.choice(1, { "1", "n", "n^2", [[\log(n)]], [[n\log(n)]] }),
    })
  )
end

---Return algorithm-course text snippets for TeX-like prose contexts.
---@param condition SnipCondition
---@return table
---TODO:
function M.latex_text_snippets(condition)
  return {
    complexity_snippet("OO", "O", "big O notation", condition),
    complexity_snippet("OM", [[\Omega]], "big Omega notation", condition),
    complexity_snippet("TT", [[\Theta]], "big Theta notation", condition),
  }
end

return M

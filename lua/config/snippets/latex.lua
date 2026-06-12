---Reusable LaTeX math snippet builders.
---
---The public module is intentionally stable because Markdown and TeX runtime
---snippet files both depend on it.  The implementation is split under
---`config.snippets.latex.*` by responsibility.
local snippets = require("config.snippets.latex.snippets")
local autos = require("config.snippets.latex.autos")

local M = {}

---Return high-frequency manual LaTeX math snippets.
---@param condition SnipCondition
---@param contexts? SnipMathContexts
---@return SnipNode[]
function M.math_snippets(condition, contexts)
  return snippets.math_snippets(condition, contexts)
end

---Return high-frequency LaTeX math autosnippets.
---@param condition SnipCondition
---@param contexts? SnipMathContexts
---@return SnipNode[]
function M.math_autosnippets(condition, contexts)
  return autos.math_autosnippets(condition, contexts)
end

return M

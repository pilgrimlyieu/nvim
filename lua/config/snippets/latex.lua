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
---@return SnipNode[]
function M.math_snippets(condition)
  return snippets.math_snippets(condition)
end

---Return high-frequency LaTeX math autosnippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_autosnippets(condition)
  return autos.math_autosnippets(condition)
end

return M

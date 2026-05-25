---Facade for additional native LuaSnip ports from the old math snippet set.
---
---The implementation is split by responsibility under
---`config.snippets.latex_extra.*` so the large migrated collection can be
---audited by topic.  Keep this module as the stable public entry point for
---`lua/snippets/{markdown,tex}/latex_math.lua`.
local snippets = require("config.snippets.latex_extra.snippets")
local autos = require("config.snippets.latex_extra.autos")

local M = {}

---Return low-frequency manual LaTeX math snippets.
---@param condition SnipCondition
---@param contexts? SnipMathContexts
---@return SnipNode[]
function M.math_snippets(condition, contexts)
  return snippets.math_snippets(condition, contexts)
end

---Return low-frequency LaTeX math autosnippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_autosnippets(condition)
  return autos.math_autosnippets(condition)
end

return M

---Chemistry-specific LaTeX snippets.
local ls = require("luasnip")
local h = require("config.snippets.latex.helpers")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local with_condition = h.with_condition

local M = {}

---Return chemistry snippets used inside VimTeX chemistry context.
---@param condition SnipCondition
---@return SnipNode[]
function M.chem_snippets(condition)
  return {
    s(with_condition({ trig = "=", wordTrig = false, priority = 2000, name = "chemical equal" }, condition), {
      t(" \\xlongequal["),
      i(1),
      t("]{\\enspace "),
      i(2),
      t("\\enspace} "),
    }),
  }
end

return M

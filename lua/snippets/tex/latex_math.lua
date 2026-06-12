---LaTeX math snippets for `.tex` buffers.
local groups = require("config.snippets.groups").values

if not (groups.latex_core or groups.latex_extra) then
  return {}, {}
end

local conditions = require("config.snippets.conditions")
local util = require("config.snippets.util")

local math = conditions.wrap(conditions.vimtex_math, conditions.vimtex_math_show)
local not_chem = conditions.wrap(conditions.vimtex_not_chem)
local not_unit = conditions.wrap(conditions.vimtex_not_unit)
local math_contexts = {
  inline = conditions.wrap(conditions.vimtex_inline_math, conditions.vimtex_inline_math_show),
  display = conditions.wrap(conditions.vimtex_display_math, conditions.vimtex_display_math_show),
  not_chem = util.and_conditions(math, not_chem),
  not_unit = util.and_conditions(math, not_unit),
  pure = util.and_conditions(math, not_chem, not_unit),
  chem = conditions.wrap(conditions.vimtex_chem),
}

local snippets = {}
local autosnippets = {}

if groups.latex_core then
  local latex = require("config.snippets.latex")

  vim.list_extend(snippets, latex.math_snippets(math, math_contexts))
  vim.list_extend(autosnippets, latex.math_autosnippets(math, math_contexts))
end

if groups.latex_extra then
  local latex_extra = require("config.snippets.latex_extra")
  vim.list_extend(snippets, latex_extra.math_snippets(math, math_contexts))
  vim.list_extend(autosnippets, latex_extra.math_autosnippets(math))
end

return snippets, autosnippets

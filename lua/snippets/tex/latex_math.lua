---LaTeX math snippets for `.tex` buffers.
local groups = require("config.snippets.groups").values

if not (groups.latex_core or groups.chemistry or groups.course or groups.latex_extra) then
  return {}, {}
end

local conditions = require("config.snippets.conditions")
local util = require("config.snippets.util")

local math = conditions.wrap(conditions.vimtex_math, conditions.vimtex_math_show)
local chem = conditions.wrap(conditions.vimtex_chem, conditions.vimtex_math_show)
local math_contexts = {
  inline = util.and_conditions(math, conditions.wrap(conditions.vimtex_inline_math, conditions.vimtex_inline_math_show)),
  display = util.and_conditions(math, conditions.wrap(conditions.vimtex_display_math, conditions.vimtex_display_math_show)),
}

local snippets = {}
local autosnippets = {}

if groups.latex_core or groups.chemistry then
  local latex = require("config.snippets.latex")

  if groups.latex_core then
    vim.list_extend(snippets, latex.math_snippets(math))
    vim.list_extend(autosnippets, latex.math_autosnippets(math))
  end

  if groups.chemistry then
    vim.list_extend(snippets, latex.chem_snippets(chem))
  end
end

if groups.course then
  local course = require("config.snippets.course")
  vim.list_extend(snippets, course.math_snippets(math))
  vim.list_extend(autosnippets, course.math_autosnippets(math))
end

if groups.latex_extra then
  local latex_extra = require("config.snippets.latex_extra")
  vim.list_extend(snippets, latex_extra.math_snippets(math, math_contexts))
  vim.list_extend(autosnippets, latex_extra.math_autosnippets(math))
end

return snippets, autosnippets

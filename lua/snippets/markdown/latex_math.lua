---Markdown LaTeX math snippets.
---
---Markdown math scope follows VimTeX's injected TeX syntax groups.  Delimiter
---and buffer-text fallback scans are intentionally not used here.
local groups = require("config.snippets.groups").values

if not (groups.latex_core or groups.latex_extra or groups.markdown_math_reference) then
  return {}, {}
end

local conditions = require("config.snippets.conditions")
local util = require("config.snippets.util")

local math = conditions.wrap(conditions.markdown_latex_math, conditions.markdown_latex_math_show)
local math_contexts = {
  inline = util.and_conditions(
    math,
    conditions.wrap(conditions.markdown_latex_inline_math, conditions.markdown_latex_inline_math_show)
  ),
  display = util.and_conditions(
    math,
    conditions.wrap(conditions.markdown_latex_display_math, conditions.markdown_latex_display_math_show)
  ),
}

local snippets = {}
local autosnippets = {}

if groups.latex_core then
  local latex = require("config.snippets.latex")

  vim.list_extend(snippets, latex.math_snippets(math))
  vim.list_extend(autosnippets, latex.math_autosnippets(math))
end

if groups.latex_extra then
  local latex_extra = require("config.snippets.latex_extra")
  vim.list_extend(snippets, latex_extra.math_snippets(math, math_contexts))
  vim.list_extend(autosnippets, latex_extra.math_autosnippets(math))
end

if groups.markdown_math_reference then
  vim.list_extend(snippets, require("config.snippets.markdown").math_reference_snippets(math))
end

return snippets, autosnippets

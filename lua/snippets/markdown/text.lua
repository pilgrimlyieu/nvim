---Markdown text snippets.
---
---This group contains prose-level helpers only.  LaTeX math snippets live in
---`markdown/latex_math.lua` so the math context can be tuned independently.
local conditions = require("config.snippets.conditions")
local groups = require("config.snippets.groups").values
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)
local snippets = markdown.snippets(text)

if groups.algorithms then
  vim.list_extend(snippets, require("config.snippets.algorithms").latex_text_snippets(text))
end

if groups.course then
  local course = require("config.snippets.course")
  vim.list_extend(snippets, course.text_snippets(text))
  vim.list_extend(snippets, course.template_snippets(text))
end

return snippets, markdown.autosnippets(text)

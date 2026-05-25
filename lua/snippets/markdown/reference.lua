---Markdown reference helpers for the custom KaTeX macros in markdown-preview.
local conditions = require("config.snippets.conditions")
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)

return markdown.reference_snippets(text)

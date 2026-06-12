---Markdown text snippets.
---
---This group contains prose-level helpers only.  LaTeX math snippets live in
---`markdown/latex_math.lua` so the math context can be tuned independently.
local conditions = require("config.snippets.conditions")
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)
local snippets = markdown.snippets(text)

return snippets, markdown.autosnippets(text)

---Markdown text snippets that create small LaTeX math fragments.
---
---These are text-mode shortcuts such as `alpha` -> `$\alpha$`.  They are
---separate from math-mode snippets to keep aggressive triggers easy to audit.
local conditions = require("config.snippets.conditions")
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)

return markdown.short_math_snippets(text)

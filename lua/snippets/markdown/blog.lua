---Hexo/blog-oriented Markdown snippets.
---
---These are intentionally isolated because blog front matter and tag helpers
---are useful in fewer files than ordinary Markdown prose/math snippets.
local conditions = require("config.snippets.conditions")
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)

return markdown.blog_snippets(text)

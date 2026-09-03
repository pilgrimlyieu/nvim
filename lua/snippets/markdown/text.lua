---Markdown prose snippets: text helpers, `alpha` -> `$\alpha$` shortcuts,
---KaTeX macro references, callouts, and blog front matter.
---
---LaTeX math snippets live in `latex_math.lua` so they can share the
---math-scope conditions with TeX buffers.
local markdown = require("config.snippets.markdown")

local snippets = {}

for _, build in ipairs({
  markdown.snippets,
  markdown.short_math_snippets,
  markdown.reference_snippets,
  markdown.vault_snippets,
  markdown.blog_snippets,
}) do
  vim.list_extend(snippets, build())
end

return snippets, markdown.autosnippets()

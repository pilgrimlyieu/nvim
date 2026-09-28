local loading = require("config.snippets.core.loading")

local collect = loading.collect

return collect("Markdown", {
  "markdown.tables",
  "markdown.prose",
  "markdown.math",
  "markdown.references",
  "markdown.callouts",
  "markdown.frontmatter",
})

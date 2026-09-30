local loading = require("config.snippets.core.loading")

local collect = loading.collect

return collect("Markdown", {
  "markdown.callouts",
  "markdown.frontmatter",
  "markdown.math",
  "markdown.prose",
  "markdown.references",
  "markdown.tables",
})

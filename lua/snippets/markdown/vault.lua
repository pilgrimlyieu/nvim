---Obsidian/Vault-style callout snippets.
local conditions = require("config.snippets.conditions")
local markdown = require("config.snippets.markdown")

local text = conditions.wrap(conditions.markdown_latex_text, conditions.markdown_latex_text_show)

return markdown.vault_snippets(text)

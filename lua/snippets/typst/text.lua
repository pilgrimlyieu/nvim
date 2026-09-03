---Typst text-mode snippets.
local enabled = require("config.snippets.groups")

if not enabled("typst_text") then
  return {}, {}
end

local typst = require("config.snippets.typst")

return typst.text_snippets(), typst.text_autosnippets()

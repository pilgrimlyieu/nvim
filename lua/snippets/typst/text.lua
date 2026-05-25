---Typst text-mode snippets.
local groups = require("config.snippets.groups").values

if not groups.typst_text then
  return {}, {}
end

local conditions = require("config.snippets.conditions")
local typst = require("config.snippets.typst")
local text = conditions.wrap(conditions.typst_text)

return typst.text_snippets(text), typst.text_autosnippets(text)

---Typst math snippets.
---
---Use Typst-native math calls (`frac`, `mat`, `cases`, `product`, etc.) instead
---of LaTeX commands.  The context is guarded by Tree-sitter only; there is no
---buffer-text delimiter fallback for Typst scope.
local enabled = require("config.snippets.groups")

if not enabled("typst_math") then
  return {}, {}
end

local typst = require("config.snippets.typst")

return typst.math_snippets(), typst.math_autosnippets()

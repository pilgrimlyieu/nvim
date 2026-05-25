---Typst math snippets.
---
---Use Typst-native math calls (`frac`, `mat`, `cases`, `product`, etc.) instead
---of LaTeX commands.  The context is guarded by Tree-sitter only; there is no
---buffer-text delimiter fallback for Typst scope.
local groups = require("config.snippets.groups").values

if not groups.typst_math then
  return {}, {}
end

local conditions = require("config.snippets.conditions")
local typst = require("config.snippets.typst")
local math = conditions.wrap(conditions.typst_math)

return typst.math_snippets(math), typst.math_autosnippets(math)

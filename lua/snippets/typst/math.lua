local loading = require("config.snippets.core.loading")

local collect = loading.collect
local enabled = loading.enabled

if not enabled("typst_math") then
  return {}, {}
end

return collect("Typst", {
  "typst.math.decorations",
  "typst.math.fractions",
  "typst.math.matrices",
  "typst.math.operators",
  "typst.math.scripts",
  "typst.math.symbols",
  "typst.math.wrappers",
})

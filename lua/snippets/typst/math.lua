local loading = require("config.snippets.core.loading")

local collect = loading.collect
local enabled = loading.enabled

if not enabled("typst_math") then
  return {}, {}
end

return collect("Typst", {
  "typst.math.operators",
  "typst.math.matrices",
  "typst.math.wrappers",
  "typst.math.scripts",
  "typst.math.fractions",
  "typst.math.symbols",
})

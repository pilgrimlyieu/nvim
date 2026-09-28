---Shared LaTeX collection, built afresh for Markdown and TeX.
local M = {}

local loading = require("config.snippets.core.loading")

local collect = loading.collect
local enabled = loading.enabled

function M.build()
  if not enabled("latex_math") then
    return {}, {}
  end
  return collect("LaTeX", {
    "latex.math.operators",
    "latex.math.environments",
    "latex.math.wrappers",
    "latex.math.matrices",
    "latex.math.fractions",
    "latex.math.scripts",
    "latex.math.symbols",
    "latex.math.chemistry",
    "latex.math.sequences",
    "latex.math.cycles",
  })
end

return M

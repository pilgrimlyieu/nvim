---Typst-native feature definitions.
local M = {}

local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local symbols = require("config.snippets.shared.symbols")

local literal_autosnippet = constructors.literal_autosnippet
local symbol_autosnippets = symbols.symbol_autosnippets

function M.autosnippets()
  local condition = conditions.math
  local autos = symbol_autosnippets(require("config.snippets.shared.aliases"), "typst", condition)

  -- TODO: remove these self-expanding/conflict aliases since Typst has native support for them.
  -- Comparison (<= >= !=), logic (forall, and, or, not), membership and
  -- subset symbols are already native; self-expanding aliases add no capability.
  -- Typst already has native `AA`, `EE`, `NN`, `RR`, etc.  Temporarily Keep old
  -- LaTeX aliases like `exist`.
  for _, greek in ipairs(symbols.typst_short_greek) do
    autos[#autos + 1] = literal_autosnippet(
      ";" .. greek.trigger,
      greek.output,
      "short greek " .. greek.trigger,
      condition,
      { wordTrig = false }
    )
  end
  return autos
end

return M

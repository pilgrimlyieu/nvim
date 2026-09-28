---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")

local s = ls.snippet
local i = ls.insert_node

local with_condition = conditions.with_condition

function M.snippets()
  local condition = conditions.text
  local math = conditions.math
  return {
    s(with_condition({ trig = "ref", name = "reference" }, condition), fmta([[$\ref{<>}$]], { i(1) })),
    s(
      with_condition({ trig = "reff", name = "named reference" }, condition),
      fmta([[$\@ref{<>}{<>}$]], { i(1, "id"), i(2, "label") })
    ),
    s(with_condition({ trig = "eqr", name = "equation reference" }, condition), fmta([[$\eqref{<>}$]], { i(1) })),
    s(
      with_condition({ trig = "eqrr", name = "named equation reference" }, condition),
      fmta([[$\@eqref{<>}{<>}$]], { i(1, "id"), i(2, "label") })
    ),
    s(with_condition({ trig = "lab", name = "label" }, math), fmta([[\label{<>}]], { i(1) })),
    s(
      with_condition({ trig = "labb", name = "named label" }, math),
      fmta([[\@label{<>}{<>}]], { i(1, "id"), i(2, "label") })
    ),
    s(
      with_condition({ trig = "labbb", name = "named label without number" }, math),
      fmta([[\@@label{<>}{<>}]], { i(1, "id"), i(2, "label") })
    ),
  }
end

return M

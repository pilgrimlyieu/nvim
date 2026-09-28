---LaTeX chemistry; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local i = ls.insert_node

local literal_snippet = constructors.literal_snippet
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

function M.snippets()
  local not_chem_condition = conditions.not_chem
  local not_unit_condition = conditions.not_unit
  local chem_condition = conditions.chem

  local snippets = {
    s(with_condition({ trig = "ce", name = "chemistry" }, not_chem_condition), fmta([[\ce{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "pu", name = "unit" }, not_unit_condition), fmta([[\pu{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "=", name = "chemical equal", wordTrig = false }, chem_condition),
      fmta([[ \xlongequal[<>]{\enspace <>\enspace} ]], { i(1), i(2) })
    ),
  }

  return snippets
end

function M.autosnippets()
  local condition = conditions.math

  local autos = {
    literal_snippet("ssd", [[\ssd]], "celsius", condition, { snippetType = "autosnippet" }),
    literal_snippet("hsd", [[\hsd]], "fahrenheit", condition, { snippetType = "autosnippet" }),
  }

  return autos
end

return M

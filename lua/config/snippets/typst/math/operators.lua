---Typst-native feature definitions.
local M = {}

local ls = require("luasnip")
local extras = require("luasnip.extras")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local i = ls.insert_node

local captured_insert = nodes.captured_insert
local rep = extras.rep
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

function M.snippets()
  local condition = conditions.math
  local result = {
    s(
      with_condition({ trig = "bin", name = "binomial" }, condition),
      fmt("binom({}, {})", { visual_insert(1, "n"), i(2, "k") })
    ),
    s(
      with_condition({ trig = "sum", name = "sum" }, condition),
      fmt("sum_({} = {})^{} ", { i(1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "sum([%a])", name = "sum by variable", trigEngine = "pattern" }, condition),
      fmt("sum_({} = {})^{} ", { captured_insert(1, 1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "prod", name = "product" }, condition),
      fmt("product_({} = {})^{} ", { i(1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "prod([%a])", name = "product by variable", trigEngine = "pattern" }, condition),
      fmt("product_({} = {})^{} ", { captured_insert(1, 1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(with_condition({ trig = "lim", name = "limit" }, condition), fmt("lim_({} -> {}) ", { i(1, "x"), i(2, "oo") })),
    s(
      with_condition({ trig = "lim([%a])", name = "limit by variable", trigEngine = "pattern" }, condition),
      fmt("lim_({} -> {}) ", { captured_insert(1, 1, "x"), i(2, "oo") })
    ),
    s(
      with_condition({ trig = "int", name = "definite integral" }, condition),
      fmt("integral_{}^{} {} dif {}", { i(1, "0"), i(2, "oo"), visual_insert(3), i(4, "x") })
    ),
    s(
      with_condition({ trig = "nint", name = "indefinite integral" }, condition),
      fmt("integral {} dif {}", { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "df", name = "derivative" }, condition),
      fmt("frac(dif {}, dif {})", { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "pf", name = "partial derivative" }, condition),
      fmt("frac(partial {}, partial {})", { visual_insert(1), i(2, "x") })
    ),
  }
  for _, def in ipairs({ { "dfn", "dif", "higher derivative" }, { "pfn", "partial", "higher partial derivative" } }) do
    result[#result + 1] = s(
      with_condition({ trig = def[1], name = def[3] }, condition),
      fmt(
        "frac(" .. def[2] .. "^({}) {}, " .. def[2] .. " {}^({}))",
        { i(1, "n"), visual_insert(2), i(3, "x"), rep(1) }
      )
    )
  end
  return result
end

return M

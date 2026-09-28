---LaTeX environments; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local environments = require("config.snippets.latex.environments")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local environment_node = environments.environment_node
local math_environment_node = environments.math_environment_node
local with_condition = conditions.with_condition

function M.snippets()
  local condition = conditions.math
  local not_chem_condition = conditions.not_chem

  local snippets = {
    s(with_condition({ trig = "env", name = "environment" }, condition), { environment_node(1, false) }),
    s(with_condition({ trig = "envo", name = "environment with option" }, condition), { environment_node(1, true) }),
    s(with_condition({ trig = "case", name = "left brace aligned" }, condition), { math_environment_node(1, "case") }),
    s(with_condition({ trig = "cases", name = "cases" }, condition), { math_environment_node(1, "cases") }),
    s(with_condition({ trig = "align", name = "aligned equations" }, condition), { math_environment_node(1, "align") }),
    s(with_condition({ trig = "tag", name = "tag" }, condition), fmta([[\tag{<>}]], { i(1) })),
    s(
      with_condition({ trig = "=", name = "aligned equal", wordTrig = false, priority = 100 }, not_chem_condition),
      t("&=")
    ),
    s(with_condition({ trig = "&=", name = "plain equal", wordTrig = false }, condition), t("=")),
    s(with_condition({ trig = "def", name = "TeX def" }, condition), fmta([[\def<>{<>}]], { i(1), i(2) })),
    s(
      with_condition({ trig = "cmd", name = "new command" }, condition),
      fmta([[\newcommand<>[<>]{<>}]], { i(1), i(2), i(3) })
    ),
    s(
      with_condition({ trig = "rcmd", name = "renew command" }, condition),
      fmta([[\renewcommand<>[<>]{<>}]], { i(1), i(2), i(3) })
    ),
  }

  return snippets
end

function M.autosnippets()
  local condition = conditions.math

  local autos = {
    s(
      with_condition({ trig = [[\\]], name = "line break", wordTrig = false, snippetType = "autosnippet" }, condition),
      t([[\\ ]])
    ),
    s(
      with_condition(
        { trig = [[\.]], name = "paragraph line break", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      t({ [[\\]], "" })
    ),
    s(
      with_condition({ trig = "  !", name = "quad space", wordTrig = false, snippetType = "autosnippet" }, condition),
      t([[\quad ]])
    ),
  }

  return autos
end

return M

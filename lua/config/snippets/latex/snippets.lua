---Manual high-frequency LaTeX math snippets.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local nodes = require("config.snippets.nodes")
local symbols = require("config.snippets.symbols")
local triggers = require("config.snippets.triggers")
local h = require("config.snippets.latex.helpers")
local util = require("config.snippets.util")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

local with_condition = h.with_condition
local literal_snippet = h.literal_snippet
local cap = h.cap
local captured_insert = h.captured_insert
local matching_right_delimiter = h.matching_right_delimiter
local visual_insert = h.visual_insert
local environment_node = h.environment_node
local math_environment_node = h.math_environment_node
local matrix_node = h.matrix_node
local style_snippet = h.style_snippet

local M = {}

---@param fallback SnipCondition
---@param contexts SnipMathContexts?
---@param key "not_chem"|"not_unit"|"pure"|"chem"
---@return SnipCondition
local function context_or(fallback, contexts, key)
  return contexts and contexts[key] or fallback
end

---@param fallback SnipCondition
---@param contexts SnipMathContexts?
---@return SnipCondition
local function inline_or_display_condition(fallback, contexts)
  if contexts and contexts.inline and contexts.display then
    return util.or_conditions(contexts.inline, contexts.display)
  end
  return fallback
end

---Return high-frequency manual LaTeX math snippets.
---@param condition SnipCondition
---@param contexts? SnipMathContexts
---@return SnipNode[]
function M.math_snippets(condition, contexts)
  local layout_condition = inline_or_display_condition(condition, contexts)
  local not_chem_condition = context_or(condition, contexts, "not_chem")
  local not_unit_condition = context_or(condition, contexts, "not_unit")
  local chem_condition = context_or(condition, contexts, "chem")

  local snippets = {
    s(
      with_condition({ trig = "sqrt", name = "root" }, condition),
      fmta([[\sqrt[<>]{<>}]], { i(1, "3"), visual_insert(2) })
    ),
    s(with_condition({ trig = "gen", name = "square root" }, condition), fmta([[\sqrt{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "op", name = "operator name" }, condition),
      fmta([[\operatorname{<>}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "bin", name = "binomial" }, condition),
      fmta([[\dbinom{<>}{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "df", name = "derivative" }, condition),
      fmta([[\dfrac{\d <>}{\d <>}]], { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "pf", name = "partial derivative" }, condition),
      fmta([[\dfrac{\partial <>}{\partial <>}]], { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "d([%a])", trigEngine = "pattern", name = "derivative by variable" }, condition),
      fmta([[\dfrac{\d <>}{\d <>}]], { visual_insert(1), cap(1, "x") })
    ),
    s(
      with_condition({ trig = "pd([%a])", trigEngine = "pattern", name = "partial derivative by variable" }, condition),
      fmta([[\dfrac{\partial <>}{\partial <>}]], { visual_insert(1), cap(1, "x") })
    ),
    s(
      with_condition({ trig = "sum", name = "sum" }, condition),
      fmta([[\sum_{<>=<>}^{<>} ]], { i(1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "sum([%a])", trigEngine = "pattern", name = "sum by variable" }, condition),
      fmta([[\sum_{<>=<>}^{<>} ]], { d(1, captured_insert(1, "i")), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "prod", name = "product" }, condition),
      fmta([[\prod_{<>=<>}^{<>} ]], { i(1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "prod([%a])", trigEngine = "pattern", name = "product by variable" }, condition),
      fmta([[\prod_{<>=<>}^{<>} ]], { d(1, captured_insert(1, "i")), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "lim", name = "limit" }, condition),
      fmta([[\lim\limits_{<> \to <>} ]], { i(1, "x"), i(2, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "lim([%a])", trigEngine = "pattern", name = "limit by variable" }, condition),
      fmta([[\lim\limits_{<> \to <>} ]], { d(1, captured_insert(1, "x")), i(2, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "int", name = "definite integral" }, condition),
      fmta([[\int_{<>}^{<>} <> \d <>]], { i(1, "0"), i(2, [[\infty]]), visual_insert(3), i(4, "x") })
    ),
    s(
      with_condition({ trig = "nint", name = "indefinite integral" }, condition),
      fmta([[\int <> \d <>]], { visual_insert(1), i(2, "x") })
    ),
    s(with_condition({ trig = "env", name = "environment" }, layout_condition), { d(1, environment_node(false)) }),
    s(with_condition({ trig = "envo", name = "environment with option" }, layout_condition), { d(1, environment_node(true)) }),
    s(
      with_condition({ trig = "case", name = "left brace aligned" }, layout_condition),
      { d(1, math_environment_node("case")) }
    ),
    s(with_condition({ trig = "cases", name = "cases" }, layout_condition), { d(1, math_environment_node("cases")) }),
    s(with_condition({ trig = "align", name = "aligned" }, layout_condition), { d(1, math_environment_node("align")) }),
    s(with_condition({ trig = "txt", name = "text" }, condition), fmta([[\text{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "text", name = "text" }, condition), fmta([[\text{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "tt", name = "text" }, condition), fmta([[\text{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "ce", name = "chemistry" }, not_chem_condition), fmta([[\ce{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "pu", name = "unit" }, not_unit_condition), fmta([[\pu{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "buji", name = "complement" }, condition),
      fmta([[\complement_{<>}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "smash", name = "smash" }, condition),
      fmta([[\smash[<>]{<>}]], { nodes.choice(1, { "t", "b", " " }), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "LR", name = "left right" }, condition),
      fmta([[\left<> <> \right<>]], { i(1, "("), visual_insert(2), f(matching_right_delimiter, { 1 }) })
    ),
    s(
      with_condition({ trig = "()", wordTrig = false, name = "parentheses" }, condition),
      fmta([[\left( <> \right)]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "[]", wordTrig = false, name = "brackets" }, condition),
      fmta([=[\left[ <> \right]]=], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "{}", wordTrig = false, name = "braces" }, condition),
      fmta([[\left\lbrace <> \right\rbrace]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "||", wordTrig = false, name = "norm" }, condition),
      fmta([[\left\lVert <> \right\rVert]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "abs", name = "absolute value" }, condition),
      fmta([[\left\lvert <> \right\rvert]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "ceil", name = "ceil" }, condition),
      fmta([[\left\lceil <> \right\rceil]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "floor", name = "floor" }, condition),
      fmta([[\left\lfloor <> \right\rfloor]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "mat([2-5])([2-5])", trigEngine = "pattern", name = "matrix" }, condition),
      { d(1, matrix_node) }
    ),
    s(
      with_condition(
        { trig = "([pbBvV])mat([2-5])([2-5])", trigEngine = "pattern", name = "delimited matrix" },
        condition
      ),
      { d(1, matrix_node) }
    ),
    s(
      with_condition({
        trig = "mm",
        trigEngine = triggers.simple_matrix_engine,
        wordTrig = false,
        name = "simple old-style matrix",
      }, condition),
      { d(1, matrix_node) }
    ),
    s(with_condition({ trig = "bm", name = "bold math" }, condition), fmta([[\bm{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "tag", name = "tag" }, condition), fmta([[\tag{<>}]], { i(1) })),
    s(with_condition({ trig = "=", wordTrig = false, name = "aligned equal" }, not_chem_condition), t("&=")),
    s(
      with_condition({ trig = "=", wordTrig = false, name = "chemical equal" }, chem_condition),
      fmta([[ \xlongequal[<>]{\enspace <>\enspace} ]], { i(1), i(2) })
    ),
    s(with_condition({ trig = "&=", wordTrig = false, name = "plain equal" }, condition), t("=")),
    s(
      with_condition({ trig = "_=", name = "long equal" }, condition),
      fmta([[\xlongequal[<>]{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "_>", name = "long right arrow" }, condition),
      fmta([[\xrightarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "_<", name = "long left arrow" }, condition),
      fmta([[\xleftarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(with_condition({ trig = "|_>", name = "long mapsto" }, condition), fmta([[\xmapsto{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "boxed", name = "boxed" }, condition), fmta([[\boxed{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "cancel", name = "cancel" }, condition), fmta([[\cancel{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "clr", name = "text color" }, condition),
      fmta([[\textcolor{<>}{<>}]], { nodes.choice(1, { "ff0099", "da6904", "05aa94" }), visual_insert(2) })
    ),
    s(with_condition({ trig = "bar", name = "bar" }, condition), fmta([[\bar{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "hat", name = "hat" }, condition), fmta([[\hat{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "vec", name = "vector" }, condition), fmta([[\vec{<>}]], { visual_insert(1) })),
  }

  local literal_snippets = {
    { "in", [[\in ]], "in" },
    { "aleph", [[\aleph]], "aleph" },
    { "alef", [[\aleph]], "aleph alias" },
    { "re", [[\Re ]], "real part" },
    { "im", [[\Im ]], "imaginary part" },
  }

  for _, item in ipairs(literal_snippets) do
    table.insert(snippets, literal_snippet(item[1], item[2], item[3], condition))
  end

  for _, def in ipairs(symbols.math_styles) do
    if def.latex then
      vim.list_extend(snippets, style_snippet(def.trigger, def.latex, def.desc, condition))
    end
  end

  return snippets
end

return M

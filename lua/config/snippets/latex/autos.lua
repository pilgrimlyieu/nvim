---High-frequency LaTeX math autosnippets.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local symbols = require("config.snippets.symbols")
local triggers = require("config.snippets.triggers")
local h = require("config.snippets.latex.helpers")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local with_condition = h.with_condition
local literal_autosnippet = h.literal_autosnippet
local word_autosnippet = h.word_autosnippet
local word_auto_snippet = h.word_auto_snippet
local cap = h.cap
local matching_right_delimiter = h.matching_right_delimiter
local visual_insert = h.visual_insert

local M = {}

---@param fallback SnipCondition
---@param contexts SnipMathContexts?
---@param key "not_unit"|"pure"
---@return SnipCondition
local function context_or(fallback, contexts, key)
  return contexts and contexts[key] or fallback
end

---Return high-frequency LaTeX math autosnippets.
---@param condition SnipCondition
---@param contexts? SnipMathContexts
---@return SnipNode[]
function M.math_autosnippets(condition, contexts)
  local not_unit_condition = context_or(condition, contexts, "not_unit")
  local pure_condition = context_or(condition, contexts, "pure")

  local autos = {
    word_auto_snippet("sqrt", "root", condition, fmta([[\sqrt[<>]{<>}]], { i(1, "3"), visual_insert(2) })),
    word_auto_snippet("gen", "square root", condition, fmta([[\sqrt{<>}]], { visual_insert(1) })),
    word_auto_snippet(
      "LR",
      "left right",
      condition,
      fmta([[\left<> <> \right<>]], { i(1, "("), visual_insert(2), f(matching_right_delimiter, { 1 }) })
    ),
    word_auto_snippet("cancel", "cancel", condition, fmta([[\cancel{<>}]], { visual_insert(1) })),
    word_auto_snippet("buji", "complement", condition, fmta([[\complement_{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "_=", wordTrig = false, name = "long equal", snippetType = "autosnippet" }, condition),
      fmta([[\xlongequal[<>]{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition(
        { trig = "_>", wordTrig = false, name = "long right arrow", snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xrightarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition(
        { trig = "_<", wordTrig = false, name = "long left arrow", snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xleftarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition(
        { trig = "_<>", wordTrig = false, name = "long left arrow alias", snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xleftarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "|_>", wordTrig = false, name = "long mapsto", snippetType = "autosnippet" }, condition),
      fmta([[\xmapsto{<>}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "//", wordTrig = false, name = "fraction", snippetType = "autosnippet" }, not_unit_condition),
      fmta([[\dfrac{<>}{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition({
        trig = "/",
        trigEngine = triggers.simple_fraction_engine,
        wordTrig = false,
        name = "simple fraction",
        snippetType = "autosnippet",
      }, not_unit_condition),
      fmta([[\dfrac{<>}{<>}]], { cap(1), visual_insert(1) })
    ),
    s(
      with_condition({ trig = "<=", wordTrig = false, name = "le", snippetType = "autosnippet" }, condition),
      t([[\le ]])
    ),
    s(
      with_condition({ trig = ">=", wordTrig = false, name = "ge", snippetType = "autosnippet" }, condition),
      t([[\ge ]])
    ),
    s(
      with_condition({ trig = "!=", wordTrig = false, name = "ne", snippetType = "autosnippet" }, condition),
      t([[\ne ]])
    ),
    s(
      with_condition({ trig = "...", wordTrig = false, name = "dots", snippetType = "autosnippet" }, condition),
      t([[\dots]])
    ),
    s(
      with_condition({ trig = "+-", wordTrig = false, name = "pm", snippetType = "autosnippet" }, condition),
      t([[\pm ]])
    ),
    s(
      with_condition({ trig = "-+", wordTrig = false, name = "mp", snippetType = "autosnippet" }, condition),
      t([[\mp ]])
    ),
    s(
      with_condition({
        trig = "([%a])(%d)",
        trigEngine = "pattern",
        wordTrig = false,
        name = "auto numeric subscript",
        snippetType = "autosnippet",
      }, pure_condition),
      {
        f(function(_, snip)
          return snip.captures[1] .. "_" .. snip.captures[2]
        end),
      }
    ),
    s(
      with_condition({
        trig = ",([%a%d])",
        trigEngine = "pattern",
        wordTrig = false,
        name = "quick subscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "_" .. snip.captures[1]
        end),
      }
    ),
  }

  local literal_autos = {
    { "=>", [[\implies ]], "implies", { wordTrig = false } },
    { "==", [[\iff ]], "iff", { wordTrig = false } },
    { "->", [[\to ]], "to", { wordTrig = false } },
    { "<-", [[\gets ]], "gets", { wordTrig = false } },
    { "<>-", [[\gets]], "gets alias", { wordTrig = false } },
    { "-->", [[\rightrightarrows ]], "uniform convergence", { wordTrig = false, priority = 200 } },
    { "|->", [[\mapsto ]], "mapsto", { wordTrig = false } },
    { ":=", [[\coloneqq]], "definition", { wordTrig = false } },
    { ">>", [[\gg ]], "much greater", { wordTrig = false } },
    { "<<", [[\ll ]], "much less", { wordTrig = false } },
    { "~>", [[\succ ]], "successor relation", { wordTrig = false } },
    { "~<", [[\prec ]], "predecessor relation", { wordTrig = false } },
    { ">~", [[\succcurlyeq ]], "successor equal relation", { wordTrig = false } },
    { "<~", [[\preccurlyeq ]], "predecessor equal relation", { wordTrig = false } },
    { "~~", [[\approx ]], "approx", { wordTrig = false } },
    { "=~", [[\sim ]], "similar", { wordTrig = false } },
    { "~=", [[\cong ]], "congruent", { wordTrig = false } },
    { "=-", [[\equiv ]], "equivalent", { wordTrig = false } },
    { "|=", [[\models ]], "models", { wordTrig = false } },
    { "|-", [[\vdash ]], "entails", { wordTrig = false } },
    { "<|", [[\trianglelefteq ]], "normal subgroup", { wordTrig = false } },
    { ",.", [[,\, ]], "thin comma", { wordTrig = false } },
    { "-.", [[\cdot ]], "center dot", { wordTrig = false } },
    { "o-", [[\circ ]], "circ", { wordTrig = false } },
    { "tim", [[\times ]], "times" },
    { "xx", [[\times ]], "times alias" },
    { "div", [[\div ]], "division" },
    { "mod", [[\bmod]], "mod" },
    { "TT", [[\mathbf{T}]], "true" },
    { "FF", [[\mathbf{F}]], "false" },
    { "bhb", [[\subset ]], "subset" },
    { "bhp", [[\supset ]], "supset" },
    { "oc", [[\propto ]], "proportional" },
    { "ooo", [[\infty ]], "infinity" },
    { "nabla", [[\nabla ]], "nabla" },
    { "ang", [[\angle ]], "angle" },
    { "tri", [[\triangle ]], "triangle" },
    { "deg", [[\degree ]], "degree" },
    { "par", [[\parallel ]], "parallel" },
    { "perp", [[\perp ]], "perpendicular" },
    { "exist", [[\exists ]], "exists" },
    { "EE", [[\exists ]], "exists alias" },
    { "forall", [[\forall ]], "forall" },
    { "AA", [[\forall ]], "forall alias" },
    { "empty", [[\emptyset ]], "empty set" },
    { "kj", [[\emptyset ]], "empty set alias" },
    { "cap", [[\cap ]], "intersection" },
    { "jiao", [[\cap ]], "intersection alias" },
    { "cup", [[\cup ]], "union" },
    { "bing", [[\cup ]], "union alias" },
    { "yw", [[\because ]], "because" },
    { "sy", [[\therefore ]], "therefore" },
    { "and", [[\land ]], "logical and" },
    { "or", [[\lor ]], "logical or" },
    { "not", [[\lnot ]], "logical not" },
  }

  for _, item in ipairs(literal_autos) do
    local trigger, output, desc, extra = item[1], item[2], item[3], item[4]
    if extra and extra.wordTrig == false then
      table.insert(autos, literal_autosnippet(trigger, output, desc, condition, extra))
    else
      table.insert(autos, word_autosnippet(trigger, output, desc, condition, extra))
    end
  end

  local common_functions = {
    "sin",
    "cos",
    "tan",
    "ln",
    "lg",
    "log",
    "max",
    "min",
    "arg",
    "det",
    "exp",
    "csc",
    "sec",
    "arcsin",
    "arccos",
    "arctan",
    "sinh",
    "cosh",
    "tanh",
    "cot",
    "coth",
    "gcd",
    "sup",
    "inf",
    "diag",
  }

  for _, name in ipairs(common_functions) do
    table.insert(autos, word_autosnippet(name, "\\" .. name, "operator " .. name, condition))
  end

  for _, greek in ipairs(symbols.latex_long_greek) do
    table.insert(autos, word_autosnippet(greek.trigger, "\\" .. greek.output, "greek " .. greek.trigger, condition))
  end

  for _, greek in ipairs(symbols.latex_upper_greek) do
    table.insert(
      autos,
      word_autosnippet(greek.trigger, "\\" .. greek.output, "upper greek " .. greek.trigger, condition)
    )
  end

  return autos
end

return M

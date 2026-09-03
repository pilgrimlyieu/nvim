---Manual low-frequency LaTeX math snippets.
---
---These snippets are normal completion/trigger snippets rather than typing-time
---autosnippets.  They are grouped apart from the helper engines so the actual
---snippet inventory is easier to scan.
local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local conditions = require("config.snippets.conditions")
local h = require("config.snippets.latex_extra.helpers")
local util = require("config.snippets.util")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local with_condition = conditions.with_condition
local cap = util.capture_nonempty
local literal = util.literal_snippet
local choose_next = util.choose_next
local suffix_cycle_engine = h.suffix_cycle_engine
local integral_engine = h.integral_engine
local angle_content_engine = h.angle_content_engine
local cycle = h.cycle
local braced_command_cycle = h.braced_command_cycle
local symbolic_matrix_engine = h.symbolic_matrix_engine
local symbolic_matrix_node = h.symbolic_matrix_node
local roman = h.roman
local visual_insert = util.visual_insert

local M = {}

---Return low-frequency manual LaTeX math snippets.
---@return SnipNode[]
function M.math_snippets()
  local condition = conditions.math
  local snippets = {
    s(
      with_condition({ trig = ",i=", name = "given i", wordTrig = false }, condition),
      fmta([[,\,i=<>, <>, \dots, <>. <>]], { i(1, "1"), i(2, "2"), i(3, "n"), i(0) })
    ),

    s(
      with_condition({ trig = "dot", name = "indexed sequence" }, condition),
      fmta([[<>_1, <>_2, \dots, <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot.", name = "indexed sequence with thin spaces" }, condition),
      fmta([[<>_1,\, <>_2,\, \dots,\, <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot;", name = "semicolon indexed sequence" }, condition),
      fmta([[<>_1; <>_2; \dots; <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1", name = "short indexed sequence" }, condition),
      fmta([[<>_1, \dots, <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1.", name = "short indexed sequence with thin spaces" }, condition),
      fmta([[<>_1,\, \dots,\, <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1;", name = "short semicolon indexed sequence" }, condition),
      fmta([[<>_1; \dots; <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp", name = "upper indexed sequence" }, condition),
      fmta([[<>^1, <>^2, \dots, <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp.", name = "upper indexed sequence with thin spaces" }, condition),
      fmta([[<>^1,\, <>^2,\, \dots,\, <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp;", name = "semicolon upper indexed sequence" }, condition),
      fmta([[<>^1; <>^2; \dots; <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1", name = "short upper indexed sequence" }, condition),
      fmta([[<>^1, \dots, <>^n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1.", name = "short upper indexed sequence with thin spaces" }, condition),
      fmta([[<>^1,\, \dots,\, <>^n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1;", name = "short semicolon upper indexed sequence" }, condition),
      fmta([[<>^1; \dots; <>^n]], { i(1), rep(1) })
    ),

    s(with_condition({ trig = "def", name = "TeX def" }, condition), fmta([[\def<>{<>}<>]], { i(1), i(2), i(0) })),
    s(
      with_condition({ trig = "cmd", name = "new command" }, condition),
      fmta([[\newcommand<>[<>]{<>}<>]], { i(1), i(2), i(3), i(0) })
    ),
    s(
      with_condition({ trig = "rcmd", name = "renew command" }, condition),
      fmta([[\renewcommand<>[<>]{<>}<>]], { i(1), i(2), i(3), i(0) })
    ),
    s(
      with_condition({ trig = "zb", name = "plane coordinate" }, condition),
      fmta([[\left(<> , <>\right)<>]], { i(1), i(2), i(0) })
    ),

    s(
      with_condition({
        trig = "definite-integral-variant",
        trigEngine = integral_engine(true),
        wordTrig = false,
        name = "definite integral variant",
      }, condition),
      fmta([[<>_{<>}^{<>} <> \d <>]], { cap(1), i(1, "0"), i(2, [[\infty]]), i(3), cap(2, "x") })
    ),
    s(
      with_condition({
        trig = "indefinite-integral-variant",
        trigEngine = integral_engine(false),
        wordTrig = false,
        name = "indefinite integral variant",
      }, condition),
      fmta([[<> <> \d <>]], { cap(1), i(1), cap(2, "x") })
    ),

    s(
      with_condition({ trig = ",", name = "subscript", wordTrig = false }, condition),
      fmta([[_{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "'", name = "superscript", wordTrig = false }, condition),
      fmta([[^{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "subst", name = "substack" }, condition),
      fmta([[_{\substack{<>}}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "''", name = "derivative order", wordTrig = false }, condition),
      fmta([[^{(<>)}<>]], { visual_insert(1), i(0) })
    ),
    literal("pp", [[\partial ]], "partial", condition),

    s(
      with_condition({ trig = [[\)]], name = "parentheses", wordTrig = false }, condition),
      fmta([[\left( <> \right)<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\bb]], name = "LaTeX parentheses", wordTrig = false }, condition),
      fmta([[\left( <> \right)<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [=[\]]=], name = "brackets", wordTrig = false }, condition),
      fmta([=[\left[ <> \right]<>]=], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\}]], name = "braces", wordTrig = false }, condition),
      fmta([[\left\lbrace <> \right\rbrace<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\|]], name = "verticals", wordTrig = false }, condition),
      fmta([[\left\lvert <> \right\rvert<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\>]], name = "angle brackets", wordTrig = false }, condition),
      fmta([[\left\langle <> \right\rangle<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({
        trig = "angle-content",
        trigEngine = angle_content_engine(),
        wordTrig = false,
        name = "angle brackets around content",
      }, condition),
      fmta([[\left\langle <> \right\rangle]], { cap(1) })
    ),

    s(with_condition({ trig = [[\\]], name = "line break", wordTrig = false }, condition), t([[\\ ]])),
    s(
      with_condition({ trig = [[\.]], name = "paragraph line break", wordTrig = false }, condition),
      t({ [[\\]], "", "" })
    ),
    literal("dis", [[\displaystyle ]], "display style", condition),
    literal("tes", [[\textstyle ]], "text style", condition),
    literal("lts", [[\limits]], "limits", condition, { wordTrig = false }),
    s(
      with_condition({ trig = "cbox", name = "theorem box" }, conditions.display_math),
      fmta([[\fcolorbox{#FF69B4}{trasparent}{$<>$}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "pha", name = "phantom" }, condition),
      fmta([[\phantom{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "hpha", name = "horizontal phantom" }, condition),
      fmta([[\hphantom{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "flr", name = "floor" }, condition),
      fmta([[\left\lfloor <> \right\rfloor<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "cil", name = "ceil" }, condition),
      fmta([[\left\lceil <> \right\rceil<>]], { visual_insert(1), i(0) })
    ),
    s(with_condition({ trig = "(%d%d?%d?%d?)rmn", trigEngine = "pattern", name = "roman number" }, condition), {
      f(function(_, snip)
        local value = tonumber(snip.captures[1])
        local result = value and roman(value)
        return result and "\\mathrm{" .. result .. "}" or snip.captures[1]
      end),
    }),

    s(
      with_condition({
        trig = "symbolic-matrix",
        trigEngine = symbolic_matrix_engine("plain"),
        wordTrig = false,
        name = "symbolic matrix",
      }, condition),
      { symbolic_matrix_node("plain") }
    ),
    s(
      with_condition({
        trig = "diagonal-matrix",
        trigEngine = symbolic_matrix_engine("diag"),
        wordTrig = false,
        name = "diagonal symbolic matrix",
      }, condition),
      { symbolic_matrix_node("diag") }
    ),
    s(
      with_condition({
        trig = "upper-triangular-matrix",
        trigEngine = symbolic_matrix_engine("upper"),
        wordTrig = false,
        name = "upper triangular symbolic matrix",
      }, condition),
      { symbolic_matrix_node("upper") }
    ),
    s(
      with_condition({
        trig = "lower-triangular-matrix",
        trigEngine = symbolic_matrix_engine("lower"),
        wordTrig = false,
        name = "lower triangular symbolic matrix",
      }, condition),
      { symbolic_matrix_node("lower") }
    ),
    s(
      with_condition(
        { trig = "([\\%w]+)mt", trigEngine = "pattern", wordTrig = false, name = "matrix symbol" },
        condition
      ),
      fmta([[\bm{<>}]], { cap(1) })
    ),
  }

  local cycle_snippets = {
    { "colon", { [[:]], [[\colon]], [[:\:]] } },
    { "semicolon", { [[;]], [[;\;]] } },
    { "big size", { [[\big]], [[\Big]], [[\bigg]], [[\Bigg]] } },
    { "spacing", { [[\!]], [[\,]], [[\:]], [[\;]], [[\quad]], [[\qquad]] } },
    { "dots", { [[\dots]], [[\cdots]], [[\vdots]], [[\ddots]] } },
    { "infinity sign", { [[\infty]], [[-\infty]], [[+\infty]] } },
    { "plus minus", { [[\pm]], [[\mp]] } },
    { "dot product", { [[\cdot]], [[\boldsymbol{\cdot}]] } },
    { "cross product", { [[\times]], [[\boldsymbol{\times}]] } },
    { "operator star", { [[\operatorname]], [[\operatorname*]] } },
    {
      "left arrow",
      { [[\leftarrow]], [[\gets]], [[\longleftarrow]], [[\Leftarrow]], [[\Longleftarrow]], [[\impliedby]] },
    },
    {
      "right arrow",
      { [[\rightarrow]], [[\to]], [[\longrightarrow]], [[\Rightarrow]], [[\Longrightarrow]], [[\implies]] },
    },
    {
      "left right arrow",
      { [[\leftrightarrow]], [[\longleftrightarrow]], [[\Leftrightarrow]], [[\Longleftrightarrow]], [[\iff]] },
    },
    { "logical terms", { [[\because]], [[\therefore]], [[\land]], [[\lor]], [[\lnot]] } },
    { "and operator", { [[\land]], [[\bigwedge]] } },
    { "or operator", { [[\lor]], [[\bigvee]] } },
    { "similar relation", { [[\sim]], [[\nsim]] } },
    { "congruent relation", { [[\cong]], [[\ncong]] } },
    { "le relation", { [[\le]], [[\nle]] } },
    { "ge relation", { [[\ge]], [[\nge]] } },
    { "exists relation", { [[\exists]], [[\nexists]], [[\forall]] } },
    { "in relation", { [[\in]], [[\notin]], [[\ni]], [[\notni]] } },
    { "mid relation", { [[|]], [[\mid]] } },
    { "cap operator", { [[\cap]], [[\bigcap]], [[\cup]], [[\bigcup]] } },
    { "subset relation", { [[\subset]], [[\subseteq]], [[\subsetneqq]], [[\supset]], [[\supseteq]], [[\supsetneqq]] } },
    { "bar h", { [[\bar{h}]], [[\hbar]] } },
    { "phantom", { [[\phantom]], [[\hphantom]] } },
    { "epsilon variant", { [[\epsilon]], [[\varepsilon]] } },
    { "theta variant", { [[\theta]], [[\vartheta]] } },
    { "Theta variant", { [[\Theta]], [[\varTheta]] } },
    { "phi variant", { [[\phi]], [[\varphi]] } },
    { "Phi variant", { [[\Phi]], [[\varPhi]] } },
    { "sigma variant", { [[\sigma]], [[\varsigma]] } },
    { "kappa variant", { [[\kappa]], [[\varkappa]] } },
    { "rho variant", { [[\rho]], [[\varrho]] } },
    { "gamma case", { [[\gamma]], [[\Gamma]] } },
    { "delta case", { [[\delta]], [[\Delta]] } },
    { "lambda case", { [[\lambda]], [[\Lambda]] } },
    { "xi case", { [[\xi]], [[\Xi]] } },
    { "upsilon case", { [[\upsilon]], [[\Upsilon]] } },
    { "psi case", { [[\psi]], [[\Psi]] } },
    { "omega case", { [[\omega]], [[\Omega]] } },
  }

  for _, item in ipairs(cycle_snippets) do
    snippets[#snippets + 1] = cycle(item[1], item[2])
  end

  snippets[#snippets + 1] = s(
    with_condition({
      trig = "space suffix cycle",
      trigEngine = suffix_cycle_engine({ [[\!]], [[\,]], [[\:]], [[\;]], [[\quad]], [[\qquad]] }),
      wordTrig = false,
      name = "space suffix cycle",
    }, condition),
    {
      f(function(_, snip)
        return choose_next(snip.captures[1] or [[\!]], { [[\!]], [[\,]], [[\:]], [[\;]], [[\quad]], [[\qquad]] })
          .. (snip.captures[2] or "")
      end),
    }
  )

  snippets[#snippets + 1] = braced_command_cycle("frac display cycle", { [[\frac]], [[\dfrac]] }, 2)
  snippets[#snippets + 1] = braced_command_cycle("binom display cycle", { [[\binom]], [[\dbinom]] }, 2)
  snippets[#snippets + 1] = braced_command_cycle("operator star cycle", { [[\operatorname]], [[\operatorname*]] }, 1)
  snippets[#snippets + 1] =
    braced_command_cycle("cancel command cycle", { [[\cancel]], [[\bcancel]], [[\xcancel]], [[\sout]] }, 1)
  snippets[#snippets + 1] = braced_command_cycle("bar command cycle", { [[\bar]], [[\overline]] }, 1)
  snippets[#snippets + 1] = braced_command_cycle("hat command cycle", { [[\hat]], [[\widehat]] }, 1)
  snippets[#snippets + 1] = braced_command_cycle("vec command cycle", { [[\vec]], [[\overrightarrow]] }, 1)
  snippets[#snippets + 1] = braced_command_cycle("phantom command cycle", { [[\phantom]], [[\hphantom]] }, 1)

  return snippets
end

return M

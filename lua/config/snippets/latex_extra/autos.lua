---Autosnippets from the legacy low-frequency LaTeX math collection.
---
---These keep UltiSnips `A`/postfix-style behavior for delimiters, accents,
---slash cycles, numeric sub/superscripts, and compact spacing helpers.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local h = require("config.snippets.latex_extra.helpers")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local with_condition = h.with_condition
local literal = h.literal
local accent_postfix_engine = h.accent_postfix_engine
local accented_postfix = h.accented_postfix
local annotation_autosnippet = h.annotation_autosnippet
local slash_cycle_autosnippet = h.slash_cycle_autosnippet
local visual_insert = h.visual_insert

local M = {}

---Return low-frequency LaTeX math autosnippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_autosnippets(condition)
  return {
    s(
      with_condition({ trig = ",i=", wordTrig = false, name = "given i", snippetType = "autosnippet" }, condition),
      fmta([[,\,i=<>, <>, \dots, <>. <>]], { i(1, "1"), i(2, "2"), i(3, "n"), i(0) })
    ),
    s(
      with_condition({ trig = [[\)]], wordTrig = false, name = "parentheses", snippetType = "autosnippet" }, condition),
      fmta([[\left( <> \right)<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition(
        { trig = [[\bb]], wordTrig = false, name = "LaTeX parentheses", snippetType = "autosnippet" },
        condition
      ),
      fmta([[\left( <> \right)<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [=[\]]=], wordTrig = false, name = "brackets", snippetType = "autosnippet" }, condition),
      fmta([=[\left[ <> \right]<>]=], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\}]], wordTrig = false, name = "braces", snippetType = "autosnippet" }, condition),
      fmta([[\left\lbrace <> \right\rbrace<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition(
        { trig = [[\>]], wordTrig = false, name = "angle brackets", snippetType = "autosnippet" },
        condition
      ),
      fmta([[\left\langle <> \right\rangle<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = [[\\]], wordTrig = false, name = "line break", snippetType = "autosnippet" }, condition),
      t([[\\ ]])
    ),
    s(
      with_condition(
        { trig = [[\.]], wordTrig = false, name = "paragraph line break", snippetType = "autosnippet" },
        condition
      ),
      t({ [[\\]], "", "" })
    ),
    s(
      with_condition({ trig = "  !", wordTrig = false, name = "quad space", snippetType = "autosnippet" }, condition),
      t([[\quad ]])
    ),
    s(
      with_condition({ trig = "pha", name = "phantom", snippetType = "autosnippet" }, condition),
      fmta([[\phantom{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "hpha", name = "horizontal phantom", snippetType = "autosnippet" }, condition),
      fmta([[\hphantom{<>}<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "flr", name = "floor", snippetType = "autosnippet" }, condition),
      fmta([[\left\lfloor <> \right\rfloor<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({ trig = "cil", name = "ceil", snippetType = "autosnippet" }, condition),
      fmta([[\left\lceil <> \right\rceil<>]], { visual_insert(1), i(0) })
    ),
    s(
      with_condition({
        trig = "accent-postfix",
        trigEngine = accent_postfix_engine(),
        wordTrig = false,
        name = "accent postfix",
        snippetType = "autosnippet",
        priority = 500,
      }, condition),
      {
        f(function(_, snip)
          return accented_postfix(snip.captures[1] or "", snip.captures[2] or "", snip.captures[3] or "bar")
        end),
      }
    ),
    annotation_autosnippet("overbrace postfix", "%%%^", "%^", [[\overbrace]], "^", condition),
    annotation_autosnippet("underbrace postfix", "%%%_", "%_", [[\underbrace]], "_", condition),
    s(
      with_condition({
        trig = "_(%d%d)",
        trigEngine = "pattern",
        wordTrig = false,
        name = "group numeric subscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "_{" .. snip.captures[1] .. "}"
        end),
      }
    ),
    s(
      with_condition({
        trig = "_%{(%d+)%}(%d)",
        trigEngine = "pattern",
        wordTrig = false,
        name = "append numeric subscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "_{" .. snip.captures[1] .. snip.captures[2] .. "}"
        end),
      }
    ),
    s(
      with_condition({
        trig = "'([%d%-])",
        trigEngine = "pattern",
        wordTrig = false,
        name = "quick numeric superscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "^" .. snip.captures[1]
        end),
      }
    ),
    s(
      with_condition({
        trig = "'([%a])",
        trigEngine = "pattern",
        wordTrig = false,
        name = "quick letter superscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "^" .. snip.captures[1]
        end),
      }
    ),
    s(
      with_condition({
        trig = "%^([%-]?%d%d)",
        trigEngine = "pattern",
        wordTrig = false,
        name = "group numeric superscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "^{" .. snip.captures[1] .. "}"
        end),
      }
    ),
    s(
      with_condition({
        trig = "%^%{(%-?%d+)%}(%d)",
        trigEngine = "pattern",
        wordTrig = false,
        name = "append numeric superscript",
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return "^{" .. snip.captures[1] .. snip.captures[2] .. "}"
        end),
      }
    ),
    s(
      with_condition(
        { trig = "%^tt", trigEngine = "pattern", wordTrig = false, name = "transpose", snippetType = "autosnippet" },
        condition
      ),
      t([[^\intercal]])
    ),
    slash_cycle_autosnippet("subset slash reverse", {
      [[\subset]],
      [[\supset]],
    }, condition),
    slash_cycle_autosnippet("subseteq slash reverse", {
      [[\subseteq]],
      [[\supseteq]],
    }, condition),
    slash_cycle_autosnippet("subsetneqq slash reverse", {
      [[\subsetneqq]],
      [[\supsetneqq]],
    }, condition),
    slash_cycle_autosnippet("cap cup slash reverse", {
      [[\cap]],
      [[\cup]],
    }, condition),
    slash_cycle_autosnippet("big cap cup slash reverse", {
      [[\bigcap]],
      [[\bigcup]],
    }, condition),
    slash_cycle_autosnippet("in ni slash reverse", {
      [[\in]],
      [[\ni]],
    }, condition),
    slash_cycle_autosnippet("notin notni slash reverse", {
      [[\notin]],
      [[\notni]],
    }, condition),
    slash_cycle_autosnippet("le slash not", {
      [[\le]],
      [[\nle]],
    }, condition),
    slash_cycle_autosnippet("ge slash not", {
      [[\ge]],
      [[\nge]],
    }, condition),
    slash_cycle_autosnippet("cong slash not", {
      [[\cong]],
      [[\ncong]],
    }, condition),
    slash_cycle_autosnippet("sim slash not", {
      [[\sim]],
      [[\nsim]],
    }, condition),
    slash_cycle_autosnippet("par slash not", {
      [[\par]],
      [[\npar]],
    }, condition),
    slash_cycle_autosnippet("land slash big", {
      [[\land]],
      [[\bigwedge]],
    }, condition),
    slash_cycle_autosnippet("lor slash big", {
      [[\lor]],
      [[\bigvee]],
    }, condition),
    slash_cycle_autosnippet("exists slash not", {
      [[\exists]],
      [[\nexists]],
    }, condition, "[_%{%}%w\\,%s]*"),
    slash_cycle_autosnippet("right arrow slash not", {
      [[\Rightarrow]],
      [[\nRightarrow]],
    }, condition),
    slash_cycle_autosnippet("left arrow slash not", {
      [[\Leftarrow]],
      [[\nLeftarrow]],
    }, condition),
    slash_cycle_autosnippet("left right arrow slash not", {
      [[\Leftrightarrow]],
      [[\nLeftrightarrow]],
    }, condition),
    slash_cycle_autosnippet("implies slash not", {
      [[\implies]],
      [[\nimplies]],
    }, condition),
    slash_cycle_autosnippet("impliedby slash not", {
      [[\impliedby]],
      [[\nimpliedby]],
    }, condition),
    slash_cycle_autosnippet("iff slash not", {
      [[\iff]],
      [[\niff]],
    }, condition),
    literal("ssd", [[\ssd]], "celsius", condition, { snippetType = "autosnippet" }),
    literal("hsd", [[\hsd]], "fahrenheit", condition, { snippetType = "autosnippet" }),
  }
end

return M

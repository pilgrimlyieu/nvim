---TODO: deprecate all

---Course-specific snippets migrated from the old `tex_course` collection.
---
---Most of these are plain domain abbreviations.  Keeping them in data tables
---makes the large legacy set easier to audit and disable by topic later.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local util = require("config.snippets.util")

local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

local M = {}
local choose_next = util.choose_next
local exact_cycle_engine = util.exact_cycle_engine
local with_condition = util.with_condition

---Build a course literal snippet under a shared condition.
---@param trigger string
---@param body string
---@param name string
---@param condition SnipCondition
---@return SnipNode
local function literal(trigger, body, name, condition)
  return util.literal_snippet(trigger, body, name, condition)
end

---Match electron-pair cycle triggers such as `\pe/`, `\npe/`, `\nnpe/`.
---@return SnipTriggerEngine
local function electron_pair_engine()
  return function()
    return function(line_to_cursor)
      local prefix = line_to_cursor:sub(math.max(1, #line_to_cursor - 8)):match("\\(n*)pe/$")
      if prefix == nil then
        return nil
      end
      return "\\" .. prefix .. "pe/", { prefix }
    end
  end
end

---Match single-electron cycle triggers such as `\se/` and `\nse/`.
---@return SnipTriggerEngine
local function single_electron_engine()
  return function()
    return function(line_to_cursor)
      local prefix = line_to_cursor:sub(math.max(1, #line_to_cursor - 8)):match("\\(n?)se/$")
      if prefix == nil then
        return nil
      end
      return "\\" .. prefix .. "se/", { prefix }
    end
  end
end

---Match orbital shorthand like `2pee` or `3deo`.
---@param kind "pair"|"orbital"
---@return SnipTriggerEngine
local function orbital_engine(kind)
  return function()
    return function(line_to_cursor)
      local prefix = line_to_cursor:sub(math.max(1, #line_to_cursor - 8))
      local level, shell = prefix:match("([%dn])([spdfg])" .. (kind == "pair" and "ee" or "eo") .. "$")
      if not level then
        return nil
      end
      return level .. shell .. (kind == "pair" and "ee" or "eo"), { level, shell }
    end
  end
end

---Build orbital occupancy nodes for paired or editable electrons.
---@param kind "pair"|"orbital"
---@return SnipNode
local function orbital_node(kind)
  local counts = { s = 1, p = 3, d = 5, f = 7, g = 9 }

  return d(1, function(_, snip)
    local level = snip.captures[1] or "2"
    local shell = snip.captures[2] or "p"
    local count = counts[shell] or 1
    local result = { t([[\overset{\normalsize ]] .. level .. [[\ce{]] .. shell .. [[}}{]]) }

    for index = 1, count do
      if kind == "pair" then
        result[#result + 1] = t([[\pe]])
      else
        result[#result + 1] = t([[\oe]])
        result[#result + 1] = i(index)
      end
    end

    result[#result + 1] = t("}")
    if kind == "pair" then
      result[#result + 1] = i(1)
    else
      result[#result + 1] = i(count + 1)
    end

    return sn(nil, result)
  end)
end

---Return course/domain snippets used in math contexts.
---@param condition SnipCondition
---@return SnipNode[]
---TODO:
function M.math_snippets(condition)
  local snippets = {
    s(
      with_condition({ trig = "jiuu([%w'|%(%+%-]+)", trigEngine = "pattern", name = "series" }, condition),
      fmta([[\displaystyle\sum_{n=1}^{\infty} <>_n]], {
        require("luasnip").function_node(function(_, snip)
          return snip.captures[1] or ""
        end),
      })
    ),

    literal("lat", [[(L, \wedge, \vee)]], "lattice", condition),
    literal("blat", [[(L, \wedge, \vee, \bm{0}, \bm{1})]], "bounded lattice", condition),
    literal("bool", [[(B, \wedge, \vee, \bar{\phantom{a}}, \bm{0}, \bm{1})]], "Boolean algebra", condition),
    literal("asys", [[\left\langle S, \circ \right\rangle]], "algebraic system", condition),
    literal("gp", [[\left\langle G, * \right\rangle]], "group", condition),
    literal("grp", [[\left\langle G, *, e, ^{-1} \right\rangle]], "group with inverse", condition),
    literal("gr", [[(V, E)]], "graph", condition),
    literal("gra", [[(V, E, \varphi)]], "graph with incidence", condition),

    literal("data", [[\left\lbrace (\bm{x}_i, y_i) \right\rbrace_{i=1}^m]], "supervised dataset", condition),
    literal(
      "datas",
      [[\left\lbrace (\bm{x}_1, y_1),\, (\bm{x}_2, y_2),\, \cdots,\, (\bm{x}_m, y_m) \right\rbrace]],
      "expanded supervised dataset",
      condition
    ),
    literal(
      "dats",
      [[\left\lbrace (\bm{x}_1, \bm{y}_1),\, (\bm{x}_2, \bm{y}_2),\, \cdots,\, (\bm{x}_m, \bm{y}_m) \right\rbrace]],
      "vector dataset",
      condition
    ),
    literal("data_0", [[\left\lbrace \bm{x}_i \right\rbrace_{i=1}^m]], "unsupervised dataset", condition),
    literal(
      "datas_0",
      [[\left\lbrace \bm{x}_1,\, \bm{x}_2,\, \cdots,\, \bm{x}_m \right\rbrace]],
      "expanded unsupervised dataset",
      condition
    ),
    literal(
      "dats_0",
      [[\left\lbrace \bm{x}_1,\, \bm{x}_2,\, \cdots,\, \bm{x}_m \right\rbrace]],
      "expanded unsupervised dataset alias",
      condition
    ),
    literal("ins", [[\bm{x} = (x_1; x_2; \cdots; x_d)]], "instance", condition),
    literal("inst", [[\bm{x}_i = (x_{i1}; x_{i2}; \cdots; x_{id})]], "indexed instance", condition),
    literal("ent", [[\operatorname{Ent}]], "entropy operator", condition),
    literal("entd", [[\operatorname{Ent}(D)]], "dataset entropy", condition),

    literal("pr", [[\Pr]], "probability", condition),
    literal("ps", [[(\Omega, \Sigma, \Pr)]], "probability space", condition),
    literal("psf", [[(\Omega, \mathcal{F}, \Pr)]], "probability space F", condition),
    s(with_condition({ trig = "ee", name = "expectation" }, condition), fmta([=[\mathbb{E} [<>]]=], { i(1, "X") })),
    s(
      with_condition({ trig = "var", name = "variance" }, condition),
      fmta([=[\operatorname{Var} [<>]]=], { i(1, "X") })
    ),
    literal("cov", [[\operatorname{Cov}]], "covariance", condition),
    literal("ind", [[\left\lbrace 0, 1 \right\rbrace]], "indicator set", condition),
    s(
      with_condition({ trig = "mag", name = "martingale" }, condition),
      fmta([[\left\lbrace <>_t \colon t \ge 0 \right\rbrace]], { i(1, "Y") })
    ),
    literal("rp", [[X_0, X_1, \dots, X_t]], "random process", condition),
    literal("od", [[\odot]], "odot", condition),

    s(
      with_condition({
        trig = "electron",
        trigEngine = exact_cycle_engine({ [[\oe]], [[\pe]], [[\se]] }, 16),
        wordTrig = false,
        name = "electron symbol cycle",
      }, condition),
      {
        f(function(_, snip)
          return choose_next(snip.captures[1] or [[\oe]], { [[\oe]], [[\pe]], [[\se]] })
        end),
      }
    ),
    s(
      with_condition({
        trig = "orbital-pair",
        trigEngine = orbital_engine("pair"),
        wordTrig = false,
        name = "orbital electron-pair expression",
      }, condition),
      { orbital_node("pair") }
    ),
    s(
      with_condition({
        trig = "orbital-electron",
        trigEngine = orbital_engine("orbital"),
        wordTrig = false,
        name = "orbital electron expression",
      }, condition),
      { orbital_node("orbital") }
    ),
    s(with_condition({ trig = "bond", name = "chemistry bond" }, condition), fmta([[\bond{<>}]], { i(1, "...") })),
  }

  return snippets
end

---Return course/domain autosnippets used in math contexts.
---@param condition SnipCondition
---@return SnipNode[]
---TODO:
function M.math_autosnippets(condition)
  return {
    s(
      with_condition({
        trig = "electron-pair",
        trigEngine = electron_pair_engine(),
        wordTrig = false,
        name = "electron pair cycle",
        snippetType = "autosnippet",
        priority = 1000,
      }, condition),
      {
        f(function(_, snip)
          return "\\" .. choose_next(snip.captures[1] or "", { "", "n", "nn" }) .. "pe"
        end),
      }
    ),
    s(
      with_condition({
        trig = "single-electron",
        trigEngine = single_electron_engine(),
        wordTrig = false,
        name = "single electron cycle",
        snippetType = "autosnippet",
        priority = 1000,
      }, condition),
      {
        f(function(_, snip)
          return "\\" .. choose_next(snip.captures[1] or "", { "", "n" }) .. "se"
        end),
      }
    ),
  }
end

---Return course/domain snippets used in text contexts.
---@param condition SnipCondition
---@return SnipNode[]
---TODO:
function M.text_snippets(condition)
  local line_condition = util.with_line_begin(condition)

  return {
    s(with_condition({ trig = "red", name = "red text marker" }, condition), t([[$\textcolor{red}{\text{red}}$ ]])),
    s(
      with_condition({ trig = "black", name = "black text marker" }, condition),
      t([[$\textcolor{orange}{\text{black}}$ ]])
    ),
    s(with_condition({ trig = "vsepr", name = "VSEPR" }, condition), t([[$\mathrm{VSEPR}$ ]])),
    s(
      with_condition({ trig = "pb", name = "problem block" }, line_condition),
      fmta(
        [[% <>
\begin{problem}
<>
\realans

\kpoint{不等式的应用}
\qtype{<>}
\difficulty{<>}

\realthink

\end{problem}
]],
        { i(3), i(0), i(1), i(2) }
      )
    ),
    s(
      with_condition({ trig = "choice", name = "choices" }, line_condition),
      fmta(
        [[\begin{choices}
    \item <>
    \item <>
    \item <>
    \item <>
\end{choices}
<>]],
        { i(1), i(2), i(3), i(4), i(0) }
      )
    ),
  }
end

---Return larger course template snippets.
---@param condition SnipCondition
---@return SnipNode[]
---TODO:
function M.template_snippets(condition)
  local first_line_condition = util.on_first_buffer_line(util.with_line_begin(condition))

  local function template(title_node, body_node)
    return {
      t({
        [[\documentclass[]],
        [[    UTF8,]],
        [[    12pt,]],
        [[    oneside,]],
        [[    a4paper]],
        [[]{ctexart}]],
        [[]],
        [[\usepackage{geometry}]],
        [[\usepackage{math_basic}]],
        [[\usepackage{private_information}]],
        [[]],
        [[\setmainfont{Times New Roman}]],
        [[\geometry{]],
        [[    a4paper,]],
        [[    left=2cm,]],
        [[    right=2cm,]],
        [[    top=3cm,]],
        [[    bottom=3cm]],
        [[}]],
        [[\pagestyle{plain}]],
        [[]],
        [[\title{]],
      }),
      title_node,
      t({
        [[}]],
        [[\author{]],
        [[    \sffamily 学号：\textbf{\PPIStudentID}\\]],
        [[    \sffamily 姓名：\PPIName\\]],
        [[}]],
        [[\date{\today}]],
        [[]],
        [[\begin{document}]],
        [[]],
        [[\maketitle]],
        [[]],
      }),
      body_node,
      t({
        [[]],
        [[\end{document}]],
      }),
    }
  end

  return {
    s(with_condition({ trig = "tmp", name = "homework template" }, first_line_condition), template(i(1), i(0))),
    s(
      with_condition({ trig = "dcm", name = "discrete math homework template" }, first_line_condition),
      template(
        fmta([[第 <> 次作业]], { i(1) }),
        sn(nil, {
          t({ [[\section{Problem 1}]], "" }),
          i(0),
          t({
            "",
            [[\section{Problem 2}]],
            "",
            [[\section{Problem 3}]],
            "",
            [[\section{Problem 4}]],
            "",
            [[\section{Problem 5}]],
            "",
            [[\section{Problem 6}]],
            "",
            [[\section{Problem 7}]],
            "",
            [[\section{Problem 8}]],
            "",
            [[\section{Problem 9}]],
            "",
            [[\section{Problem 10}]],
          }),
        })
      )
    ),
  }
end

return M

---Reusable Typst snippet builders.
---
---Typst math is intentionally not a LaTeX clone: math calls do not use `#` in
---formula mode, matrices use semicolons for rows, and `vec(...)` is a column
---vector rather than a vector accent.  The snippets below follow the bundled
---Typst reference from the `typst-author` skill and keep LaTeX-like triggers
---only where that helps muscle memory.
local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local nodes = require("config.snippets.nodes")
local symbols = require("config.snippets.symbols")
local triggers = require("config.snippets.triggers")
local util = require("config.snippets.util")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node

local M = {}
local cap = util.capture
local captured_insert = util.captured_insert
local literal_autosnippet = util.literal_autosnippet
local short_math_body = util.short_math_body
local captured_short_math_body = util.captured_short_math_body
local visual_insert = util.visual_insert
local with_condition = util.with_condition
local word_autosnippet = util.word_autosnippet

---Builds `mat(a, b; c, d)` with the requested dimensions.
---@param _ SnipNodeArgs
---@param snip SnipSnippet
---@return SnipNode
local function matrix_node(_, snip)
  local form = snip.captures[1] or ""
  local rows = tonumber(snip.captures[2]) or 2
  local cols = tonumber(snip.captures[3]) or rows

  if tonumber(form) then
    rows = tonumber(form) or 2
    cols = tonumber(snip.captures[2]) or rows
    form = ""
  elseif form == "m" then
    form = ""
  end

  local delimiter = {
    b = [["["]],
    B = [["{"]],
    v = [["|"]],
    V = [[("||", "||")]],
  }
  local matrix_nodes = { t("mat(") }
  local jump = 1

  if delimiter[form] then
    table.insert(matrix_nodes, t("delim: " .. delimiter[form] .. ", "))
  end

  for row = 1, rows do
    for col = 1, cols do
      table.insert(matrix_nodes, i(jump, row == col and "1" or "0"))
      jump = jump + 1
      if col < cols then
        table.insert(matrix_nodes, t(", "))
      end
    end
    if row < rows then
      table.insert(matrix_nodes, t({ ";", "  " }))
    end
  end

  table.insert(matrix_nodes, t(")"))
  return sn(nil, matrix_nodes)
end

---Build a manual Typst style wrapper plus a simple postfix alias.
---@param trigger string
---@param command string
---@param desc string
---@param condition SnipCondition
---@return SnipNode[]
local function style_snippet(trigger, command, desc, condition)
  return {
    s(with_condition({ trig = trigger, name = desc }, condition), fmt(command .. "({})", { visual_insert(1) })),
    s(
      with_condition(
        { trig = "([%a]+)" .. trigger, trigEngine = "pattern", wordTrig = false, name = desc .. " postfix" },
        condition
      ),
      fmt(command .. "({})", { cap(1) })
    ),
  }
end

---Return Typst text-mode snippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.text_snippets(condition)
  return {
    s(
      with_condition({ trig = "fig", name = "figure" }, condition),
      fmt(
        [[#figure(
  image("{}", width: {}),
  caption: [{}],
)]],
        { visual_insert(1), i(2, "80%"), i(3) }
      )
    ),
    s(
      with_condition({ trig = "tbl", name = "table" }, condition),
      fmt(
        [[#table(
  columns: {},
  [{}], [{}],
  [{}], [{}],
)]],
        { i(1, "2"), i(2, "Header"), i(3, "Header"), i(4), i(5) }
      )
    ),
    s(
      with_condition({ trig = "code", name = "raw block" }, condition),
      fmt(
        [[```{}
{}
```]],
        { i(1), visual_insert(2) }
      )
    ),
  }
end

---Return Typst text-mode autosnippets for math delimiters.
---@param condition SnipCondition
---@return SnipNode[]
function M.text_autosnippets(condition)
  return {
    s(
      with_condition({
        trig = "lm",
        trigEngine = triggers.short_math_word_engine,
        wordTrig = false,
        name = "inline math",
        snippetType = "autosnippet",
      }, condition),
      short_math_body("$", "$"),
      util.space_before_next_text_char_opts()
    ),
    s(
      with_condition({ trig = "dm", name = "display math", snippetType = "autosnippet" }, condition),
      fmt(
        [[$
{}
$]],
        { visual_insert(1) }
      )
    ),
    s(
      with_condition({
        trig = ",,",
        trigEngine = triggers.inline_math_postfix_engine,
        wordTrig = false,
        name = "inline captured math",
        snippetType = "autosnippet",
      }, condition),
      captured_short_math_body("$", 2, "$ ")
    ),
  }
end

---Return Typst math snippets and symbol aliases.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_snippets(condition)
  local snippets = {
    s(
      with_condition({ trig = "bin", name = "binomial" }, condition),
      fmt("binom({}, {})", { visual_insert(1, "n"), i(2, "k") })
    ),
    s(with_condition({ trig = "sqrt", name = "square root" }, condition), fmt("sqrt({})", { visual_insert(1) })),
    s(
      with_condition({ trig = "root", name = "root" }, condition),
      fmt("root({}, {})", { i(1, "n"), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "sum", name = "sum" }, condition),
      fmt("sum_({} = {})^{} ", { i(1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "sum([%a])", trigEngine = "pattern", name = "sum by variable" }, condition),
      fmt("sum_({} = {})^{} ", { d(1, captured_insert(1, "i")), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "prod", name = "product" }, condition),
      fmt("product_({} = {})^{} ", { i(1, "i"), i(2, "1"), i(3, "n") })
    ),
    s(
      with_condition({ trig = "prod([%a])", trigEngine = "pattern", name = "product by variable" }, condition),
      fmt("product_({} = {})^{} ", { d(1, captured_insert(1, "i")), i(2, "1"), i(3, "n") })
    ),
    s(with_condition({ trig = "lim", name = "limit" }, condition), fmt("lim_({} -> {}) ", { i(1, "x"), i(2, "oo") })),
    s(
      with_condition({ trig = "lim([%a])", trigEngine = "pattern", name = "limit by variable" }, condition),
      fmt("lim_({} -> {}) ", { d(1, captured_insert(1, "x")), i(2, "oo") })
    ),
    s(
      with_condition({ trig = "int", name = "integral" }, condition),
      fmt("integral_{}^{} {} dif {}", { i(1, "0"), i(2, "oo"), visual_insert(3), i(4, "x") })
    ),
    s(
      with_condition({ trig = "nint", name = "indefinite integral" }, condition),
      fmt("integral {} dif {}", { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "df", name = "derivative fraction" }, condition),
      fmt("frac(dif {}, dif {})", { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "pf", name = "partial derivative fraction" }, condition),
      fmt("frac(partial {}, partial {})", { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "cases", name = "cases" }, condition),
      fmt(
        [[cases(
  {} & {},
  {} & {},
)]],
        { i(1, "expr_1"), i(2, "condition_1"), i(3, "expr_2"), i(4, "condition_2") }
      )
    ),
    s(
      with_condition({ trig = "align", name = "aligned equations" }, condition),
      fmt(
        [[{} &= {} \
{} &= {}]],
        { visual_insert(1), i(2), i(3), i(4) }
      )
    ),
    s(
      with_condition({ trig = "mat([2-5])([2-5])", trigEngine = "pattern", name = "matrix" }, condition),
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
    s(with_condition({ trig = "vec", name = "column vector" }, condition), fmt("vec({})", { visual_insert(1) })),
    s(
      with_condition({ trig = "avec", name = "arrow vector symbol" }, condition),
      fmt("arrow({})", { visual_insert(1) })
    ),
    s(with_condition({ trig = "bvec", name = "bold vector symbol" }, condition), fmt("bold({})", { visual_insert(1) })),
    s(with_condition({ trig = "abs", name = "absolute value" }, condition), fmt("abs({})", { visual_insert(1) })),
    s(with_condition({ trig = "norm", name = "norm" }, condition), fmt("norm({})", { visual_insert(1) })),
    s(with_condition({ trig = "floor", name = "floor" }, condition), fmt("floor({})", { visual_insert(1) })),
    s(with_condition({ trig = "ceil", name = "ceil" }, condition), fmt("ceil({})", { visual_insert(1) })),
    s(with_condition({ trig = "round", name = "round" }, condition), fmt("round({})", { visual_insert(1) })),
    s(
      with_condition({ trig = "LR", name = "left right delimiters" }, condition),
      fmt("lr({}{}{})", { i(1, "("), visual_insert(2), i(3, ")") })
    ),
    s(
      with_condition({ trig = "op", name = "operator" }, condition),
      fmt([[op("{}", limits: #{})]], { i(1, "lim"), nodes.choice(2, { "true", "false" }) })
    ),
    s(with_condition({ trig = "hat", name = "hat" }, condition), fmt("hat({})", { visual_insert(1) })),
    s(with_condition({ trig = "bar", name = "bar" }, condition), fmt("bar({})", { visual_insert(1) })),
    s(with_condition({ trig = "dot", name = "dot" }, condition), fmt("dot({})", { visual_insert(1) })),
    s(
      with_condition({ trig = "over", name = "overbrace" }, condition),
      fmt("overbrace({}, {})", { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "under", name = "underbrace" }, condition),
      fmt("underbrace({}, {})", { visual_insert(1), i(2) })
    ),
    s(with_condition({ trig = "cancel", name = "cancel" }, condition), fmt("cancel({})", { visual_insert(1) })),
  }

  for _, def in ipairs(symbols.math_styles) do
    if def.typst then
      vim.list_extend(snippets, style_snippet(def.trigger, def.typst, def.desc, condition))
    end
  end

  return snippets
end

---Return Typst math autosnippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_autosnippets(condition)
  local autos = {
    s(
      with_condition({ trig = "//", wordTrig = false, name = "fraction", snippetType = "autosnippet" }, condition),
      fmt("frac({}, {})", { visual_insert(1), i(2) })
    ),
    s(
      with_condition({
        trig = "/",
        trigEngine = triggers.simple_fraction_engine,
        wordTrig = false,
        name = "simple fraction",
        snippetType = "autosnippet",
      }, condition),
      fmt("frac({}, {})", { cap(1), visual_insert(1) })
    ),
  }

  local aliases = {
    { "ooo", "oo ", "infinity" },
    { "...", "dots.h ", "horizontal dots", { wordTrig = false } },
    { "-.", "dot.c ", "center dot", { wordTrig = false } },
    { "tim", "times ", "times" },
    { "xx", "times ", "times alias" },
    { "div", "divides ", "divides" },
    { "+-", "plus.minus ", "plus minus", { wordTrig = false } },
    { "-+", "minus.plus ", "minus plus", { wordTrig = false } },
    { ":=", "colon.eq ", "definition", { wordTrig = false } },
    { "=>", "=> ", "implies", { wordTrig = false } },
    { "->", "-> ", "arrow right", { wordTrig = false } },
    { "<-", "<- ", "arrow left", { wordTrig = false } },
    { "|->", "mapsto ", "mapsto", { wordTrig = false } },
    { ">>", "gt.double ", "much greater", { wordTrig = false } },
    { "<<", "lt.double ", "much less", { wordTrig = false } },
    { "~~", "approx ", "approx", { wordTrig = false } },
    { "=~", "tilde.op ", "similar", { wordTrig = false } },
    { "~=", "tilde.equiv ", "congruent", { wordTrig = false } },
    { "=-", "equiv ", "equivalent", { wordTrig = false } },
    { "|=", "models ", "models", { wordTrig = false } },
    { "~>", "succ ", "successor relation", { wordTrig = false } },
    { "~<", "prec ", "predecessor relation", { wordTrig = false } },
    { ">~", "succ.curly.eq ", "successor equal relation", { wordTrig = false } },
    { "<~", "prec.curly.eq ", "predecessor equal relation", { wordTrig = false } },
    { "exist", "exists ", "exists" },
    { "empty", "emptyset ", "empty set" },
    { "kj", "emptyset ", "empty set alias" },
    { "cap", "inter ", "intersection" },
    { "jiao", "inter ", "intersection alias" },
    { "cup", "union ", "union" },
    { "bing", "union ", "union alias" },
    { "yw", "because ", "because" },
    { "sy", "therefore ", "therefore" },
    { "ang", "angle ", "angle" },
    { "tri", "triangle.stroked.t ", "triangle" },
    { "deg", "degree ", "degree" },
    { "par", "parallel ", "parallel" },
    { "perp", "perp ", "perpendicular" },
    { "nabla", "nabla ", "nabla" },
    { "oc", "prop ", "proportional" },
  }

  for _, item in ipairs(aliases) do
    local trigger, output, desc, extra = item[1], item[2], item[3], item[4]
    if extra and extra.wordTrig == false then
      table.insert(autos, literal_autosnippet(trigger, output, desc, condition, extra))
    else
      table.insert(autos, word_autosnippet(trigger, output, desc, condition, extra))
    end
  end

  -- Typst already has native `AA`, `EE`, `NN`, `RR`, etc.  Keep old LaTeX
  -- aliases like `exist`, but do not override those built-in symbol names.
  for _, greek in ipairs(symbols.typst_short_greek) do
    table.insert(
      autos,
      s(
        with_condition({
          trig = ";" .. greek.trigger,
          wordTrig = false,
          name = "short greek " .. greek.trigger,
          snippetType = "autosnippet",
        }, condition),
        t(greek.output)
      )
    )
  end
  return autos
end

return M

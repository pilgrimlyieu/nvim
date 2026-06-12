---LaTeX text-mode snippets.

local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local conditions = require("config.snippets.conditions")
local nodes = require("config.snippets.nodes")
local symbols = require("config.snippets.symbols")
local triggers = require("config.snippets.triggers")
local util = require("config.snippets.util")

local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local with_condition = util.with_condition
local visual_insert = util.visual_insert
local short_math_body = util.short_math_body
local fixed_short_math_body = util.fixed_short_math_body
local captured_short_math_body = util.captured_short_math_body

local text = conditions.wrap(conditions.vimtex_text, conditions.vimtex_text_show)
local line_text = util.with_line_begin(text)
local list_text = util.with_line_begin(util.and_conditions(
  text,
  conditions.wrap(function()
    return conditions.vimtex_env_any({ "enumerate", "itemize" })
  end)
))

---Build a TeX text-mode short-math snippet with the shared trigger engine.
---@param trigger string
---@param name string
---@param body SnipNodeBody
---@param extra? SnipContextExtra
---@return SnipNode
local function short_math_word_snippet(trigger, name, body, extra)
  return s(
    with_condition(
      util.extend({
        trig = trigger,
        trigEngine = triggers.short_math_word_engine,
        wordTrig = false,
        name = name,
      }, extra),
      text
    ),
    body
  )
end

local snippets = {
  s(
    with_condition({ trig = "eq", name = "equation" }, line_text),
    fmta(
      [[\begin{equation*}
    <>
\end{equation*}

<>]],
      { visual_insert(1), i(0) }
    )
  ),
  s(
    with_condition({ trig = "eqa", name = "numbered equation" }, line_text),
    fmta(
      [[\begin{equation}
    <>
\end{equation}

<>]],
      { visual_insert(1), i(0) }
    )
  ),
  s(with_condition({ trig = "-", name = "list item" }, list_text), t([[\item ]])),

  s(
    with_condition({ trig = "setminted", name = "minted settings" }, line_text),
    t({
      [[\setminted{]],
      [[    frame=lines,]],
      [[    framesep=2mm,]],
      [[    breaklines,]],
      [[    baselinestretch=1.2,]],
      [[    fontsize=\footnotesize,]],
      [[    linenos]],
      [[}]],
    })
  ),
  s(
    with_condition({ trig = "code", name = "minted block" }, line_text),
    fmta(
      [[% {{{ <>
\begin{minted}{<>}
<>
\end{minted}
% }}}
<>]],
      { i(1), nodes.choice(2, { "python", "cpp", "c" }), visual_insert(3), i(0) }
    )
  ),
  s(with_condition({ trig = "cc", name = "inline code" }, text), fmta([[\texttt{<>} ]], { visual_insert(1) })),
  s(with_condition({ trig = "vcc", name = "inline verbatim code" }, text), fmta([[\verb`<>` ]], { visual_insert(1) })),
  s(
    with_condition({ trig = "img", name = "include graphics" }, line_text),
    fmta(
      [[\begin{figure}[H]
    \centering
    \includegraphics[width=<>]{<>}<>
\end{figure}]],
      { i(1, [[0.8\textwidth]]), i(2), i(3, { "", [[    \caption{标题}]] }) }
    )
  ),
}

vim.list_extend(snippets, {
  short_math_word_snippet("ce", "inline chemistry math", short_math_body([[\(\ce{]], [[}\) ]])),
  short_math_word_snippet("pu", "inline unit math", short_math_body([[\(\pu{]], [[}\) ]])),
  short_math_word_snippet("rm", "inline roman math", short_math_body([[\(\mathrm{]], [[}\) ]])),
  short_math_word_snippet("tt", "inline text math", short_math_body([[\(\text{]], [[}\) ]])),
  short_math_word_snippet(
    "case",
    "inline brace aligned",
    short_math_body([[\(\left\lbrace\begin{aligned} ]], [[ \end{aligned}\right\.\) ]]),
    { priority = 100 }
  ),
  short_math_word_snippet(
    "cases",
    "inline cases",
    short_math_body([[\(\begin{cases} ]], [[ \end{cases}\) ]]),
    { priority = 100 }
  ),
  short_math_word_snippet(
    "align",
    "inline aligned",
    short_math_body([[\(\begin{aligned} ]], [[ \end{aligned}\) ]]),
    { priority = 100 }
  ),
  s(
    with_condition({ trig = "case", name = "display brace aligned", priority = 200 }, line_text),
    fmta(
      [=[\[
\left\lbrace\begin{aligned}
    <>
\end{aligned}\right.
\]
<>]=],
      { visual_insert(1), i(0) }
    )
  ),
  s(
    with_condition({ trig = "cases", name = "display cases", priority = 200 }, line_text),
    fmta(
      [=[\[
\begin{cases}
    <>
\end{cases}
\]
<>]=],
      { visual_insert(1), i(0) }
    )
  ),
  s(
    with_condition({ trig = "align", name = "display aligned", priority = 200 }, line_text),
    fmta(
      [=[\[
\begin{aligned}
    <>
\end{aligned}
\]
<>]=],
      { visual_insert(1), i(0) }
    )
  ),
})

for _, name in ipairs(symbols.markdown_inline_greek) do
  snippets[#snippets + 1] = short_math_word_snippet(
    name,
    "inline greek " .. name,
    fixed_short_math_body("\\(\\" .. symbols.latex_greek_command(name) .. "\\) ")
  )
end

local autosnippets = {
  s(
    with_condition({
      trig = "lm",
      trigEngine = triggers.short_math_word_engine,
      wordTrig = false,
      name = "inline math",
      snippetType = "autosnippet",
    }, text),
    short_math_body([[\(]], [[\) ]]),
    util.space_before_next_text_char_opts()
  ),
  s(
    with_condition({ trig = "dm", name = "display math", snippetType = "autosnippet" }, line_text),
    fmta(
      [=[\[
<>
\]
<>]=],
      { visual_insert(1), i(0) }
    )
  ),
  s(
    with_condition({
      trig = ",,",
      trigEngine = triggers.inline_math_postfix_engine,
      wordTrig = false,
      name = "inline captured math",
      snippetType = "autosnippet",
    }, text),
    captured_short_math_body([[\(]], 2, [[\) ]])
  ),
  s(
    with_condition({ trig = "ev", name = "environment", snippetType = "autosnippet" }, line_text),
    fmta(
      [[\begin{<>}
    <>
\end{<>}]],
      { i(1, "env"), visual_insert(2), rep(1) }
    )
  ),
  s(
    with_condition({ trig = "#1", name = "section", snippetType = "autosnippet" }, line_text),
    fmta(
      [[\section{<>}

<>]],
      { i(1), i(0) }
    )
  ),
  s(
    with_condition({ trig = "#2", name = "subsection", snippetType = "autosnippet" }, line_text),
    fmta(
      [[\subsection{<>}

<>]],
      { i(1), i(0) }
    )
  ),
  s(
    with_condition({ trig = "#3", name = "subsubsection", snippetType = "autosnippet" }, line_text),
    fmta(
      [[\subsubsection{<>}

<>]],
      { i(1), i(0) }
    )
  ),
}

return snippets, autosnippets

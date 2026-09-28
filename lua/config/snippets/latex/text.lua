---LaTeX text-mode snippets.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local inline_code = require("config.snippets.shared.inline_code")
local prose_math = require("config.snippets.latex.prose_math")
local text_math = require("config.snippets.shared.prose_math")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local capture_code = inline_code.capture_code
local capture_math = text_math.capture_math
local display = text_math.display
local inline = text_math.inline
local prose_math_snippets = prose_math.snippets
local text = conditions.text
local text_choices_insert = nodes.text_choices_insert
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin

local line_text = with_line_begin(text)
local list_text = with_line_begin(conditions.tex_list)

function M.snippets()
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
        { i(1), text_choices_insert(2, { "python", "cpp", "c" }), visual_insert(3), i(0) }
      )
    ),
    s(with_condition({ trig = "cc", name = "inline code" }, text), fmta([[\texttt{<>} ]], { visual_insert(1) })),
    s(
      with_condition({ trig = "vcc", name = "inline verbatim code" }, text),
      fmta([[\verb`<>` ]], { visual_insert(1) })
    ),
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

  vim.list_extend(snippets, prose_math_snippets("tex"))

  return snippets
end

function M.autosnippets()
  local autosnippets = {
    inline([[\(]], [[\)]]),
    display("\\[", "\\]"),
    capture_math([[\(]], [[\)]]),
    capture_code([[\texttt{]], "}"),
    s(
      with_condition({ trig = "ev", name = "environment", snippetType = "autosnippet" }, line_text),
      fmta(
        [[\begin{<>}
    <>
\end{<>}]],
        { i(1, "env"), visual_insert(2), rep(1) }
      )
    ),
  }
  for level, command in ipairs({ "section", "subsection", "subsubsection" }) do
    autosnippets[#autosnippets + 1] = s(
      with_condition({ trig = "#" .. level, name = command, snippetType = "autosnippet" }, line_text),
      fmta("\\" .. command .. "{<>}\n\n<>", { i(1), i(0) })
    )
  end

  return autosnippets
end

return M

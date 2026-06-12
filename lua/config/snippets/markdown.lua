---Reusable Markdown snippet builders.
---
---These are intentionally filetype-agnostic builders: each public function
---receives a LuaSnip condition object and returns snippets that can be composed
---from `lua/snippets/markdown/*.lua`.  Keeping the tables small by topic makes
---the migrated UltiSnips collection easier to audit later.
local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local nodes = require("config.snippets.nodes")
local symbols = require("config.snippets.symbols")
local triggers = require("config.snippets.triggers")
local util = require("config.snippets.util")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

local M = {}
local cap = util.capture
local with_condition = util.with_condition
local visual_insert = util.visual_insert
local visual_transform_insert = util.visual_transform_insert
local short_math_body = util.short_math_body
local fixed_short_math_body = util.fixed_short_math_body
local captured_short_math_body = util.captured_short_math_body

---Build a GitHub-flavored Markdown table.
---@param align "plain"|"left"|"right"|"center"
---@return fun(args: SnipNodeArgs, snip: SnipSnippet): SnipNode
local function table_node(align)
  return function(_, snip)
    local rows = tonumber(snip.captures[1]) or 2
    local cols = tonumber(snip.captures[2]) or 2
    local delimiter = {
      plain = "---",
      left = ":--",
      right = "--:",
      center = ":-:",
    }
    local cell_nodes = {}
    local jump = 1

    for row = 1, rows + 2 do
      if row == 2 then
        table.insert(cell_nodes, t("|"))
        for _ = 1, cols do
          table.insert(cell_nodes, t(delimiter[align] or delimiter.plain))
          table.insert(cell_nodes, t("|"))
        end
      else
        table.insert(cell_nodes, t("| "))
        for col = 1, cols do
          local placeholder = row == 1 and ("head" .. col) or ("R" .. (row - 2) .. "C" .. col)
          table.insert(cell_nodes, i(jump, placeholder))
          jump = jump + 1
          table.insert(cell_nodes, t(" |"))
          if col < cols then
            table.insert(cell_nodes, t(" "))
          end
        end
      end
      if row < rows + 2 then
        table.insert(cell_nodes, t({ "", "" }))
      end
    end

    return sn(nil, cell_nodes)
  end
end

---Return the current local timestamp used by blog metadata snippets.
---@return string
local function now()
  return tostring(os.date("%Y-%m-%d %H:%M:%S"))
end

---Normalize comma-separated front-matter list text.
---@param value string
---Return the current filename stem, falling back to `Untitled`.
---@return string
local function normalize_list_spacing(value)
  return (value:gsub("，", ", "):gsub("%s*,%s*", ", "):gsub("^%s+", ""):gsub("%s+$", ""))
end

---@return string
local function basename()
  local value = vim.fn.expand("%:t:r")
  return value ~= "" and value or "Untitled"
end

---Read a simple YAML front-matter value from the top of the buffer.
---@param key string
---@return string?
local function front_matter_value(key)
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(vim.api.nvim_buf_line_count(0), 12), false)
  for _, line in ipairs(lines) do
    local value = line:match("^" .. key .. ":%s*(.*)$")
    if value ~= nil and value ~= "" then
      return value
    end
  end

  return nil
end

---Return front-matter title or infer it from the filename.
---@return string
local function front_matter_title()
  return front_matter_value("title") or basename()
end

---Return front-matter date or the current timestamp.
---@return string
local function front_matter_date()
  return front_matter_value("date") or now()
end

---Return whether the inferred title marks a private note.
---@return boolean
local function front_matter_private()
  return front_matter_title():find(".private", 1, true) ~= nil
end

---Return Hexo draft flag derived from privacy.
---@return string
local function front_matter_draft()
  return front_matter_private() and "true" or "false"
end

---Return Hexo comments flag derived from privacy.
---@return string
local function front_matter_comments()
  return front_matter_private() and "false" or "true"
end

---Create a dynamic insert node whose default is evaluated at expansion time.
---@param default fun(): string
---@return fun(): SnipNode
local function dynamic_insert(default)
  return function()
    return sn(nil, { i(1, default()) })
  end
end

---Return whether the current filename follows the weekly-note convention.
---@return boolean
local function is_week_note()
  return basename():find("Week", 1, true) ~= nil
end

---Return the heading text for a weekly-note template.
---@return string
local function week_title()
  local name = basename()
  if not is_week_note() then
    return "## " .. name
  end

  local week = tonumber(name:sub(6, 7))
  return "## " .. (week and ("第 " .. week .. " 周") or name)
end

---Return the Monday-Friday date range for a weekly-note filename.
---@return string
local function week_range()
  local name = basename()
  if not is_week_note() then
    return name
  end

  local stamp = name:match("(%d%d%d%d%d%d%d%d)")
  if not stamp then
    return name
  end

  local year = tonumber("20" .. stamp:sub(1, 2))
  local month = tonumber(stamp:sub(3, 4))
  local day = tonumber(stamp:sub(5, 6))
  if not year or not month or not day then
    return name
  end

  local time = os.time({ year = year, month = month, day = day, hour = 12 })
  local weekday = tonumber(os.date("%w", time))
  if not weekday then
    return name
  end

  local monday_offset = weekday == 0 and -6 or 1 - weekday
  local monday = tostring(os.date("%Y-%m-%d", time + monday_offset * 86400))
  local friday = tostring(os.date("%Y-%m-%d", time + (monday_offset + 4) * 86400))
  return monday .. " ~ " .. friday
end

---Return the writing-time suffix inferred from the filename.
---@return string
local function writing_time()
  local name = basename()
  if is_week_note() then
    return name:sub(12, 16)
  end

  return name:sub(6)
end

---Return selected text lines for Markdown visual-aware snippets.
---@param snip SnipSnippet
---@return string[]
local function selected_lines(snip)
  return util.selected_lines(snip)
end

---Prefix each selected line as a Markdown blockquote.
---@param lines string[]
---@return string[]
local function blockquote_lines(lines)
  local result = {}
  for _, line in ipairs(lines) do
    result[#result + 1] = "> " .. line
  end
  return result
end

---Remove Obsidian callout markers and blockquote prefixes from selected lines.
---@param lines string[]
---@return string[]
local function remove_callout_lines(lines)
  local result = {}
  for _, line in ipairs(lines) do
    if not line:match("^>%s+%[![A-Z]+%]%s*$") then
      line = line:gsub("^>%s+%[![A-Z]+%]%s*", "")
      line = line:gsub("^>%s?", "")
      result[#result + 1] = line
    end
  end
  return result
end

---Build a text-mode short-math snippet using a UTF-8-aware trigger engine.
---@param trigger string
---@param name string
---@param condition SnipCondition
---@param body SnipNodeBody
---@param extra? SnipContextExtra
---@return SnipNode
local function short_math_word_snippet(trigger, name, condition, body, extra)
  return s(
    with_condition(
      util.extend({
        trig = trigger,
        trigEngine = triggers.short_math_word_engine,
        wordTrig = false,
        name = name,
      }, extra),
      condition
    ),
    body
  )
end

---Return Markdown prose snippets that produce inline/display LaTeX math.
---@param condition SnipCondition
---@return SnipNode[]
function M.snippets(condition)
  return {
    s(
      with_condition(
        { trig = "tb([1-9])([1-9])", trigEngine = "pattern", name = "table" },
        util.with_line_begin(condition)
      ),
      { d(1, table_node("plain")) }
    ),
    s(
      with_condition(
        { trig = "tbl([1-9])([1-9])", trigEngine = "pattern", name = "left table" },
        util.with_line_begin(condition)
      ),
      { d(1, table_node("left")) }
    ),
    s(
      with_condition(
        { trig = "tbr([1-9])([1-9])", trigEngine = "pattern", name = "right table" },
        util.with_line_begin(condition)
      ),
      { d(1, table_node("right")) }
    ),
    s(
      with_condition(
        { trig = "tbm([1-9])([1-9])", trigEngine = "pattern", name = "center table" },
        util.with_line_begin(condition)
      ),
      { d(1, table_node("center")) }
    ),
    s(
      with_condition({ trig = "todo", name = "todo" }, util.with_line_begin(condition)),
      fmt("- [{}] {}", { nodes.choice(1, { "x", " " }), i(2) })
    ),
    s(
      with_condition(
        { trig = "%- %[([ x])%] (.+)", trigEngine = "pattern", wordTrig = false, name = "toggle todo" },
        util.with_line_begin(condition)
      ),
      {
        f(function(_, snip)
          local mark = snip.captures[1] == "x" and " " or "x"
          return "- [" .. mark .. "] " .. (snip.captures[2] or "")
        end),
      }
    ),
    s(
      with_condition({ trig = "lnk", name = "link" }, condition),
      fmt("[{}]({})", { visual_insert(1), i(2, "https://") })
    ),
    s(with_condition({ trig = "img", name = "image" }, condition), fmt("![{}]({})", { i(1), visual_insert(2) })),
    s(
      with_condition({ trig = "imgs", name = "image under /images" }, condition),
      fmt("![{}](/images/{})", { i(1), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "code", name = "code block" }, util.with_line_begin(condition)),
      fmt(
        [[```{}
{}
```]],
        { i(1), visual_insert(2) }
      )
    ),
    s(with_condition({ trig = "cc", name = "folded code block" }, util.with_line_begin(condition)), {
      t("<!-- {{{ "),
      i(1, "code"),
      t({ " -->", "```" }),
      nodes.choice(2, { "bash", "rust", "python", "c", "cpp", "typescript", "javascript" }),
      t({ "", "" }),
      visual_insert(3),
      t({ "", "```", "<!-- }}} -->" }),
    }),
    s(with_condition({ trig = "kbd", name = "keyboard" }, condition), fmt("<kbd>{}</kbd>", { visual_insert(1) })),
    s(with_condition({ trig = "fnt", name = "footnote" }, condition), fmt("[^{}]", { visual_insert(1) })),
    s(
      with_condition(
        { trig = "temp", name = "note template" },
        util.on_first_buffer_line(util.with_trigger_column(condition, 0))
      ),
      {
        f(week_title),
        t({ "", "", "- " }),
        f(week_range),
        t({ "", "- 编写时间：" }),
        f(writing_time),
        t({ "", "", "[toc]", "", "### 任务", "", "" }),
        i(1),
        t({ "", "", "### 笔记", "", "" }),
        i(0),
      }
    ),
    s(
      with_condition({ trig = "p", name = "true or false prompt" }, util.at_buffer_start(condition)),
      t({ "判断正误：", "", "" })
    ),
    s(
      with_condition({ trig = "copt", name = "GitHub Copilot translation notice" }, util.with_line_begin(condition)),
      t({ "> 由 GitHub Copilot 生成的翻译", "> Generated by GitHub Copilot", "", "" })
    ),
    s(
      with_condition({ trig = "expdet", name = "open all details" }, condition),
      t({
        "<script>",
        "document.body.querySelectorAll('details').forEach(e => e.setAttribute('open', true))",
        "</script>",
      })
    ),
    s(with_condition({ trig = "detail", name = "folded details" }, condition), {
      t("<!-- {{{ "),
      i(1, "Details"),
      t({ " -->", "<details>", "<summary>" }),
      rep(1),
      t({ "</summary>", "", "" }),
      visual_insert(2),
      t({ "", "", "</details>", "<!-- }}} -->" }),
    }),
    s(with_condition({ trig = "ii", name = "italic" }, condition), fmt("*{}*", { visual_insert(1) })),
    s(with_condition({ trig = "bb", name = "bold" }, condition), fmt("**{}**", { visual_insert(1) })),
    s(with_condition({ trig = "bi", name = "bold italic" }, condition), fmt("***{}***", { visual_insert(1) })),
    s(with_condition({ trig = "mm", name = "mark" }, condition), fmt("=={}==", { visual_insert(1) })),
    s(with_condition({ trig = "==", name = "mark" }, condition), fmt("=={}==", { visual_insert(1) })),
    s(with_condition({ trig = "ss", name = "strike" }, condition), fmt("~~{}~~", { visual_insert(1) })),
    s(with_condition({ trig = "uu", name = "underline" }, condition), fmt("<u>{}</u>", { visual_insert(1) })),
    s(with_condition({ trig = "/.", name = "comment" }, condition), fmt("<!-- {} -->", { visual_insert(1) })),
    s(
      with_condition({ trig = "#([1-6])", trigEngine = "pattern", name = "heading" }, util.with_line_begin(condition)),
      {
        f(function(_, snip)
          return string.rep("#", tonumber(snip.captures[1]) or 1) .. " "
        end),
      }
    ),
  }
end

---Return Markdown prose snippets that wrap text as short math expressions.
---@param condition SnipCondition
---@return SnipNode[]
function M.short_math_snippets(condition)
  local snippets = {
    short_math_word_snippet("ce", "inline chemistry", condition, short_math_body([[$\ce{]], [[}$ ]])),
    short_math_word_snippet("pu", "inline unit", condition, short_math_body([[$\pu{]], [[}$ ]])),
    short_math_word_snippet("rm", "inline roman math", condition, short_math_body([[$\mathrm{]], [[}$ ]])),
    short_math_word_snippet("tt", "inline text math", condition, short_math_body([[$\text{]], [[}$ ]])),
    short_math_word_snippet(
      "case",
      "inline brace aligned",
      condition,
      short_math_body([[$\left\lbrace\begin{aligned} ]], [[ \end{aligned}\right.$ ]]),
      { priority = 100 }
    ),
    short_math_word_snippet(
      "cases",
      "inline cases",
      condition,
      short_math_body([[$\begin{cases} ]], [[ \end{cases}$ ]]),
      { priority = 100 }
    ),
    short_math_word_snippet(
      "align",
      "inline aligned",
      condition,
      short_math_body([[$\begin{aligned} ]], [[ \end{aligned}$ ]]),
      { priority = 100 }
    ),
    s(
      with_condition({ trig = "case", name = "display brace aligned", priority = 200 }, util.with_line_begin(condition)),
      fmta(
        [[$$
\left\lbrace\begin{aligned}
    <>
\end{aligned}\right.
$$
<>]],
        { visual_insert(1), i(0) }
      )
    ),
    s(
      with_condition({ trig = "cases", name = "display cases", priority = 200 }, util.with_line_begin(condition)),
      fmta(
        [[$$
\begin{cases}
    <>
\end{cases}
$$
<>]],
        { visual_insert(1), i(0) }
      )
    ),
    s(
      with_condition({ trig = "align", name = "display aligned", priority = 200 }, util.with_line_begin(condition)),
      fmta(
        [[$$
\begin{aligned}
    <>
\end{aligned}
$$
<>]],
        { visual_insert(1), i(0) }
      )
    ),
  }

  for _, name in ipairs(symbols.markdown_inline_greek) do
    table.insert(
      snippets,
      short_math_word_snippet(
        name,
        "inline greek " .. name,
        condition,
        fixed_short_math_body("$\\" .. symbols.latex_greek_command(name) .. "$ ")
      )
    )
  end

  return snippets
end

---Return Markdown text-mode reference snippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.reference_snippets(condition)
  return {
    s(with_condition({ trig = "ref", name = "reference" }, condition), fmta([[$\ref{<>}$]], { i(1) })),
    s(
      with_condition({ trig = "reff", name = "named reference" }, condition),
      fmta([[$\@ref{<>}{<>}$]], { i(1, "id"), i(2, "label") })
    ),
    s(with_condition({ trig = "eqr", name = "equation reference" }, condition), fmta([[$\eqref{<>}$]], { i(1) })),
    s(
      with_condition({ trig = "eqrr", name = "named equation reference" }, condition),
      fmta([[$\@eqref{<>}{<>}$]], { i(1, "id"), i(2, "label") })
    ),
  }
end

---Return LaTeX-math label snippets used inside Markdown math zones.
---@param condition SnipCondition
---@return SnipNode[]
function M.math_reference_snippets(condition)
  return {
    s(with_condition({ trig = "lab", name = "label" }, condition), fmta([[\label{<>}]], { i(1) })),
    s(
      with_condition({ trig = "labb", name = "named label" }, condition),
      fmta([[\@label{<>}{<>}]], { i(1, "id"), i(2, "label") })
    ),
    s(
      with_condition({ trig = "labbb", name = "named label without number" }, condition),
      fmta([[\@@label{<>}{<>}]], { i(1, "id"), i(2, "label") })
    ),
  }
end

---Return Obsidian/vault callout snippets and callout cleanup helpers.
---@param condition SnipCondition
---@return SnipNode[]
function M.vault_snippets(condition)
  local callouts = {
    calln = "NOTE",
    calla = "ABSTRACT",
    calli = "INFO",
    callt = "TODO",
    callti = "TIP",
    calls = "SUCCESS",
    callq = "QUESTION",
    callw = "WARNING",
    callf = "FAILURE",
    calld = "DANGER",
    callb = "BUG",
    calle = "ERROR",
    callqo = "QUOTE",
  }
  local snippets = {}

  for trigger, name in pairs(callouts) do
    table.insert(
      snippets,
      s(
        with_condition({ trig = trigger, name = "callout " .. name }, util.with_line_begin(condition)),
        fmt(
          [[> [!{}]
{}]],
          { t(name), visual_transform_insert(1, blockquote_lines) }
        )
      )
    )
  end

  snippets[#snippets + 1] =
    s(with_condition({ trig = "rmcall", name = "remove callout markup" }, util.with_line_begin(condition)), {
      f(function(_, snip)
        return remove_callout_lines(selected_lines(snip))
      end),
    })

  return snippets
end

---Return Hexo/blog front-matter and shortcode snippets.
---@param condition SnipCondition
---@return SnipNode[]
function M.blog_snippets(condition)
  local snippets = {
    s(
      with_condition(
        { trig = "@", name = "Hexo front matter at file start", snippetType = "autosnippet" },
        util.at_buffer_start(condition)
      ),
      fmt(
        [[---
title: {}
date: {}
updated: {}
description: {}
draft: {}
comments: {}
disableNunjucks: true
katex: {}
categories: {}
tags: {}
---
{}]],
        {
          d(1, dynamic_insert(front_matter_title)),
          f(front_matter_date),
          f(front_matter_date),
          i(2),
          d(3, dynamic_insert(front_matter_draft)),
          d(4, dynamic_insert(front_matter_comments)),
          nodes.choice(5, { "true", "false" }),
          i(6),
          i(7),
          i(8),
        }
      )
    ),
    s(
      with_condition({ trig = "fm", name = "Hexo front matter" }, condition),
      fmt(
        [[---
title: {}
date: {}
updated: {}
description: {}
draft: {}
comments: {}
disableNunjucks: true
katex: {}
categories: {}
tags: {}
---
{}]],
        {
          d(1, dynamic_insert(front_matter_title)),
          f(front_matter_date),
          f(front_matter_date),
          i(2),
          d(3, dynamic_insert(front_matter_draft)),
          d(4, dynamic_insert(front_matter_comments)),
          nodes.choice(5, { "true", "false" }),
          i(6),
          i(7),
          i(8),
        }
      )
    ),
    s(
      with_condition(
        { trig = "date: (.*)", trigEngine = "pattern", wordTrig = false, name = "refresh date" },
        util.with_line_begin(condition)
      ),
      { t("date: "), f(now) }
    ),
    s(
      with_condition(
        { trig = "updated: (.*)", trigEngine = "pattern", wordTrig = false, name = "refresh updated" },
        util.with_line_begin(condition)
      ),
      { t("updated: "), f(now) }
    ),
    s(with_condition({ trig = "tag", name = "Hexo tag" }, condition), fmta([[{{% <> %}}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "adm", name = "admonition" }, util.with_trigger_column(condition, 0)),
      fmt(
        [[!!! {} {}
    {}]],
        {
          nodes.choice(1, { "note", "info", "warning", "danger", "example", "quote", "tip", "memo", "test" }),
          i(2, [[""]]),
          visual_insert(3),
        }
      )
    ),
    s(
      with_condition({ trig = "tabs", name = "tabs" }, util.with_trigger_column(condition, 0)),
      fmta(
        [[{{% tabs <>, <> %}}
<>
{{% endtabs %}}]],
        { i(1), i(2, "-1"), visual_insert(3) }
      )
    ),
    s(
      with_condition({ trig = "tab", name = "tab" }, util.with_trigger_column(condition, 0)),
      fmt(
        [[<!-- tab {} -->
{}
<!-- endtab -->]],
        { i(1), visual_insert(2) }
      )
    ),
    s(
      with_condition({ trig = "label", name = "Hexo label" }, condition),
      fmta(
        [[{{% label <> @<> %}}]],
        { nodes.choice(1, { "default", "primary", "success", "info", "warning", "danger" }), visual_insert(2) }
      )
    ),
    s(
      with_condition(
        { trig = "^categories: (.+)", trigEngine = "pattern", wordTrig = false, name = "format categories" },
        condition
      ),
      {
        f(function(_, snip)
          local categories = normalize_list_spacing(snip.captures[1] or "")
          local lines = { "categories:" }

          for category in categories:gmatch("([^,]+)") do
            lines[#lines + 1] = "  - [" .. category:gsub("^%s+", ""):gsub("%s+$", "") .. "]"
          end

          return lines
        end),
      }
    ),
    s(
      with_condition(
        { trig = "^tags: ([^[].+)", trigEngine = "pattern", wordTrig = false, name = "format tags" },
        condition
      ),
      {
        f(function(_, snip)
          return "tags: [" .. normalize_list_spacing(snip.captures[1] or "") .. "]"
        end),
      }
    ),
    s(
      with_condition(
        { trig = "^tags: %[(.+)%]([^%[%]]+)", trigEngine = "pattern", wordTrig = false, name = "append tags" },
        condition
      ),
      {
        f(function(_, snip)
          return "tags: ["
            .. normalize_list_spacing((snip.captures[1] or "") .. ", " .. (snip.captures[2] or ""))
            .. "]"
        end),
      }
    ),
  }

  return snippets
end

---Return Markdown autosnippets for inline/display math and inline code.
---@param condition SnipCondition
---@return SnipNode[]
function M.autosnippets(condition)
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
      with_condition(
        { trig = "dm", name = "display math", snippetType = "autosnippet" },
        util.with_line_begin(condition)
      ),
      fmt(
        [[$$
{}
$$
{}]],
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
      }, condition),
      captured_short_math_body("$", 2, "$ ")
    ),
    s(
      with_condition({
        trig = ";;",
        trigEngine = triggers.inline_code_postfix_engine,
        wordTrig = false,
        name = "inline code",
        snippetType = "autosnippet",
      }, condition),
      { t("`"), cap(1), t("` "), i(0) }
    ),
  }
end

return M

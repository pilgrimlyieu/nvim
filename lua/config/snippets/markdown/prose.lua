---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local text_choices = nodes.text_choices
local text_choices_insert = nodes.text_choices_insert
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin

function M.snippets()
  local condition = conditions.text
  return {
    s(
      with_condition({ trig = "td", name = "todo" }, with_line_begin(condition)),
      fmt("- [{}] {}", { text_choices(1, { " ", "x" }), i(2) })
    ),
    s(
      with_condition(
        { trig = "%- %[([ x])%] (.+)", name = "toggle todo", trigEngine = "pattern", wordTrig = false },
        with_line_begin(condition)
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
    s(with_condition({ trig = "cc", name = "code block" }, with_line_begin(condition)), {
      t("```"),
      text_choices_insert(1, { "bash", "rust", "python", "c", "cpp", "typescript", "javascript" }),
      t({ "", "" }),
      visual_insert(2),
      t({ "", "```" }),
    }),
    s(with_condition({ trig = "kbd", name = "keyboard" }, condition), fmt("<kbd>{}</kbd>", { visual_insert(1) })),
    s(with_condition({ trig = "fnt", name = "footnote" }, condition), fmt("[^{}]", { visual_insert(1) })),
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
    s(with_condition({ trig = "==", name = "mark (==)" }, condition), fmt("=={}==", { visual_insert(1) })),
    s(with_condition({ trig = "ss", name = "strike" }, condition), fmt("~~{}~~", { visual_insert(1) })),
    s(with_condition({ trig = "uu", name = "underline" }, condition), fmt("<u>{}</u>", { visual_insert(1) })),
    s(with_condition({ trig = "/.", name = "comment" }, condition), fmt("<!-- {} -->", { visual_insert(1) })),
    s(with_condition({ trig = "#([1-6])", name = "heading", trigEngine = "pattern" }, with_line_begin(condition)), {
      f(function(_, snip)
        return string.rep("#", tonumber(snip.captures[1]) or 1) .. " "
      end),
    }),
  }
end

return M

---Typst-native feature definitions.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local inline_code = require("config.snippets.shared.inline_code")
local text_math = require("config.snippets.shared.prose_math")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local capture_code = inline_code.capture_code
local capture_math = text_math.capture_math
local display = text_math.display
local inline = text_math.inline
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin

function M.snippets()
  local condition = conditions.text
  local snippets = {
    s(with_condition({ trig = "ii", name = "italic", wordTrig = false }, condition), fmt("_{}_", { visual_insert(1) })),
    s(with_condition({ trig = "bb", name = "bold", wordTrig = false }, condition), fmt("*{}*", { visual_insert(1) })),
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
  for _, def in ipairs({ { "bold", "*", "*" }, { "em", "_", "_" }, { "raw", "`", "`" } }) do
    snippets[#snippets + 1] = s(
      with_condition({ trig = def[1], name = def[1] .. " text" }, condition),
      { t(def[2]), visual_insert(1), t(def[3]) }
    )
  end
  snippets[#snippets + 1] = s(
    with_condition({ trig = "link", name = "link" }, condition),
    fmt('#link("{}")[{}]', { i(1, "https://"), visual_insert(2) })
  )
  snippets[#snippets + 1] =
    s(with_condition({ trig = "ref", name = "reference" }, condition), { t("@"), i(1, "eq:label") })
  snippets[#snippets + 1] =
    s(with_condition({ trig = "label", name = "label" }, condition), { t("<"), i(1, "eq:label"), t(">") })
  snippets[#snippets + 1] = s(
    with_condition({ trig = "eqn", name = "numbered equation" }, with_line_begin(condition)),
    fmt('#math.equation(block: true, numbering: "(1)")[$ {} $] <{}>\n{}', { visual_insert(1), i(2, "eq:label"), i(0) })
  )
  for _, def in ipairs({
    { "h1", "= " },
    { "h2", "== " },
    { "h3", "=== " },
    { "list", "- " },
    { "enum", "+ " },
    {
      "term",
      "/ ",
    },
  }) do
    snippets[#snippets + 1] = s(
      with_condition({ trig = def[1], name = def[1] .. " block" }, with_line_begin(condition)),
      def[1] == "term" and { t(def[2]), i(1, "term"), t(": "), visual_insert(2) } or { t(def[2]), visual_insert(1) }
    )
  end
  return snippets
end

---Return Typst text-mode autosnippets for math delimiters.
---@return LuaSnip.Snippet[]
function M.autosnippets()
  return {
    inline("$", "$"),
    display("$", "$"),
    capture_math("$", "$"),
    capture_code("`", "`"),
  }
end

return M

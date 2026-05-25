---Snippets available in every filetype.

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local nodes = require("config.snippets.nodes")
local util = require("config.snippets.util")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local line_begin = util.with_line_begin(util.always_condition())
local with_condition = util.with_condition

---Return today's date for all-filetype date snippets.
local function today()
  return tostring(os.date("%Y-%m-%d"))
end

---Return the current local date and minute.
local function now_minute()
  return tostring(os.date("%Y-%m-%d %H:%M"))
end

local snippets = {
  s("dt", {
    f(today),
  }),
  s("dtt", {
    f(now_minute),
  }),
  -- TODO: remove below
  s(
    with_condition({ trig = "type", name = "section banner" }, line_begin), -- WARN: Can not resize automatically
    fmta(
      [[################################################################
#                                                              #
# <> #
#                                                              #
################################################################
<>]],
      { i(1, "Section"), i(0) }
    )
  ),
  s(
    with_condition({ trig = "gl", name = "LuaSnip module scaffold" }, line_begin),
    fmta(
      [[local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local s = ls.snippet
local i = ls.insert_node

return {
  <>
}
]],
      { i(0) }
    )
  ),
  s(
    with_condition({ trig = "txt", name = "snippet condition" }, line_begin),
    fmta([[local <> = conditions.wrap(conditions.<>)<>]], {
      i(1, "text"),
      nodes.choice(2, { "markdown_text", "vimtex_text", "vimtex_math", "markdown_latex_math", "typst_math" }),
      i(0),
    })
  ),
  s(
    with_condition({ trig = "pp", name = "LuaSnip callback" }, line_begin),
    fmta(
      [[callbacks = {
  [<>] = {
    [events.<>] = function(node)
      <>
    end,
  },
}]],
      { i(1, "1"), nodes.choice(2, { "enter", "leave" }), i(0) }
    )
  ),
  s(
    with_condition({ trig = "snip", name = "LuaSnip snippet" }, line_begin),
    fmta([=[s({ trig = "<>", name = "<>" }, fmta([[<>]], { <> }))<>]=], {
      i(1, "trigger"),
      i(2, "description"),
      i(3, "body"),
      i(4),
      i(0),
    })
  ),
  s({ trig = "rv", name = "return value" }, t("return ")),
  s({ trig = "m", name = "capture value" }, fmta([[snip.captures[<>]<>]], { i(1, "1"), i(0) })),
  s({ trig = "tab", name = "argument value" }, fmta([[args[<>][1]<>]], { i(1, "1"), i(0) })),
  s({ trig = "t", name = "insert node" }, fmta([[i(<>, "<>")<>]], { i(1, "1"), i(2), i(0) })),
  s({ trig = "vis", name = "selected text" }, t("util.visual_insert(1)")),
  s(
    { trig = "scr", name = "function node" },
    fmta(
      [[f(function(args, snip)
  <>
end, { <> })<>]],
      { i(1, 'return snip.captures[1] or ""'), i(2), i(0) }
    )
  ),
  s(
    with_condition({ trig = "from", name = "require module" }, line_begin),
    fmta([[local <> = require("<>")<>]], { i(1, "conditions"), i(2, "config.snippets.conditions"), i(0) })
  ),
  s(
    with_condition({ trig = "def", name = "Lua function" }, line_begin),
    fmta(
      [[local function <>(<>)
  <>
end]],
      { i(1, "name"), i(2), i(0) }
    )
  ),
  s(
    with_condition({ trig = "text", name = "text snippet template" }, line_begin),
    fmta([=[s(with_condition({ trig = "<>", name = "<>" }, text), fmta([[<>]], { <> }))<>]=], {
      i(1, "trigger"),
      i(2, "description"),
      i(3, "body"),
      i(4),
      i(0),
    })
  ),
  s(
    with_condition({ trig = "math", name = "math snippet template" }, line_begin),
    fmta([=[s(with_condition({ trig = "<>", name = "<>" }, math), fmta([[<>]], { <> }))<>]=], {
      i(1, "trigger"),
      i(2, "description"),
      i(3, "body"),
      i(4),
      i(0),
    })
  ),
  s({ trig = "tt", name = "insert node shorthand" }, fmta([[i(<>)<>]], { i(1, "1"), i(0) })),
  s({ trig = "ôft", name = "set filetype marker" }, fmta([[ôft=<>]], { i(1, "markdown") })),
}

-- TODO: remove this
local autosnippets = {
  s({
    trig = "ôft=(%w*)",
    trigEngine = "pattern",
    wordTrig = false,
    name = "set filetype",
    snippetType = "autosnippet",
  }, {
    f(function(_, snip)
      local filetype = snip.captures[1] or ""
      if filetype ~= "" then
        vim.bo.filetype = filetype
      end
      return ""
    end),
  }),
}

return snippets, autosnippets

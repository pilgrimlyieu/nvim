---LeetCode 练习

local ls = require("luasnip")

local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local sn = ls.snippet_node

local snippets = {
  s("cd", {
    t("// @card "),
    c(1, {
      t("hint"),
      sn(nil, { t("idea "), i(1, "解法名") }),
      t("note"),
      t("ref"),
    }),
    t({ "", "// " }),
    i(0),
  }),
  s("alt", {
    t("// @alt "),
    i(1, "解法名"),
    t({ "", "// " }),
    i(2, "说明"),
    t({ "", "class Solution" }),
    i(3, "Name"),
    t({ " {", "public:", "  " }),
    i(0),
    t({ "", "};", "// @alt end" }),
  }),
  s("nodbg", t("#define DBG(...) ((void)0)")),
}

local autosnippets = {}

return snippets, autosnippets

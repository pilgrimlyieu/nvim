---TODO: remove
---Vimscript editing snippets migrated from the old `vim/vim.snippets`.
local ls = require("luasnip")
local util = require("config.snippets.util")

local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node
local line_begin = util.with_line_begin(util.always_condition())
local with_condition = util.with_condition

---Build a centered Vimscript comment banner.
---@param width integer
---@return SnipNode[]
local function banner(width)
  local border = string.rep('"', width)

  return {
    t({ border, '"' .. string.rep(" ", width - 2) .. '"' }),
    t('" '),
    i(1),
    t(" "),
    t({ '"' .. string.rep(" ", width - 2) .. '"', border, "" }),
    i(0),
  }
end

return {
  s(with_condition({ trig = "type", name = "large Vimscript banner" }, line_begin), banner(96)),
  s(with_condition({ trig = "tpl", name = "large Vimscript separator" }, line_begin), {
    t({
      string.rep('"', 96),
      string.rep('"', 96),
      string.rep('"', 96),
    }),
  }),
  s(with_condition({ trig = "zone", name = "small Vimscript banner" }, line_begin), banner(48)),
  s(with_condition({ trig = "znl", name = "small Vimscript separator" }, line_begin), {
    t({
      string.rep('"', 48),
      string.rep('"', 48),
    }),
  }),
  s(with_condition({ trig = "line", name = "empty line" }, line_begin), {
    t({ "", "" }),
  }),
  s(with_condition({ trig = "mine", name = "multiple empty lines" }, line_begin), {
    t({ "", "", "" }),
  }),
  s(with_condition({ trig = "fd", name = "fold open marker" }, line_begin), {
    t('" '),
    i(1),
    t(" {{{1"),
    i(0),
  }),
  s(with_condition({ trig = "fde", name = "fold close marker" }, line_begin), {
    t('" }}}1'),
    i(0),
  }),
}

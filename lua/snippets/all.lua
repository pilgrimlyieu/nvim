---Snippets available in every filetype.

local ls = require("luasnip")

local s = ls.snippet
local f = ls.function_node

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
}

local autosnippets = {}

return snippets, autosnippets

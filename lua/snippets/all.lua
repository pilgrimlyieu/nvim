---Date snippets available in every filetype.
local ls = require("luasnip")

local loading = require("config.snippets.core.loading")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet

local date = nodes.date
local qualify = loading.qualify

local snippets = {
  s({ trig = "dt", name = "date" }, date("%Y-%m-%d")),
  s({ trig = "dtt", name = "date and time" }, date("%Y-%m-%d %H:%M")),
}

local autosnippets = {}

return qualify("Global", snippets, autosnippets)

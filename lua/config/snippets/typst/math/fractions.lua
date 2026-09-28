local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local operand = require("config.snippets.shared.operand")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local operand_engine = operand.engine
local ungroup = operand.ungroup
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

function M.autosnippets()
  local condition = conditions.math
  return {
    s(
      with_condition({ trig = "/.", name = "fraction", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmt("frac({}, {})", { visual_insert(1), i(2) })
    ),
    s(
      with_condition({
        trig = "/",
        name = "simple fraction",
        trigEngine = operand_engine,
        wordTrig = false,
        snippetType = "autosnippet",
      }, condition),
      fmt("frac({}, {})", {
        f(function(_, snip)
          return ungroup(snip.captures[1])
        end),
        visual_insert(1),
      })
    ),
  }
end

return M

---Typst script entry, editing, and incremental typing policy.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local triggers = require("config.snippets.core.triggers")
local syntax = require("config.snippets.typst.math.syntax")
local math_snippets = require("config.snippets.shared.math_snippets")
local rules = require("config.snippets.shared.rules.scripts")

local s = ls.snippet

local script_snippets = math_snippets.scripts
local capture = nodes.capture
local with_condition = conditions.with_condition
local rewrite_engine = triggers.rewrite_engine

-- Numeric shorthand cannot restart inside a name, field, code token or superscript.
local NUMERIC_SUBSCRIPT_BOUNDARY = '[%w_.#"`^]'

local function group(content)
  if content:match("^%d[%d%.]*$") or content:match("^[%a][%w%.]*$") then
    return content
  end
  return "(" .. content .. ")"
end

local function automatic(name, pattern, render, condition, boundary)
  return s(
    with_condition({
      trig = pattern,
      name = name,
      trigEngine = rewrite_engine(pattern, render, boundary),
      wordTrig = false,
      priority = 1100,
      snippetType = "autosnippet",
    }, condition),
    { capture(1) }
  )
end

local function quick_scripts(condition)
  local out = {}
  for _, rule in ipairs(rules.quick) do
    out[#out + 1] = automatic(rule.name, rule.pattern, function(captures)
      return rule.marker .. captures[1]
    end, condition)
  end
  return out
end

function M.snippets()
  return script_snippets(syntax, "(", ")", function(rule)
    return group(rule.value or rule.typst)
  end, 1100)
end

function M.autosnippets()
  local autos = {
    automatic("automatic numeric subscript", "([%a][%a%.]*)(%d+)$", function(captures, full)
      if captures[1]:sub(-1) == "." then
        return full
      end
      return captures[1] .. "_" .. group(captures[2])
    end, conditions.math, NUMERIC_SUBSCRIPT_BOUNDARY),
    automatic("append numeric subscript", "_%((%d+)%)(%d+)$", function(captures)
      return "_(" .. captures[1] .. captures[2] .. ")"
    end, conditions.math),
    automatic("signed superscript", "%^(%-?%d+)$", function(captures)
      return "^" .. group(captures[1])
    end, conditions.math),
    automatic("append numeric superscript", "%^%((%-?%d+)%)(%d+)$", function(captures)
      return "^(" .. captures[1] .. captures[2] .. ")"
    end, conditions.math),
  }
  vim.list_extend(autos, quick_scripts(conditions.math))
  return autos
end

return M

---Latex script entry, editing, and incremental typing policy.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local triggers = require("config.snippets.core.triggers")
local syntax = require("config.snippets.latex.math.syntax")
local math_snippets = require("config.snippets.shared.math_snippets")
local rules = require("config.snippets.shared.rules.scripts")

local s = ls.snippet

local script_snippets = math_snippets.scripts
local capture = nodes.capture
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local rewrite_engine = triggers.rewrite_engine

local function group(content)
  if content:match("^%w$") or content:match("^\\%a+$") then
    return content
  end
  return "{" .. content .. "}"
end

local function automatic(name, pattern, render, condition, boundary)
  return s(
    with_condition({
      trig = pattern,
      name = name,
      trigEngine = rewrite_engine(pattern, render, boundary),
      wordTrig = false,
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
  local out = script_snippets(syntax, "{", "}", function(rule)
    return group(rule.value or rule.latex)
  end)
  out[#out + 1] = s(
    with_condition({ trig = "subst", name = "substack" }, conditions.math),
    fmta([[_{\substack{<>}}]], { visual_insert(1) })
  )
  return out
end

function M.autosnippets()
  local math = conditions.math
  local autos = {
    automatic("automatic numeric subscript", "([%a])(%d)$", function(captures)
      return captures[1] .. "_" .. captures[2]
    end, conditions.pure_math, "[_^]"),
    automatic("numeric subscript", "_(%d+)$", function(captures)
      return "_" .. group(captures[1])
    end, math),
    automatic("append numeric subscript", "_%{(%d+)%}(%d+)$", function(captures)
      return "_{" .. captures[1] .. captures[2] .. "}"
    end, math),
    automatic("numeric superscript", "%^(%-?%d+)$", function(captures)
      return "^" .. group(captures[1])
    end, math),
    automatic("append numeric superscript", "%^%{(%-?%d+)%}(%d+)$", function(captures)
      return "^{" .. captures[1] .. captures[2] .. "}"
    end, math),
  }
  vim.list_extend(autos, quick_scripts(math))
  return autos
end

return M

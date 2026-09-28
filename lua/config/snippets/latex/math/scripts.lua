---LaTeX scripts; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local scripts = require("config.snippets.shared.scripts")

local s = ls.snippet

local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

---@type SnipScriptSyntax
local syntax = {
  open = "{",
  close = "}",
  command_prefix = "\\",
  render = function(content)
    if content:match("^%w$") or content:match("^\\%a+$") then
      return content
    end
    return "{" .. content .. "}"
  end,
}

function M.snippets()
  local snippets = {
    scripts.wrap(syntax, ",", "subscript", "_", conditions.math),
    scripts.wrap(syntax, "'", "superscript", "^", conditions.math),
    scripts.edit(syntax, "sb", "edit subscript", "_", conditions.math),
    scripts.edit(syntax, "sp", "edit superscript", "^", conditions.math),
    s(
      with_condition({ trig = "subst", name = "substack" }, conditions.math),
      fmta([[_{\substack{<>}}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "''", name = "derivative order", wordTrig = false }, conditions.math),
      fmta([[^{(<>)}]], { visual_insert(1) })
    ),
  }
  vim.list_extend(snippets, scripts.fixed(syntax, "latex", conditions.math, false))
  return snippets
end

function M.autosnippets()
  local math = conditions.math
  local autos = {
    scripts.auto(syntax, "automatic numeric subscript", "([%a])(%d)$", function(captures)
      return captures[1] .. "_" .. captures[2]
    end, conditions.pure_math),
    scripts.auto(syntax, "numeric subscript", "_(%d+)$", function(captures)
      return "_" .. syntax.render(captures[1])
    end, math),
    scripts.auto(syntax, "append numeric subscript", "_%{(%d+)%}(%d+)$", function(captures)
      return "_{" .. captures[1] .. captures[2] .. "}"
    end, math),
    scripts.auto(syntax, "numeric superscript", "%^(%-?%d%d+)$", function(captures)
      return "^" .. syntax.render(captures[1])
    end, math),
    scripts.auto(syntax, "append numeric superscript", "%^%{(%-?%d+)%}(%d+)$", function(captures)
      return "^{" .. captures[1] .. captures[2] .. "}"
    end, math),
  }
  vim.list_extend(autos, scripts.quick_scripts(syntax, math))
  vim.list_extend(autos, scripts.fixed(syntax, "latex", math, true))
  return autos
end

return M

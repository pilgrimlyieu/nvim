---Typst scripts; ordinary and automatic entries share their feature.
local M = {}

local conditions = require("config.snippets.core.conditions")
local scripts = require("config.snippets.shared.scripts")

---@type SnipScriptSyntax
local syntax = {
  open = "(",
  close = ")",
  boundary = '[%w_.#"`^]',
  priority = 1100,
  render = function(content)
    if content:match("^%d[%d%.]*$") or content:match("^[%a][%w%.]*$") then
      return content
    end
    return "(" .. content .. ")"
  end,
}

function M.snippets()
  local snippets = {
    scripts.wrap(syntax, "_", "subscript field", "_", conditions.math),
    scripts.wrap(syntax, "^", "superscript field", "^", conditions.math),
    scripts.edit(syntax, "sb", "edit subscript", "_", conditions.math),
    scripts.edit(syntax, "sp", "edit superscript", "^", conditions.math),
  }
  vim.list_extend(snippets, scripts.fixed(syntax, "typst", conditions.math, false))
  return snippets
end

function M.autosnippets()
  local autos = {
    scripts.auto(syntax, "automatic numeric subscript", "([%a][%a%.]*)(%d+)$", function(captures, full)
      if captures[1]:sub(-1) == "." then
        return full
      end
      return captures[1] .. "_" .. syntax.render(captures[2])
    end, conditions.math),
    scripts.auto(syntax, "append numeric subscript", "([%a][%a%.]*)_%((%d+)%)(%d+)$", function(captures)
      return captures[1] .. "_(" .. captures[2] .. captures[3] .. ")"
    end, conditions.math),
    scripts.auto(syntax, "signed superscript", "([%a][%a%.]*)%^(%-?%d+)$", function(captures)
      return captures[1] .. "^" .. syntax.render(captures[2])
    end, conditions.math),
    scripts.auto(syntax, "append numeric superscript", "([%a][%a%.]*)%^%((%-?%d+)%)(%d+)$", function(captures)
      return captures[1] .. "^(" .. captures[2] .. captures[3] .. ")"
    end, conditions.math),
  }
  vim.list_extend(autos, scripts.quick_scripts(syntax, conditions.math))
  vim.list_extend(autos, scripts.fixed(syntax, "typst", conditions.math, true))
  return autos
end

return M

---Latex decorations modify a base; whole-expression wrapping lives separately.
local M = {}

local syntax = require("config.snippets.latex.math.syntax")
local edits = require("config.snippets.shared.math_edits")
local rules = require("config.snippets.shared.rules.decorations")
local math_snippets = require("config.snippets.shared.math_snippets")

local decoration_snippets = math_snippets.decoration
local decorate = edits.decorate
local range_body = edits.range_body

local dotless = { i = [[\imath]], j = [[\jmath]] }

---Render a recognized base decoration, preserving attachment policy and native syntax.
---@param operand SnipMathOperand
---@param command string
---@param opts SnipLatexDecorationOptions
---@return string
local function decorate_operand(operand, command, opts)
  local body, outside = decorate(operand, opts.scripts)
  local base = body == operand.base and range_body(operand.base) or operand.base
  body = range_body(body)
  if opts.accent then
    if opts.wide and #base > 1 and not base:match("^\\%a+$") then
      command = opts.wide
    end
    body = (dotless[base] or base) .. body:sub(#base + 1)
  end
  return command .. "{" .. body .. "}" .. outside
end

function M.snippets()
  local out = {}
  for _, rule in ipairs(rules) do
    if rule.latex then
      local opts = vim.tbl_deep_extend("force", {}, rule.opts or {}, rule.latex_opts or {})
      vim.list_extend(
        out,
        decoration_snippets(syntax, rule, opts, rule.latex .. "{<>}", function(operand)
          return decorate_operand(operand, rule.latex, opts)
        end)
      )
    end
  end
  return out
end

return M

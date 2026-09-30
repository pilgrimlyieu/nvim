---Typst decorations modify a base; whole-expression wrapping lives separately.
local M = {}

local syntax = require("config.snippets.typst.math.syntax")
local edits = require("config.snippets.shared.math_edits")
local rules = require("config.snippets.shared.rules.decorations")
local math_snippets = require("config.snippets.shared.math_snippets")

local decoration_snippets = math_snippets.decoration
local decorate = edits.decorate
local range_body = edits.range_body

---Render a recognized base decoration, preserving attachment policy and native syntax.
---@param operand SnipMathOperand
---@param command string
---@param opts SnipDecorationOptions
---@return string
local function decorate_operand(operand, command, opts)
  local body, outside = decorate(operand, opts.scripts)
  body = range_body(body)
  return command .. "(" .. body .. ")" .. outside
end

function M.snippets()
  local out = {}
  for _, rule in ipairs(rules) do
    if rule.typst then
      local opts = vim.tbl_deep_extend("force", {}, rule.opts or {}, rule.typst_opts or {})
      vim.list_extend(
        out,
        decoration_snippets(syntax, rule, opts, rule.typst .. "(<>)", function(operand)
          return decorate_operand(operand, rule.typst, opts)
        end)
      )
    end
  end
  return out
end

return M

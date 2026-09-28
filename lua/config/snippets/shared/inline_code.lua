---Inline-code factories shared by Markdown, TeX and Typst text mode.
local M = {}

local prose_math = require("config.snippets.shared.prose_math")
local triggers = require("config.snippets.core.triggers")

local capture = prose_math.capture
local inline_code_postfix_engine = triggers.inline_code_postfix_engine

---Capture the preceding token as inline code, with spacing managed by prose_math.
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.capture_code(left, right, opts)
  return capture(";;", "inline code", inline_code_postfix_engine, left, right, opts)
end

return M

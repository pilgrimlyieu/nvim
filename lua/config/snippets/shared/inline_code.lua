---Inline-code factories shared by Markdown, TeX and Typst text mode.
local M = {}

local prose = require("config.snippets.shared.prose")
local triggers = require("config.snippets.core.triggers")

local capture = prose.capture
local token_postfix_engine = triggers.token_postfix_engine

---Capture the preceding token as inline code, with spacing managed by prose.
---@param left string
---@param right string
---@param opts? SnipProseOptions
---@return LuaSnip.Snippet
function M.capture_code(left, right, opts)
  return capture(";;", "inline code", function()
    return token_postfix_engine({ ";;", "；；" }, "([A-Za-z0-9_^+=%%%.<>%[%]%(%)%-]+)$")
  end, left, right, opts)
end

return M

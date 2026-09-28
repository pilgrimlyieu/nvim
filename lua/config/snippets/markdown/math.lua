---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local inline_code = require("config.snippets.shared.inline_code")
local prose_math = require("config.snippets.latex.prose_math")
local text_math = require("config.snippets.shared.prose_math")

local capture_code = inline_code.capture_code
local capture_math = text_math.capture_math
local display = text_math.display
local inline = text_math.inline
local prose_math_snippets = prose_math.snippets

function M.snippets()
  return prose_math_snippets("markdown")
end

function M.autosnippets()
  return {
    inline("$", "$"),
    display("$$", "$$"),
    capture_math("$", "$"),
    capture_code("`", "`"),
  }
end

return M

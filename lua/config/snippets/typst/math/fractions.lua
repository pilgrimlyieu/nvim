---Typst spelling and input trigger of the fraction operation.
local M = {}

local conditions = require("config.snippets.core.conditions")
local syntax = require("config.snippets.typst.math.syntax")
local math_snippets = require("config.snippets.shared.math_snippets")

local fraction_snippets = math_snippets.fractions

function M.autosnippets()
  return fraction_snippets(syntax, "/.", "frac(<>, <>)", conditions.math)
end

return M

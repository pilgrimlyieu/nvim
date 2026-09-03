---Assemble fresh LaTeX nodes for each Markdown/TeX loader invocation.
local enabled = require("config.snippets.groups")
local M = {}

---@param opts? { markdown_reference?: boolean }
---@return SnipNode[] snippets
---@return SnipNode[] autosnippets
function M.load(opts)
  local snippets, autosnippets = {}, {}
  if enabled("latex_core") then
    vim.list_extend(snippets, require("config.snippets.latex.snippets").math_snippets())
    vim.list_extend(autosnippets, require("config.snippets.latex.autos").math_autosnippets())
  end
  if enabled("latex_extra") then
    vim.list_extend(snippets, require("config.snippets.latex_extra.snippets").math_snippets())
    vim.list_extend(autosnippets, require("config.snippets.latex_extra.autos").math_autosnippets())
  end
  if opts and opts.markdown_reference and enabled("markdown_math_reference") then
    vim.list_extend(snippets, require("config.snippets.markdown").math_reference_snippets())
  end
  return snippets, autosnippets
end

return M

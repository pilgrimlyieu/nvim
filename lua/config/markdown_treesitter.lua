local M = {}

local indented_code_highlight = "%f[%S]%(indented_code_block%)%s+@markup%.raw%.block\n?"
local indented_code_injection = [[

((indented_code_block) @injection.content
  (#set! injection.language "markdown_inline"))
]]
local applied = false

---@param query_name string
---@return string?
local function read_markdown_query(query_name)
  local ok, files = pcall(vim.treesitter.query.get_files, "markdown", query_name)
  if not ok or #files == 0 then
    return nil
  end

  local chunks = {}
  for _, file in ipairs(files) do
    local lines = vim.fn.readfile(file)
    chunks[#chunks + 1] = table.concat(lines, "\n")
  end

  return table.concat(chunks, "\n")
end

---Treat four-space indented Markdown blocks as prose for editing purposes.
---
---Tree-sitter's Markdown parser must keep producing `indented_code_block`
---nodes for CommonMark compatibility.  The query patch keeps those nodes from
---looking like raw code and injects their content as `markdown_inline`, while
---fenced code blocks and their language injections keep their normal behavior.
function M.setup()
  if applied or vim.g.markdown_indented_code_blocks_as_code == true then
    return
  end

  local highlights = read_markdown_query("highlights")
  local injections = read_markdown_query("injections")
  if not highlights or not injections then
    return
  end

  highlights = highlights:gsub(indented_code_highlight, "")
  if not injections:find(indented_code_injection, 1, true) then
    injections = injections .. indented_code_injection
  end

  vim.treesitter.query.set("markdown", "highlights", highlights)
  vim.treesitter.query.set("markdown", "injections", injections)
  applied = true
end

return M

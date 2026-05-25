local M = {}

local augroup_name = "MarkdownVimtexSyntax"

local math_regions = {
  [[syntax region mkdMath start="\\\@<!\$" end="\$" skip="\\\$" contains=@markdownVimtexTex keepend]],
  [[syntax region mkdMath start="\\\@<!\$\$" end="\$\$" skip="\\\$" contains=@markdownVimtexTex keepend]],
  [[syntax region mkdMath start="\\\@<!\\(" end="\\\@<!\\)" contains=@markdownVimtexTex keepend]],
  [[syntax region mkdMath start="\\\@<!\\\[" end="\\\@<!\\\]" contains=@markdownVimtexTex keepend]],
}

---@param bufnr integer
local function valid_markdown_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "markdown"
end

---@param bufnr integer
local function apply_bridge(bufnr)
  if vim.g.markdown_vimtex_syntax_enabled == false then
    return
  end

  if not valid_markdown_buffer(bufnr) then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    if vim.bo.syntax == "markdown" and vim.b.markdown_vimtex_syntax then
      return
    end

    vim.bo.syntax = "markdown"
    vim.b.markdown_vimtex_syntax = true

    vim.b.current_syntax = nil
    vim.cmd("syntax include @markdownVimtexTex syntax/tex.vim")
    vim.b.current_syntax = "markdown"

    for _, region in ipairs(math_regions) do
      vim.cmd(region)
    end
  end)
end

---@param bufnr integer
function M.enable(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr

  vim.schedule(function()
    apply_bridge(bufnr)
  end)
end

function M.setup()
  local group = vim.api.nvim_create_augroup(augroup_name, { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(args)
      M.enable(args.buf)
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if valid_markdown_buffer(bufnr) then
      M.enable(bufnr)
    end
  end
end

return M

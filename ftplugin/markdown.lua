local line_count = vim.api.nvim_buf_line_count(0)
local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
local large_line_threshold = vim.g.markdown_large_line_threshold or 1000
local large_size_threshold = vim.g.markdown_large_size_threshold or (80 * 1024)
local large_markdown = line_count > large_line_threshold or file_size > large_size_threshold

vim.opt_local.spell = true
vim.opt_local.conceallevel = 0
vim.b.markdown_large_file = large_markdown

if large_markdown then
  vim.b.snacks_indent = false
  vim.b.snacks_scope = false
  vim.b.minihipatterns_disable = true
  vim.wo.foldmethod = "manual"
  vim.wo.foldexpr = "0"
end

-- Keep Markdown prose buffers quiet.  LazyVim's Markdown extra enables a few
-- automatic tools by default, but notes/math drafts should not lint or format
-- themselves on every edit/save.
vim.b.autoformat = false

vim.diagnostic.enable(false, { bufnr = 0 })

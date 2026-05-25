vim.opt_local.spell = true

-- Keep Markdown prose buffers quiet.  LazyVim's Markdown extra enables a few
-- automatic tools by default, but notes/math drafts should not lint or format
-- themselves on every edit/save.
vim.b.autoformat = false

if vim.diagnostic.is_enabled then
  vim.diagnostic.enable(false, { bufnr = 0 })
else
  ---@diagnostic disable-next-line: deprecated
  vim.diagnostic.disable(0)
end

vim.g.vimtex_syntax_conceal = {
  accents = 1,
  ligatures = 0,
  cites = 1,
  fancy = 1,
  texTabularChar = 1,
  spacing = 1,
  greek = 1,
  math_bounds = 0,
  math_delimiters = 1,
  math_fracs = 1,
  math_super_sub = 1,
  math_symbols = 1,
  sections = 0,
  styles = 1,
}

vim.g.vimtex_compiler_enabled = false
vim.g.vimtex_mappings_enabled = false
vim.g.vimtex_imaps_enabled = false

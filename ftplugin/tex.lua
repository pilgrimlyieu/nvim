vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us,cjk"

vim.api.nvim_create_augroup("vimtex_config", { clear = true })
vim.api.nvim_create_autocmd({ "User VimtexEventQuit" }, {
  group = "vimtex_config",
  command = "call vimtex#compiler#clean(0)",
})

vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us,cjk"

vim.api.nvim_create_augroup("vimtex_config", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = "vimtex_config",
  pattern = "VimtexEventQuit",
  callback = function()
    pcall(vim.fn["vimtex#compiler#clean"], 0)
  end,
})

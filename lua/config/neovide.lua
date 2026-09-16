vim.g.neovide_cursor_animation_length = 0.06
vim.g.neovide_cursor_trail_size = 0.3
vim.g.neovide_scroll_animation_length = 0.15
vim.g.neovide_cursor_vfx_mode = ""

vim.g.neovide_input_ime = false

vim.keymap.set({ "n", "i", "v", "c", "t" }, "<S-Insert>", function()
  vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
end, { noremap = true, silent = true, desc = "Paste from system clipboard" })

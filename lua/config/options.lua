-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.breakindent = true
vim.o.showbreak = " ↪"

vim.g.snacks_animate = false

local opt = vim.opt

opt.spelllang = "en_us,cjk"
opt.wrap = true
opt.shiftwidth = 4
opt.tabstop = 4

require("config/clipboard")

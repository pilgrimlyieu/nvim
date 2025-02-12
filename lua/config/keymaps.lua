-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<Esc>", { silent = true, desc = "Escape insert mode" })
vim.keymap.set("i", "kj", "<Esc>", { silent = true, desc = "Escape insert mode" })
vim.keymap.set("n", "U", "<C-r>", { silent = true, desc = "Redo" })
vim.keymap.set("", ";", ":", { silent = true, desc = "Command mode" })
vim.keymap.set("", ":", ",", { silent = true, desc = "Repeat opposite f/t/F/T" })
vim.keymap.set("", ",", ";", { silent = true, desc = "Repeat f/t/F/T" })
vim.keymap.set("", "`", "'", { silent = true, desc = "First non-blank location mark" })
vim.keymap.set("", "'", "`", { silent = true, desc = "Precise location" })
vim.keymap.set("", "H", "0", { silent = true, desc = "Begining of the line" })
vim.keymap.set("", "L", "$", { silent = true, desc = "End of the line" })
vim.keymap.set("n", "Y", "<Cmd>%y<Cr>", { silent = true, desc = "Yank the whole file" })
vim.keymap.set("i", "<C-s>", "<Cmd>w<Cr>", { silent = true, desc = "Save file" })

vim.keymap.set("", "gj", "j", { silent = true, desc = "Move down actual line" })
vim.keymap.set("", "gk", "k", { silent = true, desc = "Move up actual line" })
vim.keymap.set(
  "n",
  "<leader>o",
  "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>",
  { silent = true, desc = "Insert line below" }
)
vim.keymap.set(
  "n",
  "<leader>O",
  "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>",
  { silent = true, desc = "Insert line above" }
)
vim.keymap.set(
  "v",
  "gC",
  "<Cmd>'<,'>s/\\v([一-龟])@<=(\\w+)([一-龟])@=/ \\2 /e <Bar> '<,'>s/\\v([一-龟])@<=(\\w+)([一-龟])@!/ \\2/e <Bar> '<,'>s/\\v([一-龟])@<!(\\w+)([一-龟])@=/\\2 /e <Bar> noh<CR>",
  { silent = true, desc = "Add space around Chinese" }
)
vim.keymap.set("c", "w!!", "w !sudo tee > /dev/null %", { silent = true, desc = "Write as sudo" }) -- Add a command to replace

vim.opt.mouse = ""

if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set({ "n", "x" }, "<C-e>", "mciw*<Cmd>nohl<CR>")

  vim.keymap.set("n", "u", "<Cmd>call VSCodeNotify('undo')<CR>")
  vim.keymap.set("n", "U", "<Cmd>call VSCodeNotify('redo')<CR>")
end

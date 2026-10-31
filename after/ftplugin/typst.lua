-- Typst identifiers allow hyphens
vim.opt_local.iskeyword:append("-")

local undo = "setlocal iskeyword<"
vim.b.undo_ftplugin = vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | " .. undo) or undo

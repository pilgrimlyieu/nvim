-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.breakindent = true
vim.o.showbreak = " ↪"

vim.g.snacks_animate = false
vim.g.trouble_lualine = false

local opt = vim.opt

opt.spelllang = "en_us,cjk"
opt.wrap = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.list = true
opt.listchars = { tab = ">!", trail = "·", nbsp = "␣" }

if vim.fn.has("win32") == 1 then
  opt.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
  opt.shellcmdflag =
    "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues['Out-File:Encoding']='utf8';Remove-Alias -Force -ErrorAction SilentlyContinue tee;"
  opt.shellredir = '2>&1 | ForEach-Object { "$_" } | Out-File %s; exit $LastExitCode'
  opt.shellpipe = '2>&1 | ForEach-Object { "$_" } | tee %s; exit $LastExitCode'
  opt.shellquote = ""
  opt.shellxquote = ""
end

-- mason.nvim only prepends its bin dir to PATH once it loads, which is now
-- deferred past the first frame. Plugins that spawn servers at FileType time
-- (e.g. rustaceanvim -> rust-analyzer) need the correct binaries resolvable
-- earlier, so mirror mason's PATH setup here.
do
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  if vim.uv.fs_stat(mason_bin) then
    vim.env.PATH = mason_bin .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.PATH
  end
end

require("config/clipboard")

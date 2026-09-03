---Build a pinned Markdown parser with native admonition containers.
---Only the shared library is cached; upstream's checkout stays untouched.
local M = {}
local patch = assert(vim.api.nvim_get_runtime_file("treesitter/markdown-admonitions.patch", false)[1])
local runtime = vim.fs.dirname(patch)

---@param plugin { dir: string, commit: string }
---@return string
local function library_path(plugin)
  local source = table.concat(vim.fn.readfile(patch), "\n")
  local hash = vim.fn.sha256(plugin.commit .. vim.treesitter.language_version .. source):sub(1, 16)
  return plugin.dir .. "/build/nvim-markdown-" .. hash .. ".so"
end

---@param command string[]
---@param cwd string
local function run(command, cwd)
  local result = vim.system(command, { cwd = cwd, text = true }):wait(60000)
  assert(result.code == 0, table.concat(command, " ") .. "\n" .. result.stderr .. result.stdout)
end

---@param plugin { dir: string, commit: string }
function M.build(plugin)
  local build = vim.fn.tempname()
  local library = library_path(plugin)
  local output = library .. "." .. vim.uv.os_getpid() .. ".tmp"
  local ok, err = pcall(function()
    for _, file in ipairs({
      "tree-sitter.json",
      "common/common.js",
      "common/html_entities.json",
      "tree-sitter-markdown/grammar.js",
      "tree-sitter-markdown/src/scanner.c",
    }) do
      local target = build .. "/" .. file
      vim.fn.mkdir(vim.fs.dirname(target), "p")
      assert(vim.uv.fs_copyfile(plugin.dir .. "/" .. file, target))
    end
    run({ "git", "apply", "--", patch }, build)
    local grammar = build .. "/tree-sitter-markdown"
    run(
      { "tree-sitter", "generate", "--js-runtime", "native", "--abi", tostring(vim.treesitter.language_version) },
      grammar
    )
    vim.fn.mkdir(vim.fs.dirname(library), "p")
    run({ "tree-sitter", "build", "--output", output }, grammar)
    assert(vim.uv.fs_rename(output, library))
  end)
  vim.fn.delete(output)
  vim.fn.delete(build, "rf")
  assert(ok, err)
end

---@param plugin { dir: string, commit: string }
function M.setup(plugin)
  local library = library_path(plugin)
  if not vim.uv.fs_stat(library) then
    M.build(plugin)
  end
  assert(vim.treesitter.language.add("markdown", { path = library }))
  -- language.add() keeps an already loaded language until Neovim restarts.
  if not vim.treesitter.language.inspect("markdown").symbols.admonition then
    vim.notify("Restart Neovim to load the Markdown admonition parser", vim.log.levels.WARN)
    return
  end
  vim.opt.runtimepath:prepend(runtime)
end

return M

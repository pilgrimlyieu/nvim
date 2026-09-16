-- Load the maintained Typst parser and queries.
local query_names = {
  "highlights",
  "injections",
  "indents",
  "folds",
  "context",
  "images",
  "locals",
  "tags",
  "textobjects",
}

return {
  {
    "git@github.com:pilgrimlyieu/tree-sitter-typst.git",
    name = "tree-sitter-typst",
    branch = "runtime",
    lazy = false,
    priority = 2000,
    config = function(plugin)
      local parser = plugin.dir .. "/parser/" .. (vim.fn.has("win32") == 1 and "typst.dll" or "typst.so")
      assert(vim.treesitter.language.add("typst", { path = parser }), "cannot load typst parser: " .. parser)
      -- LazyVim resets 'runtimepath' and keeps stdpath("data")/site ahead of the
      -- plugin directories, so stale site queries for an older grammar would win.
      -- Pin the runtime's queries explicitly instead of relying on rtp order;
      -- :TSUpdate typst cannot clobber them.
      for _, name in ipairs(query_names) do
        local ok, lines = pcall(vim.fn.readfile, plugin.dir .. "/queries/typst/" .. name .. ".scm")
        if ok and #lines > 0 then
          vim.treesitter.query.set("typst", name, table.concat(lines, "\n"))
        end
      end
    end,
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("config.markdown_treesitter").setup()
    end,
    opts = function(_, opts)
      -- LazyVim's have_query() compiles the full query at FileType time,
      -- before the first frame (~150ms for cpp highlights). An existence
      -- check is enough here; the query is compiled when highlighting
      -- actually starts (deferred to after UIEnter, see config.options).
      local ts_util = require("lazyvim.util.treesitter")
      function ts_util.have_query(lang, query)
        local key = lang .. ":" .. query
        if ts_util._queries[key] == nil then
          ts_util._queries[key] = #vim.treesitter.query.get_files(lang, query) > 0
        end
        return ts_util._queries[key]
      end

      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs({
        "html",
        "markdown",
        "markdown_inline",
        "typst",
        "vue",
        "css",
        "scss",
      }) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {
      per_filetype = {
        markdown = {
          enable_close = false,
          enable_rename = false,
          enable_close_on_slash = false,
        },
      },
    },
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("config.markdown_treesitter").setup()
    end,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs({
        "html",
        "markdown",
        "markdown_inline",
        "typst",
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

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = function(_, opts)
      opts.library = opts.library or {}
      vim.list_extend(opts.library, {
        { path = vim.fn.stdpath("config") .. "/lua/config/snippets", words = { "Snip" } },
        { path = "jj.nvim", words = { "jj%." } },
      })
      return opts
    end,
  },
}

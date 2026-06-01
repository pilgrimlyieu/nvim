return {
  {
    "folke/lazydev.nvim",
    opts = function(_, opts)
      -- Prefer jj.nvim's shipped annotations over a copied local type mirror.
      opts.library = opts.library or {}
      table.insert(opts.library, { path = "jj.nvim", words = { "jj%." } })
    end,
  },
  {
    "nvim-mini/mini.align",
    keys = {
      { "ga", mode = { "n", "v" }, desc = "Align" },
      { "gA", mode = { "n", "v" }, desc = "Align with preview" },
    },
    opts = {},
  },
}

return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}

    opts.formatters_by_ft.json = { "biome" }

    -- LazyVim's Markdown extra wires Prettier, markdownlint-cli2, and
    -- markdown-toc into Conform.  Markdown notes are intentionally left
    -- unmanaged so saving prose does not rewrite text or table-of-contents.
    opts.formatters_by_ft.markdown = {}
    opts.formatters_by_ft["markdown.mdx"] = {}

    return opts
  end,
}

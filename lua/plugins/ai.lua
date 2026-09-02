return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      Snacks.toggle({
        name = "AI Inline Completion",
        get = vim.lsp.inline_completion.is_enabled,
        set = function(state)
          vim.lsp.inline_completion.enable(state)
        end,
      }):map("<leader>ai")

      return opts
    end,
  },
}

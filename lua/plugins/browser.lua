return {
  {
    "glacambre/firenvim",
    lazy = not vim.g.started_by_firenvim,
    cond = not not vim.g.started_by_firenvim,
    module = false,
    build = function()
      vim.fn["firenvim#install"](0)
    end,
    config = function()
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "github.com_*.txt",
        command = "set filetype=markdown",
      })

      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
        },
      }

      vim.o.guifont = "JetBrainsMono_NFM:h14"
    end,
  },
}

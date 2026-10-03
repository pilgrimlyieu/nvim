return {
  {
    "glacambre/firenvim",
    cond = not not vim.g.started_by_firenvim,
    module = false,
    build = function()
      vim.fn["firenvim#install"](0)
    end,
    init = function()
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
    end,
    config = function()
      local min_height, max_height = 20, 50

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          vim.o.guifont = "JetBrainsMono_NFM:h14"
          vim.o.guifontwide = "Microsoft_YaHei_Mono:h15"
          vim.o.lines = min_height
          vim.bo.filetype = "markdown"
        end,
      })

      local id = vim.api.nvim_create_augroup("ExpandLinesOnTextChanged", { clear = true })
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = id,
        callback = function(_)
          vim.o.lines = math.min(math.max(vim.api.nvim_win_text_height(0, {}).all, min_height), max_height)
        end,
      })
    end,
  },
}

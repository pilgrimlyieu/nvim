return {
  {
    "folke/flash.nvim",
    keys = {
      { "S", mode = { "n", "o", "x" }, false },
      {
        "gs",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
    init = function()
      local function flash_hl()
        local function get(group, key)
          return vim.api.nvim_get_hl(0, { name = group, link = false })[key]
        end
        local fg = get("Normal", "bg") or (vim.o.background == "dark" and 0x000000 or 0xffffff)
        vim.api.nvim_set_hl(0, "FlashBackdrop", { bg = get("CursorLine", "bg") })
        vim.api.nvim_set_hl(0, "FlashMatch", { fg = fg, bg = get("DiagnosticInfo", "fg") })
        vim.api.nvim_set_hl(0, "FlashCurrent", { fg = fg, bg = get("DiagnosticWarn", "fg") })
        vim.api.nvim_set_hl(0, "FlashLabel", { fg = fg, bg = get("DiagnosticError", "fg"), bold = true })
      end

      vim.api.nvim_create_autocmd("ColorScheme", { callback = flash_hl })
      flash_hl()
    end,
    ---@type Flash.Config
    opts = {
      modes = {
        search = {
          enabled = true,
        },
      },
      jump = {
        autojump = true,
      },
    },
  },
  {
    "rainzm/flash-zh.nvim",
    dependencies = "folke/flash.nvim",
    keys = {
      {
        "gz",
        mode = { "n", "x", "o" },
        function()
          require("flash-zh").jump({ chinese_only = false })
        end,
        desc = "Flash Chinese",
      },
      {
        "gZ",
        mode = { "n", "x", "o" },
        function()
          require("flash-zh").jump({ chinese_only = true })
        end,
        desc = "Flash Chinese Only",
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "nvim-mini/mini.pairs",
    enabled = false,
  },
}

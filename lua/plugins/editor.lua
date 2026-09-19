return {
  {
    "folke/flash.nvim",
    keys = {
      { "s", mode = { "n", "o", "x" }, false },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
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
    opts = function()
      local default_char_config = require("flash.config").modes.char.config or function() end
      local user_char_config = require("config.punctuation").flash_char
      ---@type Flash.Config
      return {
        label = {
          rainbow = {
            enabled = true,
            shade = 6,
          },
        },
        modes = {
          char = {
            config = function(o)
              default_char_config(o)
              user_char_config(o)
            end,
            -- Match config/keymaps.lua: ; opens commands, ,/: repeat motions.
            keys = { "f", "F", "t", "T", [";"] = ",", [","] = ":" },
          },
          search = {
            enabled = true,
          },
        },
        jump = {
          autojump = true,
        },
      }
    end,
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
  {
    "nvim-mini/mini.ai",
    opts = function(_, opts)
      opts.custom_textobjects = opts.custom_textobjects or {}
      for _, pair in ipairs({
        { "（", "）" },
        { "【", "】" },
        { "《", "》" },
        { "〈", "〉" },
        { "‘", "’" },
        { "“", "”" },
        { "「", "」" },
        { "『", "』" },
      }) do
        local left, right = pair[1], pair[2]
        local spec = { left .. "().-()" .. right } -- assume nested pairs are not common
        opts.custom_textobjects[left] = spec
        opts.custom_textobjects[right] = spec
      end
      opts.custom_textobjects.B = {
        {
          "（().-()）",
          "【().-()】",
          "《().-()》",
          "〈().-()〉",
        },
      }
      opts.custom_textobjects.Q = {
        {
          "‘().-()’",
          "“().-()”",
          "「().-()」",
          "『().-()』",
        },
      }
    end,
  },
}

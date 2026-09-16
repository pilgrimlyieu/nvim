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
      {
        "R",
        mode = "o",
        function()
          -- https://github.com/folke/flash.nvim/issues/380#issuecomment-3255575807
          local register = vim.v.register
          require("flash").treesitter_search({
            action = function(match, state)
              require("flash.jump").remote_op(match, state, register)
            end,
          })
        end,
        desc = "Remote Treesitter Flash",
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

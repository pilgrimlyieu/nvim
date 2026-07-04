return {
  {
    "folke/flash.nvim",
    keys = {
      { "S", mode = { "n", "o", "x" }, false },
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
}

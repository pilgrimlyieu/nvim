return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>j", group = "jj" },
        { "<leader>gh", group = "hunks" },
        { "<leader>jh", group = "jj diff" },
      },
      triggers = {
        { "<auto>", mode = "nixsotc" },
        { "S", mode = "nv" },
      },
    },
  },
}

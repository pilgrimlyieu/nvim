return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "soft",
      overrides = {
        -- gruvbox defines no ComplHint, so inline-completion ghost text falls
        -- back to NonText = bg2 (#504945), ~1.5:1 against the soft background.
        -- bg4 (#7c6f64) is ~2.7:1.
        ComplHint = { link = "GruvboxBg4" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}

-- DiffText: gruvbox#314's background, a 2:1 mix of the soft background with
-- bright (dark) / faded (light) yellow.
-- DiffDelete is also the filler-line highlight (see |hl-DiffDelete|), so its
-- saturated red is softened halfway into the background.
local DIFF = {
  dark = { text = "#755f2f", delete = "#522b2c" },
  light = { text = "#dec084", delete = "#f7bda2" },
}

return {
  {
    "ellisonleao/gruvbox.nvim",
    init = function()
      -- `overrides` are applied once at setup, so re-apply after every gruvbox
      -- (re)load to cover `:colorscheme gruvbox` and background switches.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "gruvbox",
        callback = function()
          local c = DIFF[vim.o.background] or DIFF.dark
          vim.api.nvim_set_hl(0, "DiffText", { fg = "NONE", bg = c.text })
          vim.api.nvim_set_hl(0, "DiffDelete", { bg = c.delete })
        end,
      })
    end,
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

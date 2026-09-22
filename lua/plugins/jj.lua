return {
  {
    "nicolasgb/jj.nvim",
    version = "*", -- Use latest stable release.
    cond = function()
      return require("config.vcs").is_jj({ buf = 0 })
    end,
    dependencies = {
      "folke/snacks.nvim",
    },
    cmd = { "J", "Jbrowse", "Jdiff", "Jvdiff", "Jhdiff", "Jread", "Jedit", "Jsplit", "Jvsplit", "Jtabedit" },
    init = function()
      require("config.jj").init()
    end,
    config = function()
      require("config.jj").setup()
    end,
  },
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    opts = {
      ui = {
        tree = {
          use_float = true,
          float = {
            border = "rounded",
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
          },
        },
      },
    },
  },
}

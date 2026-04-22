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
    cmd = { "J", "Jbrowse", "Jdiff", "Jvdiff", "Jhdiff" },
    init = function()
      require("config.jj").init()
    end,
    config = function()
      require("config.jj").setup()
    end,
  },
}

return {
  {
    "lewis6991/gitsigns.nvim",
    cond = function()
      return require("config.vcs").is_git_only({ buf = 0 })
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts = opts or {}
      if require("config.vcs").is_git_only({ buf = 0 }) then
        return
      end

      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "gitui"
      end, opts.ensure_installed or {})
    end,
  },
}

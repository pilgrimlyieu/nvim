local diffview_close = {
  { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
  { "n", "Q", "<cmd>q<cr>", { desc = "Close Diffview Successfully" } },
  { "n", "gq", "<cmd>cq<cr>", { desc = "Close Diffview with Error" } },
}

return {
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
  {
    "dlyongemallo/diffview-plus.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewDiffFiles",
      "DiffviewMergeFiles",
      "DiffviewFileHistory",
      "DiffviewToggle",
      "DiffviewLog",
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        winfixbuf = true,
      },
      keymaps = {
        file_panel = diffview_close,
        file_history_panel = diffview_close,
        view = diffview_close,
      },
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewToggle<cr>", desc = "Diffview Toggle" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview File History" },
    },
  },
}

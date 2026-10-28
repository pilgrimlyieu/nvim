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
    ---@type jj.Config
    opts = {
      terminal = {
        window = {
          type = "floating",
          floating_width = 0.95,
          floating_height = 0.9,
        },
      },
      cmd = {
        keymaps = {
          floating = {
            close = { "q", "<Esc>" },
          },
          log = {
            edit = "<CR>",
            edit_immutable = "<S-CR>",
            describe = "d",
            diff = "D",
            new = "n",
            new_after = "<C-n>",
            new_after_immutable = "<S-n>",
            undo = "u",
            redo = "U",
            abandon = "A",
            bookmark = "b",
            rebase = "r",
            rebase_mode = {
              onto = { "<CR>", "o" },
              after = "a",
              before = "b",
              onto_immutable = { "<S-CR>", "<S-o>" },
              after_immutable = "<S-a>",
              before_immutable = "<S-b>",
              exit_mode = { "<Esc>", "<C-c>" },
            },
            squash = "s",
            squash_mode = {
              into = "<CR>",
              into_immutable = "<S-CR>",
              exit_mode = { "<Esc>", "<C-c>" },
            },
            quick_squash = "S",
            fetch = "f",
            push = "p",
            push_all = "P",
            open_pr = "o",
            open_pr_list = "O",
            split = "<C-s>",
            summary = "K",
            summary_tooltip = {
              diff = "D",
              edit = "<CR>",
              edit_immutable = "<S-CR>",
            },
            tag_set = "t",
            history = "H",
            change_revset = "c",
            select_next_revision = "]h",
            select_prev_revision = "[h",
          },
          status = {
            open_file = "<CR>",
            restore_file = "X",
          },
          close = { "q", "<Esc>" },
        },
      },
    },
    init = function()
      require("config.jj").init()
    end,
    config = function(_, opts)
      require("config.jj").setup(opts)
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

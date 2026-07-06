return {
  {
    "folke/which-key.nvim",
    keys = {
      {
        "<leader>",
        function()
          require("which-key").show({ keys = "<leader>", mode = "n" })
        end,
        desc = "which-key-trigger",
        nowait = true,
        silent = true,
      },
    },
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      opts.icons = opts.icons or {}
      opts.icons.rules = opts.icons.rules or {}

      local function remove_group(spec, lhs)
        for index = #spec, 1, -1 do
          local item = spec[index]
          if type(item) == "table" then
            if item[1] == lhs and item.group then
              table.remove(spec, index)
            else
              remove_group(item, lhs)
            end
          end
        end
      end

      local jj_icon_rules = {
        { pattern = "^jj diff", icon = " ", color = "blue" },
        { pattern = "^jj status", icon = "󰊢 ", color = "green" },
        { pattern = "^jj log", icon = "󰜘 ", color = "yellow" },
        { pattern = "^jj current file history", icon = "󰈙 ", color = "cyan" },
        { pattern = "^jj annotate", icon = "󰆽 ", color = "orange" },
        { pattern = "^jj browse", icon = "󰖟 ", color = "blue" },
        { pattern = "^jj key help", icon = "󰋖 ", color = "cyan" },
        { pattern = "^jj describe", icon = "󰙎 ", color = "cyan" },
        { pattern = "^jj new", icon = " ", color = "green" },
        { pattern = "^jj edit", icon = " ", color = "yellow" },
        { pattern = "^jj rebase", icon = "󰁨 ", color = "purple" },
        { pattern = "^jj squash", icon = "󰆐 ", color = "orange" },
        { pattern = "^jj undo", icon = " ", color = "yellow" },
        { pattern = "^jj redo", icon = " ", color = "yellow" },
        { pattern = "^jj abandon", icon = " ", color = "red" },
        { pattern = "^jj fetch", icon = "󰇚 ", color = "blue" },
        { pattern = "^jj push", icon = "󰕒 ", color = "green" },
        { pattern = "^jj open pr", icon = " ", color = "purple" },
        { pattern = "^jj bookmark", icon = " ", color = "azure" },
        { pattern = "^jj", icon = "󰊢 ", color = "purple" },
      }

      remove_group(opts.spec, "<leader>g")
      remove_group(opts.spec, "<leader>gh")

      for index = #jj_icon_rules, 1, -1 do
        table.insert(opts.icons.rules, 1, jj_icon_rules[index])
      end

      vim.list_extend(opts.spec, {
        {
          "<leader>g",
          group = function()
            return require("config.vcs").is_jj({ buf = 0 }) and "jj" or "git"
          end,
        },
        { "<leader>gh", group = "hunks" },
        { "<leader>j", group = "jj" },
        { "<leader>jh", group = "jj diff" },
      })

      opts.triggers = {
        { "<auto>", mode = "nixsotc" },
        { "S", mode = "nv" },
      }

      return opts
    end,
  },
}

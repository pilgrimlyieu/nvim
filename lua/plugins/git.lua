return {
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      opts = opts or {}
      local default_on_attach = opts.on_attach

      local function map(buffer, mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc, silent = true })
      end

      local function del(buffer, mode, lhs)
        local modes = type(mode) == "table" and mode or { mode }
        for _, item in ipairs(modes) do
          pcall(vim.keymap.del, item, lhs, { buffer = buffer })
        end
      end

      local function patch_jj_hunk_keymaps(buffer)
        local gs = package.loaded.gitsigns or require("gitsigns")

        del(buffer, { "n", "x" }, "<leader>ghs")
        del(buffer, "n", "<leader>ghS")
        del(buffer, "n", "<leader>ghu")
        del(buffer, "n", "<leader>ghb")
        del(buffer, "n", "<leader>ghB")
        del(buffer, "n", "<leader>ghd")
        del(buffer, "n", "<leader>ghD")
        del(buffer, { "n", "x" }, "<leader>ghr")
        del(buffer, "n", "<leader>ghR")

        map(buffer, { "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Discard Hunk")
        map(buffer, "n", "<leader>ghR", function()
          vim.ui.select({ "Discard buffer changes", "Cancel" }, {
            prompt = "Discard all changes in this buffer?",
          }, function(choice)
            if choice == "Discard buffer changes" then
              gs.reset_buffer()
            end
          end)
        end, "Discard Buffer")
      end

      opts.on_attach = function(buffer)
        if default_on_attach then
          default_on_attach(buffer)
        end

        if require("config.vcs").is_jj({ buf = buffer }) then
          patch_jj_hunk_keymaps(buffer)
        end
      end
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

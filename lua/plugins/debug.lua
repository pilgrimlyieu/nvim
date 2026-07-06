return {
  {
    "mfussenegger/nvim-dap",
    opts = function(_, opts)
      local dap = require("dap")
      local keymap = vim.keymap
      local group = "dap_temp_keymaps"

      local function leetcode_step_into()
        local session = dap.session()
        if not session or vim.tbl_get(session, "config", "type") ~= "leetcode_gdb" then
          dap.step_into()
          return
        end
        session:evaluate({ expression = "lc-step", context = "repl" }, function(err)
          if err then
            vim.schedule(function()
              vim.notify(err.message or tostring(err), vim.log.levels.ERROR, { title = "dap" })
            end)
          end
        end)
      end

      local function set_dap_keymaps()
        keymap.set("n", "<Down>", dap.step_over, { desc = "DAP Step Over", silent = true })
        keymap.set("n", "<Right>", leetcode_step_into, { desc = "DAP Step Into", silent = true })
        keymap.set("n", "<Left>", dap.step_out, { desc = "DAP Step Out", silent = true })
        keymap.set("n", "<Up>", dap.restart_frame, { desc = "DAP Restart Frame", silent = true })
      end

      local function reset_dap_keymaps()
        pcall(keymap.del, "n", "<Down>")
        pcall(keymap.del, "n", "<Right>")
        pcall(keymap.del, "n", "<Left>")
        pcall(keymap.del, "n", "<Up>")
      end

      dap.listeners.after.event_initialized[group] = set_dap_keymaps
      dap.listeners.before.event_terminated[group] = reset_dap_keymaps
      dap.listeners.before.event_exited[group] = reset_dap_keymaps
      dap.listeners.before.disconnect[group] = reset_dap_keymaps

      if vim.fn.executable("gdb") == 1 and not dap.adapters.gdb then
        dap.adapters.gdb = {
          type = "executable",
          command = "gdb",
          args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
        }
      end

      -- dap-ui 面板设 winfixbuf，默认 uselast 跳转在步入未打开的源文件时会 E1513；
      -- 自定义跳转：优先已显示该 buffer 的窗口，否则找可换 buffer 的普通窗口
      dap.defaults.fallback.switchbuf = function(bufnr, line, column)
        local wins = vim.api.nvim_tabpage_list_wins(0)
        local target
        for _, win in ipairs(wins) do
          if vim.api.nvim_win_get_buf(win) == bufnr then
            target = win
            break
          end
        end
        if not target then
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if not vim.wo[win].winfixbuf and vim.bo[buf].buftype == "" then
              target = win
              break
            end
          end
        end
        if not target then
          return
        end
        vim.api.nvim_win_set_buf(target, bufnr)
        vim.api.nvim_set_current_win(target)
        pcall(vim.api.nvim_win_set_cursor, target, { line, math.max(0, (column or 1) - 1) })
      end

      return opts
    end,
  },
}

return {
  { "rcarriga/nvim-dap-ui", enabled = false },
  {
    "igorlfs/nvim-dap-view",
    version = "1.*",
    lazy = true,
    cmd = {
      "DapViewOpen",
      "DapViewClose",
      "DapViewToggle",
      "DapViewWatch",
      "DapViewHover",
      "DapViewJump",
      "DapViewShow",
      "DapViewNavigate",
    },
    keys = {
      {
        "<leader>du",
        function()
          require("dap-view").toggle(true)
        end,
        desc = "Dap View",
      },
      {
        "<leader>de",
        function()
          require("dap-view").hover(nil, false)
        end,
        desc = "Eval",
        mode = { "n", "x" },
      },
      {
        "<leader>dE",
        function()
          require("dap-view").add_expr()
        end,
        desc = "Watch Expression",
        mode = { "n", "x" },
      },
    },
    opts = {
      auto_toggle = true,
      winbar = { default_section = "scopes" },
      -- 继续使用 LazyVim 的 nvim-dap-virtual-text，避免重复显示变量值。
      virtual_text = { enabled = false },
    },
  },
  {
    "mfussenegger/nvim-dap",
    -- 在启动 adapter 前加载视图，确保终端接管及自动开关监听器已注册。
    dependencies = { "igorlfs/nvim-dap-view" },
    opts = function(_, opts)
      local dap = require("dap")
      local keymap = vim.keymap
      local group = "dap_temp_keymaps"

      local function set_dap_keymaps()
        keymap.set("n", "<Down>", dap.step_over, { desc = "DAP Step Over", silent = true })
        keymap.set("n", "<Right>", dap.step_into, { desc = "DAP Step Into", silent = true })
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

      -- dap-view 的视图和终端窗口也设 winfixbuf，默认 uselast 跳转可能 E1513；
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

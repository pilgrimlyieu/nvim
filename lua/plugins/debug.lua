return {
  {
    "mfussenegger/nvim-dap",
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

      return opts
    end,
  },
}

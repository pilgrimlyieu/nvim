return {
  {
    "nvim-mini/mini.align",
    keys = {
      { "ga", mode = { "n", "v" }, desc = "Align" },
      { "gA", mode = { "n", "v" }, desc = "Align with preview" },
    },
    opts = {},
  },
  {
    "sevenc-nanashi/neov-ime.nvim",
    cond = not not vim.g.neovide,
    opts = function(_, opts)
      local enable_ime_events = {
        InsertEnter = true,
        InsertLeave = false,
        CmdlineEnter = true,
        CmdlineLeave = false,
        TermEnter = true,
        TermLeave = false,
      }

      local ime_locked_on = false

      local function set_ime(args)
        if ime_locked_on then
          return
        end
        vim.g.neovide_input_ime = enable_ime_events[args.event]
      end

      local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

      local events = {
        "InsertEnter",
        "InsertLeave",
        "CmdlineEnter",
        "CmdlineLeave",
        "TermEnter",
        "TermLeave",
      }

      for _, event in ipairs(events) do
        ---@type string|string[]
        local pattern = "*"
        if event:match("^Cmdline") then
          pattern = { "\\/", "\\?" } -- 仅匹配搜索模式
        end

        vim.api.nvim_create_autocmd(event, {
          group = ime_input,
          pattern = pattern,
          callback = set_ime,
        })
      end

      Snacks.toggle({
        name = "IME Lockon",
        get = function()
          return ime_locked_on
        end,
        set = function(state)
          ime_locked_on = state
          if ime_locked_on then
            vim.g.neovide_input_ime = true
          end
        end,
      }):map("<leader>uM")

      return opts
    end,
  },
}

---Project-local jj.nvim integration.
---
---This module keeps the Lazy plugin spec small and documents the local behavior
---that differs from jj.nvim defaults:
---  - `jj log` should not be limited to 20 entries unless a limit is explicit.
---  - `JJ Log All` must quote `all()` because jj.nvim runs commands via `sh -c`.
---  - Floating `q` / `<Esc>` should close the floating window, not only hide it.

local M = {}

---@alias ConfigJjMode string|string[]
---@alias ConfigJjCommandOpts
---| jj.cmd.log_opts
---| jj.cmd.new_opts
---| jj.cmd.diff_opts
---| jj.cmd.diff_history_opts
---| jj.cmd.bookmark
---| jj.cmd.push_opts
---| jj.cmd.open_pr_opts
---| jj.cmd.fetch_pr_opts
---| jj.cmd.split.opts
---| string
---| string[]
---| nil
---@alias ConfigJjOptsProvider ConfigJjCommandOpts|fun(): ConfigJjCommandOpts
---@alias ConfigJjDiffOpts jj.diff.current_opts|jj.diff.revision_opts|jj.diff.revisions_opts|jj.diff.diff_opts|nil

local log_defaults_patched = false
local floating_close_patched = false
local augroup = vim.api.nvim_create_augroup("config_jj", { clear = true })

local lazyvim_git_keys = {
  "<leader>gg",
  "<leader>gG",
  "<leader>gL",
  "<leader>gb",
  "<leader>gf",
  "<leader>gl",
  "<leader>gB",
  "<leader>gY",
}

---@return jj.cmd.log_opts
function M.log_opts()
  -- Empty raw flags force jj.nvim's builder to emit plain `jj log --no-pager`
  -- instead of merging in its default `--limit 20`.
  return { raw_flags = "" }
end

---@return jj.cmd.log_opts
function M.log_all_opts()
  return { raw_flags = "-r 'all()'" }
end

---@param opts ConfigJjOptsProvider
---@return ConfigJjCommandOpts
local function resolve_opts(opts)
  if type(opts) == "function" then
    return opts()
  end
  return opts
end

---@param method string
---@param opts? ConfigJjOptsProvider
---@return fun()
function M.cmd(method, opts)
  return function()
    require("jj.cmd")[method](resolve_opts(opts))
  end
end

---@param method string
---@param opts? ConfigJjDiffOpts
---@return fun()
function M.diff(method, opts)
  return function()
    require("jj.diff")[method](opts)
  end
end

---@param method string
---@return fun()
function M.picker(method)
  return function()
    require("jj.picker")[method]()
  end
end

---@param method string
---@return fun()
function M.annotate(method)
  return function()
    require("jj.annotate")[method]()
  end
end

---@return nil
function M.browse()
  return require("jj.browse").browse()
end

---@return nil
function M.which_key_help()
  require("which-key").show({ keys = "<leader>j", mode = "n" })
end

---@return nil
function M.buffer_key_help()
  local keys = vim.api.nvim_buf_get_keymap(0, "n")
  table.sort(keys, function(a, b)
    return (a.desc or "") < (b.desc or "")
  end)

  local max_key_width = 0
  local entries = {}
  for _, mapping in ipairs(keys) do
    if mapping.desc then
      max_key_width = math.max(max_key_width, vim.api.nvim_strwidth(mapping.lhs))
      entries[#entries + 1] = { key = mapping.lhs, desc = mapping.desc }
    end
  end

  local lines = {}
  local width = 0
  for _, entry in ipairs(entries) do
    local line = ("  %-" .. max_key_width .. "s   %s"):format(entry.key, entry.desc)
    width = math.max(width, vim.api.nvim_strwidth(line))
    lines[#lines + 1] = line
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  q / Esc   Close"
  width = math.max(width, vim.api.nvim_strwidth(lines[#lines]))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].swapfile = false

  local key_hl = vim.api.nvim_create_namespace("jj_key_help")
  for index, entry in ipairs(entries) do
    local key_start = 2
    local key_end = key_start + #entry.key
    local desc_start = 2 + max_key_width + 3
    vim.api.nvim_buf_set_extmark(buf, key_hl, index - 1, key_start, {
      end_col = key_end,
      hl_group = "WhichKey",
    })
    vim.api.nvim_buf_set_extmark(buf, key_hl, index - 1, desc_start, {
      end_col = #lines[index],
      hl_group = "WhichKeyDesc",
    })
  end
  vim.api.nvim_buf_set_extmark(buf, key_hl, #lines - 1, 2, {
    end_col = 9,
    hl_group = "WhichKey",
  })
  vim.api.nvim_buf_set_extmark(buf, key_hl, #lines - 1, 11, {
    end_col = #lines[#lines],
    hl_group = "WhichKeyDesc",
  })

  local win_width = math.min(math.max(width + 4, 36), math.floor(vim.o.columns * 0.8))
  local win_height = math.min(#lines, math.floor(vim.o.lines * 0.8))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = math.floor((vim.o.lines - win_height) / 2),
    col = math.floor((vim.o.columns - win_width) / 2),
    border = "rounded",
    style = "minimal",
    title = " JJ keymaps ",
    title_pos = "left",
  })

  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
end

local function delete_lazyvim_git_keymaps()
  for _, key in ipairs(lazyvim_git_keys) do
    pcall(vim.keymap.del, "n", key)
    pcall(vim.keymap.del, "x", key)
  end
end

---@param mode ConfigJjMode
---@param lhs string
---@param rhs string|function
---@param desc string
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

function M.install_keymaps()
  if not require("config.vcs").is_jj({ buf = 0 }) then
    return
  end

  delete_lazyvim_git_keymaps()

  map("n", "<leader>gg", M.cmd("status"), "JJ Status")
  map("n", "<leader>gG", M.cmd("log", M.log_opts), "JJ Log")
  map("n", "<leader>gl", M.cmd("log", M.log_opts), "JJ Log")
  map("n", "<leader>gL", M.cmd("log", M.log_all_opts), "JJ Log All")
  map("n", "<leader>gf", M.picker("file_history"), "JJ Current File History")
  map("n", "<leader>gb", M.annotate("line"), "JJ Annotate Line")
  map({ "n", "x" }, "<leader>gB", M.browse, "JJ Browse")

  map("n", "<leader>j?", M.which_key_help, "JJ Key Help")
  map("n", "<leader>jd", M.cmd("describe"), "JJ Describe")
  map("n", "<leader>jhd", M.diff("open_vdiff"), "JJ Diff This")
  map("n", "<leader>jhD", M.diff("open_hdiff"), "JJ Diff This Horizontal")
  map("n", "<leader>jhp", M.cmd("j", "diff"), "JJ Diff")
  map("n", "<leader>jl", M.cmd("log", M.log_opts), "JJ Log")
  map("n", "<leader>jL", M.cmd("log", M.log_all_opts), "JJ Log All")
  map("n", "<leader>jn", M.cmd("new", { show_log = true }), "JJ New")
  map("n", "<leader>je", M.cmd("edit"), "JJ Edit")
  map("n", "<leader>js", M.cmd("status"), "JJ Status")
  map("n", "<leader>jr", M.cmd("rebase"), "JJ Rebase")
  map("n", "<leader>jS", M.cmd("squash"), "JJ Squash")
  map("n", "<leader>ju", M.cmd("undo"), "JJ Undo")
  map("n", "<leader>jy", M.cmd("redo"), "JJ Redo")
  map("n", "<leader>ja", M.cmd("abandon"), "JJ Abandon")
  map("n", "<leader>jf", M.cmd("fetch"), "JJ Fetch")
  map("n", "<leader>jp", M.cmd("push"), "JJ Push")
  map("n", "<leader>jP", M.cmd("open_pr"), "JJ Open PR")
  map("n", "<leader>jb", M.cmd("bookmark_create"), "JJ Bookmark Create")
  map("n", "<leader>jB", M.cmd("bookmark_move"), "JJ Bookmark Move")
  map("n", "<leader>jA", M.annotate("file"), "JJ Annotate File")
end

function M.init()
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "LazyVimKeymaps",
    callback = function()
      vim.schedule(M.install_keymaps)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = augroup,
    callback = function(event)
      local bufnr = event.buf
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.b[bufnr].jj_keymaps_set then
          return
        end

        vim.keymap.set("n", "g?", M.buffer_key_help, {
          buffer = bufnr,
          desc = "JJ Buffer Key Help",
          nowait = true,
          silent = true,
        })
      end)
    end,
  })
end

---@return jj.Config
function M.opts()
  ---@type jj.Config
  local opts = {
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
  }
  return opts
end

local function disable_floating_hide_keymap()
  -- `hide = nil` inside M.opts() cannot disable jj.nvim's default because Lua
  -- omits nil table fields before jj.nvim deep-merges defaults. Clear the
  -- merged config after setup instead, while keeping M.opts() typed as jj.Config.
  ---@type jj.cmd.floating.keymaps?
  local floating_keymaps = require("jj.cmd").config.keymaps.floating
  if floating_keymaps then
    floating_keymaps.hide = nil
  end
end

---@param value unknown
---@return boolean
local function is_empty_table(value)
  return type(value) == "table" and next(value) == nil
end

---@param opts jj.cmd.log_opts
---@return string
local function build_log_raw_flags(opts)
  local flags = {}

  if opts.summary then
    flags[#flags + 1] = "--summary"
  end
  if opts.reversed then
    flags[#flags + 1] = "--reversed"
  end
  if opts.no_graph then
    flags[#flags + 1] = "--no-graph"
  end
  if opts.revisions then
    flags[#flags + 1] = "--revisions " .. vim.fn.shellescape(opts.revisions)
  end

  return table.concat(flags, " ")
end

function M.patch_log_defaults()
  if log_defaults_patched then
    return
  end

  local jj_cmd_module = require("jj.cmd")
  local jj_log_module = require("jj.cmd.log")
  local original_log = jj_log_module.log

  -- jj.nvim defaults to `limit = 20`. Treat absent limits as "show the full
  -- revset", while preserving callers that explicitly request a limit.
  ---@param opts? jj.cmd.log_opts
  local function log_without_default_limit(opts)
    if opts == nil or is_empty_table(opts) then
      opts = M.log_opts()
    elseif opts.limit == nil and opts.raw_flags == nil then
      opts = vim.tbl_extend("force", opts, { raw_flags = build_log_raw_flags(opts) })
    end
    return original_log(opts)
  end

  jj_log_module.log = log_without_default_limit
  jj_cmd_module.log = log_without_default_limit
  log_defaults_patched = true
end

---@param buf integer?
local function close_windows_for_buf(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

---@param buf integer?
local function delete_buf_closing_windows(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  close_windows_for_buf(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---@param chan integer?
local function close_chan(chan)
  if chan then
    pcall(vim.fn.chanclose, chan)
  end
end

---@param job_id integer?
local function stop_job(job_id)
  if job_id then
    pcall(vim.fn.jobstop, job_id)
  end
end

---@type table[]
local suspended_floating_buffers = {}

---@param cmd string|string[]
---@return string?
local function floating_subcmd(cmd)
  if type(cmd) == "table" then
    return cmd[2]
  end

  return vim.split(cmd, "%s+", { trimempty = true })[2]
end

---@param win integer?
---@return table?
local function floating_win_config(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return nil
  end

  return vim.api.nvim_win_get_config(win)
end

---@param config table?
---@return table
local function normalized_floating_config(config)
  local max_width = math.max(vim.o.columns - 2, 1)
  local max_height = math.max(vim.o.lines - 4, 1)
  local width = math.min((config and config.width) or math.floor(vim.o.columns * 0.95), max_width)
  local height = math.min((config and config.height) or math.floor(vim.o.lines * 0.9), max_height)

  config = vim.tbl_extend("force", {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    style = "minimal",
    title = " JJ ",
    title_pos = "center",
  }, config or {})

  config.width = math.min(config.width, max_width)
  config.height = math.min(config.height, max_height)
  config.row = math.max(math.min(config.row or 0, math.max(vim.o.lines - config.height - 1, 0)), 0)
  config.col = math.max(math.min(config.col or 0, math.max(vim.o.columns - config.width, 0)), 0)
  return config
end

---@param terminal jj.ui.terminal
---@return boolean
local function suspend_floating_buffer(terminal)
  local state = terminal.state
  local buf = state.floating_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].modifiable then
    return false
  end

  local win = vim.fn.bufwinid(buf)
  local entry = {
    buf = buf,
    cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or nil,
    floating_buf_cmd = state.floating_buf_cmd,
    state_buf = state.buf == buf,
    buf_cmd = state.buf_cmd,
    win_config = floating_win_config(win),
  }

  close_windows_for_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  suspended_floating_buffers[#suspended_floating_buffers + 1] = entry
  if state.buf == buf then
    state.buf = nil
    state.buf_cmd = nil
  end
  state.floating_buf = nil
  state.floating_buf_cmd = nil
  state.floating_chan = nil
  state.floating_job_id = nil
  return true
end

---@param terminal jj.ui.terminal
---@return boolean
local function restore_suspended_floating_buffer(terminal)
  while #suspended_floating_buffers > 0 do
    local entry = table.remove(suspended_floating_buffers)
    if entry.buf and vim.api.nvim_buf_is_valid(entry.buf) then
      local ok, win = pcall(
        vim.api.nvim_open_win,
        entry.buf,
        true,
        normalized_floating_config(entry.win_config)
      )
      if not ok then
        ok, win = pcall(vim.api.nvim_open_win, entry.buf, true, normalized_floating_config())
      end
      if ok then
        terminal.state.floating_buf = entry.buf
        terminal.state.floating_buf_cmd = entry.floating_buf_cmd
        terminal.state.floating_chan = nil
        terminal.state.floating_job_id = nil
        if entry.state_buf then
          terminal.state.buf = entry.buf
          terminal.state.buf_cmd = entry.buf_cmd
        end
        if entry.cursor and vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_set_cursor, win, entry.cursor)
        end
        return true
      end
    end
  end

  return false
end

local function clear_suspended_floating_buffers()
  for _, entry in ipairs(suspended_floating_buffers) do
    delete_buf_closing_windows(entry.buf)
  end
  suspended_floating_buffers = {}
end

function M.patch_floating_close()
  if floating_close_patched then
    return
  end

  local terminal = require("jj.ui.terminal")
  local original_run = terminal.run
  local original_run_floating = terminal.run_floating
  local original_run_tooltip = terminal.run_tooltip

  -- In floating mode the displayed buffer and the logical command buffer are
  -- easy to desync. Always close visible windows before wiping or replacing a
  -- jj.nvim buffer so Neovim does not leave a nameless scratch window behind.
  ---@param restore_previous? boolean
  local function close_floating_buffer(restore_previous)
    local state = terminal.state
    local buf = state.floating_buf

    close_chan(state.floating_chan)
    stop_job(state.floating_job_id)
    delete_buf_closing_windows(buf)

    if state.buf == buf then
      state.buf = nil
      state.buf_cmd = nil
    end
    state.floating_chan = nil
    state.floating_job_id = nil
    state.floating_buf = nil
    state.floating_buf_cmd = nil

    if restore_previous ~= false then
      restore_suspended_floating_buffer(terminal)
    end
  end

  terminal.close_floating_buffer = function()
    close_floating_buffer(true)
  end

  terminal.hide_floating_buffer = terminal.close_floating_buffer

  terminal.close_tooltip = function()
    local state = terminal.state
    local buf = state.tooltip_buf

    close_chan(state.tooltip_chan)
    stop_job(state.tooltip_job_id)
    if state.tooltip_close_autocmd then
      pcall(vim.api.nvim_del_autocmd, state.tooltip_close_autocmd)
    end
    delete_buf_closing_windows(buf)

    state.tooltip_chan = nil
    state.tooltip_job_id = nil
    state.tooltip_buf = nil
    state.tooltip_win = nil
    state.tooltip_close_autocmd = nil
  end

  terminal.close_terminal_buffer = function()
    local state = terminal.state

    if state.tooltip_buf then
      terminal.close_tooltip()
      return
    end

    if
      state.floating_buf
      and vim.api.nvim_buf_is_valid(state.floating_buf)
      and (state.buf == state.floating_buf or vim.api.nvim_get_current_buf() == state.floating_buf)
    then
      terminal.close_floating_buffer()
      return
    end

    local buf = state.buf
    close_chan(state.chan)
    stop_job(state.job_id)
    delete_buf_closing_windows(buf)

    if state.buf == buf then
      state.buf = nil
    end
    state.buf_cmd = nil
    state.chan = nil
    state.job_id = nil
  end

  terminal.run_floating = function(cmd, keymaps, float_opts)
    local subcmd = floating_subcmd(cmd)
    local opens_nested_detail = subcmd == "show" or subcmd == "diff"

    if terminal.state.floating_buf and opens_nested_detail then
      if terminal.state.tooltip_buf or terminal.state.tooltip_close_autocmd then
        terminal.close_tooltip()
      end
      if not suspend_floating_buffer(terminal) then
        close_floating_buffer(false)
      end
    elseif terminal.state.floating_buf then
      close_floating_buffer(false)
      clear_suspended_floating_buffers()
    end

    return original_run_floating(cmd, keymaps, float_opts)
  end

  terminal.run_tooltip = function(cmd, tool_opts)
    if terminal.state.tooltip_buf or terminal.state.tooltip_close_autocmd then
      terminal.close_tooltip()
    end
    return original_run_tooltip(cmd, tool_opts)
  end

  terminal.run = function(cmd, keymaps)
    local state = terminal.state
    if state.buf ~= state.floating_buf then
      delete_buf_closing_windows(state.buf)
    end
    return original_run(cmd, keymaps)
  end

  floating_close_patched = true
end

function M.setup()
  require("jj").setup(M.opts())
  disable_floating_hide_keymap()
  M.patch_log_defaults()
  M.patch_floating_close()
end

return M

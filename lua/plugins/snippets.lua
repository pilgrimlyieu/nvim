---LuaSnip configuration and migrated snippet keymaps.
---
---The old Vim setup used CapsLock as a terminal-level `<A-F12>` key.  The
---explicit CSI/F-key aliases below keep that workflow working across Vim and
---Neovim key decoding:
---
---  `<A-F12>`      / CapsLock             expand first, then jump, then step
---  `<F60>`        / CapsLock             Neovim's decoded name in some terms
---  `<C-A-F12>`    / Ctrl-CapsLock        force next tabstop
---  `<C-S-A-F12>`  / Ctrl-Shift-CapsLock  force previous tabstop
---  `<A-S-F12>`    / Shift-CapsLock       previous tabstop, then step back
---  Visual `<A-F12>` / CapsLock           capture selection for next snippet
---  `<C-S-A-F12>`  / Ctrl-Shift-CapsLock  list snippets in normal mode
---  `<A-,>`/`<A-.>`                         previous/next snippet choice
---  `<A-/>`                                 open a snippet-choice picker
---  `<A-1>`..`<A-9>`                        select numbered snippet choice
---
---The delimiter fallback matters for math-heavy editing because it lets the
---same key leave `()`, `{}`, `$...$`, and similar pairs when no snippet is
---active.

local snippet_root = vim.fn.stdpath("config") .. "/lua/snippets"
local choice_hint_ns = vim.api.nvim_create_namespace("config_luasnip_choice_hint")
local select_cut_keys =
  [[<Esc><cmd>lua require("luasnip.util.select").pre_yank("z")<Cr>gv"zs<cmd>lua require("luasnip.util.select").post_yank("z")<Cr>]]
local delimiters = {
  ["["] = true,
  ["]"] = true,
  ["{"] = true,
  ["}"] = true,
  ["("] = true,
  [")"] = true,
  ["$"] = true,
  ["&"] = true,
  ['"'] = true,
  ["'"] = true,
  ["<"] = true,
  [">"] = true,
  ["`"] = true,
}

---@alias ConfigSnippetMode string|string[]

---@class ConfigVirtTextChunk
---@field [1] string Text displayed in virtual text.
---@field [2] string Highlight group.

---@class ConfigLuaSnipActiveExtOpt
---@field virt_text? ConfigVirtTextChunk[]
---@field virt_text_pos? "eol"|"overlay"|"right_align"|"inline"
---@field hl_mode? "replace"|"combine"|"blend"
---@field priority? integer

---@class ConfigLuaSnipExtOpt
---@field active? ConfigLuaSnipActiveExtOpt

---@class ConfigLuaSnipExtOpts
---@field [integer] ConfigLuaSnipExtOpt Options keyed by LuaSnip node type id.

---@class ConfigLuaSnipOpts
---@field enable_autosnippets? boolean
---@field region_check_events? string|string[]
---@field delete_check_events? string|string[]
---@field ext_opts? ConfigLuaSnipExtOpts

---@class ConfigBlinkLuaSnipProviderOpts
---@field show_autosnippets? boolean
---@field use_show_condition? boolean

---@class ConfigBlinkSnippetProvider
---@field opts? ConfigBlinkLuaSnipProviderOpts

---@class ConfigBlinkSnippetProviders
---@field snippets? ConfigBlinkSnippetProvider
---@field [string] ConfigBlinkSnippetProvider

---@class ConfigBlinkSources
---@field providers? ConfigBlinkSnippetProviders

---@class ConfigBlinkCmpOpts
---@field sources? ConfigBlinkSources

---@class ConfigLazyKeysSpec
---@field [1] string
---@field [2] fun()|string
---@field mode ConfigSnippetMode
---@field desc string

---Return the current buffer line.
---@return string
local function current_line()
  return vim.api.nvim_get_current_line()
end

---Return whether a character should be stepped over by the snippet key.
---@param char string
---@return boolean
local function is_delimiter(char)
  return delimiters[char] == true
end

---Move one character across a delimiter when no snippet jump is available.
---@param direction 1|-1
local function step_over_delimiter(direction)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local line = current_line()

  if direction > 0 then
    local next_char = line:sub(col + 1, col + 1)
    if is_delimiter(next_char) then
      vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    end
  else
    local prev_char = line:sub(col, col)
    if is_delimiter(prev_char) then
      vim.api.nvim_win_set_cursor(0, { row, math.max(col - 1, 0) })
    end
  end
end

---Close blink.cmp before a snippet action changes the buffer.
local function hide_completion_menu()
  local blink = package.loaded["blink.cmp"]
  if blink and blink.is_visible() then
    blink.hide()
  end
end

---Expand a snippet, jump forward, or step over a delimiter.
local function expand_or_jump_or_step()
  local luasnip = require("luasnip")

  hide_completion_menu()

  -- Autosnippets normally expand on InsertCharPre.  Completion popups or manual
  -- retrying can leave the trigger text in the buffer, so the UltiSnips-style
  -- trigger key checks autosnippets before falling back to normal expansion.
  local changedtick = vim.api.nvim_buf_get_changedtick(0)
  luasnip.expand_auto()
  if vim.api.nvim_buf_get_changedtick(0) ~= changedtick then
    return
  end

  if luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  else
    step_over_delimiter(1)
  end
end

---Jump to the next LuaSnip tabstop when one exists.
local function jump_forward()
  local luasnip = require("luasnip")

  hide_completion_menu()

  if luasnip.jumpable(1) then
    luasnip.jump(1)
  end
end

---Jump to the previous LuaSnip tabstop when one exists.
local function jump_backward()
  local luasnip = require("luasnip")

  hide_completion_menu()

  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  end
end

---Jump backward, or step left over a delimiter when no jump exists.
local function jump_back_or_step()
  local luasnip = require("luasnip")

  hide_completion_menu()

  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  else
    step_over_delimiter(-1)
  end
end

---Cycle the active choice node in the requested direction.
---@param direction 1|-1
local function change_choice(direction)
  local luasnip = require("luasnip")

  hide_completion_menu()

  if luasnip.choice_active() then
    luasnip.change_choice(direction)
  end
end

---Open LuaSnip's picker for the active choice node.
local function select_choice()
  local luasnip = require("luasnip")

  hide_completion_menu()

  if luasnip.choice_active() then
    require("luasnip.extras.select_choice")()
  end
end

---Select a numbered option from the active choice node.
---@param index integer
local function select_choice_index(index)
  local luasnip = require("luasnip")

  hide_completion_menu()

  if not luasnip.choice_active() then
    return
  end

  local choices = luasnip.get_current_choices()
  if index > #choices then
    return
  end

  luasnip.set_choice(index)
end

---Open LuaSnip's snippet list window.
local function open_snippet_list()
  require("luasnip.extras.snippet_list").open()
end

---Open LuaSnip's snippet-file editor helper.
local function edit_snippet_files()
  require("luasnip.loaders").edit_snippet_files()
end

---Register project Lua snippets through LuaSnip's lazy loader.
local function load_project_snippets()
  require("luasnip.loaders.from_lua").lazy_load({
    paths = snippet_root,
  })
end

---Reload group switches and project snippets in the current session.
local function reload_snippets()
  local luasnip = require("luasnip")

  require("config.snippets.groups").refresh()
  luasnip.cleanup()
  load_project_snippets()

  vim.notify("LuaSnip snippets reloaded", vim.log.levels.INFO, { title = "LuaSnip" })
end

---Clear the custom choice hint virtual text.
---@param bufnr integer?
local function clear_choice_hint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, choice_hint_ns, 0, -1)
  end
end

---Compress a choice preview to one short line.
---@param value string
---@return string
local function compact_choice_label(value)
  local label = (value:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))

  if label == "" then
    label = "<empty>"
  end

  if #label > 18 then
    label = label:sub(1, 15) .. "..."
  end

  return label
end

---Return the 1-based index of the currently active choice.
---@return integer?
local function active_choice_index()
  local ok, session = pcall(require, "luasnip.session")
  if not ok then
    return nil
  end

  local active_choice = session.active_choice_nodes[vim.api.nvim_get_current_buf()]
  if not active_choice or not active_choice.choices then
    return nil
  end

  for index, choice in ipairs(active_choice.choices) do
    if choice == active_choice.active_choice then
      return index
    end
  end

  return nil
end

---Render compact numbered choice hints at the end of the current line.
local function update_choice_hint()
  local ok, luasnip = pcall(require, "luasnip")
  if not ok then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  clear_choice_hint(bufnr)

  if not luasnip.choice_active() then
    return
  end

  local ok_choices, choices = pcall(luasnip.get_current_choices)
  if not ok_choices or not choices or #choices == 0 then
    return
  end

  local current = active_choice_index()
  local parts = {}
  for index, choice in ipairs(choices) do
    if index > 9 then
      parts[#parts + 1] = "..."
      break
    end

    local label = ("%d:%s"):format(index, compact_choice_label(choice))
    if index == current then
      label = "[" .. label .. "]"
    end
    parts[#parts + 1] = label
  end

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_set_extmark(bufnr, choice_hint_ns, row, 0, {
    virt_text = { { "◆ " .. table.concat(parts, " "), "DiagnosticVirtualTextWarn" } },
    virt_text_pos = "eol",
    hl_mode = "combine",
    priority = 200,
  })
end

---Install autocmds that maintain the custom choice hint overlay.
local function setup_choice_hint()
  local group = vim.api.nvim_create_augroup("config_luasnip_choice_hint", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LuasnipChoiceNodeEnter", "LuasnipChangeChoice" },
    callback = function()
      vim.schedule(update_choice_hint)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LuasnipChoiceNodeLeave", "LuasnipCleanup" },
    callback = function()
      clear_choice_hint()
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMovedI", "CursorMoved" }, {
    group = group,
    callback = function()
      if package.loaded["luasnip"] and require("luasnip").choice_active() then
        update_choice_hint()
      else
        clear_choice_hint()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    callback = function(event)
      clear_choice_hint(event.buf)
    end,
  })
end

---Build LuaSnip `ext_opts` for one active node marker.
---@param label string
---@param hl_group string
---@return ConfigLuaSnipExtOpt
local function active_node_hint(label, hl_group)
  return {
    active = {
      virt_text = { { label, hl_group } },
      virt_text_pos = "eol",
      hl_mode = "combine",
      priority = 120,
    },
  }
end

---Configure active-node virtual text without duplicating dynamic-node markers.
---@param opts ConfigLuaSnipOpts
local function configure_node_hints(opts)
  local types = require("luasnip.util.types")

  -- Keep this intentionally quiet: `visual_insert()` is a dynamic node that
  -- contains an insert node, so marking dynamic nodes would duplicate symbols.
  -- Choice nodes use the compact option list from setup_choice_hint().
  opts.ext_opts = vim.tbl_deep_extend("force", opts.ext_opts or {}, {
    [types.insertNode] = active_node_hint("●", "DiagnosticVirtualTextInfo"),
  })
end

---Build one Lazy.nvim key spec for snippet mappings.
---@param lhs string
---@param rhs function|string
---@param mode ConfigSnippetMode
---@param desc string
---@return ConfigLazyKeysSpec
local function key(lhs, rhs, mode, desc)
  return {
    lhs,
    rhs,
    mode = mode,
    desc = desc,
  }
end

local snippet_keys = {
  key("<A-F12>", expand_or_jump_or_step, "i", "Expand or Jump Snippet"),
  key("<F60>", expand_or_jump_or_step, "i", "Expand or Jump Snippet"),
  key("<Esc>[24;3~", expand_or_jump_or_step, "i", "Expand or Jump Snippet"),

  key("<A-F12>", select_cut_keys, "x", "Capture Snippet Selection"),
  key("<F60>", select_cut_keys, "x", "Capture Snippet Selection"),
  key("<Esc>[24;3~", select_cut_keys, "x", "Capture Snippet Selection"),

  key("<A-F12>", jump_forward, "s", "Jump Snippet Forward"),
  key("<F60>", jump_forward, "s", "Jump Snippet Forward"),
  key("<Esc>[24;3~", jump_forward, "s", "Jump Snippet Forward"),

  key("<C-A-F12>", jump_forward, { "i", "s" }, "Jump Snippet Forward"),
  key("<Esc>[24;7~", jump_forward, { "i", "s" }, "Jump Snippet Forward"),

  key("<C-S-A-F12>", jump_backward, { "i", "s" }, "Jump Snippet Backward"),
  key("<C-A-S-F12>", jump_backward, { "i", "s" }, "Jump Snippet Backward"),
  key("<Esc>[24;8~", jump_backward, { "i", "s" }, "Jump Snippet Backward"),

  key("<A-S-F12>", jump_back_or_step, { "i", "s" }, "Jump Snippet Backward or Step"),
  key("<Esc>[24;4~", jump_back_or_step, { "i", "s" }, "Jump Snippet Backward or Step"),

  key("<A-/>", select_choice, { "i", "s" }, "Select Snippet Choice"),
  key("<A-.>", function()
    change_choice(1)
  end, { "i", "s" }, "Next Snippet Choice"),
  key("<A-,>", function()
    change_choice(-1)
  end, { "i", "s" }, "Previous Snippet Choice"),

  key("<leader>uS", open_snippet_list, "n", "List Snippets"),
  key("<C-S-A-F12>", open_snippet_list, "n", "List Snippets"),
  key("<C-A-S-F12>", open_snippet_list, "n", "List Snippets"),
  key("<Esc>[24;8~", open_snippet_list, "n", "List Snippets"),
  key("<C-S-A-d>", reload_snippets, "n", "Reload Snippets"),
  key("<leader>ue", edit_snippet_files, "n", "Edit Snippets"),
}

for index = 1, 9 do
  snippet_keys[#snippet_keys + 1] = key(("<A-%d>"):format(index), function()
    select_choice_index(index)
  end, { "i", "s" }, ("Select Snippet Choice %d"):format(index))
end

return {
  {
    "rafamadriz/friendly-snippets",
    enabled = false,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    ---@param opts ConfigBlinkCmpOpts
    ---@return ConfigBlinkCmpOpts
    opts = function(_, opts)
      local sources = opts.sources or {}
      opts.sources = sources

      local providers = sources.providers or {}
      sources.providers = providers

      local snippets_provider = providers.snippets or {}
      providers.snippets = snippets_provider

      snippets_provider.opts = snippets_provider.opts or {}

      -- Autosnippets such as `lm`, `dm`, and `1/` should feel like UltiSnips
      -- `A` triggers: they expand while typing, not as noisy completion rows.
      local luasnip_opts = snippets_provider.opts
      luasnip_opts.show_autosnippets = false
      luasnip_opts.use_show_condition = true
      return opts
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    lazy = false,
    ---@param opts ConfigLuaSnipOpts
    ---@return ConfigLuaSnipOpts
    opts = function(_, opts)
      opts.enable_autosnippets = true
      opts.region_check_events = "CursorMoved,CursorHold,InsertEnter"
      opts.delete_check_events = opts.delete_check_events or "TextChanged"
      configure_node_hints(opts)
      return opts
    end,
    ---@param opts ConfigLuaSnipOpts
    config = function(_, opts)
      local luasnip = require("luasnip")
      luasnip.setup(opts)

      load_project_snippets()
      setup_choice_hint()
    end,
    keys = snippet_keys,
  },
}

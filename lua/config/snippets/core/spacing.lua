---Opt-in prose boundary spacing. No listeners exist while no boundary is pending.
local M = {}

local ls = require("luasnip")
local events = require("luasnip.util.events")
local feedkeys = require("luasnip.util.feedkeys")

local text = require("config.snippets.core.text")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local first_char = text.first
local is_prose = text.is_prose
local last_char = text.last

local group = vim.api.nvim_create_augroup("SnippetSpacing", { clear = true })
local ns = vim.api.nvim_create_namespace("SnippetSpacing")
local pending = {}

---@class SnipSpacing
---@field before? boolean
---@field after? boolean

---Cancel pending one-shot spacing autocmds for a buffer.
---@param buf integer
local function cancel(buf)
  local state = pending[buf]
  if not state then
    return
  end
  pending[buf] = nil

  for _, id in ipairs(state.events) do
    pcall(vim.api.nvim_del_autocmd, id)
  end

  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_del_extmark(buf, ns, state.mark)
  end
end

---False opts out; omitted fields use the prose default (both boundaries).
---@param policy? false|SnipSpacing
---@return SnipSpacing
local function resolve_policy(policy)
  if policy == false then
    return { before = false, after = false }
  end
  return {
    before = not policy or policy.before ~= false,
    after = not policy or policy.after ~= false,
  }
end

---Check if the cursor is at the pending boundary for a buffer.
---@param buf integer
---@param state table
---@return boolean
local function at_boundary(buf, state)
  if vim.api.nvim_get_current_buf() ~= buf or vim.api.nvim_buf_get_changedtick(buf) ~= state.tick then
    return false
  end

  local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, state.mark, {})
  local cursor = vim.api.nvim_win_get_cursor(0)
  return #pos == 2 and cursor[1] == pos[1] + 1 and cursor[2] == pos[2]
end

---Arm autocmds to insert a space at the pending boundary if the next character is prose.
---@param buf integer
---@param pos integer[] 0-indexed row, column
---@param tick integer
local function arm(buf, pos, tick)
  cancel(buf)

  if vim.api.nvim_get_current_buf() ~= buf or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  if cursor[1] ~= pos[1] + 1 or cursor[2] ~= pos[2] or vim.fn.mode():sub(1, 1) ~= "i" then
    return
  end

  local line = vim.api.nvim_buf_get_lines(buf, pos[1], pos[1] + 1, false)[1]
  local right = first_char(line:sub(pos[2] + 1))

  if is_prose(right) then
    -- Join the formula's undo block and keep further typing after its separator.
    pcall(vim.cmd.undojoin)
    vim.api.nvim_buf_set_text(buf, pos[1], pos[2], pos[1], pos[2], { " " })
    vim.api.nvim_win_set_cursor(0, { pos[1] + 1, pos[2] + 1 })
    return
  end

  local state = {
    mark = vim.api.nvim_buf_set_extmark(buf, ns, pos[1], pos[2], {
      right_gravity = false,
    }),
    tick = tick,
    events = {},
  }
  pending[buf] = state

  local function on(event, callback)
    state.events[#state.events + 1] = vim.api.nvim_create_autocmd(event, {
      group = group,
      buffer = buf,
      callback = callback,
    })
  end

  on("InsertCharPre", function()
    local valid = at_boundary(buf, state)
    cancel(buf)
    if valid and is_prose(vim.v.char) then
      vim.v.char = " " .. vim.v.char
    end
  end)

  on({ "InsertLeave", "BufLeave", "BufWipeout" }, function()
    cancel(buf)
  end)

  on({ "CursorMovedI", "TextChangedI", "TextChangedP" }, function()
    if not at_boundary(buf, state) then
      cancel(buf)
    end
  end)
end

---Attach to the final node, not snippet leave (which also runs on backward exit).
---@return LuaSnip.Node
local function exit_node()
  return i(0, nil, {
    node_callbacks = {
      [events.enter] = function(node)
        if node._prose_spacing_done then
          return
        end
        node._prose_spacing_done = true
        local buf = vim.api.nvim_get_current_buf()
        local pos = node.mark:pos_begin_raw()
        local tick = vim.api.nvim_buf_get_changedtick(buf)
        -- LuaSnip moves to $0 using queued keys; arm only after that move completes.
        feedkeys.enqueue_action(function()
          arm(buf, pos, tick)
        end)
      end,
    },
  })
end

---Build a snippet with independently optional before/after prose separators.
---Consumes a fresh body list: it adds a leading node and the sole final i(0).
---The pre-expand hook reads the actual insertion point, including direct expansion
---and dot-repeat. It never edits the buffer; previews do not read the current buffer.
---@param context SnipContext
---@param body LuaSnip.Node[] No final i(0); this factory owns the exit node.
---@param config? false|SnipSpacing Omitted fields default to true.
---@return LuaSnip.Snippet
function M.snippet(context, body, config)
  local policy = resolve_policy(config)
  local callbacks = {}
  if policy.before then
    table.insert(
      body,
      1,
      f(function(_, parent)
        return rawget(parent.snippet.env, "SNIP_SPACE_BEFORE") or ""
      end)
    )
    callbacks[-1] = {
      [events.pre_expand] = function(_, event)
        local row, col = unpack(event.expand_pos)
        local before = vim.api.nvim_buf_get_text(0, row, math.max(0, col - 4), row, col, {})[1]
        local char = last_char(before)
        local needs_space = is_prose(char) or char:match("^[,.;:!?%)%]%}]$") ~= nil
        return { env_override = { SNIP_SPACE_BEFORE = needs_space and " " or "" } }
      end,
    }
  end

  if policy.after then
    body[#body + 1] = exit_node()
  end
  return s(context, body, { callbacks = callbacks })
end

---Clean up all pending one-shot spacing autocmds for all buffers.
function M.cleanup()
  for buf in pairs(pending) do
    cancel(buf)
  end
end

return M

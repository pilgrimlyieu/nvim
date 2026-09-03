---Short math inserted from prose: bodies, triggers and boundary spacing.
local ls = require("luasnip")
local conditions = require("config.snippets.conditions")
local triggers = require("config.snippets.triggers")
local util = require("config.snippets.util")
local events = require("luasnip.util.events")
local M = {}

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

---@type table<integer, { insert_char_pre?: integer, insert_leave?: integer }>
local pending_space_autocmds = {}
local spacing_group = vim.api.nvim_create_augroup("SnippetSpacing", { clear = true })

local punctuation = {
  [""] = true,
  [" "] = true,
  ["，"] = true,
  ["。"] = true,
  ["；"] = true,
  ["："] = true,
  ["「"] = true,
  ["」"] = true,
  ["『"] = true,
  ["』"] = true,
  ["《"] = true,
  ["》"] = true,
  ["'"] = true,
  ["‘"] = true,
  ['"'] = true,
  ["【"] = true,
  ["】"] = true,
  ["["] = true,
  ["]"] = true,
  ["（"] = true,
  ["）"] = true,
  ["("] = true,
  [")"] = true,
  ["{"] = true,
  ["}"] = true,
  ["<"] = true,
  [">"] = true,
  ["、"] = true,
  ["-"] = true,
  ["*"] = true,
  ["！"] = true,
  ["!"] = true,
  ["？"] = true,
  ["?"] = true,
}

---Return whether a codepoint is a Han/CJK ideograph used as prose text.
---@param codepoint integer
---@return boolean
local function is_cjk_ideograph(codepoint)
  return (codepoint >= 0x3400 and codepoint <= 0x4DBF)
    or (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
    or (codepoint >= 0xF900 and codepoint <= 0xFAFF)
    or (codepoint >= 0x20000 and codepoint <= 0x2A6DF)
    or (codepoint >= 0x2A700 and codepoint <= 0x2B73F)
    or (codepoint >= 0x2B740 and codepoint <= 0x2B81F)
    or (codepoint >= 0x2B820 and codepoint <= 0x2CEAF)
    or (codepoint >= 0x2CEB0 and codepoint <= 0x2EBEF)
    or (codepoint >= 0x30000 and codepoint <= 0x3134F)
end

---Return the first UTF-8 character of a string.
---@param text string
---@return string
local function first_char(text)
  return vim.fn.strcharpart(text, 0, 1)
end

---Return the last UTF-8 character of a string, or empty string when absent.
---@param text string
---@return string
local function last_char(text)
  local length = vim.fn.strchars(text)
  if length == 0 then
    return ""
  end
  return vim.fn.strcharpart(text, length - 1, 1)
end

---Return the UTF-8 character immediately before the cursor.
---@return string
local function char_before_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  return last_char(line:sub(1, cursor[2]))
end

---Cancel pending one-shot spacing autocmds for a buffer.
---@param bufnr integer
local function clear_pending_space_autocmds(bufnr)
  local pending = pending_space_autocmds[bufnr]
  if not pending then
    return
  end

  pending_space_autocmds[bufnr] = nil
  for _, autocmd_id in pairs(pending) do
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
  end
end

---Return whether a typed character should receive automatic leading space.
---@param char string
---@return boolean
local function is_text_start_char(char)
  if char == "" then
    return false
  end

  local head = first_char(char)
  local codepoint = vim.fn.char2nr(head)
  if (codepoint >= 0x41 and codepoint <= 0x5A) or (codepoint >= 0x61 and codepoint <= 0x7A) then
    return true
  end

  return is_cjk_ideograph(codepoint)
end

---Queue a one-shot space before the next typed ASCII letter or Han character.
---
---This is useful for compact inline wrappers like `$...$`: after leaving the
---snippet, typing `a` or `中文` turns `$x$a` / `$x$中` into `$x$ a` / `$x$ 中`.
---The callback is cancelled on `InsertLeave` so it cannot surprise a later edit.
local function queue_space_before_next_text_char()
  local bufnr = vim.api.nvim_get_current_buf()
  clear_pending_space_autocmds(bufnr)

  local pending = {}
  pending_space_autocmds[bufnr] = pending

  pending.insert_char_pre = vim.api.nvim_create_autocmd("InsertCharPre", {
    group = spacing_group,
    buffer = bufnr,
    once = true,
    callback = function()
      pending_space_autocmds[bufnr] = nil
      if pending.insert_leave then
        pcall(vim.api.nvim_del_autocmd, pending.insert_leave)
      end

      local before = char_before_cursor()
      if is_text_start_char(vim.v.char) and before ~= "" and not before:match("^%s$") then
        vim.v.char = " " .. vim.v.char
      end
    end,
  })

  pending.insert_leave = vim.api.nvim_create_autocmd("InsertLeave", {
    group = spacing_group,
    buffer = bufnr,
    once = true,
    callback = function()
      pending_space_autocmds[bufnr] = nil
      if pending.insert_char_pre then
        pcall(vim.api.nvim_del_autocmd, pending.insert_char_pre)
      end
    end,
  })
end

---Preserve the prefix captured by the prose trigger engines.
local function prefix_node()
  return f(function(_, snip)
    local prefix = snip.captures[1] or ""
    return prefix .. (punctuation[prefix] and "" or " ")
  end)
end

---Body for manual wrappers using short_math_word_engine.
---@param left string
---@param right string
---@return SnipNode[]
function M.body(left, right)
  return { prefix_node(), t(left), util.visual_insert(1), t(right), i(0) }
end

---Body for fixed symbols using short_math_word_engine.
---@param value string
---@return SnipNode[]
function M.fixed_body(value)
  return { prefix_node(), t(value), i(0) }
end

---Expand lm in prose and space the next typed word after leaving math.
---@param left string
---@param right string
---@return SnipNode
function M.inline(left, right)
  return s(
    conditions.with_condition({
      trig = "lm",
      trigEngine = triggers.short_math_word_engine,
      wordTrig = false,
      name = "inline math",
      snippetType = "autosnippet",
    }, conditions.text),
    M.body(left, right),
    { callbacks = { [-1] = { [events.leave] = queue_space_before_next_text_char } } }
  )
end

---Wrap the token before ,, or ，，, preserving its prose prefix.
---@param left string
---@param right string
---@return SnipNode
function M.postfix(left, right)
  return s(
    conditions.with_condition({
      trig = ",,",
      trigEngine = triggers.inline_math_postfix_engine,
      wordTrig = false,
      name = "inline captured math",
      snippetType = "autosnippet",
    }, conditions.text),
    { prefix_node(), t(left), util.capture(2), t(right), i(0) }
  )
end

return M

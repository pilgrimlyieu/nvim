---Small helpers for LuaSnip snippet builder modules.
---
---These functions are deliberately boring: they keep the filetype/theme modules
---focused on snippets while avoiding repeated constructor boilerplate.

local M = {}
local ls = require("luasnip")
local condition_objects = require("luasnip.extras.conditions")
local expand_conditions = require("luasnip.extras.conditions.expand")
local events = require("luasnip.util.events")

local d = ls.dynamic_node
local f = ls.function_node
local i = ls.insert_node
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

---@type SnipPendingSpaceAutocmdByBuffer
local pending_space_autocmds = {}
local unescaped_word_engine

---Return whether completion is editing the first non-blank token of a line.
---
---LuaSnip's built-in `expand.line_begin` needs the matched trigger, but
---`show_condition` only receives `line_to_cursor`: the current line from its
---start through the cursor, including the partially typed trigger and excluding
---the rest of the buffer.  This helper is therefore only a completion-menu
---filter; actual expansion still uses LuaSnip's built-in condition.
---@param line_to_cursor? string
---@return boolean
local function line_begin_show(line_to_cursor)
  return (line_to_cursor or ""):match("^%s*%S*$") ~= nil
end

---Return the display column where the matched trigger starts.
---@param line_to_cursor string
---@param matched_trigger string
---@return integer
local function trigger_start_column(line_to_cursor, matched_trigger)
  return vim.fn.strdisplaywidth(line_to_cursor) - vim.fn.strdisplaywidth(matched_trigger)
end

---Return whether completion is editing a first token at an exact display column.
---
---LuaSnip has no built-in show-side equivalent for old `snip.column` context.
---The expansion side below still checks the real matched trigger start column.
---@param line_to_cursor? string
---@param column integer
---@return boolean
local function trigger_column_show(line_to_cursor, column)
  local text = line_to_cursor or ""
  local prefix, token = text:match("^(%s*)(%S*)$")
  return prefix ~= nil and token ~= "" and vim.fn.strdisplaywidth(prefix) == column
end

---Wrap a function as a LuaSnip condition object; pass existing objects through.
---
---All condition combinators below go through this adapter, so filetype modules
---can pass either raw predicates or LuaSnip condition objects without rebuilding
---their own boolean composition logic.
---@param value SnipConditionLike
---@return SnipConditionObject
local function condition_object(value)
  if type(value) == "table" then
    return value
  end
  return condition_objects.make_condition(value)
end

---Load the custom word trigger engine only when a word autosnippet is built.
local function get_unescaped_word_engine()
  if not unescaped_word_engine then
    unescaped_word_engine = require("config.snippets.triggers").unescaped_word_engine
  end
  return unescaped_word_engine
end

---Return the preserved prose prefix for short inline-math snippets.
---@return SnipNode
function M.short_math_prefix_node()
  return f(function(_, snip)
    return require("config.snippets.triggers").short_math_prefix(snip.captures[1] or "")
  end)
end

---Build the common short-math wrapper body: prose prefix, wrapper, final stop.
---@param left string
---@param right string
---@return SnipNode[]
function M.short_math_body(left, right)
  return { M.short_math_prefix_node(), t(left), M.visual_insert(1), t(right), i(0) }
end

---Build a short-math body whose math payload is fixed text.
---@param value string
---@return SnipNode[]
function M.fixed_short_math_body(value)
  return { M.short_math_prefix_node(), t(value), i(0) }
end

---Build a short-math body whose payload comes from a trigger capture.
---@param left string
---@param capture_index integer
---@param right string
---@return SnipNode[]
function M.captured_short_math_body(left, capture_index, right)
  return { M.short_math_prefix_node(), t(left), M.capture(capture_index), t(right), i(0) }
end

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

---Return whether a string or line list contains any text.
---@param value string|string[]?
---@return boolean
local function has_text(value)
  if type(value) == "string" then
    return value ~= ""
  end

  if type(value) == "table" then
    return #value > 1 or (value[1] ~= nil and value[1] ~= "")
  end

  return false
end

---Collapse one-line selections to a string; keep multi-line selections as lines.
---@param value string|string[]?
---@return string|string[]
local function normalize_insert_text(value)
  if type(value) == "table" then
    if #value == 1 then
      return value[1] or ""
    end
    return value
  end

  return value or ""
end

---Find the LuaSnip environment from a snippet or nested snippet node.
---@param snip SnipSnippet
---@return SnipSnippetEnv
local function snippet_env(snip)
  local seen = {}
  ---@type SnipSnippet?
  local node = snip
  while type(node) == "table" and not seen[node] do
    seen[node] = true
    if node.env then
      return node.env
    end
    node = node.snippet or node.parent
  end

  return {}
end

---Return whether a typed character should receive automatic leading space.
---@param char string
---@return boolean
function M.is_text_start_char(char)
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
function M.queue_space_before_next_text_char()
  local bufnr = vim.api.nvim_get_current_buf()
  clear_pending_space_autocmds(bufnr)

  local pending = {}
  pending_space_autocmds[bufnr] = pending

  pending.insert_char_pre = vim.api.nvim_create_autocmd("InsertCharPre", {
    buffer = bufnr,
    once = true,
    callback = function()
      pending_space_autocmds[bufnr] = nil
      if pending.insert_leave then
        pcall(vim.api.nvim_del_autocmd, pending.insert_leave)
      end

      local before = char_before_cursor()
      if M.is_text_start_char(vim.v.char) and before ~= "" and not before:match("^%s$") then
        vim.v.char = " " .. vim.v.char
      end
    end,
  })

  pending.insert_leave = vim.api.nvim_create_autocmd("InsertLeave", {
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

---Return LuaSnip callbacks that queue conditional spacing after snippet exit.
---@return SnipEventCallbacks
function M.space_before_next_text_char_callbacks()
  return {
    [-1] = {
      [events.leave] = function()
        M.queue_space_before_next_text_char()
      end,
    },
  }
end

---Return a LuaSnip opts table for conditional post-snippet spacing.
---@return SnipOpts
function M.space_before_next_text_char_opts()
  return {
    callbacks = M.space_before_next_text_char_callbacks(),
  }
end

---Test hook: clear pending spacing callbacks for the current buffer.
function M._clear_pending_space_autocmds()
  clear_pending_space_autocmds(vim.api.nvim_get_current_buf())
end

---Return the last LuaSnip visual selection as lines, with an optional fallback.
---@param snip SnipSnippet
---@param default? string|string[]
---@return string[]
function M.selected_lines(snip, default)
  local env = snippet_env(snip)
  local selected = env.LS_SELECT_RAW or env.TM_SELECTED_TEXT

  if has_text(selected) then
    if type(selected) == "table" then
      return selected
    end
    return vim.split(selected, "\n", { plain = true })
  end

  if type(default) == "table" then
    return default
  end

  if type(default) == "string" and default ~= "" then
    return vim.split(default, "\n", { plain = true })
  end

  return { "" }
end

---Return the last visual selection in the shape expected by an insert node.
---@param snip SnipSnippet
---@param default? string|string[]
---@return string|string[]
function M.selected_text(snip, default)
  return normalize_insert_text(M.selected_lines(snip, default))
end

---Create an editable node seeded from the last captured visual selection.
---
---Use this instead of directly translating UltiSnips' visual placeholder. The selection
---is populated by LuaSnip's visual-mode selection key and falls back to `default`
---for ordinary non-visual expansion.
---@param index integer
---@param default? string|string[]
---@return SnipNode
function M.visual_insert(index, default)
  return d(index, function(_, snip)
    return sn(nil, { i(1, M.selected_text(snip, default)) })
  end)
end

---Create an editable node from a transformed visual selection.
---
---This replaces legacy UltiSnips/TextMate replacement syntax with explicit Lua
---line transforms.
---@param index integer
---@param transform fun(lines: string[], snip: SnipSnippet): string|string[]
---@param default? string|string[]
---@return SnipNode
function M.visual_transform_insert(index, transform, default)
  return d(index, function(_, snip)
    return sn(nil, { i(1, normalize_insert_text(transform(M.selected_lines(snip, default), snip))) })
  end)
end

---Attach a shared expansion/show condition to a freshly-created snippet context.
---
---The context table is always local to a snippet constructor, so mutating it is
---cheaper and clearer than allocating another table through `vim.tbl_extend`.
---@param context SnipContext
---@param condition SnipCondition
---@return SnipContext context
function M.with_condition(context, condition)
  context.condition = condition.condition
  context.show_condition = condition.show_condition
  return context
end

---Return a condition pair that always passes.
---@return SnipCondition
function M.always_condition()
  local always = condition_objects.make_condition(function()
    return true
  end)

  return {
    condition = always,
    show_condition = always,
  }
end

---Return the logical AND of condition pairs using LuaSnip condition objects.
---@param ... SnipCondition
---@return SnipCondition
function M.and_conditions(...)
  local conditions = { ... }
  local expansion = condition_object(conditions[1].condition)
  local show = condition_object(conditions[1].show_condition)

  for index = 2, #conditions do
    expansion = expansion * condition_object(conditions[index].condition)
    show = show * condition_object(conditions[index].show_condition)
  end

  return { condition = expansion, show_condition = show }
end

---Return the logical OR of condition pairs using LuaSnip condition objects.
---@param ... SnipCondition
---@return SnipCondition
function M.or_conditions(...)
  local conditions = { ... }
  local expansion = condition_object(conditions[1].condition)
  local show = condition_object(conditions[1].show_condition)

  for index = 2, #conditions do
    expansion = expansion + condition_object(conditions[index].condition)
    show = show + condition_object(conditions[index].show_condition)
  end

  return { condition = expansion, show_condition = show }
end

---Add UltiSnips-style `b` line-begin behavior to a condition.
---
---Expansion delegates to LuaSnip's built-in `expand.line_begin`, so custom
---trigger engines and pattern triggers use the actual matched trigger.  The
---show side uses only a conservative completion filter because LuaSnip does not
---provide a `show.line_begin` condition.  Both sides are still LuaSnip
---condition objects before they are combined with the caller's condition.
---@param condition SnipCondition
---@return SnipCondition
function M.with_line_begin(condition)
  local show_first_token = condition_objects.make_condition(line_begin_show)

  return {
    condition = condition_object(condition.condition) * expand_conditions.line_begin,
    show_condition = condition_object(condition.show_condition) * show_first_token,
  }
end

---Restrict expansion to triggers that begin at an exact display column.
---@param condition SnipCondition
---@param column integer
---@return SnipCondition
function M.with_trigger_column(condition, column)
  local expansion_column = condition_objects.make_condition(function(line_to_cursor, matched_trigger)
    return trigger_start_column(line_to_cursor or "", matched_trigger or "") == column
  end)
  local show_column = condition_objects.make_condition(function(line_to_cursor)
    return trigger_column_show(line_to_cursor, column)
  end)

  return {
    condition = condition_object(condition.condition) * expansion_column,
    show_condition = condition_object(condition.show_condition) * show_column,
  }
end

---Restrict a condition to the first buffer line.
---@param condition SnipCondition
---@return SnipCondition
function M.on_first_buffer_line(condition)
  local first_line = condition_objects.make_condition(function()
    return vim.api.nvim_win_get_cursor(0)[1] == 1
  end)

  return {
    condition = condition_object(condition.condition) * first_line,
    show_condition = condition_object(condition.show_condition) * first_line,
  }
end

---Restrict expansion to a trigger that starts at column zero on the first line.
---@param condition SnipCondition
---@return SnipCondition
function M.at_buffer_start(condition)
  return M.on_first_buffer_line(M.with_trigger_column(condition, 0))
end

---Merge optional fields into a freshly-created context table.
---@generic T: SnipContext|SnipContextExtra
---@param context T
---@param extra? SnipContextExtra
---@return T context
function M.extend(context, extra)
  if extra == nil then
    return context
  end

  for key, value in pairs(extra) do
    context[key] = value
  end
  return context
end

---Read a trigger capture in a function node.
---@param n integer
---@param default? string
---@return SnipNode
function M.capture(n, default)
  return f(function(_, snip)
    return snip.captures[n] or default or ""
  end)
end

---Read a trigger capture, treating an empty capture as missing.
---@param n integer
---@param default? string
---@return SnipNode
function M.capture_nonempty(n, default)
  return f(function(_, snip)
    local value = snip.captures[n]
    if value == nil or value == "" then
      return default or ""
    end
    return value
  end)
end

---Build a dynamic-node callback seeded from a trigger capture.
---@param n integer
---@param default string
---@return fun(args: SnipNodeArgs, snip: SnipSnippet): SnipNode
function M.captured_insert(n, default)
  return function(_, snip)
    local value = snip.captures[n]
    if value == nil or value == "" then
      value = default
    end

    return sn(nil, { i(1, value) })
  end
end

---Return the next value in a fixed cycle.
---@param current string
---@param values string[]
---@return string
function M.choose_next(current, values)
  for index, value in ipairs(values) do
    if value == current then
      return values[index % #values + 1]
    end
  end
  return values[1]
end

---Escape a literal string for use inside Lua pattern matching.
---@param value string
---@return string
function M.escape_lua_pattern(value)
  return (value:gsub("([^%w])", "%%%1"))
end

---Return a copy ordered by descending byte length for longest-match scans.
---@param values string[]
---@return string[]
function M.sorted_longest_first(values)
  local ordered = {}
  for index, value in ipairs(values) do
    ordered[index] = value
  end

  table.sort(ordered, function(left, right)
    return #left > #right
  end)
  return ordered
end

---Build a literal text snippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.literal_snippet(trigger, output, name, condition, extra)
  return s(M.with_condition(M.extend({ trig = trigger, name = name }, extra), condition), t(output))
end

---Build a literal autosnippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.literal_autosnippet(trigger, output, name, condition, extra)
  return M.literal_snippet(trigger, output, name, condition, M.extend({ snippetType = "autosnippet" }, extra))
end

---Build an unescaped-word autosnippet.
---@param trigger string
---@param output string
---@param name string
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
function M.word_autosnippet(trigger, output, name, condition, extra)
  return M.literal_autosnippet(
    trigger,
    output,
    name,
    condition,
    M.extend({
      trigEngine = get_unescaped_word_engine(),
      wordTrig = false,
    }, extra)
  )
end

---Build a word autosnippet from arbitrary nodes instead of a literal body.
---@param trigger string
---@param name string
---@param condition SnipCondition
---@param body SnipNodeBody
---@param extra? SnipContextExtra
---@return SnipNode
function M.word_auto_snippet(trigger, name, condition, body, extra)
  return s(
    M.with_condition(
      M.extend({
        trig = trigger,
        trigEngine = get_unescaped_word_engine(),
        wordTrig = false,
        name = name,
        snippetType = "autosnippet",
      }, extra),
      condition
    ),
    body
  )
end

---Match one of several exact suffixes.
---@param values string[]
---@param max_len? integer
---@return SnipTriggerEngine
function M.exact_cycle_engine(values, max_len)
  return function()
    return function(line_to_cursor)
      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - (max_len or 48)))
      for _, value in ipairs(values) do
        if text:sub(-#value) == value then
          return value, { value }
        end
      end
      return nil
    end
  end
end

return M

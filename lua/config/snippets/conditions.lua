---Shared LuaSnip context predicates.
---
---The old UltiSnips setup delegated most Markdown/LaTeX decisions to VimTeX via
---`mdtex.scopes`.  This module keeps math decisions on VimTeX for TeX and
---Markdown LaTeX zones, and uses Tree-sitter for Markdown/Typst code, comment,
---and Typst math scope.
local M = {}
local condition_objects = require("luasnip.extras.conditions")
local nil_value = {}
local unpack = table.unpack or unpack
local scope_cache = {}

local cache_augroup = vim.api.nvim_create_augroup("SnippetScopeCache", { clear = true })
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "FileType", "Syntax" }, {
  group = cache_augroup,
  callback = function(args)
    scope_cache[args.buf] = nil
  end,
})

---@class VimtexCurrentCommand
---@field name? string Current LaTeX command, including the leading backslash.

---Return the per-position cache used by high-volume completion predicates.
---
---Each buffer keeps only one cursor position.  Moving the cursor or changing
---the buffer replaces the whole value table, so old positions do not build up.
---@return table<string, unknown>
local function current_scope_cache()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local cache = scope_cache[bufnr]

  if
    not cache
    or cache.changedtick ~= changedtick
    or cache.row ~= cursor[1]
    or cache.col ~= cursor[2]
  then
    cache = {
      changedtick = changedtick,
      row = cursor[1],
      col = cursor[2],
      values = {},
    }
    scope_cache[bufnr] = cache
  end

  return cache.values
end

---@param name string
---@return string
local function cache_key(name, ...)
  local parts = { name }
  for index = 1, select("#", ...) do
    parts[#parts + 1] = tostring(select(index, ...))
  end
  return table.concat(parts, "\31")
end

---Return a value cached for the current buffer, changedtick, and cursor.
---@generic T
---@param key string
---@param compute fun(): T
---@return T
local function cached_at_cursor(key, compute)
  local values = current_scope_cache()
  local value = values[key]
  if value ~= nil then
    return value == nil_value and nil or value
  end

  value = compute()
  values[key] = value == nil and nil_value or value
  return value
end

---Call a VimTeX function safely, returning nil when unavailable or failing.
---@param name string
---@return unknown?
local function call_vimtex(name, ...)
  -- Call directly so VimTeX autoload functions can be sourced on demand.
  -- `exists("*vimtex#...")` may be 0 before the first successful call.
  local ok, value = pcall(vim.fn[name], ...)
  if not ok then
    return nil
  end
  return value
end

---Call a VimTeX scope function once per cursor position.
---@param name string
---@return unknown?
local function cached_call_vimtex(name, ...)
  local arg_count = select("#", ...)
  local args = { ... }
  local key = cache_key("vimtex", name, unpack(args, 1, arg_count))
  return cached_at_cursor(key, function()
    return call_vimtex(name, unpack(args, 1, arg_count))
  end)
end

---Return VimTeX's current command metadata, or an empty table.
---@return VimtexCurrentCommand
local function current_cmd()
  local value = cached_call_vimtex("vimtex#cmd#get_current")
  return type(value) == "table" and value or {}
end

---Return whether VimTeX reports the cursor inside a named environment.
---@param name string
---@return boolean
local function in_vimtex_env(name)
  local value = cached_call_vimtex("vimtex#env#is_inside", name)
  if type(value) ~= "table" then
    return false
  end
  return tostring(value[1] or "0") ~= "0" and tostring(value[2] or "0") ~= "0"
end

---Return whether the Tree-sitter node ancestry matches one of the patterns.
---@param patterns string[]
---@return boolean
local function ts_node_matches(patterns)
  local key = cache_key("ts_node", table.concat(patterns, "\31"))
  return cached_at_cursor(key, function()
    local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
    if not ok or not node then
      return false
    end
    while node do
      local node_type = node:type()
      for _, pattern in ipairs(patterns) do
        if node_type:find(pattern) then
          return true
        end
      end
      node = node:parent()
    end
    return false
  end)
end

---Return whether Tree-sitter highlight captures match at the cursor.
---@param capture string
---@param lang string?
---@return boolean
local function ts_capture_matches(capture, lang)
  local key = cache_key("ts_capture", capture, lang or "")
  return cached_at_cursor(key, function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, cursor[2])
    if not ok then
      return false
    end
    for _, item in ipairs(captures) do
      if item.capture == capture and (lang == nil or item.lang == lang) then
        return true
      end
    end
    return false
  end)
end

---Return whether Markdown Tree-sitter reports an HTML comment at the cursor.
---@return boolean
local function markdown_html_comment()
  return ts_capture_matches("comment", "html")
end

---Return whether VimTeX considers the cursor in usable math context.
---@return boolean
local function vimtex_in_mathzone()
  local in_math = cached_call_vimtex("vimtex#syntax#in_mathzone")
  if in_math == nil then
    return false
  end
  return tostring(in_math) == "1"
end

---Return whether VimTeX considers the cursor in usable math context.
---@return boolean
function M.vimtex_math()
  if not vimtex_in_mathzone() then
    return false
  end

  -- `vimtex#cmd#get_current()` is much more expensive than mathzone syntax
  -- checks in real TeX buffers.  Keep it on the expansion path for exact
  -- exclusions, but only after VimTeX has confirmed that math snippets apply.
  local cmd = current_cmd().name
  return cmd ~= "\\textcolor"
    and cmd ~= "\\operatorname"
    and not in_vimtex_env("sympy")
    and not in_vimtex_env("wolfram")
end

---Return a cheap VimTeX math predicate for completion visibility.
---
---This intentionally skips command/environment exclusions.  Completion menus
---may evaluate `show_condition` hundreds of times at the same cursor position;
---actual expansion still uses `vimtex_math()` for precise filtering.
---@return boolean
function M.vimtex_math_show()
  return vimtex_in_mathzone()
end

---Return whether the cursor is inside a LaTeX `\ce{...}` math command.
---@return boolean
function M.vimtex_chem()
  return M.vimtex_math() and current_cmd().name == "\\ce"
end

---Return whether the cursor is inside a LaTeX `\pu{...}` math command.
---@return boolean
function M.vimtex_unit()
  return M.vimtex_math() and current_cmd().name == "\\pu"
end

---Return whether the cursor is in math but not chemistry or unit context.
---@return boolean
function M.vimtex_pure_math()
  return M.vimtex_math() and not M.vimtex_chem() and not M.vimtex_unit()
end

---Return whether VimTeX reports an inline math zone.
---@return boolean
function M.vimtex_inline_math()
  return tostring(cached_call_vimtex("vimtex#syntax#in", "texMathZone[LT]I")) == "1"
end

---Return whether VimTeX reports a display math zone.
---@return boolean
function M.vimtex_display_math()
  return tostring(cached_call_vimtex("vimtex#syntax#in", "texMathZone[LT]D")) == "1"
end

---Return a cheap VimTeX inline-math predicate for completion visibility.
---@return boolean
function M.vimtex_inline_math_show()
  return M.vimtex_inline_math()
end

---Return a cheap VimTeX display-math predicate for completion visibility.
---@return boolean
function M.vimtex_display_math_show()
  return M.vimtex_display_math()
end

---Return the VimTeX math layout at the cursor.
---
---`true` means inline math, `false` means display math, and `nil` means VimTeX
---does not report either layout.  Callers should not add delimiter text scans
---as a fallback; Markdown and TeX math layout follows VimTeX.
---@return boolean?
function M.vimtex_inline_layout()
  if M.vimtex_inline_math() then
    return true
  end
  if M.vimtex_display_math() then
    return false
  end
  return nil
end

---Return whether VimTeX reports a comment context.
---@return boolean
function M.vimtex_comment()
  return tostring(cached_call_vimtex("vimtex#syntax#in_comment")) == "1"
end

---Return whether VimTeX reports the cursor inside any named environment.
---@param names string[]
---@return boolean
function M.vimtex_env_any(names)
  for _, name in ipairs(names) do
    if in_vimtex_env(name) then
      return true
    end
  end
  return false
end

---Return whether TeX snippets should use text-mode behavior.
---@return boolean
function M.vimtex_text()
  return not M.vimtex_math() and not M.vimtex_comment() and not M.in_code()
end

---Return a cheap TeX text predicate for completion visibility.
---@return boolean
function M.vimtex_text_show()
  return not M.vimtex_math_show() and not M.vimtex_comment() and not M.in_code()
end

---Return whether Markdown LaTeX snippets should be suppressed as comments.
---@return boolean
function M.in_code()
  return ts_node_matches({ "code", "fence", "raw" })
end

---Return whether Markdown LaTeX math snippets are allowed at the cursor.
---@return boolean
function M.markdown_latex_comment()
  return vim.bo.filetype == "markdown" and markdown_html_comment()
end

---Return whether Markdown LaTeX math snippets are allowed at the cursor.
---@return boolean
function M.markdown_latex_math()
  if vim.bo.filetype ~= "markdown" or M.in_code() or M.markdown_latex_comment() then
    return false
  end

  return M.vimtex_math()
end

---Return a cheap Markdown LaTeX math predicate for completion visibility.
---@return boolean
function M.markdown_latex_math_show()
  if vim.bo.filetype ~= "markdown" or M.in_code() or M.markdown_latex_comment() then
    return false
  end

  return M.vimtex_math_show()
end

---Return whether Markdown LaTeX inline-math snippets are allowed at the cursor.
---@return boolean
function M.markdown_latex_inline_math()
  if not M.markdown_latex_math() then
    return false
  end
  return M.vimtex_inline_math()
end

---Return a cheap Markdown LaTeX inline-math predicate for completion visibility.
---@return boolean
function M.markdown_latex_inline_math_show()
  if not M.markdown_latex_math_show() then
    return false
  end
  return M.vimtex_inline_math_show()
end

---Return whether Markdown LaTeX display-math snippets are allowed at the cursor.
---@return boolean
function M.markdown_latex_display_math()
  if not M.markdown_latex_math() then
    return false
  end
  return M.vimtex_display_math()
end

---Return a cheap Markdown LaTeX display-math predicate for completion visibility.
---@return boolean
function M.markdown_latex_display_math_show()
  if not M.markdown_latex_math_show() then
    return false
  end
  return M.vimtex_display_math_show()
end

---Return whether Markdown prose snippets are allowed at the cursor.
---@return boolean
function M.markdown_latex_text()
  return vim.bo.filetype == "markdown"
    and not M.markdown_latex_math()
    and not M.markdown_latex_comment()
    and not M.in_code()
end

---Return a cheap Markdown prose predicate for completion visibility.
---@return boolean
function M.markdown_latex_text_show()
  return vim.bo.filetype == "markdown"
    and not M.markdown_latex_math_show()
    and not M.markdown_latex_comment()
    and not M.in_code()
end

---Return whether Typst math snippets are allowed at the cursor.
---@return boolean
function M.typst_math()
  if vim.bo.filetype ~= "typst" then
    return false
  end
  if M.typst_comment() or M.in_code() then
    return false
  end
  return ts_node_matches({ "math" })
end

---Return whether Typst text snippets are allowed at the cursor.
---@return boolean
function M.typst_comment()
  return vim.bo.filetype == "typst" and ts_node_matches({ "comment" })
end

---@return boolean
function M.typst_text()
  return vim.bo.filetype == "typst" and not M.typst_math() and not M.typst_comment() and not M.in_code()
end

---Wrap a predicate as both LuaSnip expansion and completion visibility condition.
---@param fn SnipConditionFn
---@param show_fn? SnipConditionFn
---@return SnipCondition
function M.wrap(fn, show_fn)
  local condition = condition_objects.make_condition(fn)
  local show_condition = show_fn and condition_objects.make_condition(show_fn) or condition

  return {
    condition = condition,
    show_condition = show_condition,
  }
end

return M

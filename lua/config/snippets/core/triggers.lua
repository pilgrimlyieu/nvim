---Custom LuaSnip trigger engines shared by snippet builders.
local M = {}

local sorted_longest_first = require("config.snippets.core.matching").sorted_longest_first

-- Trigger engines receive the full current line on every match attempt.  These
-- byte windows cap suffix scans to the migrated shorthand grammar instead of
-- treating autosnippets as paragraph-scale parsers.
local POSTFIX_TRIGGER_WINDOW = 160 -- compact prose/math/code token before `,,` or `;;`.
local INLINE_MATH_SUFFIXES = { ",,", "，，" }
local INLINE_CODE_SUFFIXES = { ";;", "；；" }

---Return whether a byte-sized character is an ASCII identifier character.
---@param char string
---@return boolean
local function is_ascii_word_char(char)
  return char:match("[A-Za-z0-9_]") ~= nil
end

---Return the first matching exact suffix from a small suffix set.
---@param text string
---@param suffixes string[]
---@return string?
local function matching_suffix(text, suffixes)
  for _, suffix in ipairs(suffixes) do
    if vim.endswith(text, suffix) then
      return suffix
    end
  end
  return nil
end

---Match a complete word trigger only when it is not already escaped.
---
---This preserves the old UltiSnips `(?<!\\)\b...` behavior for long math
---commands such as `alpha` or `sin`: typing `alpha` in a math zone expands to
---`\alpha`, but typing an existing `\alpha` does not become `\\alpha`.
---@param trigger string
---@return SnipTriggerMatcher
function M.unescaped_word_engine(trigger)
  return function(line_to_cursor)
    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - #trigger - 2))
    if not vim.endswith(text, trigger) then
      return nil
    end

    local before = text:sub(#text - #trigger, #text - #trigger)
    if before == "\\" or is_ascii_word_char(before) then
      return nil
    end

    return trigger, {}
  end
end

---Match a short prose-math word without consuming its preceding character.
---Only ASCII identifier bytes block expansion; spacing is decided on expansion.
---@param trigger string
---@return SnipTriggerMatcher
function M.short_math_word_engine(trigger)
  return function(line_to_cursor)
    if not vim.endswith(line_to_cursor, trigger) then
      return nil
    end

    local stop = #line_to_cursor - #trigger
    if is_ascii_word_char(line_to_cursor:sub(stop, stop)) then
      return nil
    end
    return trigger, {}
  end
end

---Match text followed by `,,`/`，，` for prose-to-inline-math autosnippets.
---
---This intentionally preserves the older Markdown/TeX text-mode behavior:
---only the compact math token is wrapped, while a preceding punctuation/CJK
---character stays outside the replaced range. captures[1] is the math token.
---@return SnipTriggerMatcher
function M.inline_math_postfix_engine()
  return function(line_to_cursor)
    local suffix = matching_suffix(line_to_cursor, INLINE_MATH_SUFFIXES)
    if not suffix then
      return nil
    end

    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - POSTFIX_TRIGGER_WINDOW))
    local before_suffix = text:sub(1, #text - #suffix)
    local token = before_suffix:match("([A-Za-z0-9_^+=%%%.<>%-]+)$")
    if token then
      local stop = #before_suffix - #token
      if not is_ascii_word_char(before_suffix:sub(stop, stop)) then
        return token .. suffix, { token }
      end
    end

    return nil
  end
end

---Match text followed by `;;`/`；；` for Markdown inline-code autosnippets.
---@return SnipTriggerMatcher
function M.inline_code_postfix_engine()
  return function(line_to_cursor)
    local suffix = matching_suffix(line_to_cursor, INLINE_CODE_SUFFIXES)
    if not suffix then
      return nil
    end

    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - POSTFIX_TRIGGER_WINDOW))
    local before_suffix = text:sub(1, #text - #suffix)
    local token = before_suffix:match("([A-Za-z0-9_^+=%%%.<>%[%]%(%)%-]+)$")
    if token ~= nil and token ~= "" then
      return token .. suffix, { token }
    end

    return nil
  end
end

---Match one of several exact suffixes.
---@param values string[]
---@return SnipTriggerEngine
function M.exact_cycle_engine(values)
  local matches = sorted_longest_first(values)
  return function()
    return function(line_to_cursor)
      for _, value in ipairs(matches) do
        if line_to_cursor:sub(-#value) == value then
          return value, { value }
        end
      end
      return nil
    end
  end
end

return M

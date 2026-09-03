---Custom LuaSnip trigger engines shared by snippet builders.
local M = {}

-- Trigger engines receive the full current line on every match attempt.  These
-- byte windows cap suffix scans to the migrated shorthand grammar instead of
-- treating autosnippets as paragraph-scale parsers.
local FRACTION_TRIGGER_WINDOW = 80 -- simple atom/script numerators and short parenthesized groups.
local MATRIX_TRIGGER_WINDOW = 16 -- old `bmm.22&` family: form + `mm.` + one/two dimensions + suffix.
local POSTFIX_TRIGGER_WINDOW = 160 -- compact prose/math/code token before `,,` or `;;`.
local SHORT_MATH_TRIGGER_WINDOW = 16 -- short math words like `ce`, `alpha`, and `lm`.
local INLINE_MATH_SUFFIXES = { ",,", "，，" }
local INLINE_CODE_SUFFIXES = { ";;", "；；" }

---Return whether a byte-sized character is an ASCII identifier character.
---@param char string
---@return boolean
local function is_ascii_word_char(char)
  return char:match("[A-Za-z0-9_]") ~= nil
end

---Count UTF-8 characters in a string.
---@param value string
---@return integer
local function char_count(value)
  return vim.fn.strchars(value)
end

---Return the last UTF-8 character of a string.
---@param value string
---@return string
local function last_char(value)
  local count = char_count(value)
  if count == 0 then
    return ""
  end

  return vim.fn.strcharpart(value, count - 1, 1)
end

---Return whether `text` ends with an exact suffix.
---@param text string
---@param suffix string
---@return boolean
local function ends_with(text, suffix)
  return text:sub(-#suffix) == suffix
end

---Return the first matching exact suffix from a small suffix set.
---@param text string
---@param suffixes string[]
---@return string?
local function matching_suffix(text, suffixes)
  for _, suffix in ipairs(suffixes) do
    if ends_with(text, suffix) then
      return suffix
    end
  end
  return nil
end

---Match the numerator part of `1/`, `x_i/`, `\alpha/`, etc.
---
---The old UltiSnips trigger was a Python regex. LuaSnip's `"pattern"` engine
---uses Lua patterns, which have no alternation, so this custom engine preserves
---the useful old behavior without depending on jsregexp.
---@return SnipTriggerMatcher
function M.simple_fraction_engine()
  local patterns = {
    -- `x_{i}^{j}/`: two braced scripts.
    [[([%a%d]*\?[%a]+[_^]%b{}[_^]%b{})/$]],
    -- `x_{i}^j/`: braced first script, unbraced second script.
    [[([%a%d]*\?[%a]+[_^]%b{}[_^][%a%d])/$]],
    -- `x_i^{j}/`: unbraced first script, braced second script.
    [[([%a%d]*\?[%a]+[_^][%a%d][_^]%b{})/$]],
    -- `x_i^j/`: two unbraced scripts.
    [[([%a%d]*\?[%a]+[_^][%a%d][_^][%a%d])/$]],
    -- `x_{i}/`: one braced script.
    [[([%a%d]*\?[%a]+[_^]%b{})/$]],
    -- `x_i/`: one unbraced script.
    [[([%a%d]*\?[%a]+[_^][%a%d])/$]],
    -- `\alpha/` or `foo/`: command/word atom.
    [[([%a%d]*\?[%a]+)/$]],
    -- `1/` or `n!/`: numeric/alnum atom, optionally factorial.
    [[([%a%d]+!?)/$]],
  }

  return function(line_to_cursor)
    if not ends_with(line_to_cursor, "/") then
      return nil
    end

    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - FRACTION_TRIGGER_WINDOW))

    if text:sub(-2, -2) == ")" then
      local depth = 1

      for index = #text - 2, 1, -1 do
        local char = text:sub(index, index)

        if char == ")" then
          depth = depth + 1
        elseif char == "(" then
          depth = depth - 1

          if depth == 0 then
            local group = text:sub(index, #text - 1)
            local numerator = group:sub(2, -2)

            if numerator ~= "" then
              return group .. "/", { numerator }
            end
          end
        end
      end
    end

    for _, pattern in ipairs(patterns) do
      local numerator = text:match(pattern)
      if numerator then
        return numerator .. "/", { numerator }
      end
    end

    return nil
  end
end

---Match the old simple matrix family: `bmm.22&`, `pmm.3&`, `mmm.23&`.
---
---This intentionally keeps only the fast, common behavior.  The old Python
---matrix helper also supported computed cells and many style flags; those are
---better handled by explicit Lua snippets when a concrete workflow needs them.
---@return SnipTriggerMatcher
function M.simple_matrix_engine()
  return function(line_to_cursor)
    if not ends_with(line_to_cursor, "&") then
      return nil
    end

    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - MATRIX_TRIGGER_WINDOW))
    local match, form, rows, cols = text:match("(([mpbBvV])mm%.([1-5])([1-5]?)&)$")

    if not form then
      return nil
    end

    return match, { form, rows, cols }
  end
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
    if not ends_with(text, trigger) then
      return nil
    end

    local before = text:sub(#text - #trigger, #text - #trigger)
    if before == "\\" or is_ascii_word_char(before) then
      return nil
    end

    return trigger, {}
  end
end

---Match old text-mode short-math words like `ce`, `alpha`, and `lm`.
---
---The legacy regex captured one preceding non-word character and inserted an
---extra separating space only when that prefix was not punctuation.  The prefix
---is captured as a full UTF-8 character so CJK prose before a trigger is not
---split byte-by-byte.
---@param trigger string
---@return SnipTriggerMatcher
function M.short_math_word_engine(trigger)
  return function(line_to_cursor)
    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - #trigger - SHORT_MATH_TRIGGER_WINDOW))
    if not ends_with(text, trigger) then
      return nil
    end

    local before_trigger = line_to_cursor:sub(1, #line_to_cursor - #trigger)
    local prefix = last_char(before_trigger)
    if prefix ~= "" and is_ascii_word_char(prefix) then
      return nil
    end

    return prefix .. trigger, { prefix }
  end
end

---Match text followed by `,,`/`，，` for prose-to-inline-math autosnippets.
---
---This intentionally preserves the older Markdown/TeX text-mode behavior:
---only the compact math token is wrapped, while a preceding punctuation/CJK
---character is kept outside the math delimiters.
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
      local before_token = before_suffix:sub(1, #before_suffix - #token)
      local prefix = last_char(before_token)
      if prefix == "" or not is_ascii_word_char(prefix) then
        return prefix .. token .. suffix, { prefix, token }
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

return M

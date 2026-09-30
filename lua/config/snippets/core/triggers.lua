---Custom LuaSnip trigger engines shared by snippet builders.
local M = {}

---Return whether a byte-sized character is an ASCII identifier character.
---@param char string
---@return boolean
local function is_ascii_word_char(char)
  return char:match("[A-Za-z0-9_]") ~= nil
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

---Match a short word without consuming its preceding character.
---Only ASCII identifier bytes block expansion; spacing is decided on expansion.
---@param trigger string
---@return SnipTriggerMatcher
function M.word_suffix_engine(trigger)
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

---Capture a compact token before one of the supplied literal suffixes.
---The token pattern belongs to the feature. A truncated token never matches.
---@param suffixes string[]
---@param pattern string A Lua pattern matching/capturing the final token.
---@return SnipTriggerMatcher
function M.token_postfix_engine(suffixes, pattern)
  return function(line)
    for _, suffix in ipairs(suffixes) do
      if line:sub(-#suffix) == suffix then
        local stop = #line - #suffix
        local tail = line:sub(math.max(1, stop - 160), stop)
        local token = tail:match(pattern)
        if token and not (#token == #tail and stop > 160) then
          local before = tail:sub(#tail - #token, #tail - #token)
          if not is_ascii_word_char(before) then
            return token .. suffix, { token }
          end
        end
      end
    end
  end
end

---Bounded suffix rewrite. Unchanged output never matches an autosnippet.
---boundary is a language-owned Lua character class blocking the preceding byte.
---@param pattern string Cursor-anchored Lua pattern.
---@param render fun(captures: string[], full: string): string
---@param boundary? string
---@return SnipTriggerEngine
function M.rewrite_engine(pattern, render, boundary)
  return function()
    return function(line)
      local tail = line:sub(-65)
      local found = { tail:find(pattern) }
      local start, stop = found[1], found[2]
      if not start or (#line > 64 and start == 1) then
        return nil
      end
      if boundary and tail:sub(start - 1, start - 1):match(boundary) then
        return nil
      end
      local full = tail:sub(start, stop)
      local rendered = render({ unpack(found, 3) }, full)
      if rendered ~= full then
        return full, { rendered }
      end
    end
  end
end

return M

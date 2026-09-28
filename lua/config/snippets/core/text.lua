---UTF-8 boundary characters, shared by trigger matching and prose spacing.
local M = {}

---Return the first UTF-8 character of a string.
---@param value string
---@return string
function M.first(value)
  return vim.fn.strcharpart(value, 0, 1)
end

---Return the final UTF-8 character using at most four bytes.
---Input must end at a character boundary; its beginning may be a sliced byte tail.
---@param value string
---@return string
function M.last(value)
  local start = #value
  while start > math.max(1, #value - 3) do
    local byte = value:byte(start)
    if byte < 0x80 or byte >= 0xC0 then
      break
    end
    start = start - 1
  end
  return value:sub(start)
end

---Check if a value is within a range (inclusive).
---@param value integer
---@param start integer
---@param finish integer
---@return boolean
local function in_range(value, start, finish)
  return value >= start and value <= finish
end

---Check if a character is considered prose (alphanumeric or CJK).
---@param char string
---@return boolean
function M.is_prose(char)
  if char == "" then
    return false
  end
  local cp = vim.fn.char2nr(char)
  return in_range(cp, 0x30, 0x39) -- 0-9
    or in_range(cp, 0x41, 0x5A) -- A-Z
    or in_range(cp, 0x61, 0x7A) -- a-z
    or in_range(cp, 0x3400, 0x4DBF) -- CJK Unified Ideographs Extension A
    or in_range(cp, 0x4E00, 0x9FFF) -- CJK Unified Ideographs
    or in_range(cp, 0xF900, 0xFAFF) -- CJK Compatibility Ideographs
    or in_range(cp, 0x20000, 0x2EBEF) -- CJK Unified Ideographs Extension B-F
    or in_range(cp, 0x30000, 0x323AF) -- CJK Unified Ideographs Extension G-H
end

return M

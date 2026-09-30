---Read only the Typst math object touching the cursor; no buffer or parser state.
local M = {}

M.window = 64

---@class SnipTypstOperand: SnipMathOperand
---@field delimiters? string Body of a proven outer visible delimiter pair.

local opening = { [")"] = "(", ["]"] = "[", ["}"] = "{" }

---A matched range may contain opaque math, but not strings, code or escapes.
---Walk backwards so unrelated groups before the operand need no work.
---@param text string Cursor prefix without the trigger.
---@param last number Index of the last character to consider.
---@return number? index Index of the first character of the matched group, or nil if none.
local function group(text, last)
  if not opening[text:sub(last, last)] then
    return nil
  end

  local stack = {}
  for pos = last, 1, -1 do
    local char = text:sub(pos, pos)
    if opening[char] then
      stack[#stack + 1] = opening[char]
    elseif char:match("[([{]") then
      if stack[#stack] ~= char then
        return nil
      end
      stack[#stack] = nil
      if #stack == 0 then
        return pos
      end
    end
  end
end

---A short word run needs forward lexing: a.b is three math tokens whereas
---phi.alt is one field access; a decimal needs digits on both sides of its dot.
---@param text string Cursor prefix without the trigger.
---@param last number Index of the last character to consider.
---@return number? index Index of the first character of the matched word, or nil if none.
local function word(text, last)
  local edge = last
  while edge > 0 and text:sub(edge, edge):match("[%w%.]") do
    edge = edge - 1
  end
  local run = text:sub(edge + 1, last)
  if run == "" or run:find("..", 1, true) or run:sub(-1) == "." then
    return nil
  end
  local pos, start = 1, 1
  while pos <= #run do
    start = pos
    local tail = run:sub(pos)
    local value = tail:match("^%a%w*") or tail:match("^%d+%.%d+") or tail:match("^%d+")
    if not value then
      return nil
    end
    pos = pos + #value
    if value:match("^%a") and #value > 1 then
      while run:sub(pos, pos) == "." do
        local field = run:sub(pos):match("^%.%a%w*")
        if not field then
          return nil
        end
        pos = pos + #field
      end
    end
    if pos <= #run then
      if run:sub(pos, pos) ~= "." then
        return nil
      end
      pos = pos + 1
    end
  end
  return last - #run + start
end

---@param text string
---@param last number Index of the closing quote.
---@return number? index Index of the opening quote, or nil.
local function string_atom(text, last)
  if text:sub(last, last) ~= '"' then
    return nil
  end
  local pos = last - 1
  while pos > 0 do
    if text:sub(pos, pos) == '"' then
      local bs, check = 0, pos - 1
      while check > 0 and text:sub(check, check) == "\\" do
        bs, check = bs + 1, check - 1
      end
      if bs % 2 == 0 then
        return pos
      end
    end
    pos = pos - 1
  end
end

---@param text string Cursor prefix without the trigger.
---@param last number Index of the last character to consider.
---@return number? first Index of the first character of the matched atom, or nil if none
---@return string? delimiters Body of a proven outer visible delimiter pair, or nil if none.
local function atom(text, last)
  local char = text:sub(last, last)
  if char == '"' then
    return string_atom(text, last)
  end
  if not opening[char] then
    return word(text, last)
  end
  local first = group(text, last)
  if not first then
    return nil
  end
  local body = text:sub(first + 1, last - 1)
  if char == ")" and text:sub(first - 1, first - 1):match("[%w%.]") then
    local name = word(text, first - 1)
    if not name or not text:sub(name, name):match("%a") then
      return nil
    end
    local delimiters
    if text:sub(name, first - 1) == "lr" and body:match("^[([{]") and group(body, #body) == 1 then
      delimiters = body:sub(2, -2)
    end
    return name, delimiters
  end
  return first, body
end

---Recognize one adjacent atom with at most one _ and one ^, preserving spelling.
---Only () in script position is syntax grouping. Failure consumes nothing.
---A 64-byte suffix plus one witness bounds work and prevents clipped matches.
---@param source string Cursor prefix without the trigger.
---@return SnipTypstOperand?
function M.read(source)
  local text = source:sub(-M.window - 1)
  local last, scripts, seen = #text, {}, {}
  while last > 0 do
    local first, delimiters = atom(text, last)
    if not first then
      return nil
    end
    local marker = text:sub(first - 1, first - 1)
    if marker == "_" or marker == "^" then
      if seen[marker] then
        return nil
      end
      local content = text:sub(first, last)
      if content:sub(1, 1) == "(" then
        content = content:sub(2, -2)
      end
      table.insert(scripts, 1, { marker = marker, source = text:sub(first - 1, last), content = content })
      seen[marker], last = true, first - 2
    else
      if first > 1 then
        local before = first - 1
        while before > 0 and text:sub(before, before):match("[%s+%-]") do
          before = before - 1
        end
        if text:sub(before, before):match("[_^]") then
          return nil
        end
      end
      if #text - first + 1 > M.window or (#source > M.window and first == 1) then
        return nil
      end
      return { source = text:sub(first), base = text:sub(first, last), scripts = scripts, delimiters = delimiters }
    end
  end
end

return M

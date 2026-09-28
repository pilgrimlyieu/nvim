---Bounded cursor-relative operand recognition, deliberately not a language parser.
---Escapes are not modelled: `\\` and `\{` are treated as literal bytes.
local M = {}

---Operand scans start at the cursor and never cross this many bytes backwards.
M.OPERAND_WINDOW = 64

---@class SnipOperandSyntax
---@field command_prefix? string Absorb a command prefix such as LaTeX `\` into the atom. Only the immediately preceding byte is considered.

---Return the first byte of a command-prefixed atom, or start unchanged.
---@param text string
---@param start integer
---@param limit integer
---@param prefix string?
---@return integer
local function absorb_command(text, start, limit, prefix)
  if not prefix or start <= limit then
    return start
  end
  if text:sub(start - 1, start - 1) ~= prefix or not text:sub(start, start):match("%a") then
    return start
  end
  return start - 1
end

---Return the final complete operand and its 1-based byte start, or nil.
---Never consumes across OPERAND_WINDOW; malformed groups and code/string boundaries fail closed.
---@param text string
---@param syntax? SnipOperandSyntax
---@return string? operand
---@return integer? start
function M.last(text, syntax)
  local limit = math.max(1, #text - M.OPERAND_WINDOW + 1)
  local prefix = syntax and syntax.command_prefix

  local function atom(pos)
    if pos < limit then
      return nil
    end
    local char = text:sub(pos, pos)
    local start
    if char == ")" or char == "]" or char == "}" then
      local stack = { char }
      local closes = { ["("] = ")", ["["] = "]", ["{"] = "}" }
      for n = pos - 1, limit, -1 do
        local c = text:sub(n, n)
        if c == '"' or c == "#" or c == "`" then
          return nil
        end
        if c == ")" or c == "]" or c == "}" then
          stack[#stack + 1] = c
        elseif closes[c] then
          if closes[c] ~= stack[#stack] then
            return nil
          end
          stack[#stack] = nil
          if #stack == 0 then
            start = n
            break
          end
        end
      end

      if not start then
        return nil
      end
      local first = start - 1
      while first >= limit and text:sub(first, first):match("[%w%.]") do
        first = first - 1
      end
      if first < start - 1 and text:sub(first + 1, first + 1):match("%a") then
        start = first + 1
      end
      start = absorb_command(text, start, limit, prefix)
    else
      start = pos
      while start >= limit and text:sub(start, start):match("[%w%.]") do
        start = start - 1
      end
      start = start + 1
      if start > pos or text:sub(start, start) == "." or text:sub(pos, pos) == "." then
        return nil
      end
      start = absorb_command(text, start, limit, prefix)
    end

    while start > limit and text:sub(start - 1, start - 1):match("[_^]") do
      start = atom(start - 2)

      if not start then
        return nil
      end
    end
    return start
  end

  local start = atom(#text)
  if not start or (start == limit and limit > 1) then
    return nil
  end

  local before = text:sub(start - 1, start - 1)
  if before == "#" or before == '"' or before == "`" or before == "." or before:match("[%w_^]") then
    return nil
  end
  return text:sub(start), start
end

---Match an operand followed by trigger; captures[1] is the entire operand.
---@param trigger string
---@param syntax? SnipOperandSyntax
---@return SnipTriggerMatcher
function M.engine(trigger, syntax)
  return function(line)
    if line:sub(-#trigger) ~= trigger then
      return nil
    end
    local operand = M.last(line:sub(math.max(1, #line - #trigger - M.OPERAND_WINDOW), -#trigger - 1), syntax)
    if operand then
      return operand .. trigger, { operand }
    end
  end
end

---Strip parentheses only when doing so cannot split one operand into arguments.
---@param value string
---@return string
function M.ungroup(value)
  if value:match("^%b()$") then
    local body = value:sub(2, -2)
    local depth = 0
    for char in body:gmatch(".") do
      if char:match("[([{]") then
        depth = depth + 1
      elseif char:match("[)%]}]") then
        depth = depth - 1
      elseif depth == 0 and (char == "," or char == ";" or char == ":") then
        return value -- Keep a single operand from becoming multiple call arguments.
      end
    end
    return body
  end
  return value
end

---Remove an existing outer delimiter wrapper when switching its shape.
function M.undelimit(value)
  if value:match("^lr%b()$") then
    value = value:sub(4, -2)
  end
  if value:match("^%b()$") or value:match("^%b[]$") or value:match("^%b{}$") then
    return value:sub(2, -2)
  end
  return value
end

return M

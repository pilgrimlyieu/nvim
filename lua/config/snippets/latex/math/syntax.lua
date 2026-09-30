---TeX math suffixes with explicit command ownership and token-sized scripts.
local M = {}

local decorations = require("config.snippets.shared.rules.decorations")

M.window = 64

-- Only commands whose adjacent argument grammar is known may own groups.
-- Unknown control words are usable as symbols, but never guessed to own arguments.
local arguments = {
  frac = 2,
  dfrac = 2,
  tfrac = 2,
  binom = 2,
  dbinom = 2,
  sqrt = 1,
  smash = 1,
  boldsymbol = 1,
  ddot = 1,
  text = 1,
  texttt = 1,
  textrm = 1,
  textcolor = 2,
  operatorname = 1,
  ["operatorname*"] = 1,
  cancel = 1,
  bcancel = 1,
  xcancel = 1,
  sout = 1,
  boxed = 1,
  phantom = 1,
  hphantom = 1,
  vphantom = 1,
  overbrace = 1,
  underbrace = 1,
  substack = 1,
}
for _, rule in ipairs(decorations) do
  if rule.latex then
    arguments[rule.latex:sub(2)] = 1
  end
  if rule.latex_opts and rule.latex_opts.wide then
    arguments[rule.latex_opts.wide:sub(2)] = 1
  end
end

local closes = { ["("] = ")", ["["] = "]", ["{"] = "}", ["\\{"] = "\\}" }
local opens = {}
for open, close in pairs(closes) do
  opens[close] = open
end

---Read a control sequence or plain letter run for backwards scanning. Actual
---script tokens are checked by atom below; backslash parity preserves escapes.
---@param text string Cursor prefix without the trigger.
---@param last number Index of the last character to consider.
---@return number first Index of the first character of the matched run.
---@return string value The matched run, including the backslash if present.
local function previous(text, last)
  local first = last
  while first > 1 and text:sub(first, first):match("%a") and text:sub(first - 1, first - 1):match("%a") do
    first = first - 1
  end
  if text:sub(last, last) == "*" and text:sub(1, last):match("\\operatorname%*$") then
    first = last - #"operatorname*" + 1
  end
  local slash = first - 1
  while slash > 0 and text:sub(slash, slash) == "\\" do
    slash = slash - 1
  end
  if (first - 1 - slash) % 2 == 1 then
    first = first - 1
  end
  return first, text:sub(first, last)
end

---@param text string Cursor prefix without the trigger.
---@param last number Index of the last character to consider.
---@return number? first Index of the first character of the matched group, or nil if none.
local function group(text, last)
  local stack, pos = {}, last
  while pos > 0 do
    local first, value = previous(text, pos)
    if opens[value] then
      stack[#stack + 1] = opens[value]
    elseif closes[value] then
      if stack[#stack] ~= value then
        return nil
      end
      stack[#stack] = nil
      if #stack == 0 then
        return first
      end
    end
    pos = first - 1
  end
end

---Recognize a compact suffix with token-sized TeX scripts and known adjacent
---command arguments. Balanced groups are opaque math, not macro expansion.
---Read at most 64 bytes plus a left-edge witness; ordinary failure returns nil.
---@param source string Cursor prefix without a trigger.
---@return SnipMathOperand?
function M.read(source)
  local text = source:sub(-M.window - 1)
  local first, pos, groups = #text + 1, #text, {}
  while pos > 0 do
    local start, value = previous(text, pos)
    if opens[value] then
      local next_start = group(text, pos)
      if not next_start then
        return nil
      end
      start = next_start
      groups[start] = pos
    elseif closes[value] or value == "\\(" or value == "\\[" or value:match("^[%s$+%-=*/,:;<>|&]$") then
      break
    end
    first, pos = start, start - 1
  end
  if first > #text or #text - first + 1 > M.window or (#source > M.window and first == 1) then
    return nil
  end
  local before = first - 1
  while before > 0 and text:sub(before, before):match("[%s+%-]") do
    before = before - 1
  end
  if text:sub(before, before):match("[_^]") then
    return nil
  end

  local function atom(at, script)
    local char = text:sub(at, at)
    if groups[at] then
      return (not script or char == "{") and groups[at] or nil
    elseif char:match("[%w%.]") then
      return at
    elseif char ~= "\\" then
      return nil
    end
    local command = text:sub(at):match("^\\(%a+)")
    if not command then
      return text:sub(at, at + 1):match("^\\[%%_&#$]$") and at + 1 or nil
    end
    local last = at + #command
    if command == "operatorname" and text:sub(last + 1, last + 1) == "*" then
      command, last = command .. "*", last + 1
    end
    local arity = arguments[command] or 0
    for _ = 1, arity do
      if text:sub(last + 1, last + 1) ~= "{" or not groups[last + 1] then
        return nil
      end
      last = groups[last + 1]
    end
    return last, { command = "\\" .. command, arity = arity }
  end

  local index, base_end, base_command, base_arity, scripts, seen = first, nil, nil, nil, {}, {}
  while index <= #text do
    local char = text:sub(index, index)
    if char == "_" or char == "^" then
      local last = atom(index + 1, true)
      if not base_end or not last or seen[char] then
        return nil
      end
      local content = text:sub(index + 1, last)
      if content:sub(1, 1) == "{" then
        content = content:sub(2, -2)
      end
      scripts[#scripts + 1] = { marker = char, source = text:sub(index, last), content = content }
      seen[char], index = true, last + 1
    else
      local last, meta
      if char == "!" and base_end then
        last = index
      else
        last, meta = atom(index)
      end
      if not last or #scripts > 0 then
        return nil
      end
      if base_end then
        base_command, base_arity = nil, nil
      else
        base_command = meta and meta.command or nil
        base_arity = meta and meta.arity or nil
      end
      base_end, index = last, last + 1
    end
  end
  if base_end then
    return {
      source = text:sub(first),
      base = text:sub(first, base_end),
      scripts = scripts,
      base_command = base_command,
      base_arity = base_arity,
    }
  end
end

return M

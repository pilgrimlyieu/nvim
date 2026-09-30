---Adapt language math readers and edit captures to LuaSnip postfix matching.
local M = {}

local edits = require("config.snippets.shared.math_edits")

local range_body = edits.range_body

---The language owns recognition; an operation only produces its node captures.
---Failed reads consume nothing. Successful edits consume exactly operand.source.
---The reader gets at most window+1 bytes; the extra byte witnesses truncation.
---@generic Operand: SnipMathOperand
---@param syntax {window: integer, read: fun(source: string): Operand?}
---@param captures fun(operand: Operand): string[]
---@return SnipTriggerEngine
function M.engine(syntax, captures)
  return function(trigger)
    return function(line)
      if line:sub(-#trigger) ~= trigger then
        return nil
      end
      local stop = #line - #trigger
      local operand = syntax.read(line:sub(math.max(1, stop - syntax.window), stop))
      if operand then
        return operand.source .. trigger, captures(operand)
      end
    end
  end
end

---Capture the complete operand, consuming one enclosing range-parenthesis pair.
---@param syntax {window: integer, read: fun(source: string): SnipMathOperand?}
---@return SnipTriggerEngine
function M.whole(syntax)
  return M.engine(syntax, function(operand)
    return { range_body(operand.source) }
  end)
end

return M

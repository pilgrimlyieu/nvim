---Pure editing policies for already recognized math operands. No syntax guessing.
local M = {}

---@class SnipMathScript
---@field marker string
---@field source string Includes marker and original grouping.
---@field content string Only language-defined script grouping is removed.
---@class SnipMathOperand
---@field source string Exact suffix: base followed by script sources, without gaps.
---@field base string Exact source before attachments.
---@field scripts SnipMathScript[] Attachments in source order.
---@field base_command? string
---@field base_arity? integer

---@class SnipDecorationScripts
---@field subscript? boolean Include subscripts inside a decoration.
---@field superscript? boolean Include superscripts inside a decoration.

---One outer pair of parentheses specifies the range of a postfix operation.
---Input is an already recognized body. A second pair remains visible; scripts
---outside the pair prevent removal because they still need that grouped base.
---@param value string
---@return string
function M.range_body(value)
  return value:match("^%b()$") and value:sub(2, -2) or value
end

---Partition attachments for a decoration, preserving source within each part.
---Full-operand operations do not use this policy: they use operand.source.
---@param operand SnipMathOperand
---@param policy? SnipDecorationScripts Missing fields leave the script outside.
---@return string inside
---@return string outside
function M.decorate(operand, policy)
  local inside, outside = { operand.base }, {}
  for _, script in ipairs(operand.scripts) do
    local key = script.marker == "_" and "subscript" or "superscript"
    local target = policy and policy[key] and inside or outside
    target[#target + 1] = script.source
  end
  return table.concat(inside), table.concat(outside)
end

---Locate a script field. Missing script means append; all other text is retained.
---The reader has already decided what is a script and removed only syntax grouping.
---@param operand SnipMathOperand
---@param marker string
---@return string before
---@return string content
---@return string after
function M.script(operand, marker)
  local offset = #operand.base
  for _, script in ipairs(operand.scripts) do
    if script.marker == marker then
      return operand.source:sub(1, offset), script.content, operand.source:sub(offset + #script.source + 1)
    end
    offset = offset + #script.source
  end
  return operand.source, "", ""
end

return M

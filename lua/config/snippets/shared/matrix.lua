---Shared matrix trigger and layout: bounded matching, dimensions and cell building.
local M = {}

local ls = require("luasnip")

local t = ls.text_node
local i = ls.insert_node

local MATRIX_TRIGGER_WINDOW = 16

---Match the old simple matrix family: `bmm.22&`, `pmm.3&`, `mmm.23&`.
---
---This intentionally keeps only the fast, common behavior.  The old Python
---matrix helper also supported computed cells and many style flags; those are
---better handled by explicit Lua snippets when a concrete workflow needs them.
---@return SnipTriggerMatcher
function M.engine()
  return function(line_to_cursor)
    if not vim.endswith(line_to_cursor, "&") then
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

function M.dimensions(captures)
  local form = captures[1] or ""
  local rows = tonumber(captures[2]) or 2
  local cols = tonumber(captures[3]) or rows
  return form, rows, cols
end

---Build matrix cells row by row, seeding the diagonal and separating rows.
---@param rows integer
---@param cols integer
---@param between string Cell separator.
---@param next_row string|string[] Row separator.
---@return LuaSnip.Node[]
function M.cells(rows, cols, between, next_row)
  local nodes, jump = {}, 1
  for row = 1, rows do
    for col = 1, cols do
      nodes[#nodes + 1] = i(jump, row == col and "1" or "0")
      jump = jump + 1
      if col < cols then
        nodes[#nodes + 1] = t(between)
      end
    end
    if row < rows then
      nodes[#nodes + 1] = t(next_row)
    end
  end
  return nodes
end

return M

---Pure helpers for literal trigger matching and cycles.
local M = {}

---Return the next value in a fixed cycle.
---@param current string
---@param values string[]
---@return string
function M.choose_next(current, values)
  for index, value in ipairs(values) do
    if value == current then
      return values[index % #values + 1]
    end
  end
  return values[1]
end

---Return a copy ordered by descending byte length for longest-match scans.
---@param values string[]
---@return string[]
function M.sorted_longest_first(values)
  local ordered = {}
  for index, value in ipairs(values) do
    ordered[index] = value
  end

  table.sort(ordered, function(left, right)
    return #left > #right
  end)
  return ordered
end

return M

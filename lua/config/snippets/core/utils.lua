local M = {}

---Shallow-copy defaults, then apply overrides; neither input is modified.
---@generic T: table
---@param defaults T
---@param overrides? table
---@return T
function M.extend(defaults, overrides)
  return vim.tbl_extend("force", defaults, overrides or {})
end

---Append items to a destination list, optionally mapping each item first.
---@generic T
---@param dst T[] The destination list to append to.
---@param items T[] The items to append.
---@param map? fun(item: T): T Optional mapping function to transform each item before appending.
---@return T[] The destination list after appending the items.
function M.append_all(dst, items, map)
  if not map then
    return vim.list_extend(dst, items)
  end
  for _, item in ipairs(items) do
    dst[#dst + 1] = map(item)
  end
  return dst
end

---Map a list of items to a new list using a mapping function.
---@generic T, U
---@param list T[] The input list to map.
---@param map fun(item: T): U The mapping function to apply to each item.
---@return U[] The new list containing the mapped items.
function M.map_list(list, map)
  local result = {}
  for i, item in ipairs(list) do
    result[i] = map(item)
  end
  return result
end

return M

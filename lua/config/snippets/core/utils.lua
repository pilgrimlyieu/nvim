local M = {}

---Shallow-copy defaults, then apply overrides; neither input is modified.
---@generic T: table
---@param defaults T
---@param overrides? table
---@return T
function M.table_extend(defaults, overrides)
  return vim.tbl_extend("force", defaults, overrides or {})
end

return M

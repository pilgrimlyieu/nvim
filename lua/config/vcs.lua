local M = {}

---@param path string?
---@return string?
local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

---@param opts table?
---@return string?
local function start_path(opts)
  opts = opts or {}

  if opts.path then
    return normalize(opts.path)
  end

  local buf = opts.buf
  if buf == nil or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  if vim.api.nvim_buf_is_valid(buf) then
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      local stat = vim.uv.fs_stat(name)
      if stat and stat.type == "file" then
        return normalize(vim.fs.dirname(name))
      end
      return normalize(name)
    end
  end

  local arg = vim.fn.argv(0)
  if type(arg) == "string" and arg ~= "" then
    local stat = vim.uv.fs_stat(arg)
    if stat and stat.type == "file" then
      return normalize(vim.fs.dirname(arg))
    end
    return normalize(arg)
  end

  return normalize(vim.uv.cwd())
end

---@param marker string
---@param opts table?
---@return string?
function M.find_root(marker, opts)
  local path = start_path(opts)
  if not path then
    return nil
  end

  local found = vim.fs.find(marker, { path = path, upward = true })[1]
  return found and normalize(vim.fs.dirname(found)) or nil
end

---@param opts table?
---@return string?
function M.jj_root(opts)
  return M.find_root(".jj", opts)
end

---@param opts table?
---@return string?
function M.git_root(opts)
  return M.find_root(".git", opts)
end

---@param opts table?
---@return boolean
function M.is_jj(opts)
  return M.jj_root(opts) ~= nil
end

---@param opts table?
---@return boolean
function M.is_git(opts)
  return M.git_root(opts) ~= nil
end

---@param opts table?
---@return boolean
function M.is_git_only(opts)
  return M.is_git(opts) and not M.is_jj(opts)
end

---@param opts table?
---@return string?
function M.root(opts)
  return M.jj_root(opts) or M.git_root(opts) or start_path(opts)
end

return M

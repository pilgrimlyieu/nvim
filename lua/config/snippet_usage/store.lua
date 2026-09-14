local M = {}
local uv = vim.uv
local lock = require("config.snippet_usage.lock")

---@class SnippetUsageRecord
---@field count integer Non-negative usage count.
---@field last_used integer Non-negative last-used timestamp.

---@alias SnippetUsageFiletypes table<string, SnippetUsageRecord>
---@alias SnippetUsageCounts table<string, SnippetUsageFiletypes>

---@class SnippetUsageData
---@field version 1 Format version. Currently only 1 is accepted.
---@field counts SnippetUsageCounts

---Run `fn` with `fd`, then always close `fd`.
---@generic T
---@param fd integer
---@param fn fun(handle: integer): T
---@return T
local function with_fd(fd, fn)
  local ok, result = pcall(fn, fd)
  local closed, err = uv.fs_close(fd)
  if not ok then
    error(result, 0)
  end
  assert(closed, err)
  return result
end

---Check whether `value` is a non-negative integer.
---@param value any
---@return boolean
local function nonnegative_integer(value)
  return type(value) == "number" and value >= 0 and value % 1 == 0
end

---Read and validate the snippet usage history.
---A missing file yields a fresh empty history. Invalid existing data is never replaced.
---@param path string
---@return SnippetUsageData
function M.read(path)
  local fd, err, code = uv.fs_open(path, "r", 384)
  if not fd then
    if code == "ENOENT" then
      return { version = 1, counts = {} }
    end
    error(err, 0)
  end
  local text = with_fd(fd, function(handle)
    local stat = assert(uv.fs_fstat(handle))
    local contents = assert(uv.fs_read(handle, stat.size, 0))
    assert(#contents == stat.size, "Incomplete snippet usage read")
    return contents
  end)
  local data = vim.json.decode(text)
  assert(type(data) == "table" and data.version == 1 and type(data.counts) == "table", "Invalid snippet usage format")
  for id, filetypes in pairs(data.counts) do
    assert(type(id) == "string" and id ~= "" and type(filetypes) == "table", "Invalid snippet usage identity")
    for ft, row in pairs(filetypes) do
      assert(
        type(ft) == "string"
          and type(row) == "table"
          and nonnegative_integer(row.count)
          and nonnegative_integer(row.last_used),
        "Invalid snippet usage record: " .. id
      )
    end
  end
  return data
end

---Merge a delta into freshly read data.
---The delta table is not aliased or mutated; `data` is mutated in place.
---@param data SnippetUsageData
---@param delta SnippetUsageCounts
---@return SnippetUsageData
function M.merge(data, delta)
  for id, filetypes in pairs(delta) do
    local target = data.counts[id] or {}
    data.counts[id] = target
    for ft, row in pairs(filetypes) do
      local previous = target[ft] or { count = 0, last_used = 0 }
      target[ft] = previous
      previous.count = previous.count + row.count
      previous.last_used = math.max(previous.last_used, row.last_used)
    end
  end
  return data
end

---Persist a usage delta under a non-blocking cross-process lock.
---Writes a temporary file and atomically renames it over `path`.
---@param path string
---@param delta SnippetUsageCounts
---@return boolean committed
---@return string? error `"busy"` if the lock is held, otherwise an error message. If `committed` is true, this may be a post-commit lock release error.
function M.save(path, delta)
  local directory = vim.fs.dirname(path)
  vim.fn.mkdir(directory, "p", "448") -- 448 = 0700
  local release, status, err = lock.try_acquire(vim.fs.joinpath(directory, "stats.lock"))
  if not release then
    return false, status == "busy" and status or err
  end

  local temporary = path .. ".tmp"
  local committed, failure = pcall(function()
    local data = M.merge(M.read(path), delta)
    local text = vim.json.encode(data) .. "\n"
    local fd = assert(uv.fs_open(temporary, "w", 384)) -- 384 = 0600
    with_fd(fd, function(handle)
      local written, write_err = uv.fs_write(handle, text, 0)
      assert(written == #text, write_err or "Incomplete snippet usage write")
      return true -- Fix warning: Annotations specify that a return value is required here.
    end)
    assert(uv.fs_rename(temporary, path))
    -- Nothing fallible belongs after this commit point inside the transaction.
  end)
  if not committed then
    -- This shared temporary path is protected by the same lock as the total.
    uv.fs_unlink(temporary)
  end
  local released, release_err = pcall(function()
    local ok, close_err = release()
    assert(ok, close_err)
  end)
  if not committed then
    return false, tostring(failure)
  end
  return true, not released and tostring(release_err) or nil
end

return M

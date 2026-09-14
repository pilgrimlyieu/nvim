-- One nonblocking kernel lock per save. Keep the sidecar inode across releases.
local platform = jit and jit.os
local M = { available = platform == "Linux" or platform == "Windows" }
local uv = vim.uv
local acquire_handle, close_handle

if M.available then
  local ffi = require("ffi")
  if platform == "Linux" then
    ffi.cdef("int flock(int fd, int operation);")
    local LOCK_EX, LOCK_NB, EAGAIN = 2, 4, 11

    acquire_handle = function(path)
      local fd, err = uv.fs_open(path, "a", 384)
      if not fd then
        return nil, "error", err
      end
      if ffi.C.flock(fd, LOCK_EX + LOCK_NB) ~= 0 then
        local errno = ffi.errno()
        uv.fs_close(fd)
        if errno == EAGAIN then
          return nil, "busy"
        end
        return nil, "error", ("flock failed (errno %d): %s"):format(errno, path)
      end
      return fd
    end
    close_handle = uv.fs_close
  elseif platform == "Windows" then
    ffi.cdef([[
      int __stdcall MultiByteToWideChar(uint32_t code_page, uint32_t flags,
        const char *input, int input_size, uint16_t *output, int output_size);
      void *__stdcall CreateFileW(const uint16_t *name, uint32_t access,
        uint32_t share, void *security, uint32_t disposition, uint32_t flags, void *template_file);
      int __stdcall CloseHandle(void *handle);
      uint32_t __stdcall GetLastError(void);
    ]])
    local kernel32 = ffi.load("kernel32")
    local get_last_error = kernel32.GetLastError
    local INVALID_HANDLE_VALUE = ffi.cast("void *", -1)
    local CP_UTF8, MB_ERR_INVALID_CHARS = 65001, 8
    local GENERIC_READ_WRITE, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL = 0xC0000000, 4, 0x80
    local ERROR_SHARING_VIOLATION = 32

    local function windows_error(operation, code)
      return ("%s failed (Windows error %d)"):format(operation, code)
    end

    acquire_handle = function(path)
      -- The -1 input length includes the terminating NUL in both conversions.
      local length = kernel32.MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, nil, 0)
      if length == 0 then
        return nil, "error", windows_error("MultiByteToWideChar", get_last_error())
      end
      local wide = ffi.new("uint16_t[?]", length)
      if kernel32.MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, wide, length) == 0 then
        return nil, "error", windows_error("MultiByteToWideChar", get_last_error())
      end
      -- share=0 denies competing opens; security=nil makes the handle non-inheritable.
      local handle = kernel32.CreateFileW(wide, GENERIC_READ_WRITE, 0, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nil)
      if handle == INVALID_HANDLE_VALUE then
        local code = get_last_error()
        if code == ERROR_SHARING_VIOLATION then
          return nil, "busy"
        end
        return nil, "error", windows_error("CreateFileW", code) .. ": " .. path
      end
      return handle
    end
    close_handle = function(handle)
      if kernel32.CloseHandle(handle) == 0 then
        return nil, windows_error("CloseHandle", get_last_error())
      end
      return true
    end
  end
end

---The caller must release after both successful and failed transactions.
---@param path string
---@return function? release
---@return string? status
---@return string? error
function M.try_acquire(path)
  if not M.available then
    return nil, "error", "Snippet usage requires Linux/WSL or Windows with LuaJIT"
  end

  local handle, status, err = acquire_handle(path)
  if not handle then
    return nil, status, err
  end

  return function()
    if not handle then
      return true
    end
    local owned = handle
    handle = nil
    -- Process death also closes the handle. Never unlink the shared lock file.
    return close_handle(owned)
  end
end

return M

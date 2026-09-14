-- State lives outside config.snippets.*, which the snippet reload command clears.
local M = { SAVE_INTERVAL_MS = 5 * 60 * 1000, EXIT_SAVE_WAIT_MS = 200 }
local store = require("config.snippet_usage.store")
local lock = require("config.snippet_usage.lock")
local ls = require("luasnip")
local path = vim.fs.joinpath(vim.fn.stdpath("state"), "snippet-usage", "stats.json")
local config = vim.fn.stdpath("config")
local windows = jit and jit.os == "Windows"
local function source_path(file)
  return windows and vim.fs.normalize(file, { expand_env = false }) or file
end
local source_roots = {}
for _, directory in ipairs({ config .. "/lua/snippets", config .. "/lua/config/snippets" }) do
  -- Loaders resolve links, while required helper modules can retain the configured path.
  local logical = vim.fs.normalize(directory, { expand_env = false })
  local resolved = source_path(vim.uv.fs_realpath(directory) or logical)
  source_roots[#source_roots + 1] = resolved .. "/"
  if logical ~= resolved then
    source_roots[#source_roots + 1] = logical .. "/"
  end
end
---@type SnippetUsageCounts
local pending = {}
local timer, last_error
local initialized, exiting = false, false

local function report(err)
  if err == last_error then
    return
  end
  last_error = err
  if err then
    vim.schedule(function()
      vim.notify(err, vim.log.levels.WARN, { title = "Snippet usage" })
    end)
  end
end

function M.flush()
  if next(pending) == nil then
    return true
  end
  -- The short save transaction is synchronous: pending cannot change mid-save.
  local ok, committed, err = pcall(store.save, path, pending)
  if not ok then
    err, committed = tostring(committed), false
  end
  if committed then
    pending = {}
    report(err)
  elseif err ~= "busy" then
    report(err)
  end
  return committed, err
end

local function schedule_save()
  if timer or exiting or next(pending) == nil then
    return
  end
  timer = vim.defer_fn(function()
    timer = nil
    if not exiting then
      M.flush()
      schedule_save()
    end
  end, M.SAVE_INTERVAL_MS)
end

local function record()
  local snippet = ls.session.event_node
  local source = ls.snippet_source.get(snippet)
  if not source then
    return
  end
  local file = source_path(source.file)
  local own = false
  for _, root in ipairs(source_roots) do
    if file:sub(1, #root) == root then
      own = true
      break
    end
  end
  if not own then
    return
  end

  local id = snippet.key or snippet.name or snippet.trigger
  assert(type(id) == "string" and id ~= "", "Snippet usage needs a nonempty name or key")
  local ft = vim.bo.filetype
  pending[id] = pending[id] or {}
  local row = pending[id][ft] or { count = 0 }
  pending[id][ft] = row
  row.count = row.count + 1
  row.last_used = os.time()
  schedule_save()
end

function M.show()
  if not lock.available then
    vim.notify("Snippet usage requires Linux/WSL or Windows with LuaJIT", vim.log.levels.INFO)
    return
  end
  local ok, data = pcall(store.read, path)
  if not ok then
    report(tostring(data))
    return
  end
  store.merge(data, pending)
  local rows = {}
  for id, filetypes in pairs(data.counts) do
    for ft, row in pairs(filetypes) do
      rows[#rows + 1] = { id = id, ft = ft, count = row.count, last_used = row.last_used }
    end
  end
  table.sort(rows, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.id == b.id and a.ft < b.ft or a.id < b.id
  end)
  local lines = {
    "Snippet usage — 累计次数（包含本进程尚未保存的计数）",
    "",
    "   次数  最近使用          文件类型    Snippet",
  }
  for _, row in ipairs(rows) do
    lines[#lines + 1] = ("%7d  %s  %-10s  %s"):format(
      row.count,
      os.date("%Y-%m-%d %H:%M", row.last_used),
      row.ft ~= "" and row.ft or "(none)",
      row.id
    )
  end
  if #rows == 0 then
    lines[#lines + 1] = "还没有使用记录。"
  end
  vim.cmd("botright 12new")
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].buflisted = false
  vim.bo[buffer].swapfile = false
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer, silent = true })
end

local function on_exit()
  exiting = true
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  timer = nil
  if not M.flush() then
    -- Windows can also reject replacement while a short-lived reader holds the target.
    vim.wait(M.EXIT_SAVE_WAIT_MS, M.flush, 10)
  end
  if next(pending) then
    vim.notify("退出前未能保存剩余的 snippet 计数", vim.log.levels.WARN, { title = "Snippet usage" })
  end
end

function M.setup()
  if initialized then
    return
  end
  initialized = true
  vim.api.nvim_create_user_command("SnippetStats", M.show, { desc = "Show cumulative snippet usage" })
  if not lock.available then
    return
  end
  local group = vim.api.nvim_create_augroup("config_snippet_usage", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LuasnipPreExpand",
    callback = function()
      local ok, err = pcall(record)
      if not ok then
        report(tostring(err))
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = on_exit })
end

return M

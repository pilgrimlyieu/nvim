local M = {}

-- Fullwidth ASCII is handled below; these Chinese forms need explicit aliases.
local extra = {
  ["."] = { "。" },
  ["["] = { "【" },
  ["]"] = { "】" },
  ["<"] = { "《", "〈" },
  [">"] = { "》", "〉" },
  ["'"] = { "‘", "’", "「", "」" },
  ['"'] = { "“", "”", "『", "』" },
}

---Extend Flash's character motions through its public dynamic config callback.
---Flash builds a fresh `search.mode` per invocation, so no re-wrap guard is needed.
---@param opts Flash.State.Config
function M.flash_char(opts)
  local mode = opts.search.mode
  if type(mode) ~= "function" then
    return
  end

  local function punctuation_mode(input)
    -- Letters, digits, and explicitly typed Unicode still match literally.
    if #input ~= 1 or not input:match("%p") then
      return mode(input)
    end

    -- U+FF01..U+FF5E are the fullwidth counterparts of ASCII ! through ~.
    local patterns = { mode(input), mode(vim.fn.nr2char(input:byte() + 0xFEE0)) }
    for _, char in ipairs(extra[input] or {}) do
      patterns[#patterns + 1] = mode(char)
    end
    -- Combine complete patterns so Flash retains t/T offsets and line limits.
    return [[\m\%(]] .. table.concat(patterns, [[\m\|]]) .. [[\m\)]]
  end

  opts.search.mode = punctuation_mode
end

return M

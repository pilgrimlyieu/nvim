local custom = {}

-- Define each pair once, together with its ASCII and Unicode identifiers.
for pair, ids in pairs({
  ["（）"] = { "p", "（", "）" },
  ["【】"] = { "k", "【", "】" },
  ["《》"] = { "j", "《", "》" },
  ["「」"] = { "u", "「", "」", "‘", "’" },
  ["『』"] = { "U", "『", "』", "“", "”" },
}) do
  local left = vim.fn.strcharpart(pair, 0, 1)
  local right = vim.fn.strcharpart(pair, 1, 1)
  local spec = {
    input = { left .. "().-()" .. right },
    output = { left = left, right = right },
  }
  for _, id in ipairs(ids) do
    custom[id] = spec
  end
end

-- Extend input only: mini.surround keeps its builtin ASCII output and spacing.
for ascii, chinese in pairs({
  ["()"] = { "（）" },
  ["[]"] = { "【】" },
  ["<>"] = { "《》", "〈〉" },
}) do
  for i = 1, 2 do
    local extraction = i == 1 and "^.%s*().-()%s*.$" or "^.().*().$"
    local alternatives = { { "%b" .. ascii, extraction } } ---@type (string|string[])[]
    local inner = i == 1 and "%s*().-()%s*" or "().-()"
    for _, pair in ipairs(chinese) do
      -- Full Unicode delimiters, not byte-oriented Lua character classes.
      local left, right = vim.fn.strcharpart(pair, 0, 1), vim.fn.strcharpart(pair, 1, 1)
      alternatives[#alternatives + 1] = left .. inner .. right
    end
    custom[ascii:sub(i, i)] = { input = { alternatives } }
  end
end

custom["'"] = { input = { { "'().-()'", "‘().-()’", "「().-()」" } } }
custom['"'] = { input = { { '"().-()"', "“().-()”", "『().-()』" } } }

return {
  {
    "nvim-mini/mini.surround",
    opts = {
      custom_surroundings = custom,
      mappings = {
        add = "Sa",
        delete = "Sd",
        find = "Sf",
        find_left = "SF",
        highlight = "Sh",
        replace = "Sr",
      },
      search_method = "cover_or_nearest",
    },
  },
}

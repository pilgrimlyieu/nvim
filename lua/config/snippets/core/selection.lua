---Read LuaSnip selection variables; no snippet construction.
local M = {}

---Return whether a string or line list contains any text.
---@param value string|string[]?
---@return boolean
local function has_text(value)
  if type(value) == "string" then
    return value ~= ""
  end

  if type(value) == "table" then
    return #value > 1 or (value[1] ~= nil and value[1] ~= "")
  end

  return false
end

---Return the visual selection with common indentation removed.
---Relative indentation is preserved; the destination node supplies its own indent.
---@param snip SnipParent
---@param default? string|string[]
---@return string[]
function M.lines(snip, default)
  local env = snip.snippet.env
  local selected = env.LS_SELECT_DEDENT
  -- LuaSnip supplies {} for an unset variable, including raw-only env overrides.
  if selected == nil or (type(selected) == "table" and #selected == 0) then
    selected = env.LS_SELECT_RAW or env.TM_SELECTED_TEXT
  end

  if has_text(selected) then
    if type(selected) == "table" then
      return selected
    end
    ---@diagnostic disable-next-line: param-type-mismatch -- `has_text` already checks for non-string tables.
    return vim.split(selected, "\n", { plain = true })
  end

  if type(default) == "table" then
    return default
  end

  if type(default) == "string" and default ~= "" then
    return vim.split(default, "\n", { plain = true })
  end

  return { "" }
end

return M

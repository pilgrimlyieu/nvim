---Runtime switches for large or situational snippet groups.
---
---All groups default to enabled so the migrated UltiSnips behaviour stays
---available.  Override them before LuaSnip loads, for example in
---`lua/config/options.lua`:
---
---```lua
---vim.g.config_snippet_groups = {
---  course = false,
---  latex_extra = false,
---}
---```
---
---Disabled groups are not required and their snippet constructors are not run.
---That keeps low-use collections out of the first filetype load path.

local M = {}

---@class ConfigSnippetGroupDefaults
---@field algorithms boolean Algorithm/textbook helper snippets.
---@field chemistry boolean Chemistry snippets that depend on VimTeX chem scope.
---@field course boolean Course-specific snippets and templates.
---@field latex_core boolean Core Markdown/TeX LaTeX math snippets.
---@field latex_extra boolean Large low-frequency LaTeX math migration group.
---@field markdown_math_reference boolean Markdown math reference blocks.
---@field typst_math boolean Typst math snippets.
---@field typst_text boolean Typst text snippets.

---@class ConfigSnippetGroupOverrides
---@field algorithms? boolean Algorithm/textbook helper snippets.
---@field chemistry? boolean Chemistry snippets that depend on VimTeX chem scope.
---@field course? boolean Course-specific snippets and templates.
---@field latex_core? boolean Core Markdown/TeX LaTeX math snippets.
---@field latex_extra? boolean Large low-frequency LaTeX math migration group.
---@field markdown_math_reference? boolean Markdown math reference blocks.
---@field typst_math? boolean Typst math snippets.
---@field typst_text? boolean Typst text snippets.

---@type ConfigSnippetGroupDefaults
local defaults = {
  algorithms = true,
  chemistry = true,
  course = true,
  latex_core = true,
  latex_extra = true,
  markdown_math_reference = true,
  typst_math = true,
  typst_text = true,
}

---Merge user overrides with default group switches.
---@param overrides? ConfigSnippetGroupOverrides
---Reload group switches from `vim.g.config_snippet_groups`.
---@return ConfigSnippetGroupDefaults
local function resolve(overrides)
  local values = {}
  for name, enabled in pairs(defaults) do
    values[name] = enabled
  end

  if type(overrides) ~= "table" then
    return values
  end

  for name, enabled in pairs(overrides) do
    values[name] = enabled ~= false
  end

  return values
end

---Return a copy of the currently resolved group switches.
---@return ConfigSnippetGroupDefaults
function M.refresh()
  local value = vim.g.config_snippet_groups
  M.values = resolve(value)
  return M.values
end

---@type ConfigSnippetGroupDefaults
M.values = resolve(vim.g.config_snippet_groups)

---@return ConfigSnippetGroupDefaults
function M.snapshot()
  local values = {}
  for name, enabled in pairs(M.values) do
    values[name] = enabled
  end
  return values
end

return M

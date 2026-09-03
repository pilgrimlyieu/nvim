---All groups are enabled unless explicitly disabled in `vim.g.config_snippet_groups`.
---Read on each collection load so the reload key also picks up changed settings.
---@alias SnipGroup "latex_core"|"latex_extra"|"markdown_math_reference"|"typst_math"|"typst_text"
---@param group SnipGroup
---@return boolean
return function(group)
  local overrides = vim.g.config_snippet_groups or {}
  return overrides[group] ~= false
end

---Shared entry vocabulary. Language script modules own syntax and input normalization.
---@class SnipFixedScriptRule
---@field trigger string
---@field name string
---@field value? string Shared spelling; otherwise both native spellings are provided.
---@field latex? string Native LaTeX value before script grouping.
---@field typst? string Native Typst value before script grouping.
---@field auto? boolean Automatic entry; defaults to manual.
---TODO: add "marker" field if needed.

return {
  manual = {
    { trigger = "''", name = "derivative order", marker = "^", body = "(<>)" },
    { trigger = ",", name = "subscript", marker = "_" },
    { trigger = "'", name = "superscript", marker = "^" },
  },
  edit = {
    { trigger = "sb", name = "edit subscript", marker = "_" },
    { trigger = "sp", name = "edit superscript", marker = "^" },
  },
  ---@type SnipFixedScriptRule[]
  fixed = {
    { trigger = "sq", name = "square", value = "2" },
    { trigger = "cb", name = "cube", value = "3" },
    { trigger = "inv", name = "inverse", value = "-1" },
    { trigger = "trp", name = "transpose", latex = [[\intercal]], typst = "top" },
    { trigger = "^tt", name = "transpose", latex = [[\intercal]], typst = "top", auto = true },
  },
  quick = {
    { pattern = ",([%a%d])$", name = "quick subscript", marker = "_" },
    { pattern = "'([%a%d%-])$", name = "quick superscript", marker = "^" },
  },
}

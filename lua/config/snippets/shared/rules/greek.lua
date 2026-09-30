---Shared symbol tables for snippet builders.
---
---This module intentionally stores only data.  LaTeX, Markdown, and Typst
---builders still decide how each symbol is rendered because their math syntax
---is not interchangeable.
local M = {}

---@class SnipSymbol
---@field trigger string Trigger typed by the user.
---@field output string Text inserted by the snippet.

---Create a symbol table entry with a generated default output.
---@param trigger string
---@param output? string
---@return SnipSymbol
local function symbol(trigger, output)
  return { trigger = trigger, output = output or trigger }
end

local greek_names = {
  "alpha",
  "beta",
  "gamma",
  "delta",
  "epsilon",
  "zeta",
  "eta",
  "theta",
  "iota",
  "kappa",
  "lambda",
  "mu",
  "nu",
  "xi",
  "omicron",
  "pi",
  "rho",
  "sigma",
  "tau",
  "upsilon",
  "phi",
  "chi",
  "psi",
  "omega",
}

local markdown_greek_variants = {
  "varepsilon",
  "varkappa",
  "vartheta",
  "varpi",
  "varrho",
  "varsigma",
  "varphi",
}

local latex_long_overrides = {
  epsilon = "varepsilon",
  phi = "varphi",
}

---Return the preferred LaTeX command name for a Greek text alias.
---@param name string
---@return string
function M.latex_greek_command(name)
  return latex_long_overrides[name] or name
end

local short_greek = {
  symbol("a", "alpha"),
  symbol("b", "beta"),
  symbol("g", "gamma"),
  symbol("d", "delta"),
  symbol("ep", "epsilon"),
  symbol("z", "zeta"),
  symbol("e", "eta"),
  symbol("t", "theta"),
  symbol("i", "iota"),
  symbol("k", "kappa"),
  symbol("l", "lambda"),
  symbol("m", "mu"),
  symbol("n", "nu"),
  symbol("x", "xi"),
  symbol("pi", "pi"),
  symbol("r", "rho"),
  symbol("s", "sigma"),
  symbol("u", "upsilon"),
  symbol("ph", "phi"),
  symbol("ps", "psi"),
  symbol("o", "omega"),
}

---Capitalize the first ASCII letter of a string, leaving the rest unchanged.
---@param name string
---@return string
local function capitalize(name)
  return (name:gsub("^%l", string.upper))
end

---Greek names that Markdown text-mode snippets wrap as `$\<name>$`.
---@type string[]
M.markdown_inline_greek = vim.list_extend(vim.deepcopy(greek_names), markdown_greek_variants)

---Long Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_long_greek = {}

---Uppercase Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_upper_greek = {}

for _, name in ipairs(greek_names) do
  local upper = capitalize(name)
  M.latex_long_greek[#M.latex_long_greek + 1] = symbol(name, M.latex_greek_command(name))
  M.latex_upper_greek[#M.latex_upper_greek + 1] = symbol(upper)
  M.markdown_inline_greek[#M.markdown_inline_greek + 1] = upper
end

---Copy entries as well as the list so extending either language stays independent.
---Backslash-prefixed short Greek triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_short_greek = vim.deepcopy(short_greek)
M.latex_short_greek[#M.latex_short_greek + 1] = symbol("ve", "varepsilon")
M.latex_short_greek[#M.latex_short_greek + 1] = symbol("vp", "varphi")

---Semicolon-prefixed short Greek autosnippet triggers for Typst math zones.
---@type SnipSymbol[]
M.typst_short_greek = vim.deepcopy(short_greek)

return M

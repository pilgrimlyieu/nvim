---Shared symbol tables for snippet builders.
---
---This module intentionally stores only data.  LaTeX, Markdown, and Typst
---builders still decide how each symbol is rendered because their math syntax
---is not interchangeable.
local M = {}

---@class SnipSymbol
---@field trigger string Trigger typed by the user.
---@field output string Text inserted by the snippet.

---@class SnipMathStyle
---@field trigger string Trigger typed by the user.
---@field desc string Human-readable snippet name suffix.
---@field latex? string LaTeX command without braces, such as `\mathbb`.
---@field typst? string Typst math function, such as `bb`.

---Create a symbol table entry with a generated default output.
---@param trigger string
---@param output? string
---@return SnipSymbol
local function symbol(trigger, output)
  return {
    trigger = trigger,
    output = output or trigger,
  }
end

---Return a copy of symbol entries so callers can extend safely.
---@param source SnipSymbol[]
---@return SnipSymbol[]
local function copy_symbols(source)
  local result = {}
  for _, item in ipairs(source) do
    result[#result + 1] = symbol(item.trigger, item.output)
  end
  return result
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

---Greek names that Markdown text-mode snippets wrap as `$\<name>$`.
---@type string[]
M.markdown_inline_greek = {}
for _, name in ipairs(greek_names) do
  M.markdown_inline_greek[#M.markdown_inline_greek + 1] = name
end
for _, name in ipairs(markdown_greek_variants) do
  M.markdown_inline_greek[#M.markdown_inline_greek + 1] = name
end
for _, name in ipairs(greek_names) do
  M.markdown_inline_greek[#M.markdown_inline_greek + 1] = name:gsub("^%l", string.upper)
end

---Long Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_long_greek = {}
for _, name in ipairs(greek_names) do
  M.latex_long_greek[#M.latex_long_greek + 1] = symbol(name, M.latex_greek_command(name))
end

---Uppercase Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_upper_greek = {}
for _, name in ipairs(greek_names) do
  local upper = name:gsub("^%l", string.upper)
  M.latex_upper_greek[#M.latex_upper_greek + 1] = symbol(upper)
end

---Backslash-prefixed short Greek triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_short_greek = copy_symbols(short_greek)
M.latex_short_greek[#M.latex_short_greek + 1] = symbol("ve", "varepsilon")
M.latex_short_greek[#M.latex_short_greek + 1] = symbol("vp", "varphi")

---Semicolon-prefixed short Greek autosnippet triggers for Typst math zones.
---@type SnipSymbol[]
M.typst_short_greek = copy_symbols(short_greek)

---Shared style trigger metadata.  Commands stay language-specific.
---@type SnipMathStyle[]
M.math_styles = {
  { trigger = "rm", desc = "roman", latex = [[\mathrm]], typst = "upright" },
  { trigger = "bb", desc = "blackboard", latex = [[\mathbb]], typst = "bb" },
  { trigger = "bf", desc = "bold", latex = [[\mathbf]], typst = "bold" },
  { trigger = "cal", desc = "calligraphic", latex = [[\mathcal]], typst = "cal" },
  { trigger = "it", desc = "italic", latex = [[\mathit]], typst = "italic" },
  { trigger = "sf", desc = "sans", latex = [[\mathsf]], typst = "sans" },
  { trigger = "fra", desc = "fraktur alias", latex = [[\mathfrak]], typst = "frak" },
  { trigger = "frak", desc = "fraktur", latex = [[\mathfrak]], typst = "frak" },
  { trigger = "scr", desc = "script", latex = [[\mathscr]], typst = "scr" },
  { trigger = "mono", desc = "monospace", typst = "mono" },
}

return M

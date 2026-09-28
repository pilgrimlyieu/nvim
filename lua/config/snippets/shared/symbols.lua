---Shared symbol tables for snippet builders.
---
---This module intentionally stores only data.  LaTeX, Markdown, and Typst
---builders still decide how each symbol is rendered because their math syntax
---is not interchangeable.
local M = {}

local constructors = require("config.snippets.core.constructors")
local utils = require("config.snippets.core.utils")

local literal_autosnippet = constructors.literal_autosnippet
local word_autosnippet = constructors.word_autosnippet
local append_all = utils.append_all
local map_list = utils.map_list

---@class SnipSymbol
---@field trigger string Trigger typed by the user.
---@field output string Text inserted by the snippet.

---@class SnipMathStyle
---@field trigger string Trigger typed by the user.
---@field name string Human-readable snippet name suffix.
---@field latex? string LaTeX command without braces, such as `\mathbb`.
---@field typst? string Typst math function, such as `bb`.

---Create a symbol table entry with a generated default output.
---@param trigger string
---@param output? string
---@return SnipSymbol
local function symbol(trigger, output)
  return { trigger = trigger, output = output or trigger }
end

---Return a copy of symbol entries so callers can extend safely.
---@param source SnipSymbol[]
---@return SnipSymbol[]
local function copy_symbols(source)
  return map_list(source, function(item)
    return symbol(item.trigger, item.output)
  end)
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
M.markdown_inline_greek = append_all({}, greek_names)
M.markdown_inline_greek = append_all(M.markdown_inline_greek, markdown_greek_variants)
M.markdown_inline_greek = append_all(M.markdown_inline_greek, greek_names, capitalize)

---Long Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_long_greek = map_list(greek_names, function(name)
  return symbol(name, M.latex_greek_command(name))
end)

---Uppercase Greek autosnippet triggers for LaTeX math zones.
---@type SnipSymbol[]
M.latex_upper_greek = map_list(greek_names, function(name)
  return symbol(capitalize(name))
end)

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
  { trigger = "rm", name = "roman", latex = [[\mathrm]], typst = "upright" },
  { trigger = "bb", name = "blackboard", latex = [[\mathbb]], typst = "bb" },
  { trigger = "bf", name = "bold", latex = [[\mathbf]], typst = "bold" },
  { trigger = "cal", name = "calligraphic", latex = [[\mathcal]], typst = "cal" },
  { trigger = "it", name = "italic", latex = [[\mathit]], typst = "italic" },
  { trigger = "sf", name = "sans", latex = [[\mathsf]], typst = "sans" },
  { trigger = "fra", name = "fraktur alias", latex = [[\mathfrak]], typst = "frak" },
  { trigger = "frak", name = "fraktur", latex = [[\mathfrak]], typst = "frak" },
  { trigger = "scr", name = "script", latex = [[\mathscr]], typst = "scr" },
  { trigger = "mono", name = "monospace", typst = "mono" },
}

---@class SymbolAliasRule
---@field trigger string|string[]
---@field name string
---@field latex? string
---@field latex_name? string
---@field typst? string
---@field typst_name? string
---@field opts? SnipOptions
---@field append_space? boolean Append a space after the snippet output.  Defaults to true.

---Compile pure per-language symbol rules once when a collection is loaded.
---@param rules SymbolAliasRule[]
---@param language string
---@param condition SnipCondition
---@return LuaSnip.Snippet[]
function M.symbol_autosnippets(rules, language, condition)
  local result = {}
  local name_field = language .. "_name"

  for _, rule in ipairs(rules) do
    local output = rule[language]
    if output then
      if rule.append_space ~= false then
        output = output .. " "
      end
      local build = (rule.opts and rule.opts.wordTrig == false) and literal_autosnippet or word_autosnippet
      local name = rule[name_field] or rule.name
      local trigger = rule.trigger
      local triggers = type(trigger) == "table" and trigger or { trigger } ---@type string[]

      for _, trig in ipairs(triggers) do
        result[#result + 1] = build(trig, output, name .. " '" .. trig .. "'", condition, rule.opts)
      end
    end
  end

  return result
end

return M

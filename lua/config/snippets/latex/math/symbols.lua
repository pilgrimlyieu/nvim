---LaTeX symbols; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")

local aliases = require("config.snippets.shared.aliases")
local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local symbols = require("config.snippets.shared.symbols")

local s = ls.snippet
local t = ls.text_node

local literal_snippet = constructors.literal_snippet
local symbol_autosnippets = symbols.symbol_autosnippets
local with_condition = conditions.with_condition
local word_autosnippet = constructors.word_autosnippet

function M.snippets()
  local condition = conditions.math

  local snippets = {}

  local literal_snippets = {
    { "in", [[\in ]], "in" },
    { "aleph", [[\aleph]], "aleph" },
    { "alef", [[\aleph]], "aleph alias" },
    { "re", [[\Re ]], "real part" },
    { "im", [[\Im ]], "imaginary part" },
  }

  for _, item in ipairs(literal_snippets) do
    table.insert(snippets, literal_snippet(item[1], item[2], item[3], condition))
  end

  for _, greek in ipairs(symbols.latex_short_greek) do
    table.insert(
      snippets,
      s(
        with_condition(
          { trig = "\\" .. greek.trigger, name = "short greek " .. greek.trigger, wordTrig = false },
          condition
        ),
        t("\\" .. greek.output)
      )
    )
  end

  return snippets
end

function M.autosnippets()
  local condition = conditions.math

  local autos = {}

  vim.list_extend(autos, symbol_autosnippets(aliases, "latex", condition))

  for _, greek in ipairs(symbols.latex_long_greek) do
    table.insert(autos, word_autosnippet(greek.trigger, "\\" .. greek.output, "greek " .. greek.trigger, condition))
  end

  for _, greek in ipairs(symbols.latex_upper_greek) do
    table.insert(
      autos,
      word_autosnippet(greek.trigger, "\\" .. greek.output, "upper greek " .. greek.trigger, condition)
    )
  end

  return autos
end

return M

---LaTeX sequences; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

local conditions = require("config.snippets.core.conditions")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local with_condition = conditions.with_condition

---Render a small integer as kern-adjusted Roman numerals.
---@param number integer
---@return string?
local function roman(number)
  if number > 1666 then
    return nil
  end

  local numerals = {
    { 1000, "M" },
    { 900, "CM" },
    { 500, "D" },
    { 400, "CD" },
    { 100, "C" },
    { 90, "XC" },
    { 50, "L" },
    { 40, "XL" },
    { 10, "X" },
    { 9, "IX" },
    { 5, "V" },
    { 4, "IV" },
    { 1, "I" },
  }
  local result = {}

  for _, item in ipairs(numerals) do
    local value, glyph = item[1], item[2]
    while number >= value do
      for index = 1, #glyph do
        result[#result + 1] = glyph:sub(index, index)
      end
      number = number - value
    end
  end

  return table.concat(result, [[\kern{-0.1em}]])
end

function M.snippets()
  local condition = conditions.math

  local snippets = {
    s(
      with_condition({ trig = ",i=", name = "given i", wordTrig = false }, condition),
      fmta([[,\,i=<>, <>, \dots, <>. <>]], { i(1, "1"), i(2, "2"), i(3, "n"), i(0) })
    ),
    s(
      with_condition({ trig = "dot", name = "indexed sequence" }, condition),
      fmta([[<>_1, <>_2, \dots, <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot.", name = "indexed sequence with thin spaces" }, condition),
      fmta([[<>_1,\, <>_2,\, \dots,\, <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot;", name = "semicolon indexed sequence" }, condition),
      fmta([[<>_1; <>_2; \dots; <>_n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1", name = "short indexed sequence" }, condition),
      fmta([[<>_1, \dots, <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1.", name = "short indexed sequence with thin spaces" }, condition),
      fmta([[<>_1,\, \dots,\, <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "dot_1;", name = "short semicolon indexed sequence" }, condition),
      fmta([[<>_1; \dots; <>_n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp", name = "upper indexed sequence" }, condition),
      fmta([[<>^1, <>^2, \dots, <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp.", name = "upper indexed sequence with thin spaces" }, condition),
      fmta([[<>^1,\, <>^2,\, \dots,\, <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp;", name = "semicolon upper indexed sequence" }, condition),
      fmta([[<>^1; <>^2; \dots; <>^n]], { i(1), rep(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1", name = "short upper indexed sequence" }, condition),
      fmta([[<>^1, \dots, <>^n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1.", name = "short upper indexed sequence with thin spaces" }, condition),
      fmta([[<>^1,\, \dots,\, <>^n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "upp_1;", name = "short semicolon upper indexed sequence" }, condition),
      fmta([[<>^1; \dots; <>^n]], { i(1), rep(1) })
    ),
    s(
      with_condition({ trig = "zb", name = "plane coordinate" }, condition),
      fmta([[\left(<> , <>\right)]], { i(1), i(2) })
    ),
    s(with_condition({ trig = "(%d%d?%d?%d?)rmn", name = "roman number", trigEngine = "pattern" }, condition), {
      f(function(_, snip)
        local value = tonumber(snip.captures[1])
        local result = value and roman(value)
        return result and "\\mathrm{" .. result .. "}" or snip.captures[1]
      end),
    }),
  }

  return snippets
end

return M

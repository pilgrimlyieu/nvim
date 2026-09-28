---LaTeX operators; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local i = ls.insert_node

local capture = nodes.capture
local capture_nonempty = nodes.capture_nonempty
local captured_insert = nodes.captured_insert
local literal_snippet = constructors.literal_snippet
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local word_autosnippet = constructors.word_autosnippet

local INTEGRAL_TRIGGER_WINDOW = 24 -- compact `2nointx` / `oiiintt`-style triggers.

---Convert old integral trigger text into the LaTeX integral command.
---@param raw string
---@return string?
local function integral_command(raw)
  local count, open = raw:match("^([1-3])n?(o?)int$")
  if count then
    return "\\" .. open .. string.rep("i", tonumber(count) or 1) .. "nt"
  end

  local open_i = raw:match("^n?(o?i+)nt$")
  if open_i then
    return "\\" .. open_i .. "nt"
  end

  return nil
end

---Match multi-integral triggers and separate definite from indefinite forms.
---@param definite boolean
---Captures contain the integral command and its variable.
---@return SnipTriggerEngine
local function integral_engine(definite)
  return function()
    return function(line_to_cursor)
      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - INTEGRAL_TRIGGER_WINDOW))
      local match, raw, variable = text:match("(\\?([1-3]n?o?int[%a]?))$")

      if not raw then
        match, raw, variable = text:match("(\\?(n?o?i+i?nt[%a]?))$")
      end
      if not raw then
        return nil
      end

      local body = raw
      variable = body:match("([%a])$")
      if variable and not body:sub(-3):match("int") and body:sub(-2) ~= "nt" then
        body = body:sub(1, -2)
      else
        variable = ""
      end

      local is_indefinite = body:match("^%d+n") ~= nil or body:match("^n") ~= nil
      if is_indefinite == definite then
        return nil
      end

      if raw == "int" or raw == "nint" then
        return nil
      end

      local command = integral_command(body)
      if not command then
        return nil
      end

      return match, { command, variable ~= "" and variable or "x" }
    end
  end
end

function M.snippets()
  local condition = conditions.math

  local snippets = {
    s(with_condition({ trig = "op", name = "operator" }, condition), fmta([[\operatorname{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "bin", name = "binomial" }, condition),
      fmta([[\dbinom{<>}{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "df", name = "derivative" }, condition),
      fmta([[\dfrac{\d <>}{\d <>}]], { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "pf", name = "partial derivative" }, condition),
      fmta([[\dfrac{\partial <>}{\partial <>}]], { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({ trig = "d([%a])", name = "derivative by variable", trigEngine = "pattern" }, condition),
      fmta([[\dfrac{\d <>}{\d <>}]], { visual_insert(1), capture(1, "x") })
    ),
    s(
      with_condition({ trig = "pd([%a])", name = "partial derivative by variable", trigEngine = "pattern" }, condition),
      fmta([[\dfrac{\partial <>}{\partial <>}]], { visual_insert(1), capture(1, "x") })
    ),
    s(
      with_condition({ trig = "sum", name = "sum" }, condition),
      fmta([[\sum_{<>=<>}^{<>} ]], { i(1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "sum([%a])", name = "sum by variable", trigEngine = "pattern" }, condition),
      fmta([[\sum_{<>=<>}^{<>} ]], { captured_insert(1, 1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "prod", name = "product" }, condition),
      fmta([[\prod_{<>=<>}^{<>} ]], { i(1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "prod([%a])", name = "product by variable", trigEngine = "pattern" }, condition),
      fmta([[\prod_{<>=<>}^{<>} ]], { captured_insert(1, 1, "i"), i(2, "1"), i(3, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "lim", name = "limit" }, condition),
      fmta([[\lim\limits_{<> \to <>} ]], { i(1, "x"), i(2, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "lim([%a])", name = "limit by variable", trigEngine = "pattern" }, condition),
      fmta([[\lim\limits_{<> \to <>} ]], { captured_insert(1, 1, "x"), i(2, [[\infty]]) })
    ),
    s(
      with_condition({ trig = "int", name = "definite integral" }, condition),
      fmta([[\int_{<>}^{<>} <> \d <>]], { i(1, "0"), i(2, [[\infty]]), visual_insert(3), i(4, "x") })
    ),
    s(
      with_condition({ trig = "nint", name = "indefinite integral" }, condition),
      fmta([[\int <> \d <>]], { visual_insert(1), i(2, "x") })
    ),
    s(
      with_condition({
        trig = "definite-integral-variant",
        name = "definite integral variant",
        trigEngine = integral_engine(true),
        wordTrig = false,
      }, condition),
      fmta(
        [[<>_{<>}^{<>} <> \d <>]],
        { capture_nonempty(1), i(1, "0"), i(2, [[\infty]]), i(3), capture_nonempty(2, "x") }
      )
    ),
    s(
      with_condition({
        trig = "indefinite-integral-variant",
        name = "indefinite integral variant",
        trigEngine = integral_engine(false),
        wordTrig = false,
      }, condition),
      fmta([[<> <> \d <>]], { capture_nonempty(1), i(1), capture_nonempty(2, "x") })
    ),
    literal_snippet("pp", [[\partial ]], "partial", condition),
    literal_snippet("lts", [[\limits]], "limits", condition, { wordTrig = false }),
  }

  return snippets
end

function M.autosnippets()
  local condition = conditions.math

  local autos = {
    s(
      with_condition({ trig = "_=", name = "long equal", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmta([[\xlongequal[<>]{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition(
        { trig = "_>", name = "long right arrow", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xrightarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition(
        { trig = "_<", name = "long left arrow", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xleftarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition(
        { trig = "_<>", name = "long left arrow alias", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      fmta([[\xleftarrow[<>]{<>}]], { i(1), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "|_>", name = "long mapsto", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmta([[\xmapsto{<>}]], { visual_insert(1) })
    ),
  }

  local common_functions = {
    "sin",
    "cos",
    "tan",
    "ln",
    "lg",
    "log",
    "max",
    "min",
    "arg",
    "det",
    "exp",
    "csc",
    "sec",
    "arcsin",
    "arccos",
    "arctan",
    "sinh",
    "cosh",
    "tanh",
    "cot",
    "coth",
    "gcd",
    "sup",
    "inf",
    "diag",
  }

  for _, name in ipairs(common_functions) do
    table.insert(autos, word_autosnippet(name, "\\" .. name, "operator " .. name, condition))
  end

  return autos
end

return M

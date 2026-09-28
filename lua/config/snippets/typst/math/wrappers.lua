---Typst-native feature definitions.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local operand = require("config.snippets.shared.operand")
local symbols = require("config.snippets.shared.symbols")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local operand_engine = operand.engine
local text_choices = nodes.text_choices
local undelimit = operand.undelimit
local ungroup = operand.ungroup
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

---Build one manual postfix wrapper for a complete Typst operand.
---@param trigger string
---@param command string
---@param name string
---@return LuaSnip.Snippet
local function postfix(trigger, command, name)
  return s(
    with_condition(
      { trig = trigger, name = name .. " postfix", trigEngine = operand_engine, wordTrig = false, priority = 1100 },
      conditions.math
    ),
    fmt(command .. "({})", {
      f(function(_, snip)
        return ungroup(snip.captures[1])
      end),
    })
  )
end

local function style_snippet(trigger, command, name, postfix_name)
  local snippets = {
    s(with_condition({ trig = trigger, name = name }, conditions.math), fmt(command .. "({})", { visual_insert(1) })),
  }
  if postfix_name ~= false then
    snippets[#snippets + 1] = postfix(trigger, command, postfix_name or name)
  end
  return snippets
end

function M.snippets()
  local condition = conditions.math
  local snippets = {
    s(
      with_condition({ trig = "sqrt", name = "root" }, condition),
      fmt("root({}, {})", { i(1, "3"), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "root", name = "root (default n)" }, condition),
      fmt("root({}, {})", { i(1, "n"), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "LR", name = "left right delimiters" }, condition),
      fmt("lr({}{}{})", { i(1, "("), visual_insert(2), i(3, ")") })
    ),
    s(
      with_condition({ trig = "op", name = "operator" }, condition),
      fmt([[op("{}", limits: #{})]], { i(1, "lim"), text_choices(2, { "true", "false" }) })
    ),
    s(
      with_condition({ trig = "over", name = "overbrace" }, condition),
      fmt("overbrace({}, {})", { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "under", name = "underbrace" }, condition),
      fmt("underbrace({}, {})", { visual_insert(1), i(2) })
    ),
  }

  -- One rule owns the ordinary wrapper and its manual postfix counterpart.
  for _, def in ipairs({
    -- TODO: Rename to av/bv and add LaTeX-style wrapping previous element autosnipptes.
    { "avec", command = "arrow", name = "arrow vector symbol", postfix = false },
    { "bvec", command = "bold", name = "bold vector symbol", postfix = false },
    { "abs", name = "absolute value", postfix = "abs" },
    { "norm" },
    { "floor" },
    { "ceil" },
    { "round" },
    { "hat" },
    { "bar" },
    { "dot" },
    { "cancel" },
    { "arrow" },
    { "gen", command = "sqrt", name = "square root" },
    { "sin", name = "sine" },
    { "cos", name = "cosine" },
    { "tan", name = "tangent" },
    { "log", name = "logarithm" },
    { "ln", name = "natural logarithm" },
    { "exp", name = "exponential" },
    { "min", name = "minimum" },
    { "max", name = "maximum" },
  }) do
    vim.list_extend(snippets, style_snippet(def[1], def.command or def[1], def.name or def[1], def.postfix))
  end
  snippets[#snippets + 1] = s(
    with_condition(
      { trig = "sqrt", name = "root postfix", trigEngine = operand_engine, wordTrig = false, priority = 1100 },
      condition
    ),
    fmt("root({}, {})", { i(1, "3"), f(function(_, snip)
      return ungroup(snip.captures[1])
    end) })
  )
  snippets[#snippets + 1] =
    s(with_condition({ trig = "set", name = "set enumeration" }, condition), fmt("lr({{{}}})", { visual_insert(1) }))
  snippets[#snippets + 1] = s(
    with_condition({ trig = "setb", name = "set builder" }, condition),
    fmt("lr({{{} | {}}})", { visual_insert(1, "x"), i(2) })
  )

  for _, def in ipairs({ { "paren", "(", ")" }, { "brack", "[", "]" }, { "brace", "{", "}" } }) do
    local function wrapped()
      return { t("lr(" .. def[2]), visual_insert(1), t(def[3] .. ")") }
    end
    snippets[#snippets + 1] = s(with_condition({ trig = def[1], name = def[1] .. " delimiters" }, condition), wrapped())
    snippets[#snippets + 1] = s(
      with_condition(
        { trig = def[1], name = def[1] .. " postfix", trigEngine = operand_engine, wordTrig = false, priority = 1100 },
        condition
      ),
      {
        t("lr(" .. def[2]),
        f(function(_, snip)
          return undelimit(snip.captures[1])
        end),
        t(def[3] .. ")"),
      }
    )
  end

  for _, def in ipairs(symbols.math_styles) do
    if def.typst then
      vim.list_extend(snippets, style_snippet(def.trigger, def.typst, def.name))
    end
  end

  return snippets
end

return M

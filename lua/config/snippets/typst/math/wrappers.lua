---Typst-native feature definitions.
---TODO: make latex/math/wrappers.lua shared, and make here rules-based.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local syntax = require("config.snippets.typst.math.syntax")
local postfix = require("config.snippets.shared.math_postfix")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local operand_engine = postfix.engine
local capture = nodes.capture
local text_choices = nodes.text_choices
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local whole_operand_engine = postfix.whole(syntax)

local function wrapper_pair(trigger, template, name)
  return {
    s(with_condition({ trig = trigger, name = name }, conditions.math), fmta(template, { visual_insert(1) })),
    s(
      with_condition({
        trig = trigger,
        name = name .. " postfix",
        trigEngine = whole_operand_engine,
        wordTrig = false,
        priority = 1100,
      }, conditions.math),
      fmta(template, { capture(1) })
    ),
  }
end

function M.snippets()
  local condition = conditions.math
  local snippets = {
    s(
      with_condition({ trig = "sqrt", name = "root" }, condition),
      fmta("root(<>, <>)", { i(1, "3"), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "root", name = "root (default n)" }, condition),
      fmta("root(<>, <>)", { i(1, "n"), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "LR", name = "left right delimiters" }, condition),
      fmta("lr(<><><>)", { i(1, "("), visual_insert(2), i(3, ")") })
    ),
    s(
      with_condition({ trig = "op", name = "operator" }, condition),
      fmta([[op("<>", limits: #<>)]], { i(1, "lim"), text_choices(2, { "true", "false" }) })
    ),
    s(
      with_condition({ trig = "over", name = "overbrace" }, condition),
      fmta("overbrace(<>, <>)", { visual_insert(1), i(2) })
    ),
    s(
      with_condition({ trig = "under", name = "underbrace" }, condition),
      fmta("underbrace(<>, <>)", { visual_insert(1), i(2) })
    ),
  }

  -- One rule owns the ordinary wrapper and its manual postfix counterpart.
  for _, def in ipairs({
    { "abs", name = "absolute value" },
    { "norm" },
    { "floor" },
    { "ceil" },
    { "round" },
    { "cancel" },
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
    vim.list_extend(snippets, wrapper_pair(def[1], (def.command or def[1]) .. "(<>)", def.name or def[1]))
  end
  snippets[#snippets + 1] = s(
    with_condition(
      { trig = "sqrt", name = "root postfix", trigEngine = whole_operand_engine, wordTrig = false, priority = 1100 },
      condition
    ),
    fmta("root(<>, <>)", { i(1, "3"), capture(1) })
  )
  snippets[#snippets + 1] =
    s(with_condition({ trig = "set", name = "set enumeration" }, condition), fmta("lr({<>})", { visual_insert(1) }))
  snippets[#snippets + 1] = s(
    with_condition({ trig = "setb", name = "set builder" }, condition),
    fmta("lr({<> | <>})", { visual_insert(1, "x"), i(2) })
  )

  for _, def in ipairs({ { "paren", "(", ")" }, { "brack", "[", "]" }, { "brace", "{", "}" } }) do
    local function wrapped()
      return { t("lr(" .. def[2]), visual_insert(1), t(def[3] .. ")") }
    end
    snippets[#snippets + 1] = s(with_condition({ trig = def[1], name = def[1] .. " delimiters" }, condition), wrapped())
    snippets[#snippets + 1] = s(
      with_condition({
        trig = def[1],
        name = def[1] .. " postfix",
        trigEngine = operand_engine(syntax, function(operand)
          if operand.delimiters then
            return { operand.delimiters, operand.source:sub(#operand.base + 1) }
          end
          return { operand.source, "" }
        end),
        wordTrig = false,
        priority = 1100,
      }, condition),
      {
        t("lr(" .. def[2]),
        capture(1),
        t(def[3] .. ")"),
        capture(2),
      }
    )
  end

  return snippets
end

return M

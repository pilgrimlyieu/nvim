---Construct concrete math editing operations with fresh LuaSnip nodes.
---Language features provide native spelling/rendering; recognition stays in their readers.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local postfix = require("config.snippets.shared.math_postfix")
local edits = require("config.snippets.shared.math_edits")
local script_rules = require("config.snippets.shared.rules.scripts")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local with_condition = conditions.with_condition
local capture = nodes.capture
local captured_insert = nodes.captured_insert
local visual_insert = nodes.visual_insert
local operand_engine = postfix.engine
local whole_operand_engine = postfix.whole
local script_field = edits.script

-- Captures: source before this script, editable content, untouched later scripts.
local function script_engine(syntax, marker)
  return operand_engine(syntax, function(operand)
    return { script_field(operand, marker) }
  end)
end

---Replace an existing superscript or append one, retaining all other source.
---The language renders each rule's value with its necessary grouping at load time.
---Fresh nodes follow rule order; each rule declares its own manual/automatic type.
---@param syntax {window: integer, read: fun(source: string): SnipMathOperand?}
---@param render fun(rule: SnipFixedScriptRule): string Native value, without the ^ marker.
---@param priority? integer Omitted means LuaSnip's default priority.
---@return LuaSnip.Snippet[]
local function fixed_superscripts(syntax, render, priority)
  local engine = script_engine(syntax, "^")
  local out = {}
  for _, rule in ipairs(script_rules.fixed) do
    out[#out + 1] = s(
      with_condition({
        trig = rule.trigger,
        name = rule.name,
        trigEngine = engine,
        wordTrig = false,
        priority = priority,
        snippetType = rule.auto and "autosnippet" or "snippet",
      }, conditions.math),
      { capture(1), t("^" .. render(rule)), capture(3) }
    )
  end
  return out
end

---Construct fixed superscripts, selected script entry and script editing in rule order.
---The native template contains one editable field, without a script marker.
---Editing retains all surrounding source and seeds the field from capture 2.
---Each call creates fresh nodes; fixed rules route their manual/automatic type.
---@param syntax {window: integer, read: fun(source: string): SnipMathOperand?}
---@param open string  Left delimiter for the script group.
---@param close string Right delimiter for the script group.
---@param render_fixed fun(rule: SnipFixedScriptRule): string Native value, without the ^ marker.
---@param priority? integer Omitted means LuaSnip's default priority.
---@return LuaSnip.Snippet[]
function M.scripts(syntax, open, close, render_fixed, priority)
  local out = fixed_superscripts(syntax, render_fixed, priority)
  local function template(rule)
    return open .. (rule.body or "<>") .. close
  end
  for _, rule in ipairs(script_rules.manual) do
    out[#out + 1] = s(
      with_condition({
        trig = rule.trigger,
        name = rule.name,
        wordTrig = false,
        priority = priority,
      }, conditions.math),
      fmta(rule.marker .. template(rule), { visual_insert(1) })
    )
  end
  for _, rule in ipairs(script_rules.edit) do
    out[#out + 1] = s(
      with_condition({
        trig = rule.trigger,
        name = rule.name,
        trigEngine = script_engine(syntax, rule.marker),
        wordTrig = false,
        priority = priority,
      }, conditions.math),
      fmta("<>" .. rule.marker .. template(rule) .. "<>", {
        capture(1),
        captured_insert(1, 2, ""),
        capture(3),
      })
    )
  end
  return out
end

---Create the optional editable prefix and the postfix of one decoration.
---The renderer returns native output; matcher/capture construction stays here.
---No nodes are cached.
---@param syntax {window: integer, read: fun(source: string): SnipMathOperand?}
---@param rule SnipDecorationRule
---@param opts SnipDecorationOptions
---@param template string Native fmta template with one editable placeholder.
---@param render fun(operand: SnipMathOperand): string Native decorated output.
---@return LuaSnip.Snippet[]
function M.decoration(syntax, rule, opts, template, render)
  local out = {}
  if opts.prefix ~= false then
    out[#out + 1] = s(
      with_condition({ trig = rule.trigger, name = rule.name }, conditions.math),
      fmta(template, { visual_insert(1) })
    )
  end
  out[#out + 1] = s(
    with_condition({
      trig = rule.trigger,
      name = rule.name .. " postfix",
      docTrig = "a_1^2" .. rule.trigger,
      trigEngine = operand_engine(syntax, function(operand)
        return { render(operand) }
      end),
      wordTrig = false,
      priority = 1100,
      snippetType = opts.auto and "autosnippet" or "snippet",
    }, conditions.math),
    { capture(1) }
  )
  return out
end

---Fraction editing always offers a selected numerator and an editable denominator.
---A postfix captures the complete numerator and selects/edits the denominator.
---@param syntax {window: integer, read: fun(source: string): SnipMathOperand?}
---@param prefix_trigger string
---@param template string Native fmta template with numerator/denominator placeholders.
---@param condition SnipCondition
---@return LuaSnip.Snippet[]
function M.fractions(syntax, prefix_trigger, template, condition)
  return {
    s(
      with_condition({
        trig = prefix_trigger,
        name = "fraction",
        wordTrig = false,
        snippetType = "autosnippet",
      }, condition),
      fmta(template, { visual_insert(1), i(2) })
    ),
    s(
      with_condition({
        trig = "/",
        name = "simple fraction",
        trigEngine = whole_operand_engine(syntax),
        wordTrig = false,
        snippetType = "autosnippet",
      }, condition),
      fmta(template, { capture(1), visual_insert(1) })
    ),
  }
end

return M

---Shared engines for the migrated low-frequency LaTeX snippets.
---
---This module contains reusable trigger engines and node builders only.  The
---public snippet groups live in snippets.lua and autos.lua.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local latex_helpers = require("config.snippets.latex.helpers")
local conditions = require("config.snippets.conditions")
local util = require("config.snippets.util")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node

local ACCENT_NAMES = { "bar", "hat", "vec" }
local SHORT_ACCENT_COMMANDS = {
  bar = [[\bar]],
  hat = [[\hat]],
  vec = [[\vec]],
}
local LONG_ACCENT_COMMANDS = {
  bar = [[\overline]],
  hat = [[\widehat]],
  vec = [[\overrightarrow]],
}
local ACCENT_SPECIAL_TARGETS = {
  i = [[\imath]],
  j = [[\jmath]],
}

-- LuaSnip calls custom trigger engines with the full current line.  These
-- windows keep migrated postfix scans bounded to the old shorthand grammar.
local CYCLE_SUFFIX_WINDOW = 120 -- exact spacing commands plus optional whitespace.
local SLASH_CYCLE_WINDOW = 140 -- command-cycle value, optional suffix, then `/`.
local INTEGRAL_TRIGGER_WINDOW = 24 -- compact `2nointx` / `oiiintt`-style triggers.
local ACCENT_POSTFIX_WINDOW = 80 -- target, optional script, and `bar`/`hat`/`vec`.
local ANGLE_CONTENT_WINDOW = 80 -- one-line `<content>` delimiter shorthand.
local BRACED_COMMAND_WINDOW = 180 -- command cycles that preserve one/two brace groups.
local ANNOTATION_POSTFIX_WINDOW = 80 -- label plus `%^` / `%_` annotation suffix.
local SYMBOLIC_MATRIX_WINDOW = 24 -- symbolic matrix shorthands ending in `.`.

local cap = util.capture_nonempty
local choose_next = util.choose_next
local escape_lua_pattern = util.escape_lua_pattern
local cycle_engine = util.exact_cycle_engine
local sorted_longest_first = util.sorted_longest_first
local visual_insert = util.visual_insert
local with_condition = conditions.with_condition
local matrix_text_lines = latex_helpers.matrix_text_lines

---@param text string
---@param suffix string
---@return boolean
local function ends_with(text, suffix)
  return text:sub(-#suffix) == suffix
end

---@param text string
---@param suffixes string[]
---@return boolean
local function ends_with_any(text, suffixes)
  for _, suffix in ipairs(suffixes) do
    if ends_with(text, suffix) then
      return true
    end
  end
  return false
end

---Match any value at the cursor and preserve trailing whitespace.
---@param values string[]
---@return SnipTriggerEngine
local function suffix_cycle_engine(values)
  local specs = {}
  for _, value in ipairs(sorted_longest_first(values)) do
    specs[#specs + 1] = "(" .. escape_lua_pattern(value) .. ")(%s*)$"
  end

  return function()
    return function(line_to_cursor)
      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - CYCLE_SUFFIX_WINDOW))
      for _, pattern in ipairs(specs) do
        local match, suffix = text:match(pattern)
        if match then
          return match .. suffix, { match, suffix }
        end
      end
      return nil
    end
  end
end

---Match any value followed by `/` for cycle-style autosnippets.
---@param values string[]
---@param suffix_pattern? string
---@return SnipTriggerEngine
local function slash_cycle_engine(values, suffix_pattern)
  local specs = {}
  local suffix = suffix_pattern or "%s*"
  for _, value in ipairs(sorted_longest_first(values)) do
    specs[#specs + 1] = "(" .. escape_lua_pattern(value) .. ")(" .. suffix .. ")/$"
  end

  return function()
    return function(line_to_cursor)
      if not ends_with(line_to_cursor, "/") then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - SLASH_CYCLE_WINDOW))
      for _, pattern in ipairs(specs) do
        local match, matched_suffix = text:match(pattern)
        if match then
          return match .. matched_suffix .. "/", { match, matched_suffix or "" }
        end
      end

      return nil
    end
  end
end

---Build an autosnippet that cycles slash-triggered command variants.
---@param name string
---@param values string[]
---@param suffix_pattern? string
---@return SnipNode
local function slash_cycle_autosnippet(name, values, suffix_pattern)
  return s(
    with_condition({
      trig = name,
      trigEngine = slash_cycle_engine(values, suffix_pattern),
      wordTrig = false,
      name = name,
      snippetType = "autosnippet",
      priority = 1500,
    }, conditions.math),
    {
      f(function(_, snip)
        return choose_next(snip.captures[1], values) .. (snip.captures[2] or "")
      end),
    }
  )
end

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
---Match postfix accent triggers such as `xbar`, `x_ihat`, or `\alphavec`.
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

---@return SnipTriggerEngine
local function accent_postfix_engine()
  return function()
    return function(line_to_cursor)
      if not ends_with_any(line_to_cursor, ACCENT_NAMES) then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ACCENT_POSTFIX_WINDOW))
      for _, accent in ipairs(ACCENT_NAMES) do
        local target, suffix = text:match("([%a%d\\]+)([_^]%b{})" .. accent .. "$")

        if not target then
          target, suffix = text:match("([%a%d\\]+)([_^][%a%d\\]+)" .. accent .. "$")
        end

        if not target then
          target = text:match("([%a%d\\]+)" .. accent .. "$")
          suffix = ""
        end

        if target then
          return target .. suffix .. accent, { target, suffix or "", accent }
        end
      end

      return nil
    end
  end
end

---Render a postfix accent target with short or wide accent commands.
---@param target string
---@param suffix string
---@param accent string
---@return string
local function accented_postfix(target, suffix, accent)
  local command = SHORT_ACCENT_COMMANDS[accent] or [[\bar]]
  if not target:match("^\\") and #target > 1 then
    command = LONG_ACCENT_COMMANDS[accent] or command
  end

  return command .. "{" .. (ACCENT_SPECIAL_TARGETS[target] or target) .. "}" .. suffix
end

---Match `<content>` so it can be converted to angle delimiters.
---@return SnipTriggerEngine
local function angle_content_engine()
  return function()
    return function(line_to_cursor)
      if not ends_with(line_to_cursor, ">") then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ANGLE_CONTENT_WINDOW))
      local match, content = text:match("(<([^<>]+)>)$")
      if match then
        return match, { content }
      end
      return nil
    end
  end
end

---Build a snippet that cycles exact command spellings in place.
---@param name string
---@param values string[]
---@return SnipNode
local function cycle(name, values)
  return s(
    with_condition({
      trig = name,
      trigEngine = cycle_engine(values),
      wordTrig = false,
      name = name,
    }, conditions.math),
    {
      f(function(_, snip)
        return choose_next(snip.captures[1], values)
      end),
    }
  )
end

---Build a cycle snippet for braced commands while preserving their arguments.
---@param name string
---@param commands string[]
---@param brace_count integer
---@return SnipNode
local function braced_command_cycle(name, commands, brace_count)
  local match_commands = sorted_longest_first(commands)

  local function command_pattern(command)
    local escaped = (command:gsub("([^%w])", "%%%1"))
    return escaped .. string.rep("%b{}", brace_count)
  end

  return s(
    with_condition({
      trig = name,
      trigEngine = function()
        return function(line_to_cursor)
          if brace_count > 0 and not ends_with(line_to_cursor, "}") then
            return nil
          end

          local text = line_to_cursor:sub(math.max(1, #line_to_cursor - BRACED_COMMAND_WINDOW))
          for _, command in ipairs(match_commands) do
            local target = text:match("(" .. command_pattern(command) .. ")$")
            if target then
              return target, { target, command }
            end
          end
          return nil
        end
      end,
      wordTrig = false,
      name = name,
    }, conditions.math),
    {
      f(function(_, snip)
        local target = snip.captures[1] or ""
        local command = snip.captures[2]
        return command and choose_next(command, commands) .. target:sub(#command + 1) or target
      end),
    }
  )
end

---Build annotation autosnippets like overbrace/underbrace with captured label.
---@param name string
---@param suffix_pattern string
---@param suffix_text string
---@param command string
---@param marker string
---@return SnipNode
local function annotation_autosnippet(name, suffix_pattern, suffix_text, command, marker)
  return s(
    with_condition({
      trig = name,
      trigEngine = function()
        return function(line_to_cursor)
          if not ends_with(line_to_cursor, suffix_text) then
            return nil
          end

          local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ANNOTATION_POSTFIX_WINDOW))
          local label = text:match("([%w%d^\\]*)" .. suffix_pattern .. "$")
          if label ~= nil then
            return label .. suffix_text, { label }
          end
          return nil
        end
      end,
      wordTrig = false,
      name = name,
      snippetType = "autosnippet",
    }, conditions.math),
    fmta(command .. [[{<>}]] .. marker .. [[{<>}]], { visual_insert(1), cap(1) })
  )
end

---Render a symbolic matrix entry with row and column subscripts.
---@param prefix string
---@param row string
---@param col string
---@return string
local function indexed(prefix, row, col)
  return ("%s_{%s %s}"):format(prefix, row, col)
end

---Match symbolic matrix shorthand for plain/diagonal/triangular matrices.
---@param kind "plain"|"diag"|"upper"|"lower"
---@return SnipTriggerEngine
local function symbolic_matrix_engine(kind)
  return function()
    return function(line_to_cursor)
      if not ends_with(line_to_cursor, ".") then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - SYMBOLIC_MATRIX_WINDOW))
      local form, row, col, value

      if kind == "plain" then
        form, row, col, value = text:match("([mpbBvV])([%a])([%a])([%a]?)%.$")
        if not form then
          return nil
        end
        return form .. row .. col .. value .. ".", { form, row, col, value ~= "" and value or "a" }
      end

      local prefix = (kind == "diag" and "d" or kind == "upper" and "ut" or "lt")
      form, row, value = text:match(prefix .. "([mpbBvV])([%a])([%a]?)%.$")
      if not form then
        return nil
      end

      local match = prefix .. form .. row .. value .. "."
      return match, { form, row, value ~= "" and value or "a" }
    end
  end
end

---Build a symbolic matrix node from captures produced by the matrix engine.
---@param kind "plain"|"diag"|"upper"|"lower"
---@return SnipNode
local function symbolic_matrix_node(kind)
  return d(1, function(_, snip)
    local form = snip.captures[1]
    local n1 = snip.captures[2]
    local n2 = kind == "plain" and snip.captures[3] or snip.captures[2]
    local value = kind == "plain" and snip.captures[4] or snip.captures[3]

    local rows
    if kind == "diag" then
      rows = {
        ("%s & 0 & \\cdots & 0 \\\\"):format(indexed(value, "1", "1")),
        ("0 & %s & \\cdots & 0 \\\\"):format(indexed(value, "2", "2")),
        "\\vdots & \\vdots & \\ddots & \\vdots \\\\",
        ("0 & 0 & \\cdots & %s"):format(indexed(value, n1, n1)),
      }
    elseif kind == "upper" then
      rows = {
        ("%s & %s & \\cdots & %s \\\\"):format(
          indexed(value, "1", "1"),
          indexed(value, "1", "2"),
          indexed(value, "1", n1)
        ),
        ("0 & %s & \\cdots & %s \\\\"):format(indexed(value, "2", "2"), indexed(value, "2", n1)),
        "\\vdots & \\vdots & \\ddots & \\vdots \\\\",
        ("0 & 0 & \\cdots & %s"):format(indexed(value, n1, n1)),
      }
    elseif kind == "lower" then
      rows = {
        ("%s & 0 & \\cdots & 0 \\\\"):format(indexed(value, "1", "1")),
        ("%s & %s & \\cdots & 0 \\\\"):format(indexed(value, "2", "1"), indexed(value, "2", "2")),
        "\\vdots & \\vdots & \\ddots & \\vdots \\\\",
        ("%s & %s & \\cdots & %s"):format(indexed(value, n1, "1"), indexed(value, n1, "2"), indexed(value, n1, n1)),
      }
    else
      rows = {
        ("%s & %s & \\cdots & %s \\\\"):format(
          indexed(value, "1", "1"),
          indexed(value, "1", "2"),
          indexed(value, "1", n2)
        ),
        ("%s & %s & \\cdots & %s \\\\"):format(
          indexed(value, "2", "1"),
          indexed(value, "2", "2"),
          indexed(value, "2", n2)
        ),
        "\\vdots & \\vdots & \\ddots & \\vdots \\\\",
        ("%s & %s & \\cdots & %s"):format(indexed(value, n1, "1"), indexed(value, n1, "2"), indexed(value, n1, n2)),
      }
    end

    return sn(nil, { t(matrix_text_lines(form, rows)) })
  end)
end

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

return {
  suffix_cycle_engine = suffix_cycle_engine,
  slash_cycle_autosnippet = slash_cycle_autosnippet,
  integral_engine = integral_engine,
  accent_postfix_engine = accent_postfix_engine,
  accented_postfix = accented_postfix,
  angle_content_engine = angle_content_engine,
  cycle = cycle,
  braced_command_cycle = braced_command_cycle,
  annotation_autosnippet = annotation_autosnippet,
  symbolic_matrix_engine = symbolic_matrix_engine,
  symbolic_matrix_node = symbolic_matrix_node,
  roman = roman,
}

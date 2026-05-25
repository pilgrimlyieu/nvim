---Shared engines for the migrated low-frequency LaTeX snippets.
---
---This module contains reusable trigger engines and node builders only.  The
---public snippet groups live in `snippets.lua` and `autos.lua`, while
---`config.snippets.latex_extra` remains the compatibility facade used by the
---runtime snippet files.
local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta
local latex_helpers = require("config.snippets.latex.helpers")
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
local MAT_CALL_WINDOW = 32 -- `pmat(22)` / `bmat(3n)`-style calls.
local INLINE_ENVIRONMENT_WINDOW = 300 -- one-line calculation environment body.
local ENVIRONMENT_END_WINDOW = 48 -- `\end{latex_wolfram}` plus optional timeout.
local BRACED_COMMAND_WINDOW = 180 -- command cycles that preserve one/two brace groups.
local ANNOTATION_POSTFIX_WINDOW = 80 -- label plus `%^` / `%_` annotation suffix.
local SYMBOLIC_MATRIX_WINDOW = 24 -- symbolic matrix shorthands ending in `.`.

local cap = util.capture_nonempty
local choose_next = util.choose_next
local escape_lua_pattern = util.escape_lua_pattern
local cycle_engine = util.exact_cycle_engine
local literal = util.literal_snippet
local sorted_longest_first = util.sorted_longest_first
local visual_insert = util.visual_insert
local with_condition = util.with_condition
local matrix_env = latex_helpers.matrix_env
local matrix_nodes = latex_helpers.matrix_nodes
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

---@param text string
---@param marker string
---@param allow_digits boolean
---@return boolean
local function ends_with_marker(text, marker, allow_digits)
  if ends_with(text, marker) then
    return true
  end
  if not allow_digits then
    return false
  end

  local index = #text
  while index > 0 and text:sub(index, index):match("%d") do
    index = index - 1
  end
  return index < #text and text:sub(index - #marker + 1, index) == marker
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
---@param condition SnipCondition
---@param suffix_pattern? string
---@return SnipNode
local function slash_cycle_autosnippet(name, values, condition, suffix_pattern)
  return s(
    with_condition({
      trig = name,
      trigEngine = slash_cycle_engine(values, suffix_pattern),
      wordTrig = false,
      name = name,
      snippetType = "autosnippet",
      priority = 1500,
    }, condition),
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

---Match `pmat(22)`-style matrix calls and capture form and dimensions.
---@return SnipTriggerEngine
local function mat_call_engine()
  return function()
    return function(line_to_cursor)
      if not ends_with(line_to_cursor, ")") then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - MAT_CALL_WINDOW))
      local match, form, spec = text:match("(([pbBvV])mat%(([1-9][1-9]?[%a]*)%))$")
      if not match then
        return nil
      end

      local rows, cols = spec:match("^([1-9])([1-9])")
      rows = rows or spec:match("^([1-9])")
      cols = cols or rows
      return match, { form, rows, cols }
    end
  end
end

---Run an external command as a stdin/stdout filter with timeout.
---@param command string[]
---@param input string
---@param timeout_ms integer
---@return string?
local function run_filter(command, input, timeout_ms)
  if not vim.system then
    return nil
  end

  local ok, result = pcall(function()
    return vim.system(command, { stdin = input, text = true }):wait(timeout_ms)
  end)
  if not ok or not result or result.code ~= 0 then
    return nil
  end

  local stdout = result.stdout or ""
  return (stdout:gsub("%s+$", ""))
end

---Evaluate a small SymPy body and return rendered LaTeX.
---@param text string
---@return string?
local function eval_sympy(text)
  local script = [=[
from re import sub
from sys import stdin
from sympy import *
from sympy import latex

def pre_process_text(text):
    return text.replace('\\', '').replace('^', '**').replace('{', '(').replace('}', ')')

def process_latex(text):
    return sub(r'(\s|\W?)e(?=\W)', r'\g<1>\\e', text).replace(r'\, d', r'\d ')

x, y, z, t = symbols('x y z t')
k, m, n = symbols('k m n', integer=True)
f, g, h = symbols('f g h', cls=Function)
rv = None
exec(pre_process_text(stdin.read()))
print(process_latex(latex(rv or "")))
]=]
  return run_filter({ "python", "-c", script }, text, 10000)
end

---Evaluate WolframScript input and return rendered TeXForm text.
---@param text string
---@param from_latex boolean
---@param timeout string?
---@return string?
local function eval_wolfram(text, from_latex, timeout)
  local code
  if from_latex then
    local latex = (text:gsub([[\e]], " e"):gsub([[\d ]], [[\, d]]):gsub("\\", "\\\\"))
    code = ('ToString[ToExpression["%s", TeXForm], TeXForm]'):format(latex)
  else
    code = ("ToString[%s, TeXForm]"):format((text:gsub("\n", ";")))
  end

  local result = run_filter({ "wolframscript", "-code", code }, "", (tonumber(timeout) or 10) * 1000)
  if not result or result == "" then
    return nil
  end

  return (result:gsub("([%s%W]?)e(%W)", "%1\\e%2"):gsub([[\, d]], [[\d ]]))
end

---Match an inline calculation environment with body on the same line.
---@param env string
---@param timeout? boolean
---@return SnipTriggerEngine
local function inline_environment_engine(env, timeout)
  local end_marker = [[\end{]] .. env .. "}"

  return function()
    return function(line_to_cursor)
      if not ends_with_marker(line_to_cursor, end_marker, timeout == true) then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - INLINE_ENVIRONMENT_WINDOW))
      local pattern = "(\\begin{" .. env .. "} (.-) \\end{" .. env .. "}" .. (timeout and "(%d*)" or "") .. ")$"
      local match, body, timeout_value = text:match(pattern)
      if match then
        return match, { body, timeout_value or "" }
      end
      return nil
    end
  end
end

---Match an environment end marker used to evaluate a preceding block body.
---@param env string
---@param timeout? boolean
---@return SnipTriggerEngine
local function environment_end_engine(env, timeout)
  local end_marker = [[\end{]] .. env .. "}"

  return function()
    return function(line_to_cursor)
      if not ends_with_marker(line_to_cursor, end_marker, timeout == true) then
        return nil
      end

      local text = line_to_cursor:sub(math.max(1, #line_to_cursor - ENVIRONMENT_END_WINDOW))
      local pattern = "(\\end{" .. env .. "}" .. (timeout and "(%d*)" or "") .. ")$"
      local match, timeout_value = text:match(pattern)
      if match then
        return match, { timeout_value or "" }
      end
      return nil
    end
  end
end

---Replace a completed calculation environment with evaluator output.
---@param env string
---@param evaluator fun(body: string, timeout: string?): string?
---@return SnipNode
local function environment_eval_node(env, evaluator)
  return f(function(_, snip)
    local bufnr = vim.api.nvim_get_current_buf()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local timeout = snip.captures[1] or ""

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
      local start
      for index = row + 1, 1, -1 do
        if (lines[index] or ""):match("^%s*\\begin{" .. env .. "}%s*$") then
          start = index - 1
          break
        end
      end

      if not start then
        vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "\\end{" .. env .. "}" .. timeout })
        return
      end

      local body_lines = vim.list_slice(lines, start + 2, row)
      local body = table.concat(body_lines, "\n")
      local result = evaluator(body, timeout)

      if result and result ~= "" then
        vim.api.nvim_buf_set_lines(bufnr, start, row + 1, false, { result })
      else
        vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "\\end{" .. env .. "}" .. timeout })
      end
    end)

    return ""
  end)
end

---Build a snippet that cycles exact command spellings in place.
---@param name string
---@param values string[]
---@param condition SnipCondition
---@param extra? SnipContextExtra
---@return SnipNode
local function cycle(name, values, condition, extra)
  return s(
    with_condition(
      util.extend({
        trig = name,
        trigEngine = cycle_engine(values),
        wordTrig = false,
        name = name,
      }, extra),
      condition
    ),
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
---@param condition SnipCondition
---@return SnipNode
local function braced_command_cycle(name, commands, brace_count, condition)
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
              return target, { target }
            end
          end
          return nil
        end
      end,
      wordTrig = false,
      name = name,
    }, condition),
    {
      f(function(_, snip)
        local target = snip.captures[1] or ""
        for index, command in ipairs(commands) do
          if target:sub(1, #command) == command then
            return commands[index % #commands + 1] .. target:sub(#command + 1)
          end
        end
        return target
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
---@param condition SnipCondition
---@return SnipNode
local function annotation_autosnippet(name, suffix_pattern, suffix_text, command, marker, condition)
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
    }, condition),
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

      form, row, value =
        text:match((kind == "diag" and "d" or kind == "upper" and "ut" or "lt") .. "([mpbBvV])([%a])([%a]?)%.$")
      if not form then
        return nil
      end

      local match = (kind == "diag" and "d" or kind == "upper" and "ut" or "lt") .. form .. row .. value .. "."
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
  with_condition = with_condition,
  cap = cap,
  visual_insert = visual_insert,
  literal = literal,
  cycle_engine = cycle_engine,
  choose_next = choose_next,
  suffix_cycle_engine = suffix_cycle_engine,
  slash_cycle_autosnippet = slash_cycle_autosnippet,
  integral_engine = integral_engine,
  accent_postfix_engine = accent_postfix_engine,
  accented_postfix = accented_postfix,
  angle_content_engine = angle_content_engine,
  mat_call_engine = mat_call_engine,
  eval_sympy = eval_sympy,
  eval_wolfram = eval_wolfram,
  inline_environment_engine = inline_environment_engine,
  environment_end_engine = environment_end_engine,
  environment_eval_node = environment_eval_node,
  cycle = cycle,
  braced_command_cycle = braced_command_cycle,
  annotation_autosnippet = annotation_autosnippet,
  matrix_env = matrix_env,
  matrix_nodes = matrix_nodes,
  indexed = indexed,
  symbolic_matrix_engine = symbolic_matrix_engine,
  symbolic_matrix_node = symbolic_matrix_node,
  roman = roman,
}

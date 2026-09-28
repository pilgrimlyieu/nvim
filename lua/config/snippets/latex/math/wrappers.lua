---LaTeX wrappers; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local constructors = require("config.snippets.core.constructors")
local nodes = require("config.snippets.core.nodes")
local symbols = require("config.snippets.shared.symbols")

local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node

local capture = nodes.capture
local capture_nonempty = nodes.capture_nonempty
local literal_snippet = constructors.literal_snippet
local text_choices = nodes.text_choices
local text_choices_insert = nodes.text_choices_insert
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local word_autosnippet = constructors.word_autosnippet

local ANNOTATION_POSTFIX_WINDOW = 80 -- label plus `%^` / `%_` annotation suffix.
local ANGLE_CONTENT_WINDOW = 80 -- one-line `<content>` delimiter shorthand.
local ACCENT_POSTFIX_WINDOW = 80 -- target, optional script, and `bar`/`hat`/`vec`.
local ACCENT_SPECIAL_TARGETS = {
  i = [[\imath]],
  j = [[\jmath]],
}

local LONG_ACCENT_COMMANDS = {
  bar = [[\overline]],
  hat = [[\widehat]],
  vec = [[\overrightarrow]],
}

local SHORT_ACCENT_COMMANDS = {
  bar = [[\bar]],
  hat = [[\hat]],
  vec = [[\vec]],
}

local ACCENT_NAMES = { "bar", "hat", "vec" }
local MATH_DELIMITER_PAIRS = {
  ["("] = ")",
  ["["] = "]",
  ["\\{"] = "\\}",
  ["\\lbrace"] = "\\rbrace",
  ["\\langle"] = "\\rangle",
  ["\\lvert"] = "\\rvert",
  ["\\lVert"] = "\\rVert",
  ["|"] = "|",
}

---Return the right delimiter matching the first insert node.
---@param args SnipNodeArgs
---@return string
local function matching_right_delimiter(args)
  local left = args[1] and args[1][1] or ""
  return MATH_DELIMITER_PAIRS[left] or left
end

---Build a manual command wrapper and postfix style snippet pair.
---@param trigger string
---@param command string
---@param name string
---@return LuaSnip.Snippet[]
local function style_snippet(trigger, command, name)
  return {
    s(with_condition({ trig = trigger, name = name }, conditions.math), fmta(command .. "{<>}", { visual_insert(1) })),
    s(
      with_condition(
        { trig = "([%a\\]+)" .. trigger, name = name .. " postfix", trigEngine = "pattern", wordTrig = false },
        conditions.math
      ),
      fmta(command .. "{<>}", { capture(1) })
    ),
  }
end

---@param text string
---@param suffixes string[]
---@return boolean
local function ends_with_any(text, suffixes)
  for _, suffix in ipairs(suffixes) do
    if vim.endswith(text, suffix) then
      return true
    end
  end
  return false
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
      if not vim.endswith(line_to_cursor, ">") then
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

---Build annotation autosnippets like overbrace/underbrace with captured label.
---@param name string
---@param suffix_pattern string
---@param suffix_text string
---@param command string
---@param marker string
---@return LuaSnip.Snippet
local function annotation_autosnippet(name, suffix_pattern, suffix_text, command, marker)
  return s(
    with_condition({
      trig = name,
      trigEngine = function()
        return function(line_to_cursor)
          if not vim.endswith(line_to_cursor, suffix_text) then
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
    fmta(command .. [[{<>}]] .. marker .. [[{<>}]], { visual_insert(1), capture_nonempty(1) })
  )
end

function M.snippets()
  local condition = conditions.math

  local snippets = {
    s(with_condition({ trig = "txt", name = "text" }, condition), fmta([[\text{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "text", name = "text word alias" }, condition),
      fmta([[\text{<>}]], { visual_insert(1) })
    ),
    s(with_condition({ trig = "tt", name = "text short alias" }, condition), fmta([[\text{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "smash", name = "smash" }, condition),
      fmta([[\smash[<>]{<>}]], { text_choices(1, { "t", "b", " " }), visual_insert(2) })
    ),
    s(
      with_condition({ trig = "LR", name = "left right delimiters" }, condition),
      fmta([[\left<> <> \right<>]], { i(1, "("), visual_insert(2), f(matching_right_delimiter, { 1 }) })
    ),
    s(
      with_condition({ trig = "()", name = "parentheses", wordTrig = false }, condition),
      fmta([[\left( <> \right)]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "[]", name = "brackets", wordTrig = false }, condition),
      fmta([=[\left[ <> \right]]=], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "{}", name = "braces", wordTrig = false }, condition),
      fmta([[\left\lbrace <> \right\rbrace]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "||", name = "norm", wordTrig = false }, condition),
      fmta([[\left\lVert <> \right\rVert]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "abs", name = "absolute value" }, condition),
      fmta([[\left\lvert <> \right\rvert]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "ceil", name = "ceil" }, condition),
      fmta([[\left\lceil <> \right\rceil]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "floor", name = "floor" }, condition),
      fmta([[\left\lfloor <> \right\rfloor]], { visual_insert(1) })
    ),
    s(with_condition({ trig = "bm", name = "bold math" }, condition), fmta([[\bm{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "boxed", name = "boxed" }, condition), fmta([[\boxed{<>}]], { visual_insert(1) })),
    s(
      with_condition({ trig = "clr", name = "text color" }, condition),
      fmta([[\textcolor{<>}{<>}]], { text_choices_insert(1, { "ff0099", "da6904", "05aa94" }), visual_insert(2) })
    ),
    s(with_condition({ trig = "bar", name = "bar" }, condition), fmta([[\bar{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "hat", name = "hat" }, condition), fmta([[\hat{<>}]], { visual_insert(1) })),
    s(with_condition({ trig = "vec", name = "vector accent" }, condition), fmta([[\vec{<>}]], { visual_insert(1) })),
    s(
      with_condition({
        trig = "angle-content",
        name = "angle brackets around content",
        trigEngine = angle_content_engine(),
        wordTrig = false,
      }, condition),
      fmta([[\left\langle <> \right\rangle]], { capture_nonempty(1) })
    ),
    literal_snippet("dis", [[\displaystyle ]], "display style", condition),
    literal_snippet("tes", [[\textstyle ]], "text style", condition),
    s(
      with_condition({ trig = "cbox", name = "theorem box" }, conditions.display_math),
      fmta([[\fcolorbox{#FF69B4}{trasparent}{$<>$}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "pha", name = "phantom wrapper" }, condition),
      fmta([[\phantom{<>}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "hpha", name = "horizontal phantom" }, condition),
      fmta([[\hphantom{<>}]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "flr", name = "floor alias" }, condition),
      fmta([[\left\lfloor <> \right\rfloor]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = "cil", name = "ceil alias" }, condition),
      fmta([[\left\lceil <> \right\rceil]], { visual_insert(1) })
    ),
    s(
      with_condition(
        { trig = "([\\%w]+)mt", name = "matrix symbol", trigEngine = "pattern", wordTrig = false },
        condition
      ),
      fmta([[\bm{<>}]], { capture_nonempty(1) })
    ),
  }

  for _, def in ipairs(symbols.math_styles) do
    if def.latex then
      vim.list_extend(snippets, style_snippet(def.trigger, def.latex, def.name))
    end
  end

  return snippets
end

function M.autosnippets()
  local condition = conditions.math

  local autos = {
    word_autosnippet("sqrt", fmta([[\sqrt[<>]{<>}]], { i(1, "3"), visual_insert(2) }), "root", condition),
    word_autosnippet("gen", fmta([[\sqrt{<>}]], { visual_insert(1) }), "square root", condition),
    word_autosnippet("cancel", fmta([[\cancel{<>}]], { visual_insert(1) }), "cancel", condition),
    word_autosnippet("buji", fmta([[\complement_{<>}]], { visual_insert(1) }), "complement", condition),
    s(
      with_condition({ trig = [[\)]], name = "parentheses", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmta([[\left( <> \right)]], { visual_insert(1) })
    ),
    s(
      with_condition(
        { trig = [[\bb]], name = "parentheses (\\bb)", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      fmta([[\left( <> \right)]], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = [=[\]]=], name = "brackets", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmta([=[\left[ <> \right]]=], { visual_insert(1) })
    ),
    s(
      with_condition({ trig = [[\}]], name = "braces", wordTrig = false, snippetType = "autosnippet" }, condition),
      fmta([[\left\lbrace <> \right\rbrace]], { visual_insert(1) })
    ),
    s(
      with_condition(
        { trig = [[\>]], name = "angle brackets", wordTrig = false, snippetType = "autosnippet" },
        condition
      ),
      fmta([[\left\langle <> \right\rangle]], { visual_insert(1) })
    ),
    s(
      with_condition({
        trig = "accent-postfix",
        name = "accent postfix",
        trigEngine = accent_postfix_engine(),
        wordTrig = false,
        priority = 500,
        snippetType = "autosnippet",
      }, condition),
      {
        f(function(_, snip)
          return accented_postfix(snip.captures[1] or "", snip.captures[2] or "", snip.captures[3] or "bar")
        end),
      }
    ),
    annotation_autosnippet("overbrace postfix", "%%%^", "%^", [[\overbrace]], "^"),
    annotation_autosnippet("underbrace postfix", "%%%_", "%_", [[\underbrace]], "_"),
  }

  return autos
end

return M

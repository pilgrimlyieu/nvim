---LaTeX cycles; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local matching = require("config.snippets.core.matching")
local triggers = require("config.snippets.core.triggers")

local s = ls.snippet
local f = ls.function_node

local choose_next = matching.choose_next
local exact_cycle_engine = triggers.exact_cycle_engine
local sorted_longest_first = matching.sorted_longest_first
local with_condition = conditions.with_condition

local BRACED_COMMAND_WINDOW = 180 -- command cycles that preserve one/two brace groups.
local SLASH_CYCLE_WINDOW = 140 -- command-cycle value, optional suffix, then `/`.
local CYCLE_SUFFIX_WINDOW = 120 -- exact spacing commands plus optional whitespace.

---Match any value at the cursor and preserve trailing whitespace.
---@param values string[]
---@return SnipTriggerEngine
local function suffix_cycle_engine(values)
  local specs = {}
  for _, value in ipairs(sorted_longest_first(values)) do
    specs[#specs + 1] = "(" .. vim.pesc(value) .. ")(%s*)$"
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
    specs[#specs + 1] = "(" .. vim.pesc(value) .. ")(" .. suffix .. ")/$"
  end

  return function()
    return function(line_to_cursor)
      if not vim.endswith(line_to_cursor, "/") then
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
---@return LuaSnip.Snippet
local function slash_cycle_autosnippet(name, values, suffix_pattern)
  return s(
    with_condition({
      trig = name,
      name = name,
      trigEngine = slash_cycle_engine(values, suffix_pattern),
      wordTrig = false,
      priority = 1500,
      snippetType = "autosnippet",
    }, conditions.math),
    {
      f(function(_, snip)
        return choose_next(snip.captures[1], values) .. (snip.captures[2] or "")
      end),
    }
  )
end

---Build a snippet that cycles exact command spellings in place.
---@param name string
---@param values string[]
---@return LuaSnip.Snippet
local function cycle(name, values)
  return s(
    with_condition(
      { trig = name, name = name, trigEngine = exact_cycle_engine(values), wordTrig = false },
      conditions.math
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
---@return LuaSnip.Snippet
local function braced_command_cycle(name, commands, brace_count)
  local patterns = {}
  local arguments = string.rep("%b{}", brace_count)
  for _, command in ipairs(sorted_longest_first(commands)) do
    patterns[#patterns + 1] = { command = command, pattern = "(" .. vim.pesc(command) .. arguments .. ")$" }
  end

  return s(
    with_condition({
      trig = name,
      trigEngine = function()
        return function(line_to_cursor)
          if brace_count > 0 and not vim.endswith(line_to_cursor, "}") then
            return nil
          end

          local text = line_to_cursor:sub(math.max(1, #line_to_cursor - BRACED_COMMAND_WINDOW))
          for _, spec in ipairs(patterns) do
            local target = text:match(spec.pattern)
            if target then
              return target, { target, spec.command }
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

function M.snippets()
  local condition = conditions.math

  local spacing = { [[\!]], [[\,]], [[\:]], [[\;]], [[\quad]], [[\qquad]] }

  return {
    -- cycle
    cycle("colon", { [[:]], [[\colon]], [[:\:]] }),
    cycle("semicolon", { [[;]], [[;\;]] }),
    cycle("big size", { [[\big]], [[\Big]], [[\bigg]], [[\Bigg]] }),
    cycle("spacing", spacing),
    cycle("dots", { [[\dots]], [[\cdots]], [[\vdots]], [[\ddots]] }),
    cycle("infinity sign", { [[\infty]], [[-\infty]], [[+\infty]] }),
    cycle("plus minus", { [[\pm]], [[\mp]] }),
    cycle("dot product", { [[\cdot]], [[\boldsymbol{\cdot}]] }),
    cycle("cross product", { [[\times]], [[\boldsymbol{\times}]] }),
    cycle("operator star", { [[\operatorname]], [[\operatorname*]] }),
    cycle(
      "left arrow",
      { [[\leftarrow]], [[\gets]], [[\longleftarrow]], [[\Leftarrow]], [[\Longleftarrow]], [[\impliedby]] }
    ),
    cycle(
      "right arrow",
      { [[\rightarrow]], [[\to]], [[\longrightarrow]], [[\Rightarrow]], [[\Longrightarrow]], [[\implies]] }
    ),
    cycle(
      "left right arrow",
      { [[\leftrightarrow]], [[\longleftrightarrow]], [[\Leftrightarrow]], [[\Longleftrightarrow]], [[\iff]] }
    ),
    cycle("logical terms", { [[\because]], [[\therefore]], [[\land]], [[\lor]], [[\lnot]] }),
    cycle("and operator", { [[\land]], [[\bigwedge]] }),
    cycle("or operator", { [[\lor]], [[\bigvee]] }),
    cycle("similar relation", { [[\sim]], [[\nsim]] }),
    cycle("congruent relation", { [[\cong]], [[\ncong]] }),
    cycle("le relation", { [[\le]], [[\nle]] }),
    cycle("ge relation", { [[\ge]], [[\nge]] }),
    cycle("exists relation", { [[\exists]], [[\nexists]], [[\forall]] }),
    cycle("in relation", { [[\in]], [[\notin]], [[\ni]], [[\notni]] }),
    cycle("mid relation", { [[|]], [[\mid]] }),
    cycle("cap operator", { [[\cap]], [[\bigcap]], [[\cup]], [[\bigcup]] }),
    cycle(
      "subset relation",
      { [[\subset]], [[\subseteq]], [[\subsetneqq]], [[\supset]], [[\supseteq]], [[\supsetneqq]] }
    ),
    cycle("bar h", { [[\bar{h}]], [[\hbar]] }),
    cycle("phantom", { [[\phantom]], [[\hphantom]] }),
    cycle("epsilon variant", { [[\epsilon]], [[\varepsilon]] }),
    cycle("theta variant", { [[\theta]], [[\vartheta]] }),
    cycle("Theta variant", { [[\Theta]], [[\varTheta]] }),
    cycle("phi variant", { [[\phi]], [[\varphi]] }),
    cycle("Phi variant", { [[\Phi]], [[\varPhi]] }),
    cycle("sigma variant", { [[\sigma]], [[\varsigma]] }),
    cycle("kappa variant", { [[\kappa]], [[\varkappa]] }),
    cycle("rho variant", { [[\rho]], [[\varrho]] }),
    cycle("gamma case", { [[\gamma]], [[\Gamma]] }),
    cycle("delta case", { [[\delta]], [[\Delta]] }),
    cycle("lambda case", { [[\lambda]], [[\Lambda]] }),
    cycle("xi case", { [[\xi]], [[\Xi]] }),
    cycle("upsilon case", { [[\upsilon]], [[\Upsilon]] }),
    cycle("psi case", { [[\psi]], [[\Psi]] }),
    cycle("omega case", { [[\omega]], [[\Omega]] }),
    -- braced command cycle
    braced_command_cycle("frac display cycle", { [[\frac]], [[\dfrac]] }, 2),
    braced_command_cycle("binom display cycle", { [[\binom]], [[\dbinom]] }, 2),
    braced_command_cycle("operator star cycle", { [[\operatorname]], [[\operatorname*]] }, 1),
    braced_command_cycle("cancel command cycle", { [[\cancel]], [[\bcancel]], [[\xcancel]], [[\sout]] }, 1),
    braced_command_cycle("bar command cycle", { [[\bar]], [[\overline]] }, 1),
    braced_command_cycle("hat command cycle", { [[\hat]], [[\widehat]] }, 1),
    braced_command_cycle("vec command cycle", { [[\vec]], [[\overrightarrow]] }, 1),
    braced_command_cycle("phantom command cycle", { [[\phantom]], [[\hphantom]] }, 1),
    -- space suffix cycle
    s(
      with_condition({
        trig = "space suffix cycle",
        name = "space suffix cycle",
        trigEngine = suffix_cycle_engine(spacing),
        wordTrig = false,
      }, condition),
      {
        f(function(_, snip)
          return choose_next(snip.captures[1] or [[\!]], spacing) .. (snip.captures[2] or "")
        end),
      }
    ),
  }
end

function M.autosnippets()
  return {
    slash_cycle_autosnippet("subset slash reverse", { [[\subset]], [[\supset]] }),
    slash_cycle_autosnippet("subseteq slash reverse", { [[\subseteq]], [[\supseteq]] }),
    slash_cycle_autosnippet("subsetneqq slash reverse", { [[\subsetneqq]], [[\supsetneqq]] }),
    slash_cycle_autosnippet("cap cup slash reverse", { [[\cap]], [[\cup]] }),
    slash_cycle_autosnippet("big cap cup slash reverse", { [[\bigcap]], [[\bigcup]] }),
    slash_cycle_autosnippet("in ni slash reverse", { [[\in]], [[\ni]] }),
    slash_cycle_autosnippet("notin notni slash reverse", { [[\notin]], [[\notni]] }),
    slash_cycle_autosnippet("le slash not", { [[\le]], [[\nle]] }),
    slash_cycle_autosnippet("ge slash not", { [[\ge]], [[\nge]] }),
    slash_cycle_autosnippet("cong slash not", { [[\cong]], [[\ncong]] }),
    slash_cycle_autosnippet("sim slash not", { [[\sim]], [[\nsim]] }),
    slash_cycle_autosnippet("par slash not", { [[\par]], [[\npar]] }),
    slash_cycle_autosnippet("land slash big", { [[\land]], [[\bigwedge]] }),
    slash_cycle_autosnippet("lor slash big", { [[\lor]], [[\bigvee]] }),
    slash_cycle_autosnippet("exists slash not", { [[\exists]], [[\nexists]] }, "[_%{%}%w\\,%s]*"),
    slash_cycle_autosnippet("right arrow slash not", { [[\Rightarrow]], [[\nRightarrow]] }),
    slash_cycle_autosnippet("left arrow slash not", { [[\Leftarrow]], [[\nLeftarrow]] }),
    slash_cycle_autosnippet("left right arrow slash not", { [[\Leftrightarrow]], [[\nLeftrightarrow]] }),
    slash_cycle_autosnippet("implies slash not", { [[\implies]], [[\nimplies]] }),
    slash_cycle_autosnippet("impliedby slash not", { [[\impliedby]], [[\nimpliedby]] }),
    slash_cycle_autosnippet("iff slash not", { [[\iff]], [[\niff]] }),
  }
end

return M

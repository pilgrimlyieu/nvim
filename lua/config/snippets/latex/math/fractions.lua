---LaTeX fractions; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local i = ls.insert_node

local capture = nodes.capture
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

local FRACTION_TRIGGER_WINDOW = 80

---Match the numerator part of `1/`, `x_i/`, `\alpha/`, etc.
---
---The old UltiSnips trigger was a Python regex. LuaSnip's `"pattern"` engine
---uses Lua patterns, which have no alternation, so this custom engine preserves
---the useful old behavior without depending on jsregexp.
---@return SnipTriggerMatcher
local function simple_fraction_engine()
  local patterns = {
    -- `x_{i}^{j}/`: two braced scripts.
    [[([%a%d]*\?[%a]+[_^]%b{}[_^]%b{})/$]],
    -- `x_{i}^j/`: braced first script, unbraced second script.
    [[([%a%d]*\?[%a]+[_^]%b{}[_^][%a%d])/$]],
    -- `x_i^{j}/`: unbraced first script, braced second script.
    [[([%a%d]*\?[%a]+[_^][%a%d][_^]%b{})/$]],
    -- `x_i^j/`: two unbraced scripts.
    [[([%a%d]*\?[%a]+[_^][%a%d][_^][%a%d])/$]],
    -- `x_{i}/`: one braced script.
    [[([%a%d]*\?[%a]+[_^]%b{})/$]],
    -- `x_i/`: one unbraced script.
    [[([%a%d]*\?[%a]+[_^][%a%d])/$]],
    -- `\alpha/` or `foo/`: command/word atom.
    [[([%a%d]*\?[%a]+)/$]],
    -- `1/` or `n!/`: numeric/alnum atom, optionally factorial.
    [[([%a%d]+!?)/$]],
  }

  return function(line_to_cursor)
    if not vim.endswith(line_to_cursor, "/") then
      return nil
    end

    local text = line_to_cursor:sub(math.max(1, #line_to_cursor - FRACTION_TRIGGER_WINDOW))

    if text:sub(-2, -2) == ")" then
      local depth = 1

      for index = #text - 2, 1, -1 do
        local char = text:sub(index, index)

        if char == ")" then
          depth = depth + 1
        elseif char == "(" then
          depth = depth - 1

          if depth == 0 then
            local group = text:sub(index, #text - 1)
            local numerator = group:sub(2, -2)

            if numerator ~= "" then
              return group .. "/", { numerator }
            end
          end
        end
      end
    end

    for _, pattern in ipairs(patterns) do
      local numerator = text:match(pattern)
      if numerator then
        return numerator .. "/", { numerator }
      end
    end

    return nil
  end
end

function M.autosnippets()
  local not_unit_condition = conditions.not_unit

  local autos = {
    s(
      with_condition(
        { trig = "//", name = "fraction", wordTrig = false, snippetType = "autosnippet" },
        not_unit_condition
      ),
      fmta([[\dfrac{<>}{<>}]], { visual_insert(1), i(2) })
    ),
    s(
      with_condition({
        trig = "/",
        name = "simple fraction",
        trigEngine = simple_fraction_engine,
        wordTrig = false,
        snippetType = "autosnippet",
      }, not_unit_condition),
      fmta([[\dfrac{<>}{<>}]], { capture(1), visual_insert(1) })
    ),
  }

  return autos
end

return M

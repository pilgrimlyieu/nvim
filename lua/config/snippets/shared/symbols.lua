---Compile symbol aliases; rule data stays independent of LuaSnip.
local M = {}

local constructors = require("config.snippets.core.constructors")

local literal_autosnippet = constructors.literal_autosnippet
local word_autosnippet = constructors.word_autosnippet

---@class SymbolAliasRule
---@field trigger string|string[]
---@field name string
---@field latex? string
---@field latex_name? string
---@field typst? string
---@field typst_name? string
---@field opts? SnipOptions
---@field append_space? boolean Append a space after the snippet output.  Defaults to true.

---Compile pure per-language symbol rules once when a collection is loaded.
---@param rules SymbolAliasRule[]
---@param language string
---@param condition SnipCondition
---@return LuaSnip.Snippet[]
function M.symbol_autosnippets(rules, language, condition)
  local result = {}
  local name_field = language .. "_name"

  for _, rule in ipairs(rules) do
    local output = rule[language]
    if output then
      if rule.append_space ~= false then
        output = output .. " "
      end
      local build = (rule.opts and rule.opts.wordTrig == false) and literal_autosnippet or word_autosnippet
      local name = rule[name_field] or rule.name
      local trigger = rule.trigger
      local triggers = type(trigger) == "table" and trigger or { trigger } ---@type string[]

      for _, trig in ipairs(triggers) do
        result[#result + 1] = build(trig, output, name .. " '" .. trig .. "'", condition, rule.opts)
      end
    end
  end

  return result
end

return M

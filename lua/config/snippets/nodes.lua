---Small LuaSnip node helpers shared by snippet builders.
---
---UltiSnips-style choice placeholders map most directly to LuaSnip
---`choice_node`s.  Keeping the constructor here avoids reimplementing the same
---fixed-text choice boilerplate in every Markdown/TeX/Typst module.
local ls = require("luasnip")

local c = ls.choice_node
local t = ls.text_node

local M = {}

---Build a LuaSnip choice node from fixed text alternatives.
---@param index integer Jump index of the choice node.
---@param values string[] Fixed choices in display order.
---@return LuaSnip.ChoiceNode node A LuaSnip choice node containing text-node choices.
function M.choice(index, values)
  local choices = {}

  for _, value in ipairs(values) do
    choices[#choices + 1] = t(value)
  end

  return c(index, choices)
end

return M

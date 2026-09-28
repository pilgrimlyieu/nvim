---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node

local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin

local function table_node(align)
  return function(_, snip)
    local rows = tonumber(snip.captures[1]) or 2
    local cols = tonumber(snip.captures[2]) or 2
    local delimiter = {
      plain = "---",
      left = ":--",
      right = "--:",
      center = ":-:",
    }
    local cell_nodes = {}
    local jump = 1

    for row = 1, rows + 2 do
      if row == 2 then
        table.insert(cell_nodes, t("|"))
        for _ = 1, cols do
          table.insert(cell_nodes, t(delimiter[align] or delimiter.plain))
          table.insert(cell_nodes, t("|"))
        end
      else
        table.insert(cell_nodes, t("| "))
        for col = 1, cols do
          local placeholder = row == 1 and ("head" .. col) or ("R" .. (row - 2) .. "C" .. col)
          table.insert(cell_nodes, i(jump, placeholder))
          jump = jump + 1
          table.insert(cell_nodes, t(" |"))
          if col < cols then
            table.insert(cell_nodes, t(" "))
          end
        end
      end
      if row < rows + 2 then
        table.insert(cell_nodes, t({ "", "" }))
      end
    end

    return sn(nil, cell_nodes)
  end
end

function M.snippets()
  local snippets = {}
  local condition = with_line_begin(conditions.text)
  for _, def in ipairs({
    { "tb([1-9])([1-9])", "plain", "table" },
    { "tbl([1-9])([1-9])", "left", "left table" },
    { "tbr([1-9])([1-9])", "right", "right table" },
    { "tbm([1-9])([1-9])", "center", "center table" },
  }) do
    snippets[#snippets + 1] = s(
      with_condition({ trig = def[1], name = def[3], trigEngine = "pattern" }, condition),
      { d(1, table_node(def[2])) }
    )
  end
  return snippets
end

return M

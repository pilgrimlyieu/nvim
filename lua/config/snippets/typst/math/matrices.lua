---Typst-native feature definitions.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local matrix = require("config.snippets.shared.matrix")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node

local matrix_engine = matrix.engine
local cells = matrix.cells
local dimensions = matrix.dimensions
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition

---Build a matrix body with insert nodes in each cell.
---@param form string
---@param rows integer
---@param cols integer
---@return LuaSnip.Node[]
local function matrix_nodes(form, rows, cols)
  local delimiter = {
    b = [["["]],
    B = [["{"]],
    v = [["|"]],
    V = [["‖"]],
  }
  local mat_nodes = { t("mat(") }

  if delimiter[form] then
    mat_nodes[#mat_nodes + 1] = t("delim: " .. delimiter[form] .. ", ")
  end

  vim.list_extend(mat_nodes, cells(rows, cols, ", ", { ";", "  " }))
  mat_nodes[#mat_nodes + 1] = t(")")
  return mat_nodes
end

---Builds `mat(a, b; c, d)` with the requested dimensions.
---@param _ SnipNodeArgs
---@param snip SnipParent
---@return LuaSnip.Node
local function matrix_node(_, snip)
  local form, rows, cols = dimensions(snip.captures)

  return sn(nil, matrix_nodes(form, rows, cols))
end

function M.snippets()
  local condition = conditions.math
  return {
    s(
      with_condition({ trig = "cases", name = "cases" }, condition),
      fmt(
        [[cases(
  {} & {},
  {} & {},
)]],
        { i(1, "expr_1"), i(2, "condition_1"), i(3, "expr_2"), i(4, "condition_2") }
      )
    ),
    s(
      with_condition({ trig = "align", name = "aligned equations" }, condition),
      fmt(
        [[{} &= {} \
{} &= {}]],
        { visual_insert(1), i(2), i(3), i(4) }
      )
    ),
    s(
      with_condition(
        { trig = "mm", name = "simple old-style matrix", trigEngine = matrix_engine, wordTrig = false },
        condition
      ),
      { d(1, matrix_node) }
    ),
    s(with_condition({ trig = "vec", name = "column vector" }, condition), fmt("vec({})", { visual_insert(1) })),
  }
end

return M

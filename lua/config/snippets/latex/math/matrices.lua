---LaTeX matrices; ordinary and automatic entries share their feature.
local M = {}

local ls = require("luasnip")

local conditions = require("config.snippets.core.conditions")
local matrix = require("config.snippets.shared.matrix")
local scope = require("config.snippets.core.scope")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local d = ls.dynamic_node

local cells = matrix.cells
local dimensions = matrix.dimensions
local get_scope = scope.get
local matrix_engine = matrix.engine
local with_condition = conditions.with_condition

local DISPLAY_INDENT = "    "

---Map a matrix trigger prefix to a LaTeX matrix environment.
---@param form string
---@return string
local function matrix_env(form)
  if form == "" or form == "m" then
    return "matrix"
  end
  return form .. "matrix"
end

---Build a matrix body with insert nodes in each cell.
---@param form string
---@param rows integer
---@param cols integer
---@return LuaSnip.Node[]
local function matrix_nodes(form, rows, cols)
  local env = matrix_env(form)
  local inline = get_scope().layout == "inline"
  local body = { t(inline and ("\\begin{" .. env .. "} ") or { "\\begin{" .. env .. "}", DISPLAY_INDENT }) }
  vim.list_extend(body, cells(rows, cols, " & ", inline and [[ \\ ]] or { " \\\\", DISPLAY_INDENT }))
  body[#body + 1] = t(inline and (" \\end{" .. env .. "}") or { "", "\\end{" .. env .. "}" })
  return body
end

---Builds a LaTeX matrix environment from triggers.
---@param _ SnipNodeArgs
---@param snip SnipParent
---@return LuaSnip.Node
local function matrix_node(_, snip)
  local form, rows, cols = dimensions(snip.captures)

  return sn(nil, matrix_nodes(form, rows, cols))
end

function M.snippets()
  local condition = conditions.math

  local snippets = {
    s(
      with_condition(
        { trig = "mm", name = "simple old-style matrix", trigEngine = matrix_engine, wordTrig = false },
        condition
      ),
      { d(1, matrix_node) }
    ),
  }

  return snippets
end

return M

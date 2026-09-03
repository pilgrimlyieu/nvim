---Shared helpers for high-frequency LaTeX math snippets.
---
---This file owns dynamic-node builders and trigger constructors used by both
---TeX buffers and Markdown LaTeX math zones.
local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local conditions = require("config.snippets.conditions")
local scope = require("config.snippets.scope")
local util = require("config.snippets.util")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node

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
local DISPLAY_INDENT = "    "
local cap = util.capture
local visual_insert = util.visual_insert
local with_condition = conditions.with_condition

---Map a matrix trigger prefix to a LaTeX matrix environment.
---@param form string
---@return string
local function matrix_env(form)
  if form == "" or form == "m" then
    return "matrix"
  end
  return form .. "matrix"
end

---Return the right delimiter matching the first insert node.
---@param args SnipNodeArgs
---@return string
local function matching_right_delimiter(args)
  local left = args[1] and args[1][1] or ""
  return MATH_DELIMITER_PAIRS[left] or left
end

---Build the body for a generic LaTeX environment snippet.
---@param with_option boolean
---@param inline boolean
---@return SnipNode[]
local function environment_body(with_option, inline)
  local nodes = {
    t([[\begin{]]),
    i(1, "environment"),
  }
  local body_index = 2

  if with_option then
    nodes[#nodes + 1] = t([[}{]])
    nodes[#nodes + 1] = i(2, "option")
    body_index = 3
  end

  if inline then
    vim.list_extend(nodes, {
      t([[} ]]),
      visual_insert(body_index),
      t([[ \end{]]),
      rep(1),
      t("}"),
    })
  else
    vim.list_extend(nodes, {
      t({ "}", DISPLAY_INDENT }),
      visual_insert(body_index),
      t({ "", [[\end{]] }),
      rep(1),
      t("}"),
    })
  end

  return nodes
end

local math_environment_layouts = {
  case = {
    inline = { open = [[\left\lbrace\begin{aligned} ]], close = [[ \end{aligned}\right.]] },
    display = { open = { [[\left\lbrace\begin{aligned}]], DISPLAY_INDENT }, close = { "", [[\end{aligned}\right.]] } },
  },
  cases = {
    inline = { open = [[\begin{cases} ]], close = [[ \end{cases}]] },
    display = { open = { [[\begin{cases}]], DISPLAY_INDENT }, close = { "", [[\end{cases}]] } },
  },
  align = {
    inline = { open = [[\begin{aligned} ]], close = [[ \end{aligned}]] },
    display = { open = { [[\begin{aligned}]], DISPLAY_INDENT }, close = { "", [[\end{aligned}]] } },
  },
}

---Build an environment snippet node, adapting line breaks to math layout.
---@param with_option boolean
---@return fun(): SnipNode
local function environment_node(with_option)
  return function()
    return sn(nil, environment_body(with_option, scope.get().layout == "inline"))
  end
end

---Build case/cases/align nodes, adapting line breaks to math layout.
---@param kind "case"|"cases"|"align"
---@return fun(): SnipNode
local function math_environment_node(kind)
  return function()
    local layout = math_environment_layouts[kind][scope.get().layout == "inline" and "inline" or "display"]
    return sn(nil, { t(layout.open), visual_insert(1), t(layout.close) })
  end
end

---Build a matrix body with insert nodes in each cell.
---@param form string
---@param rows integer
---@param cols integer
---@return SnipNode[]
local function matrix_nodes(form, rows, cols)
  local env = matrix_env(form)
  local inline = scope.get().layout == "inline"
  local nodes = { t(inline and ("\\begin{" .. env .. "} ") or { "\\begin{" .. env .. "}", DISPLAY_INDENT }) }
  local jump = 1

  for row = 1, rows do
    for col = 1, cols do
      nodes[#nodes + 1] = i(jump, row == col and "1" or "0")
      jump = jump + 1
      if col < cols then
        nodes[#nodes + 1] = t(" & ")
      end
    end
    if row < rows then
      nodes[#nodes + 1] = t(inline and [[ \\ ]] or { " \\\\", DISPLAY_INDENT })
    end
  end

  nodes[#nodes + 1] = t(inline and (" \\end{" .. env .. "}") or { "", "\\end{" .. env .. "}" })
  return nodes
end

---Wrap prepared matrix row text in inline or display layout.
---@param form string
---@param rows string[]
---@return string[]
local function matrix_text_lines(form, rows)
  local env = matrix_env(form)
  if scope.get().layout == "inline" then
    return { "\\begin{" .. env .. "} " .. table.concat(rows, " ") .. " \\end{" .. env .. "}" }
  end

  local lines = { "\\begin{" .. env .. "}" }
  for _, row in ipairs(rows) do
    lines[#lines + 1] = DISPLAY_INDENT .. row
  end
  lines[#lines + 1] = "\\end{" .. env .. "}"
  return lines
end

---Builds a LaTeX matrix environment from triggers.
---@param _ SnipNodeArgs
---@param snip SnipSnippet
---@return SnipNode
local function matrix_node(_, snip)
  local form = snip.captures[1] or ""
  local rows = tonumber(snip.captures[2]) or 2
  local cols = tonumber(snip.captures[3]) or rows

  if tonumber(form) then
    rows = tonumber(form) or 2
    cols = tonumber(snip.captures[2]) or rows
    form = ""
  end

  return sn(nil, matrix_nodes(form, rows, cols))
end

---Build a manual command wrapper and postfix style snippet pair.
---@param trigger string
---@param command string
---@param desc string
---@return SnipNode[]
local function style_snippet(trigger, command, desc)
  return {
    s(with_condition({ trig = trigger, name = desc }, conditions.math), fmta(command .. "{<>}", { visual_insert(1) })),
    s(
      with_condition({
        trig = "([%a\\]+)" .. trigger,
        trigEngine = "pattern",
        wordTrig = false,
        name = desc .. " postfix",
      }, conditions.math),
      fmta(command .. "{<>}", { cap(1) })
    ),
  }
end

return {
  matrix_text_lines = matrix_text_lines,
  matching_right_delimiter = matching_right_delimiter,
  environment_node = environment_node,
  math_environment_node = math_environment_node,
  matrix_node = matrix_node,
  style_snippet = style_snippet,
}

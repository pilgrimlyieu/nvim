---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")
local selection = require("config.snippets.core.selection")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local selected_lines = selection.lines
local text_choices = nodes.text_choices
local visual_insert = nodes.visual_insert
local visual_transform_insert = nodes.visual_transform_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin
local with_trigger_column = conditions.with_trigger_column

---Prefix each selected line as a Markdown blockquote.
---@param lines string[]
---@return string[]
local function blockquote_lines(lines)
  local result = {}
  for _, line in ipairs(lines) do
    result[#result + 1] = "> " .. line
  end
  return result
end

---Remove Obsidian callout markers and blockquote prefixes from selected lines.
---@param lines string[]
---@return string[]
local function remove_callout_lines(lines)
  local result = {}
  for _, line in ipairs(lines) do
    if not line:match("^>%s+%[![A-Z]+%]%s*$") then
      line = line:gsub("^>%s+%[![A-Z]+%]%s*", "")
      line = line:gsub("^>%s?", "")
      result[#result + 1] = line
    end
  end
  return result
end

function M.snippets()
  local condition = conditions.text
  local callouts = {
    calln = "NOTE",
    calla = "ABSTRACT",
    calli = "INFO",
    callt = "TODO",
    callti = "TIP",
    calls = "SUCCESS",
    callq = "QUESTION",
    callw = "WARNING",
    callf = "FAILURE",
    calld = "DANGER",
    callb = "BUG",
    calle = "ERROR",
    callqo = "QUOTE",
  }
  local snippets = {
    s(
      with_condition({ trig = "adm", name = "admonition" }, with_trigger_column(condition, 0)),
      fmt(
        [[!!! {} {}
    {}]],
        {
          text_choices(1, { "note", "info", "warning", "danger", "example", "quote", "tip", "memo", "test" }),
          i(2, [[""]]),
          visual_insert(3),
        }
      )
    ),
  }

  for trigger, name in pairs(callouts) do
    table.insert(
      snippets,
      s(
        with_condition({ trig = trigger, name = "callout " .. name }, with_line_begin(condition)),
        fmt(
          [[> [!{}]
{}]],
          { t(name), visual_transform_insert(1, blockquote_lines) }
        )
      )
    )
  end

  snippets[#snippets + 1] =
    s(with_condition({ trig = "rmcall", name = "remove callout markup" }, with_line_begin(condition)), {
      f(function(_, snip)
        return remove_callout_lines(selected_lines(snip))
      end),
    })

  return snippets
end

return M

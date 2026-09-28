---Markdown snippet factories, grouped by writing task.
---Each factory owns its conditions and returns fresh nodes for the loader.
local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local nodes = require("config.snippets.core.nodes")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local at_buffer_start = conditions.at_buffer_start
local or_conditions = conditions.or_conditions
local computed_insert = nodes.computed_insert
local date = nodes.date
local text_choices = nodes.text_choices
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin

local DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

---Normalize comma-separated front-matter list text.
---@param value string
---@return string
local function normalize_list_spacing(value)
  return (value:gsub("，", ", "):gsub("%s*,%s*", ", "):gsub("^%s+", ""):gsub("%s+$", ""))
end

---Return the current filename stem, falling back to `Untitled`.
---@return string
local function basename()
  local value = vim.fn.expand("%:t:r")
  return value ~= "" and value or "Untitled"
end

---Read a simple YAML front-matter value from the top of the buffer.
---@param key string
---@return string?
local function front_matter_value(key)
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(vim.api.nvim_buf_line_count(0), 12), false)
  for _, line in ipairs(lines) do
    local value = line:match("^" .. key .. ":%s*(.*)$")
    if value ~= nil and value ~= "" then
      return value
    end
  end

  return nil
end

---Return front-matter title or infer it from the filename.
---@return string
local function front_matter_title()
  return front_matter_value("title") or basename()
end

---Return front-matter date or the current timestamp.
---@return string
local function front_matter_date()
  return front_matter_value("date") or tostring(os.date(DATE_FORMAT))
end

---Return whether the inferred title marks a private note.
---@return boolean
local function front_matter_private()
  return front_matter_title():find(".private", 1, true) ~= nil
end

---Return Hexo draft flag derived from privacy.
---@return string
local function front_matter_draft()
  return front_matter_private() and "true" or "false"
end

---Return Hexo comments flag derived from privacy.
---@return string
local function front_matter_comments()
  return front_matter_private() and "false" or "true"
end

function M.snippets()
  local condition = conditions.text
  local metadata = or_conditions(condition, conditions.frontmatter)
  local snippets = {
    s(
      with_condition(
        { trig = "@@", name = "Hexo front matter at file start", snippetType = "autosnippet" },
        at_buffer_start(condition)
      ),
      fmt(
        [[---
title: {}
date: {}
updated: {}
description: {}
draft: {}
comments: {}
disableNunjucks: true
katex: {}
categories: {}
tags: {}
---
{}]],
        {
          computed_insert(1, front_matter_title),
          f(front_matter_date),
          f(front_matter_date),
          i(2),
          computed_insert(3, front_matter_draft),
          computed_insert(4, front_matter_comments),
          text_choices(5, { "true", "false" }),
          i(6),
          i(7),
          i(8),
        }
      )
    ),
    s(
      with_condition(
        { trig = "date: (.*)", name = "refresh date", trigEngine = "pattern", wordTrig = false },
        with_line_begin(metadata)
      ),
      { t("date: "), date(DATE_FORMAT) }
    ),
    s(
      with_condition(
        { trig = "updated: (.*)", name = "refresh updated", trigEngine = "pattern", wordTrig = false },
        with_line_begin(metadata)
      ),
      { t("updated: "), date(DATE_FORMAT) }
    ),
    s(with_condition({ trig = "tag", name = "Hexo tag" }, condition), fmta([[{{% <> %}}]], { visual_insert(1) })),
    s(
      with_condition(
        { trig = "^categories: (.+)", name = "format categories", trigEngine = "pattern", wordTrig = false },
        metadata
      ),
      {
        f(function(_, snip)
          local categories = normalize_list_spacing(snip.captures[1] or "")
          local lines = { "categories:" }

          for category in categories:gmatch("([^,]+)") do
            lines[#lines + 1] = "  - [" .. category:gsub("^%s+", ""):gsub("%s+$", "") .. "]"
          end

          return lines
        end),
      }
    ),
    s(
      with_condition(
        { trig = "^tags: ([^[].+)", name = "format tags", trigEngine = "pattern", wordTrig = false },
        metadata
      ),
      {
        f(function(_, snip)
          return "tags: [" .. normalize_list_spacing(snip.captures[1] or "") .. "]"
        end),
      }
    ),
    s(
      with_condition(
        { trig = "^tags: %[(.+)%]([^%[%]]+)", name = "append tags", trigEngine = "pattern", wordTrig = false },
        metadata
      ),
      {
        f(function(_, snip)
          return "tags: ["
            .. normalize_list_spacing((snip.captures[1] or "") .. ", " .. (snip.captures[2] or ""))
            .. "]"
        end),
      }
    ),
  }

  return snippets
end

return M

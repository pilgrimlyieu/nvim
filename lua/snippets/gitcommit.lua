---TODO: remove this
---Git commit message snippets.
---
---The old UltiSnips `oj` snippet inspected Git's commented status block and
---generated a commit title for Online Judge files.  This keeps that behavior in
---native LuaSnip rather than relying on a post-jump Python hook.
local ls = require("luasnip")

local c = ls.choice_node
local d = ls.dynamic_node
local i = ls.insert_node
local sn = ls.snippet_node
local s = ls.snippet
local t = ls.text_node

---@class OjChange
---@field course string
---@field problem string

---Collect staged OJ additions and modifications from Git commit comments.
---@return OjChange[], OjChange[]
local function collect_oj_changes()
  local added = {}
  local updated = {}
  local in_committed = false

  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line == "# Changes to be committed:" then
      in_committed = true
    elseif line == "# Changes not staged for commit:" then
      break
    elseif in_committed then
      local kind, file = line:match("^#%s+([^:]+):%s+OJ/(.*)$")
      if file then
        local course = vim.fn.fnamemodify(file, ":h")
        local problem = vim.fn.fnamemodify(file, ":t:r")
        local change = {
          course = course == "." and "" or course,
          problem = problem,
        }

        if kind == "new file" then
          added[#added + 1] = change
        elseif kind == "modified" then
          updated[#updated + 1] = change
        end
      end
    end
  end

  return added, updated
end

---Format one OJ change as a course/problem label.
---@param change OjChange
---@return string
local function oj_label(change)
  if change.course == "" then
    return "#" .. change.problem
  end

  return change.course .. " #" .. change.problem
end

---Build numbered text nodes for a list of OJ changes.
---@param changes OjChange[]
---@return SnipNode[]
local function numbered_changes(changes)
  local nodes = {}

  for index, change in ipairs(changes) do
    nodes[#nodes + 1] = t(('%d. "%s"'):format(index, oj_label(change)))
    nodes[#nodes + 1] = t({ "", "" })
  end

  if #nodes > 0 then
    nodes[#nodes] = t("")
  end

  return nodes
end

---Build the dynamic OJ commit-message node from staged changes.
---@return SnipNode
local function oj_commit_node()
  local added, updated = collect_oj_changes()

  if #added == 1 and #updated == 0 then
    return sn(nil, {
      t(('Complete "%s"'):format(oj_label(added[1]))),
      i(0),
    })
  end

  if #added == 0 and #updated == 1 then
    return sn(nil, {
      c(1, { t("Update"), t("Optimize") }),
      t((' "%s"'):format(oj_label(updated[1]))),
      i(0),
    })
  end

  local nodes = { i(1), t({ "", "" }) }

  if #added > 0 then
    nodes[#nodes + 1] = t({ "Complete:", "" })
    vim.list_extend(nodes, numbered_changes(added))
    nodes[#nodes + 1] = t({ "", "" })
  end

  if #updated > 0 then
    nodes[#nodes + 1] = c(2, { t("Update"), t("Optimize") })
    nodes[#nodes + 1] = t({ ":", "" })
    vim.list_extend(nodes, numbered_changes(updated))
  end

  return sn(nil, nodes)
end

return {
  s({
    trig = "oj",
    name = "Online Judge commit",
    condition = function(line_to_cursor)
      return vim.api.nvim_win_get_cursor(0)[1] == 1 and line_to_cursor == "oj"
    end,
  }, {
    d(1, oj_commit_node),
  }),
}

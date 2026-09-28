---Names are assigned only at the loader boundary.
local M = {}

local ls = require("luasnip")

local source = ls.snippet_source

---LuaSnip's stack-based source lookup changes with loader tail calls.
---Record the feature factory instead, so shared definitions have the same source.
---@param factory fun(): LuaSnip.Snippet[]
---@return LuaSnip.Snippet[]
local function build(factory)
  local snippets = factory()
  if ls.session.config.loaders_store_source then
    local info = debug.getinfo(factory, "S")
    local location = source.from_location(info.source:sub(2), { line = info.linedefined })
    for _, snippet in ipairs(snippets) do
      -- Registration transfers this loader field into snippet_source's ID map.
      ---@diagnostic disable-next-line: inject-field
      snippet._source = location
    end
  end
  return snippets
end

---Qualify fresh definitions at the loader boundary; explicit identity keys stay unchanged.
---@param namespace string
---@param snippets LuaSnip.Snippet[]
---@param autosnippets LuaSnip.Snippet[]
---@return LuaSnip.Snippet[] snippets, LuaSnip.Snippet[] autosnippets
function M.qualify(namespace, snippets, autosnippets)
  local function apply(list, default_type)
    for _, snippet in ipairs(list) do
      local kind = snippet.snippetType or default_type
      snippet.name = namespace .. ": " .. snippet.name .. (kind == "autosnippets" and " [auto]" or "")
    end
  end

  apply(snippets, "snippets")
  apply(autosnippets, "autosnippets")
  return snippets, autosnippets
end

---Construct each enabled feature once; definitions never live in the module cache.
---@param namespace string
---@param modules string[]
---@return LuaSnip.Snippet[], LuaSnip.Snippet[]
function M.collect(namespace, modules)
  local snippets, autosnippets = {}, {}
  for _, name in ipairs(modules) do
    local feature = require("config.snippets." .. name)
    if feature.snippets then
      vim.list_extend(snippets, build(feature.snippets))
    end
    if feature.autosnippets then
      vim.list_extend(autosnippets, build(feature.autosnippets))
    end
  end
  return M.qualify(namespace, snippets, autosnippets)
end

---Groups default to enabled; collection reload reads the new settings.
---@param group string
---@return boolean
function M.enabled(group)
  return (vim.g.config_snippet_groups or {})[group] ~= false
end

return M

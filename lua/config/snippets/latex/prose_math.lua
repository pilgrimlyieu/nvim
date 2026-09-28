---LaTeX short-form math in Markdown and TeX prose. One definition per operation.
local M = {}

local ls = require("luasnip")
local fmta = require("luasnip.extras.fmt").fmta

local conditions = require("config.snippets.core.conditions")
local environments = require("config.snippets.latex.environments").rules
local nodes = require("config.snippets.core.nodes")
local symbols = require("config.snippets.shared.symbols")
local text_math = require("config.snippets.shared.prose_math")

local s = ls.snippet
local i = ls.insert_node

local latex_greek_command = symbols.latex_greek_command
local symbol = text_math.symbol
local visual_insert = nodes.visual_insert
local with_condition = conditions.with_condition
local with_line_begin = conditions.with_line_begin
local wrap = text_math.wrap

local delimiters = {
  markdown = { inline = { "$", "$" }, display = { "$$", "$$" } },
  tex = { inline = { [[\(]], [[\)]] }, display = { [[\[]], [=[\]]=] } },
}
local commands = {
  { "ce", [[\ce]], "inline chemistry" },
  { "pu", [[\pu]], "inline unit" },
  { "rm", [[\mathrm]], "inline roman math" },
  { "tt", [[\text]], "inline text math" },
}

local line_text = with_line_begin(conditions.text)

---@param dialect "markdown"|"tex"
function M.snippets(dialect)
  local delimit = assert(delimiters[dialect])
  local left, right = unpack(delimit.inline)
  local snippets, displays = {}, {}

  for _, def in ipairs(commands) do
    local name = def[3]
    snippets[#snippets + 1] = wrap(def[1], name, left .. def[2] .. "{", "}" .. right)
  end

  for _, def in ipairs(environments) do
    snippets[#snippets + 1] =
      wrap(def.trigger, "inline " .. def.name, left .. def.open .. " ", " " .. def.close .. right, { priority = 100 })
    displays[#displays + 1] = s(
      with_condition({ trig = def.trigger, name = "display " .. def.name, priority = 200 }, line_text),
      fmta(
        delimit.display[1] .. "\n" .. def.open .. "\n    <>\n" .. def.close .. "\n" .. delimit.display[2] .. "\n<>",
        { visual_insert(1), i(0) }
      )
    )
  end
  vim.list_extend(snippets, displays)

  for _, name in ipairs(symbols.markdown_inline_greek) do
    snippets[#snippets + 1] = symbol(name, "inline greek " .. name, left .. "\\" .. latex_greek_command(name) .. right)
  end

  return snippets
end

return M

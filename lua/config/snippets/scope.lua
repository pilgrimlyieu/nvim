---Cursor semantics shared by Markdown, TeX and Typst snippets.
---Tree-sitter owns Markdown/Typst syntax; VimTeX owns TeX syntax.
local M = {}

---@class SnipScope
---@field kind "text"|"math"|"code"|"comment"|"frontmatter"
---@field layout? "inline"|"display"
---@field command? string Innermost LaTeX command.

-- Add text-mode commands here as needed. Each ancestor uses one table lookup.
local LATEX_TEXT_COMMANDS = {
  ["\\text"] = true,
  ["\\textcolor"] = true,
  ["\\operatorname"] = true,
}

local MATH_NODES = { inline_formula = true, displayed_equation = true, math_environment = true }
local CODE_NODES = { fenced_code_block = true, indented_code_block = true, code_span = true }
local TYPST_KINDS = { math = "math", comment = "comment", raw_span = "code", raw_blck = "code" }
local TEXT = { kind = "text" }

---@type table<integer, { tick: integer, row: integer, col: integer, value: SnipScope }>
local cache = {}

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout", "FileType" }, {
  group = vim.api.nvim_create_augroup("SnippetScopeCache", { clear = true }),
  callback = function(event)
    cache[event.buf] = nil
  end,
})

---@param node TSNode?
---@param types table<string, boolean>
---@return TSNode?
local function ancestor(node, types)
  while node do
    if types[node:type()] then
      return node
    end
    node = node:parent()
  end
end

---@param node TSNode?
---@return boolean math
---@return string? command
local function latex_context(node)
  local command
  while node do
    local field = node:field("command")[1]
    local name = field and vim.treesitter.get_node_text(field, 0):gsub("%*$", "")
    command = command or name
    if name and LATEX_TEXT_COMMANDS[name] then
      return false, command
    end
    -- Explicit math nested inside prose re-enters math mode.
    if MATH_NODES[node:type()] or name == "\\ensuremath" then
      break
    end
    node = node:parent()
  end
  return true, command
end

---@param language vim.treesitter.LanguageTree
---@param tree TSTree
---@param range Range4
---@return vim.treesitter.LanguageTree, TSNode?
local function deepest(language, tree, range)
  for _, child in pairs(language:children()) do
    -- The public lookup handles sparse/unordered trees and disjoint HTML ranges.
    local candidate = child:tree_for_range(range)
    if candidate then
      return deepest(child, candidate, range)
    end
  end
  return language, tree:root():named_descendant_for_range(unpack(range))
end

---@param row integer
---@return vim.treesitter.LanguageTree?
local function ready_parser(row)
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return nil
  end
  -- Parse exactly this line. Ending at the next row makes injection queries
  -- include an unparsed neighbour, which can turn an empty LaTeX range into
  -- a whole-buffer injection on incremental parses.
  parser:parse({ row, 0, row, #vim.api.nvim_get_current_line() })
  return parser
end

---@param row integer
---@param col integer
---@param filetype string
---@return SnipScope
local function treesitter_scope(row, col, filetype)
  local parser = ready_parser(row)
  if not parser then
    return TEXT
  end
  local range = { row, col, row, col + 1 }
  local root = parser:tree_for_range(range)
  if not root then
    return TEXT
  end
  local outer = root:root():named_descendant_for_range(unpack(range))

  if filetype == "markdown" then
    -- Outer code always wins over injected Markdown or LaTeX example content.
    if ancestor(outer, CODE_NODES) then
      return { kind = "code" }
    end
    if ancestor(outer, { minus_metadata = true }) then
      return { kind = "frontmatter" }
    end
  end

  local language, node = deepest(parser, root, range)
  local lang = language:lang()
  if filetype == "typst" then
    if lang ~= "typst" then
      return { kind = "code" }
    end
    while node do
      if TYPST_KINDS[node:type()] then
        return { kind = TYPST_KINDS[node:type()] }
      end
      node = node:parent()
    end
    return TEXT
  end

  if lang == "markdown" then
    return TEXT
  elseif lang == "markdown_inline" then
    return ancestor(node, CODE_NODES) and { kind = "code" } or TEXT
  elseif lang == "html" then
    return ancestor(node, { comment = true }) and { kind = "comment" } or TEXT
  elseif lang ~= "latex" then
    return { kind = "code" }
  end

  -- Markdown delimiters determine layout, even while the LaTeX tree is incomplete.
  local parent = language:parent()
  local block = parent
    and parent:lang() == "markdown_inline"
    and ancestor(parent:named_node_for_range(range), { latex_block = true })
  if not block then
    return { kind = "code" }
  end
  if ancestor(node, { line_comment = true }) then
    return { kind = "comment" }
  end
  local math, command = latex_context(node)
  if not math then
    return TEXT
  end
  local delimiter = block:named_child(0)
  local text = delimiter and vim.treesitter.get_node_text(delimiter, 0) or "$"
  return { kind = "math", layout = #text >= 2 and "display" or "inline", command = command }
end

---@param name string
---@return any
local function vimtex(name, ...)
  -- TODO: call VimTeX functions with cache
  local ok, value = pcall(vim.fn["vimtex#" .. name], ...)
  if ok then
    return value
  end
end

---@return SnipScope
local function tex_scope()
  if vimtex("syntax#in_comment") == 1 then
    return { kind = "comment" }
  end
  if vimtex("syntax#in", [[tex\%(Verb\|Lst\|Minted\)Zone]]) == 1 then
    return { kind = "code" }
  end
  if vimtex("syntax#in_mathzone") ~= 1 then
    return TEXT
  end
  local current = vimtex("cmd#get_current")
  local command = type(current) == "table" and current.name or nil
  if command and LATEX_TEXT_COMMANDS[command] then
    return TEXT
  end
  local inline = vimtex("syntax#in", "texMathZone[LT]I") == 1
  return { kind = "math", layout = inline and "inline" or "display", command = command }
end

---Compute once per buffer edit/cursor position; all snippet predicates reuse it.
---@return SnipScope
function M.get()
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local previous = cache[buf]
  if previous and previous.tick == tick and previous.row == row and previous.col == col then
    return previous.value
  end

  local ft = vim.bo[buf].filetype
  local value = TEXT
  if ft == "markdown" or ft == "typst" then
    value = treesitter_scope(row, col, ft)
  elseif ft == "tex" then
    value = tex_scope()
  end
  cache[buf] = { tick = tick, row = row, col = col, value = value }
  return value
end

---List membership is only queried by the TeX list-item condition.
---@return boolean
function M.in_tex_list()
  if vim.bo.filetype == "tex" then
    for _, name in ipairs({ "enumerate", "itemize" }) do
      local range = vimtex("env#is_inside", name) -- TODO: get all surrounding environments instead?
      if type(range) == "table" and range[1] > 0 and range[2] > 0 then
        return true
      end
    end
  end
  return false
end

return M

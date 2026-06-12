local M = {}

local math_regions = {
  {
    group = "texMathZoneTD",
    region = [[syntax region texMathZoneTD start="\\\@<!\$\$" end="\$\$" skip="\\\$" keepend transparent]],
  },
  {
    group = "texMathZoneTI",
    region = [[syntax region texMathZoneTI start="\(^\|[^\\$]\)\zs\$\(\$\)\@!" end="\(^\|[^\\$]\)\zs\$\(\$\)\@!" skip="\\\$" keepend oneline transparent]],
  },
  {
    group = "texMathZoneLD",
    region = [[syntax region texMathZoneLD start="\\\@<!\\\[" end="\\\@<!\\\]" keepend transparent]],
  },
  {
    group = "texMathZoneLI",
    region = [[syntax region texMathZoneLI start="\\\@<!\\(" end="\\\@<!\\)" keepend oneline transparent]],
  },
}

local abbreviation_definition = [=[syntax match mkdAbbreviationDefinition "^\*\[[^]]\+\]:.*$" contains=@Spell]=]

---@param bufnr integer
local function valid_markdown_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "markdown"
end

---@param bufnr integer
local function apply_bridge(bufnr)
  if vim.g.markdown_vimtex_syntax_enabled == false then
    return
  end

  if not valid_markdown_buffer(bufnr) then
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    pcall(vim.fn["vimtex#options#init"])
    vim.b.markdown_vimtex_syntax = true

    vim.cmd("syntax sync minlines=200")
    for _, item in ipairs(math_regions) do
      vim.cmd("silent! syntax clear " .. item.group)
    end
    vim.cmd("silent! syntax clear mkdAbbreviationDefinition")
    vim.cmd(abbreviation_definition)
    for _, item in ipairs(math_regions) do
      vim.cmd(item.region)
    end
  end)
end

---@param bufnr integer
function M.enable(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr

  apply_bridge(bufnr)
end

return M

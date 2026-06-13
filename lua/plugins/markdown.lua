return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
  {
    "pilgrimlyieu/markdown-preview.nvim",
    name = "markdown-preview.nvim",
    url = "git@github.com:pilgrimlyieu/markdown-preview.nvim.git",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "bun install --frozen-lockfile && bun run build-local",
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    init = function()
      -- Avoid full content refresh on every cursor move; it makes the preview
      -- jump to the top before markdown-preview.nvim reapplies scroll sync.
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_auto_close = 0
      -- Start an independent preview server per buffer so several files can
      -- keep live browser previews open at the same time.
      vim.g.mkdp_multi_port = 1
      vim.g.mkdp_port = "18282"
      vim.g.mkdp_port_range = 32
      vim.g.mkdp_sync_scroll_on_cursor = 1
      vim.g.mkdp_theme = "light"
      vim.g.mkdp_preview_options = {
        disable_sync_scroll = 0,
        sync_scroll_type = "relative",
        katex = {
          trust = false,
          macros = {
            ["\\e"] = "\\mathrm{e}",
            ["\\d"] = "\\mathop{}\\!\\mathrm{d}",
            ["\\as"] = "\\bigg\\vert",
            ["\\combination"] = "\\operatorname{C}",
            ["\\rank"] = "\\operatorname{r}",
            ["\\trace"] = "\\operatorname{tr}",
            ["\\grad"] = "\\boldsymbol{\\nabla}",
            ["\\span"] = "\\operatorname{span}",
            ["\\dim"] = "\\operatorname{dim}",
            ["\\real"] = '\\mathord{\\char"211c}',
            ["\\Re"] = "\\operatorname{Re}",
            ["\\image"] = '\\mathord{\\char"2111}',
            ["\\Im"] = "\\operatorname{Im}",
            ["\\le"] = "\\leqslant",
            ["\\ge"] = "\\geqslant",
            ["\\nle"] = "\\nleqslant",
            ["\\nge"] = "\\ngeqslant",
            ["\\nl"] = "\\nless",
            ["\\ng"] = "\\ngtr",
            ["\\par"] = "\\mathrel{/\\kern-5mu/}",
            ["\\npar"] = "\\mathrel{/\\kern-13mu\\smallsetminus\\kern-13mu/}",
            ["\\nimplies"] = "\\mathrel{\\kern13mu\\not\\kern-13mu\\implies}",
            ["\\nimpliedby"] = "\\mathrel{\\kern13mu\\not\\kern-13mu\\impliedby}",
            ["\\niff"] = "\\mathrel{\\kern13mu\\not\\kern-13mu\\iff}",
            ["\\arccot"] = "\\operatorname{arccot}",
            ["\\arsinh"] = "\\operatorname{arsinh}",
            ["\\arcosh"] = "\\operatorname{arcosh}",
            ["\\artanh"] = "\\operatorname{artanh}",
            ["\\arcoth"] = "\\operatorname{arcoth}",
            ["\\ssd"] = "{\\mathrm{\\degree\\kern-0.2em C}}",
            ["\\hsd"] = "{\\mathrm{\\degree\\kern-0.2em F}}",
            ["\\eqref"] = "\\href{##label-#1}{(\\text{#1})}",
            ["\\ref"] = "\\href{##label-#1}{\\text{#1}}",
            ["\\label"] = "\\htmlId{label-#1}{}",
            ["\\@eqref"] = "\\href{##label-#1}{(\\text{#2})}",
            ["\\@ref"] = "\\href{##label-#1}{\\text{#2}}",
            ["\\@label"] = "\\htmlId{label-#1}{\\tag{#2}}",
            ["\\@@label"] = "\\htmlId{label-#1}{\\tag*{#2}}",
          },
        },
      }
      vim.cmd([[
       function OpenMarkdownPreview (url)
         silent execute '!"/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --app=' . a:url
       endfunction
      ]])
      vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
    end,
    config = function()
      vim.cmd([[do FileType]])
    end,
  },
}

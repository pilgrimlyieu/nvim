return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
  -- Replaced by the fork below. It needs a lazy.nvim name of its own for this
  -- to work: sharing `markdown-preview.nvim` merges the two specs into one, and
  -- `enabled = false` would then disable the fork as well.
  {
    "iamcco/markdown-preview.nvim",
    enabled = false,
  },
  {
    "pilgrimlyieu/markdown-preview.nvim",
    name = "markdown-preview",
    url = "git@github.com:pilgrimlyieu/markdown-preview.nvim.git",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = "bun install --frozen-lockfile && bun run build-local",
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    opts = {
      auto_close = false,
      theme = "light",
      -- An independent server per buffer, so several files can keep live
      -- browser previews open at the same time.
      server = {
        per_buffer = true,
        port = 18282,
        port_range = 32,
      },
      browser = function(url)
        local edge = vim.fn.has("win32") == 1 and "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
          or "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
        vim.fn.jobstart({ edge, "--app=" .. url }, { detach = true })
      end,
      render = {
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
      },
    },
  },
}

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {},
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    init = function()
      vim.g.mkdp_port = "18282"
      vim.g.mkdp_theme = "light"
      vim.g.mkdp_preview_options = {
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
  },
}

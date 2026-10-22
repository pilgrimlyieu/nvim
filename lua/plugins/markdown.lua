return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    -- Replace LazyVim's FileType triggers so opening a note does not load it.
    ft = function()
      return {}
    end,
    cmd = { "RenderMarkdown" },
    init = function()
      local groups = {
        RenderMarkdownUnchecked = { fg = "#f78c6c", bold = true },
        RenderMarkdownChecked = { fg = "#89ddff", bold = true },
        RenderMarkdownCancelled = { fg = "#fb4934", bold = true },
        RenderMarkdownProgress = { fg = "#fabd2f", bold = true },
        RenderMarkdownImportant = { fg = "#fe8019", bold = true },
        RenderMarkdownForwarded = { fg = "#83a598", bold = true },
        RenderMarkdownQuestion = { fg = "#8ec07c", bold = true },
        RenderMarkdownStar = { fg = "#d3869b", bold = true },
      }
      local function apply()
        for name, hl in pairs(groups) do
          vim.api.nvim_set_hl(0, name, hl)
        end
      end
      apply()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("render_markdown_checkbox_hl", { clear = true }),
        callback = apply,
      })
    end,
    keys = {
      {
        "<leader>um",
        function()
          require("render-markdown").toggle()
        end,
        desc = "Toggle Render Markdown",
        ft = "markdown",
      },
    },
    opts = {
      enabled = false,
      file_types = { "markdown", "norg", "rmd", "org", "codecompanion" },
      -- The plugin's throttle can drop a toggle-off immediately after an edit.
      debounce = 0,
      -- Converting each formula spawns an external process and blocks edits.
      latex = { enabled = false },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
        checked = { icon = "󰄵 ", highlight = "RenderMarkdownChecked" },
        custom = {
          todo = { raw = "[-]", rendered = "󰡖 ", highlight = "RenderMarkdownCancelled" },
          progress = { raw = "[/]", rendered = "󰦖 ", highlight = "RenderMarkdownProgress" },
          important = { raw = "[!]", rendered = "󰀪 ", highlight = "RenderMarkdownImportant" },
          forward = { raw = "[>]", rendered = "󰁔 ", highlight = "RenderMarkdownForwarded" },
          question = { raw = "[?]", rendered = "󰘥 ", highlight = "RenderMarkdownQuestion" },
          star = { raw = "[*]", rendered = "󱞈 ", highlight = "RenderMarkdownStar" },
        },
      },
      win_options = {
        conceallevel = {
          default = 0,
          rendered = 3,
        },
      },
    },
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
      server = {
        per_buffer = false,
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

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local disabled_markdown_tools = { "markdownlint-cli2", "markdown-toc", "marksman" }

      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = vim.tbl_filter(function(name)
        return not vim.tbl_contains(disabled_markdown_tools, name)
      end, opts.ensure_installed)
      if not vim.tbl_contains(opts.ensure_installed, "tinymist") then
        table.insert(opts.ensure_installed, "tinymist")
      end

      opts.npm = opts.npm or {}
      opts.npm.install_args = opts.npm.install_args or {}
      if not vim.tbl_contains(opts.npm.install_args, "--min-release-age=0") then
        table.insert(opts.npm.install_args, "--min-release-age=0")
      end

      return opts
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- The Markdown extra enables marksman by default.  Keep Markdown buffers
      -- quiet: prose notes should not get LSP diagnostics/format hooks unless
      -- this is explicitly re-enabled later.
      opts.servers.marksman = { enabled = false }

      opts.servers.tinymist = vim.tbl_deep_extend("force", opts.servers.tinymist or {}, {
        settings = {
          exportPdf = "never",
          formatterMode = "typstyle",
          semanticTokens = "disable",
        },
      })

      -- The system python3 lacks ensurepip, so Mason cannot create the PyPI
      -- venv it needs to install ruff. Use the existing global ruff binary.
      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
        mason = false,
      })

      return opts
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}

      return opts
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          sign = false,
        },
      })
    end,
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- optional
      "nvim-tree/nvim-web-devicons", -- optional
    },
  },
}

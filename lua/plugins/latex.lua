return {
  {
    "lervag/vimtex",
    ft = { "markdown", "tex" },
    config = function()
      vim.g.tex_conceal = "abgs"

      vim.g.vimtex_view_method = "zathura"

      vim.g.maplocalleader = "\\"

      vim.g.tex_flavor = "latex"

      vim.g.vimtex_texcount_custom_arg = " -ch -total"

      vim.g.vimtex_compiler_latexmk_engines = {
        _ = "-xelatex",
        pdflatex = "-pdf",
        dvipdfex = "-pdfdvi",
        lualatex = "-lualatex",
        xelatex = "-xelatex",
        ["context (pdftex)"] = "-pdf -pdflatex=texexec",
        ["context (luatex)"] = "-pdf -pdflatex=context",
        ["context (xetex)"] = "-pdf -pdflatex='texexec --xtx'",
      }

      vim.g.vimtex_compiler_latexmk = {
        out_dir = function()
          return "out"
        end,
        callback = 1,
        continuous = 1,
        executable = "latexmk",
        hooks = {},
        options = {
          "-verbose",
          "-file-line-error",
          "-shell-escape",
          "-synctex=1",
          "-interaction=nonstopmode",
        },
      }

      vim.g.vimtex_quickfix_mode = 0
      vim.g.vimtex_quickfix_open_on_warning = 0

      vim.g.vimtex_toggle_fractions = {
        frac = "dfrac",
        dfrac = "frac",
      }

      vim.g.vimtex_delim_toggle_mod_list = {
        { "\\left", "\\right" },
        { "\\bigl", "\\bigr" },
        { "\\Bigl", "\\Bigr" },
        { "\\biggl", "\\biggr" },
        { "\\Biggl", "\\Biggr" },
      }

      vim.g.vimtex_syntax_conceal = {
        accents = 1,
        ligatures = 1,
        cites = 1,
        fancy = 1,
        spacing = 1,
        greek = 1,
        math_bounds = 0,
        math_delimiters = 1,
        math_fracs = 1,
        math_super_sub = 1,
        math_symbols = 1,
        sections = 0,
        styles = 1,
      }
    end,
  },
}

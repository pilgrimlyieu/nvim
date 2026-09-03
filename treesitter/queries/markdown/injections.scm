; nvim-treesitter's Markdown base query, with injection.combined removed.
; HTML blocks stay separate; runtimepath extensions still apply normally.
; Use `:lua=vim.api.nvim_get_runtime_file('queries/markdown/injections.scm', true)` to get the base query path.
; Injections of Snacsk.nvim (math -> latex) is ignored.

(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  ; (#set! injection.combined) ; <-- This is the only change from the base query.
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))

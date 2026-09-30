---Decoration vocabulary and per-rule editing policy. No snippet implementation.
---@class SnipDecorationOptions
---@field prefix? boolean Generate the editable prefix template; defaults to true.
---@field auto? boolean Automatic postfix; prefix stays manual.
---@field scripts? SnipDecorationScripts
---@class SnipLatexDecorationOptions: SnipDecorationOptions
---@field accent? boolean Use dotless i/j and choose a wide accent.
---@field wide? string Command for a multi-atom base.

---@class SnipDecorationRule
---@field trigger string Trigger typed by the user.
---@field name string Human-readable snippet name suffix.
---@field latex? string LaTeX command without braces, such as `\mathbb`.
---@field typst? string Typst math function, such as `bb`.
---@field opts? SnipDecorationOptions Shared postfix policy; omitted scripts stay outside.
---@field latex_opts? SnipLatexDecorationOptions
---@field typst_opts? SnipDecorationOptions

---Each language output is a unary math decoration. TeX recognition also uses
---these command names, so a new rule remains chainable without a second list.
---@type SnipDecorationRule[]
return {
  { trigger = "bm", name = "bold math", latex = [[\bm]], typst = "bold" },
  { trigger = "mt", name = "matrix symbol", latex = [[\bm]], opts = { prefix = false } },
  { trigger = "rm", name = "roman", latex = [[\mathrm]], typst = "upright" },
  { trigger = "bb", name = "blackboard", latex = [[\mathbb]], typst = "bb" },
  { trigger = "bf", name = "bold", latex = [[\mathbf]], typst = "bold" },
  { trigger = "cal", name = "calligraphic", latex = [[\mathcal]], typst = "cal" },
  { trigger = "it", name = "italic", latex = [[\mathit]], typst = "italic" },
  { trigger = "sf", name = "sans", latex = [[\mathsf]], typst = "sans" },
  { trigger = "fra", name = "fraktur", latex = [[\mathfrak]], typst = "frak" },
  { trigger = "scr", name = "script", latex = [[\mathscr]], typst = "scr" },
  { trigger = "mono", name = "monospace", typst = "mono" },
  { trigger = "av", name = "arrow vector symbol", typst = "arrow" },
  { trigger = "bv", name = "bold vector symbol", typst = "bold" },
  -- Accents

  {
    trigger = "bar",
    name = "bar",
    latex = [[\bar]],
    typst = "macron",
    opts = { auto = true },
    latex_opts = { accent = true, wide = [[\overline]] },
  },
  {
    trigger = "hat",
    name = "hat",
    latex = [[\hat]],
    typst = "hat",
    opts = { auto = true },
    latex_opts = { accent = true, wide = [[\widehat]] },
  },
  {
    trigger = "vec",
    name = "vector accent",
    latex = [[\vec]],
    typst = "arrow",
    typst_opts = { prefix = false }, -- Bare `vec` is a column vector; use `av` for an editable arrow.
    opts = { auto = true, scripts = { subscript = false, superscript = false } },
    latex_opts = { accent = true, wide = [[\overrightarrow]] },
  },
  { trigger = "dot", name = "dot", latex = [[\dot]], typst = "dot", latex_opts = { accent = true } },
  {
    trigger = "tilde",
    name = "tilde",
    latex = [[\tilde]],
    typst = "tilde",
    latex_opts = { accent = true, wide = [[\widetilde]] },
  },
}

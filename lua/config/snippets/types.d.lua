---@meta

---LuaLS type declarations shared by the LuaSnip snippet modules.
---
---LuaSnip builds most runtime values as Lua tables but does not ship project
---local LuaLS classes for every node/context shape in every environment.  These
---aliases keep helper signatures specific while remaining compatible with
---LuaSnip/LazyDev's own `LuaSnip.*` node classes when they are available.

---@class LuaSnip.Node

---@class LuaSnip.Snippet: LuaSnip.Node

---@class LuaSnip.ChoiceNode: LuaSnip.Node

---@alias SnipNode LuaSnip.Node

---@class SnipSnippet: LuaSnip.Snippet
---@field captures string[] Regex/custom trigger captures for this expansion.
---@field env? SnipSnippetEnv TextMate/LuaSnip environment variables.
---@field snippet? SnipSnippet Parent snippet used by nested snippet nodes.
---@field parent? SnipSnippet Parent node used by nested dynamic nodes.

---@class SnipSnippetEnv
---@field LS_SELECT_RAW? string|string[] Visual text captured by LuaSnip.
---@field TM_SELECTED_TEXT? string|string[] TextMate-compatible visual text.
---@field SELECT_RAW? string|string[] Alternate LuaSnip visual text key.
---@field POSTFIX_MATCH? string Postfix capture used by LuaSnip postfix helpers.

---@alias SnipNodeList SnipNode[]
---@alias SnipNodeBody SnipNode|SnipNode[]
---@alias SnipNodeArgs string[][]

---@class SnipDynamicState

---@alias SnipConditionFn fun(line_to_cursor?: string, matched_trigger?: string, captures?: string[]): boolean

---@class SnipConditionObject

---@alias SnipConditionLike SnipConditionFn|SnipConditionObject

---@class SnipCondition
---@field condition SnipConditionLike Predicate used during expansion.
---@field show_condition SnipConditionLike Predicate used while showing completions.

---@class SnipMathContexts
---@field inline SnipCondition Condition for inline math layout.
---@field display SnipCondition Condition for display math layout.
---@field not_chem SnipCondition Condition for math zones outside `\ce`.
---@field not_unit SnipCondition Condition for math zones outside `\pu`.
---@field pure SnipCondition Condition for math zones outside `\ce` and `\pu`.
---@field chem SnipCondition Condition for math zones inside `\ce`.

---@alias SnipTriggerMatcher fun(line_to_cursor: string): string?, string[]?
---@alias SnipTriggerEngine fun(trigger?: string): SnipTriggerMatcher

---@class SnipContext
---@field trig string Trigger text or logical name for custom engines.
---@field name? string Completion/list display name.
---@field dscr? string|string[] Longer snippet documentation.
---@field desc? string|string[] Alternate documentation field.
---@field trigEngine? string|SnipTriggerEngine LuaSnip trigger engine.
---@field wordTrig? boolean Whether the trigger must be a whole word.
---@field regTrig? boolean Whether the trigger is Vim regex based.
---@field snippetType? "snippet"|"autosnippet"|string Expansion mode.
---@field priority? integer Selection priority for overlapping triggers.
---@field hidden? boolean Whether completion should hide this snippet.
---@field condition? SnipConditionLike Expansion predicate attached by helpers.
---@field show_condition? SnipConditionLike Completion predicate attached by helpers.

---@class SnipContextExtra
---@field trig? string
---@field name? string
---@field dscr? string|string[]
---@field desc? string|string[]
---@field trigEngine? string|SnipTriggerEngine
---@field wordTrig? boolean
---@field regTrig? boolean
---@field snippetType? "snippet"|"autosnippet"|string
---@field priority? integer
---@field hidden? boolean
---@field condition? SnipConditionLike
---@field show_condition? SnipConditionLike

---@class SnipEventCallbackByEvent
---@field [integer] fun() Callback keyed by LuaSnip event id.

---@class SnipEventCallbacks
---@field [integer] SnipEventCallbackByEvent Callback map keyed by LuaSnip node index.

---@class SnipOpts
---@field callbacks? SnipEventCallbacks

---@class SnipPendingSpaceAutocmds
---@field insert_char_pre? integer InsertCharPre autocmd id.
---@field insert_leave? integer InsertLeave autocmd id.

---@class SnipPendingSpaceAutocmdByBuffer
---@field [integer] SnipPendingSpaceAutocmds Pending autocmds keyed by buffer id.

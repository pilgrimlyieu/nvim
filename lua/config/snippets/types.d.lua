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
---@field env SnipSnippetEnv TextMate/LuaSnip environment available in callbacks.
---@field snippet SnipSnippet Root snippet; points to self on the root.

---@class SnipSnippetEnv
---@field LS_SELECT_RAW? string|string[] Visual text captured by LuaSnip.
---@field TM_SELECTED_TEXT? string|string[] TextMate-compatible visual text.

---@alias SnipNodeBody SnipNode|SnipNode[]
---@alias SnipNodeArgs string[][]

---@class SnipConditionObject
---@operator call(string?, string?, string[]?): boolean
---@operator add(SnipConditionObject): SnipConditionObject
---@operator mul(SnipConditionObject): SnipConditionObject

---@class SnipCondition
---@field condition SnipConditionObject Predicate used during expansion.
---@field show_condition SnipConditionObject Predicate used while showing completions.

---@alias SnipTriggerMatcher fun(line_to_cursor: string): string?, string[]?
---@alias SnipTriggerEngine fun(trigger?: string): SnipTriggerMatcher

---@class SnipContext
---@field trig string Trigger text or logical name for custom engines.
---@field name? string Completion/list display name.
---@field dscr? string|string[] Longer snippet documentation.
---@field desc? string|string[] Alternate documentation field.
---@field trigEngine? string|SnipTriggerEngine LuaSnip trigger engine.
---@field wordTrig? boolean Whether the trigger must be a whole word.
---@field snippetType? "snippet"|"autosnippet"|string Expansion mode.
---@field priority? integer Selection priority for overlapping triggers.
---@field hidden? boolean Whether completion should hide this snippet.
---@field condition? SnipConditionObject Expansion predicate attached by helpers.
---@field show_condition? SnipConditionObject Completion predicate attached by helpers.

---@class SnipContextExtra
---@field trig? string
---@field name? string
---@field dscr? string|string[]
---@field desc? string|string[]
---@field trigEngine? string|SnipTriggerEngine
---@field wordTrig? boolean
---@field snippetType? "snippet"|"autosnippet"|string
---@field priority? integer
---@field hidden? boolean
---@field condition? SnipConditionObject
---@field show_condition? SnipConditionObject

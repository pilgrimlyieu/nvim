---@meta

---Fields used by callbacks which LuaSnip's approximate parent types omit.
---@class SnipParent: LuaSnip.Snippet
---@field captures string[] Captures from the matched trigger.
---@field env SnipEnvironment
---@field snippet SnipParent Root snippet supplied to node callbacks.
---@field insert_nodes table<integer, LuaSnip.Node>
---@field indentstr string

---@class SnipEnvironment
---@field LS_SELECT_DEDENT? string|string[]
---@field LS_SELECT_RAW? string|string[]
---@field TM_SELECTED_TEXT? string|string[]

---@alias SnipNodeBody LuaSnip.Node|LuaSnip.Node[]
---@alias SnipNodeArgs string[][]

---Callable LuaSnip conditions, composed with OR (+) and AND (*).
---@class SnipPredicate
---@overload fun(line?: string, trigger?: string, captures?: string[]): boolean
---@operator add(SnipPredicate): SnipPredicate
---@operator mul(SnipPredicate): SnipPredicate

---@class SnipCondition
---@field condition SnipPredicate
---@field show_condition SnipPredicate

---@alias SnipTriggerMatcher fun(line_to_cursor: string): string?, string[]?
---@alias SnipTriggerEngine fun(trigger?: string): SnipTriggerMatcher

---Fields forwarded to LuaSnip; project-only policies belong to their module.
---@class SnipOptions
---@field trig? string
---@field name? string
---@field dscr? string|string[]
---@field docTrig? string Example input used by LuaSnip to generate a meaningful preview.
---@field trigEngine? string|SnipTriggerEngine
---@field wordTrig? boolean
---@field snippetType? "snippet"|"autosnippet"
---@field priority? integer
---@field hidden? boolean
---@field condition? SnipPredicate
---@field show_condition? SnipPredicate

---@class SnipContext: SnipOptions
---@field trig string

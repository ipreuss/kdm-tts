---
name: lua-module-debugging
description: Debugging Lua module issues - nil function calls, missing exports, module state visibility. Use when encountering attempt to call nil, function not exported, module state not visible, or require returning wrong values. Triggers on attempt to call nil, function not exported, module return, require, missing export.
---

# Lua Module Debugging

Common issues with Lua module exports and how to debug them.

## "attempt to call a nil value"

When a function exists but calling it throws this error:

1. **Check the module's return statement** — Lua modules must explicitly export functions in their `return { ... }` table
2. Debug pattern: `log:Debugf("Module.Function: %s", tostring(Module.Function))` — if this prints `nil`, the function isn't exported
3. **Root cause:** Missing function in the return statement at the end of the module file

**Preferred pattern:** Return the module table directly (`return Module`) instead of explicit export tables to avoid this issue.

## Module Export vs Internal Table

**Problem:** `Module.field = value` assignments are not visible to other modules via `require()`

**Root cause:** When a module uses `return {...}` with explicit exports, dynamic assignments go to the **internal** `local Module = {}` table, not the **exported** table:

```lua
local Module = {}  -- Internal table

function Module.DoThing()
    Module.state = "done"  -- Assigns to INTERNAL table
end

return {
    DoThing = Module.DoThing,
    -- state is NOT exported!
}
```

**Solution:** Return the internal table directly:
```lua
return Module  -- Now Module.state is visible to other modules
```

## Debug Logging

### Enabling Logging for a Module

When adding `log:Debugf()` statements, you must also enable the module in `Log.ttslua`:

```lua
local DEBUG_MODULES = {
    ["MyModule"] = true,  -- Add/uncomment the module you're debugging
}
```

**CRITICAL:** Without this step, your debug output will not appear.

### Logging Pattern

```lua
local Log = require("Log")
local log = Log.ForModule("MyModule")

log:Debugf("Variable X = %s", tostring(x))
log:Debugf("Function exists: %s", tostring(SomeModule.SomeFunction ~= nil))
```

### Retention Policy

**Debug statements do NOT need to be removed** if:
- Their execution cost is negligible (simple string formatting, no loops)
- The module's debug logging can be disabled via `Log.ttslua`

**Benefits of keeping debug statements:**
- Future debugging is faster (no need to re-add the same logging)
- Debug paths are already tested and working
- Reduces risk of introducing bugs when re-adding logging later

## Save File Inspection

The TTS save file (`template_workshop.json`) contains all object data and can be inspected:

1. **Use Python/jq to query the JSON** for specific objects by GUID or name
2. **Compare working vs broken objects** to find property differences
3. **Key properties to check:**
   - `Name`: Object type (`Card`, `CardCustom`, `Deck`, etc.)
   - `CustomDeck`: Card image sheet definitions with `FaceURL`, `BackURL`, `NumWidth`, `NumHeight`
   - `ContainedObjects`: Items inside decks/bags

## Progressive Debug Logging Strategy

When functions don't execute, add logging **backwards through the call chain**:

```lua
-- 1. Start at the deepest point that should execute
function Archive.TakeFromDeck(params)
    log:Debugf("[DEBUG] TakeFromDeck START") -- Never appears? Check caller
    -- ...
end

-- 2. Add logging to the caller
function Strain:_TakeFromRewardsDeck(params)
    log:Debugf("[DEBUG] _TakeFromRewardsDeck START") -- Appears? Check function exists
    log:Debugf("[DEBUG] Archive.TakeFromDeck exists: %s", tostring(Archive.TakeFromDeck ~= nil))
    Archive.TakeFromDeck({...})
end

-- 3. Check at call site
log:Debugf("[DEBUG] Strain.Test._TakeRewardCard exists: %s", tostring(Strain.Test._TakeRewardCard ~= nil))
local ok = Strain.Test._TakeRewardCard(Strain, {...})
```

**Pattern:** Work backwards from where execution stops until you find the nil value or missing export.

## Fail Fast Philosophy

**Fail fast with meaningful errors** — Don't silently ignore missing dependencies; log and fail clearly.

Use `assert(obj, "helpful message")` to fail loud and reveal issues.

Function existence checks should be rare and only used for:
- **Test environment compatibility** — where modules genuinely might not exist
- **Optional features** — where the functionality is truly optional
- **Never** for hiding missing required dependencies

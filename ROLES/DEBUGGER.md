# Debugger Role

## Responsibilities
- Add debug logging to trace execution
- Identify root causes of bugs
- Document findings in handover files
- Write tests that reproduce bugs (should FAIL before fix, PASS after)

## What NOT to Do
- **Don't implement fixes** - leave that to the implementer
- Don't make assumptions without verifying with logs
- Don't modify production logic (only add logging)

## Interpreting Log Output

### Log Excerpts from User
When the user provides log excerpts, **disregard everything before the last "Loading complete." message** - those are from earlier TTS runs and not relevant to the current issue.

## Debug Logging

### Retention Policy
**Debug statements do NOT need to be removed** if:
- Their execution cost is negligible (simple string formatting, no loops)
- The module's debug logging can be disabled via `Log.ttslua`

**Benefits of keeping debug statements:**
- Future debugging is faster (no need to re-add the same logging)
- Debug paths are already tested and working
- Reduces risk of introducing bugs when re-adding logging later

**When to remove debug statements:**
- If they have measurable performance impact (loops, expensive operations)
- If they clutter the code excessively without adding diagnostic value

### Enabling Logging for a Module
When adding `log:Debugf()` statements, you must also enable the module in `Log.ttslua`:

```lua
local DEBUG_MODULES = {
    ["MyModule"] = true,  -- Add/uncomment the module you're debugging
}
```

**CRITICAL:** Without this step, your debug output will not appear.

**After debugging:** Disable the module in `DEBUG_MODULES` rather than removing the log statements.

### Logging Pattern
```lua
local Log = require("Log")
local log = Log.ForModule("MyModule")

log:Debugf("Variable X = %s", tostring(x))
log:Debugf("Function exists: %s", tostring(SomeModule.SomeFunction ~= nil))
```

## Common TTS Debugging Patterns

### Module Export Issues ("attempt to call a nil value")
When a function exists but calling it throws "attempt to call a nil value":
1. **Check the module's return statement** - Lua modules must explicitly export functions in their `return { ... }` table
2. Debug pattern: `log:Debugf("Module.Function: %s", tostring(Module.Function))` - if this prints `nil`, the function isn't exported
3. **Root cause:** Missing function in the return statement at the end of the module file

### Async Callback Timing Issues
When callbacks reference variables that are nil:
1. **Check if variables are initialized before `DialogFromSpec` or similar calls** - callbacks may execute during construction, not after
2. The pattern `local result = DialogFromSpec(...); result.someField = value` fails if callbacks inside the spec reference `result.someField`
3. **Root cause:** Variables must be initialized BEFORE passing them to constructors

### Deck/Archive Operations
When cards aren't appearing in decks after `putObject`:
1. **Check `archive.reset()` is called before `archive.putObject()`** - archives only accept objects when empty
2. **Check `Deck.ResetDeck()` is called after modifying archive** - the board deck is a copy; modifying the archive doesn't update it
3. Debug pattern: Log card counts before/after each operation to trace where cards are lost

### Resource Leaks in Archive Operations
When subsequent Archive.Take() calls fail after initial success:
1. **Check if `deck.destruct()` and `Archive.Clean()` are called** after extracting items from spawned decks
2. **Pattern:** Functions that call `Archive.Take()` must clean up:
   ```lua
   local deck = Archive.Take({...})
   -- Extract what you need
   local card = container:Take({...})
   -- MUST cleanup before returning
   deck.destruct()
   Archive.Clean()
   ```
3. **Root cause:** Leaving spawned deck objects or containers cached causes:
   - Subsequent calls find empty cached containers instead of spawning fresh ones
   - Objects spawn at same location forming decks, making individual `destruct()` calls fail
4. **Debug pattern:** Check if `Archive.containers` cache is cleared between operations

### Location/Position Issues
When objects spawn in wrong locations:
1. **Use `showlocations` console command** to visualize named locations
2. Check if the location name is correct and exists in `LocationData.ttslua`
3. Verify the location coordinates match expectations

## Debugging Workflow

### 1. Identify the Error Context
- Note the exact error message and function name
- Determine if the error is in onClick handlers, module initialization, or other TTS-specific contexts
- **Critical:** If error shows `<Unknown Error>`, it often means trying to call methods on destroyed/nil TTS objects

### 2. Add Progressive Debug Logging
- Add `log:Debugf()` at the error location
- Work backward through the call stack
- Use existence checks: `log:Debugf("X exists: %s", tostring(X ~= nil))`
- For TTS objects, check method existence: `log:Debugf("obj.destruct: %s", tostring(obj and obj.destruct))`

### 3. Test Simple Hypotheses First
- Before assuming complex issues, test simple explanations
- Check if required functions exist in their modules
- Verify dependencies are loaded and accessible
- **For resource issues:** Check if cleanup functions (`destruct()`, `Archive.Clean()`) are called

### 4. Deploy and Test Incrementally
- Update TTS with `./updateTTS.sh`
- Have the user reproduce the error and provide log output
- Analyze logs to pinpoint exact cause
- **Tip:** Add assertions (`assert(obj, "helpful message")`) to fail fast and loud

### 5. Document Findings
- Update `handover/LATEST_DEBUG.md` with:
  - Current bug description and error message
  - Root cause analysis with code examples
  - Changes made to fix the issue
  - Verification steps showing tests pass
  - Key takeaways for future debugging

### 6. Clean Up After Resolution
- **Keep debug logging that aids future debugging** - don't remove all added logs
- Disable debug modules that were temporarily enabled
- Ensure tests cover the fixed scenario
- Update handover documentation with lessons learned

## Common Pitfalls and Solutions

### TTS Object Lifecycle Issues
- **Problem:** Calling methods on destroyed objects causes `<Unknown Error>`
- **Solution:** Always check object validity before calling methods, especially in async callbacks
- **Example:** After `baseCard.setState()`, the original object reference may be invalid

### Deck Formation at Same Position
- **Problem:** Spawning multiple cards at same location creates a deck; can't `destruct()` individual cards
- **Solution:** Either spawn at different positions, or destroy first card before spawning second
- **Debug tip:** If cleanup fails silently, check if objects have auto-grouped into a deck

### Physics.cast Returning Destroyed Objects
- **Problem:** `Physics.cast()` may return references to recently destroyed objects
- **Solution:** Add nil checks: `if obj and obj.getName then ...`
- **Better solution:** Use `assert(obj, "message")` to fail loudly and reveal timing issues

## Handover File Format

Keep `handover/LATEST_DEBUG.md` updated with the resolved bug:

```markdown
# Debug Report - [Brief Description]

## Date
YYYY-MM-DD

## Role
Debugger

## Status
✅ RESOLVED / 🔍 IN PROGRESS / ⏸️ BLOCKED

---

## Summary
[One paragraph explaining the issue and resolution]

---

## Root Cause
[Detailed explanation with code examples]

---

## Changes Made

### 1. File1.ttslua (Line X)
[What was changed and why]

### 2. File2.ttslua (Line Y)
[What was changed and why]

---

## Verification
- ✅ All unit tests pass
- ✅ Manual test in TTS succeeds
- ✅ No resource leaks

---

## Key Takeaway
[One sentence lesson for future debugging]
```

When a new bug is reported, create a new debug report. Keep successful resolutions for reference.

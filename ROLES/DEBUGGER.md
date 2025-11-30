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

### Location/Position Issues
When objects spawn in wrong locations:
1. **Use `showlocations` console command** to visualize named locations
2. Check if the location name is correct and exists in `LocationData.ttslua`
3. Verify the location coordinates match expectations

## Debugging Workflow

### 1. Identify the Error Context
- Note the exact error message and function name
- Determine if the error is in onClick handlers, module initialization, or other TTS-specific contexts

### 2. Add Progressive Debug Logging
- Add `log:Debugf()` at the error location
- Work backward through the call stack
- Use existence checks: `log:Debugf("X exists: %s", tostring(X ~= nil))`

### 3. Test Simple Hypotheses First
- Before assuming complex issues, test simple explanations
- Check if required functions exist in their modules
- Verify dependencies are loaded and accessible

### 4. Deploy and Test Incrementally
- Update TTS with `./updateTTS.sh`
- Have the user reproduce the error and provide log output
- Analyze logs to pinpoint exact cause

### 5. Document Findings
- Update `handover/debug_report.md` with:
  - Current bug description and error message
  - Root cause analysis
  - Recommended fix for implementer
  - Any architectural insights discovered

### 6. Clean Up After Resolution
- Remove excessive debug logging once issue is resolved
- Disable debug modules that were temporarily enabled
- Ensure tests cover the fixed scenario

## Handover File Format

Keep `handover/debug_report.md` updated with only the current bug:

```markdown
# Debug Report

## Current Bug: [Brief Description]

**Error Message:**
[Exact error from TTS]

**Reproduction Steps:**
1. ...

**Root Cause:**
[What's actually wrong]

**Recommended Fix:**
[What the implementer should do]

**Files Involved:**
- File1.ttslua (line X)
- File2.ttslua (line Y)
```

When a new bug is reported, assume previous bugs are fixed and replace the content.

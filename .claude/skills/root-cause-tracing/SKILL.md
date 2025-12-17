---
name: root-cause-tracing
description: Trace bugs backward through call stack to find the source of invalid data. Use when errors surface deep in call stack, "attempt to call/index nil value" with long trace, origin of problematic data is unclear, or need to identify which code path triggers failure. Triggers on stack trace, nil value, call chain, trace backward, upstream bug.
---

# Root Cause Tracing

**Core Principle:** "Root issues originate upstream. Fix at the source, not where the symptom appears."

When problems manifest deep in execution, trace backward to find the original trigger.

## When to Use

- Errors surface deep in call stack
- "attempt to call/index a nil value" with long trace
- Origin of problematic data is unclear
- Need to identify which code path triggers failure

---

## The Five-Step Tracing Process

### Step 1: Observe the Symptom

Document the exact error and location.

```
Error: attempt to index a nil value (field 'resources')
Stack: Showdown.ttslua:234 in GetRewards
```

### Step 2: Find Immediate Cause

What code directly produces the error?

```lua
-- Showdown.ttslua:234
local rewards = self.level.resources  -- self.level is nil!
```

### Step 3: Ask "What Called This?"

Trace one level up the call stack.

```lua
-- Who called GetRewards?
-- → Setup() at line 180
-- → Why is self.level nil in Setup?
```

### Step 4: Keep Tracing Up

Continue asking what invoked each function.

```
GetRewards ← Setup ← OnShowdownStart ← EventManager.Fire
```

Document the chain as you go.

### Step 5: Find Original Trigger

Keep tracing until reaching the source of invalid input.

```
Root cause: EventManager.Fire("showdown_start") called
before Showdown.LoadMonsterData() completed
```

---

## Adding Debug Traces

When manual tracing is insufficient, add instrumentation:

```lua
function Showdown.Setup(monsterName, levelName)
    log:Debugf("Showdown.Setup called: monster=%s, level=%s",
        tostring(monsterName), tostring(levelName))
    log:Debugf("Stack: %s", debug.traceback())
    -- ...
end
```

Enable module in `Log.DEBUG.MODULES`:
```lua
Log.DEBUG.MODULES = {
    ["Showdown"] = true,  -- Enable temporarily
}
```

**Remember to disable after debugging.**

---

## Lua Stack Trace Helper

```lua
local function logWithStack(msg)
    log:Debugf("%s\nStack: %s", msg, debug.traceback())
end

-- Usage
logWithStack("Archive.Take called with nil name")
```

---

## Common Root Cause Patterns

| Pattern | Symptom | Root Cause |
|---------|---------|------------|
| Async timing | nil field access | Callback fires before init |
| Missing init | nil module | Used before Init() called |
| Event ordering | wrong state | Events fire in unexpected order |
| Destroyed object | nil or error | Object cleaned up before use |

---

## The Iron Rule

**NEVER fix where the error appears. ALWAYS trace to the source.**

The visual symptom location is rarely the root cause. Fixing at the symptom hides the bug — it will return.

A proper fix:

1. **Identifies** the original trigger
2. **Fixes** at the source
3. **Adds validation** at intermediate layers (see `defense-in-depth`)
4. **Makes the bug** impossible to recreate
5. **Writes a regression test** proving the fix

---

## Common Rationalizations to Reject

| Rationalization | Reality |
|-----------------|---------|
| "The error location IS the problem" | No. Errors surface downstream from their cause. |
| "Quick fix at symptom saves time" | Quick fixes create recurring bugs. Trace first. |
| "I know what's wrong already" | Verify with evidence. Assumptions waste hours. |
| "Tracing takes too long" | Fixing the wrong location takes longer. |
| "Just add a nil check here" | That masks the bug; it doesn't fix it. |
| "Stack trace is enough" | Stack shows WHERE, not WHY. Keep tracing. |

---

## Red Flags — STOP

Stop and trace further if you notice:

- Proposing a fix at the error location without tracing
- Adding a nil guard without understanding WHY it's nil
- Assuming the visible error IS the root cause
- "I think it's X" without evidence from tracing
- Fixing without documenting the trace chain
- Skipping Steps 3-5 (the actual tracing)

**If you can't draw the full call chain from trigger to symptom, you haven't found the root cause.**

---

## Example: Complete Trace

**Symptom:** `attempt to index nil (field 'resources')` at Showdown:234

**Trace:**
```
Showdown.GetRewards():234    ← self.level is nil
  ↑
Showdown.Setup():180         ← self.level set from monster.levels[levelName]
  ↑
Showdown.OnShowdownStart()   ← Called by EventManager
  ↑
EventManager.Fire("showdown_start")
  ↑
UI.OnButtonClick()           ← User clicked before data loaded
```

**Root Cause:** Button enabled before monster data loaded

**Fix Location:** UI.OnButtonClick or button enable logic, NOT Showdown.GetRewards

---

## Integration

- Used by `systematic-debugging` skill in Phase 1
- Feeds into `defense-in-depth` for multi-layer validation
- Document findings in Debugger handover
- Write regression test after fix
- Git commits require human approval

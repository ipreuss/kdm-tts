---
name: systematic-debugging
description: Four-phase structured debugging methodology. Use when encountering test failures, runtime errors, "attempt to call a nil value" errors, unexpected behavior, or performance problems. Enforces root cause investigation before any fix attempts. Triggers on debugging, error, failure, nil value, crash, investigate, diagnose.
---

# Systematic Debugging

**Iron Law:** "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"

Random fixes waste time and create new bugs. You cannot propose solutions until completing Phase 1.

## When to Use

- Test failures
- Runtime errors (especially TTS console errors)
- Unexpected behavior
- Performance problems
- "attempt to call a nil value" errors
- Any bug investigation

---

## The Four Phases

### Phase 1: Root Cause Investigation (REQUIRED)

**Before ANY fix, complete all steps:**

1. **Read error messages carefully** — They often contain the solution
2. **Reproduce consistently** — What are the exact steps?
3. **Check recent changes** — `git diff`, recent handovers
4. **Gather evidence** — Add `log:Debugf(...)` if needed
5. **Trace the call stack** — Use `root-cause-tracing` skill for deep errors

**Output:** Clear statement of root cause with evidence

```markdown
Root Cause: OnShowdownStart fires before monster data loaded
Evidence: log:Debugf shows self.level is nil at Showdown.ttslua:234
Trace: GetRewards ← Setup ← OnShowdownStart ← EventManager.Fire
```

### Phase 2: Pattern Analysis

1. **Find working examples** — Locate similar working code in codebase
2. **Compare working vs broken** — List every difference
3. **Identify discrepancies** — What's different?
4. **Check module exports** — Missing exports cause nil errors

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis** — "I think X is root cause because Y"
2. **State confidence** — e.g., "85% confident"
3. **Test minimally** — Smallest possible change to test theory
4. **Verify before continuing** — If wrong, form new hypothesis

**After ≥3 failed attempts:** Question the architecture. Multiple failed fixes suggest design problems.

### Phase 4: Implementation

1. **Write failing test first** — Headless preferred, proves bug exists
2. **Implement single fix** — Address only the identified root cause
3. **Verify fix** — Run tests, confirm issue resolved
4. **Run code-reviewer** — Before handover

### Phase 5: Monitoring Mode (For Non-Reproducible Bugs)

When a bug cannot be reproduced despite thorough investigation:

1. **Add permanent logging** — Use `log:Printf()` (not `Debugf`) so it always outputs
2. **Document the logging** — Add comment explaining WHY the logging exists
3. **Mark in DEBUG_MODULES** — Add note with status "MONITORING" to prevent accidental removal
4. **Close as "cannot reproduce"** — With monitoring in place, if bug recurs, diagnostic info is captured

```lua
-- MONITORING (kdm-li3): Intermittent Unknown Error during terrain cleanup
-- If this triggers, capture the log output and reopen the bead
log:Printf("[MONITOR] TestSetup.CleanupTerrain called with deck: %s", tostring(deck))
```

This is better than leaving bugs open indefinitely or removing investigation code.

---

## Red Flags — Stop and Follow Process

If you catch yourself thinking:

| Red Flag | Response |
|----------|----------|
| "Quick fix for now, investigate later" | STOP. Return to Phase 1 |
| "Just try changing X and see" | STOP. Form hypothesis first |
| "Skip the test, I'll manually verify" | STOP. Write the test |
| "I don't understand but this might work" | STOP. Understand first |
| Multiple fix attempts without success | STOP. Return to Phase 1 |

---

## TTS-Specific Debugging

### Enabling Debug Logging

```lua
-- In your module
log:Debugf("Showdown.Setup: monster=%s, level=%s",
    tostring(monsterName), tostring(levelName))
```

Enable in `Log.ttslua`:
```lua
Log.DEBUG.MODULES = {
    ["Showdown"] = true,  -- Uncomment temporarily
}
```

**Remember to disable after debugging.**

### Common TTS Issues

| Symptom | Likely Cause |
|---------|--------------|
| "attempt to call nil" | Missing module export or require |
| "attempt to index a nil value" | Accessing unexported module state (check return statement) |
| Callback never fires | Object destroyed before callback |
| Wrong position | Coordinate system confusion |
| UI not visible | Wrong player color or z-order |

### Unexported Module State

**Problem:** "attempt to index a nil value" when accessing a field like `Module.someTable[key]`

**Root cause:** Lua modules export via `return { ... }`. If the module stores internal state that's not in the return statement, external code accessing it gets `nil`.

**Diagnostic pattern:**
1. Check the module's `return { ... }` statement
2. See what's actually exported vs what you're trying to access
3. Use exported APIs (like `Module.All()`) instead of internal state

---

## Debugging Checklist

Before implementing any fix:

- [ ] Phase 1: Root cause identified with evidence
- [ ] Phase 2: Compared with working examples
- [ ] Phase 3: Hypothesis formed and tested
- [ ] Phase 4.1: Failing test written
- [ ] Phase 4.2: Single fix implemented
- [ ] Phase 4.3: All tests pass
- [ ] Phase 4.4: code-reviewer ran

**If any box is unchecked, you are not ready to fix.**

---

## Integration

- **Debugger role:** Primary methodology
- **Implementer/Tester:** Use for quick diagnosis
- Links to `root-cause-tracing` skill for Phase 1
- Links to `test-driven-development` for Phase 4
- Links to `defense-in-depth` for multi-layer fixes
- Human maintainer handles git commits

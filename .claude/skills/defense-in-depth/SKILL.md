---
name: defense-in-depth
description: Multi-layer validation strategy to make bugs structurally impossible. Use when fixing data-related bugs, implementing new data flows, when invalid data causes deep execution failures, or after root-cause-tracing identifies validation gaps. Triggers on validation, guards, assertions, data integrity, defensive programming.
---

# Defense in Depth

**Core Principle:** "Validate at EVERY layer data passes through. Make the bug structurally impossible."

Single validation points can be bypassed through different code paths, refactoring, or test mocks. Multiple validation layers ensure bugs become structurally impossible.

## When to Use

- Fixing data-related bugs
- Implementing new data flows
- Invalid data causes deep execution failures
- After `root-cause-tracing` identifies the problem source

---

## The Four Validation Layers

### Layer 1: Entry Point Validation

Reject obviously invalid input at API boundaries.

```lua
function Module.Process(data)
    if not data then
        error("Module.Process: data required")
    end
    if not data.name then
        error("Module.Process: data.name required")
    end
    -- proceed with valid data
end
```

### Layer 2: Business Logic Validation

Ensure data makes sense for the specific operation.

```lua
function Showdown.Setup(monsterName, levelName)
    local monster = monsters[monsterName]
    if not monster then
        error("Showdown.Setup: unknown monster '" ..
            tostring(monsterName) .. "'")
    end
    local level = monster.levels[levelName]
    if not level then
        error("Showdown.Setup: monster '" .. monsterName ..
            "' has no level '" .. tostring(levelName) .. "'")
    end
    -- proceed with valid monster and level
end
```

### Layer 3: Environment Guards

Prevent dangerous operations in invalid contexts.

```lua
function Archive.Take(params)
    if not self.archiveObject then
        error("Archive.Take: archive not initialized")
    end
    if self.archiveObject.isDestroyed() then
        error("Archive.Take: archive object was destroyed")
    end
    -- proceed with valid archive
end
```

### Layer 4: Debug Instrumentation

Capture execution context for forensics when other layers fail.

```lua
log:Debugf("Archive.Take: name=%s, type=%s, archive=%s",
    tostring(params.name),
    tostring(params.type),
    tostring(self.archiveObject))
```

---

## Application Process

When fixing a data-related bug:

1. **Trace data flow** from origin through all consumption points
2. **Map checkpoints** where data passes between modules
3. **Add validation** at each layer:
   - Entry point (API boundary)
   - Business logic (semantic validity)
   - Environment (context validity)
   - Debug (forensic capture)
4. **Test each layer** to verify bypass attempts are caught

---

## Example: Complete Defense

```lua
-- Layer 1: Entry validation
function ResourceRewards.Setup(showdownData)
    if not showdownData then
        error("ResourceRewards.Setup: showdownData required")
    end
    if not showdownData.monster then
        error("ResourceRewards.Setup: showdownData.monster required")
    end

    -- Layer 2: Business logic validation
    local rewards = showdownData.level and showdownData.level.resources
    if not rewards then
        error("ResourceRewards.Setup: no resources defined for " ..
            tostring(showdownData.monster) .. " " ..
            tostring(showdownData.levelName))
    end

    -- Layer 4: Debug instrumentation
    log:Debugf("ResourceRewards.Setup: monster=%s, level=%s, rewards=%s",
        showdownData.monster, showdownData.levelName,
        Log.TableToString(rewards))

    -- Layer 3: Environment guard (if applicable)
    if not self.container then
        error("ResourceRewards.Setup: container not initialized")
    end

    -- Proceed with validated data
    self:CreateButton(rewards)
end
```

---

## Why All Four Layers?

| Layer | Catches |
|-------|---------|
| Entry | Obvious nil/missing data from caller |
| Business | Valid-looking but semantically wrong data |
| Environment | Operations in invalid state |
| Debug | Forensics when unexpected paths occur |

Different code paths, test mocks, and edge cases require each layer. Don't stop at single validation.

---

## Common Rationalizations to Reject

| Rationalization | Reality |
|-----------------|---------|
| "One validation layer is enough" | Different code paths bypass single layers |
| "Performance cost of multiple checks" | nil errors cost far more to debug than guard clauses |
| "I'll add more validation later" | You won't. Add it now. |
| "Tests will catch missing validation" | Tests can be mocked; production can't |
| "Entry validation covers everything" | Refactoring can bypass entry points |
| "This data is always valid here" | Famous last words. Validate anyway. |

---

## Red Flags — STOP

Stop and add validation if you notice:

- Thinking "this layer is good enough"
- Skipping environment guards because "object is always initialized"
- No debug logging at data consumption points
- Assuming upstream code validates correctly
- Fixing a nil error without adding guards at ALL layers
- "Trust the caller" reasoning

**If you fixed a data bug without adding 4 layers of validation, you haven't fixed it — you've hidden it.**

---

## Integration

- Aligns with PROCESS.md "Fail fast and meaningfully"
- Uses guard clause pattern from `kdm-coding-conventions`
- Apply after `root-cause-tracing` identifies gaps
- Verify with `verification-before-completion`
- Human maintainer handles git commits

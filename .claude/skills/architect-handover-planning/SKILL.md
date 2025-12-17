---
name: architect-handover-planning
description: Creates detailed, implementation-ready task breakdowns for Implementer handovers. Use when Architect has completed design decisions and needs to create a comprehensive handover with exact file paths, code examples, and verification steps. Assumes Implementer may have minimal context. Triggers on "ready to hand off", "create implementation plan", "detailed tasks for", or when Architect role completes design phase.
---

# Architect Handover Planning

Create comprehensive implementation plans with bite-sized tasks, exact file paths, complete code examples, and verification steps. Assumes the Implementer has minimal codebase context.

## When to Use

- Architect has completed design decisions
- Ready to hand off to Implementer
- Feature involves multiple files or complex implementation
- After using `brainstorming` skill to finalize design
- When phrases appear: "ready to hand off", "create implementation plan", "detailed tasks"

## Reference Work Folder Design Documents

**Important:** Don't duplicate content from `work/<bead-id>/design.md` in the handover.

Per PROCESS.md, handovers should focus on "what action is needed now" while work folders provide "persistent context." The handover should:

1. **Reference** the design.md file for detailed design decisions
2. **Summarize** key points (1-3 sentences)
3. **Focus on** implementation steps and verification

```markdown
## Design Context

See `work/kdm-xxx/design.md` for full design decisions. Key points:
- [Summary of architectural approach]
- [Key pattern or integration point]
```

**Avoid:** Copying code examples, full data structures, or detailed rationale that's already in design.md.

## When NOT to Use

- Simple single-file changes
- Design is still being explored (use `brainstorming` first)
- Bug fixes with obvious fix location

## Announce at Start

> "I'll use the architect-handover-planning skill to create a detailed implementation plan."

---

## Bite-Sized Task Granularity

Each step is **one action (2-5 minutes)**:

- "Write the failing test" — step
- "Run it to confirm it fails" — step
- "Implement minimal code to pass" — step
- "Run tests to confirm they pass" — step
- "Checkpoint: ready for next task" — step

**Why this granular?** Implementers with minimal context can follow mechanical steps without needing to understand the full picture. Each step is verifiable before proceeding.

---

## Handover Document Structure

Save to: `handover/HANDOVER_ARCHITECT_IMPLEMENTER_<feature>.md`

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach and key decisions]

**Files Overview:**
| File | Action | Purpose |
|------|--------|---------|
| `path/to/file.lua` | Create | New module for X |
| `path/to/existing.lua` | Modify | Add Y integration |
| `tests/feature_test.lua` | Create | Unit tests |

**Testing Requirements:**
- [ ] Headless tests for: [list specific behaviors]
- [ ] TTS console tests for: [list if applicable, or "N/A - no TTS interaction"]

---

## Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.lua`
- Modify: `exact/path/to/existing.lua:123-145`
- Test: `tests/exact/path/to/test.lua`

### Step 1: Write the failing test

```lua
-- tests/feature_test.lua
Test.test("specific behavior description", function(t)
    local Module = require("Kdm/Module")

    local result = Module.Function(input)

    t:assertEqual(result, expected)
end)
```

### Step 2: Run test to verify it fails

```bash
lua tests/run.lua
```

**Expected:** FAIL with "module 'Kdm/Module' not found" or similar

### Step 3: Write minimal implementation

```lua
-- Kdm/Module.ttslua
local Module = {}

function Module.Function(input)
    return expected
end

return Module
```

### Step 4: Run test to verify it passes

```bash
lua tests/run.lua
```

**Expected:** PASS

### Step 5: Checkpoint

- [ ] Test passes
- [ ] Code is minimal (no over-engineering)
- [ ] Ready for next task

---

## Task 2: [Next Component]

[Same structure...]

---

## Final Verification

After all tasks complete:

1. Run full test suite: `lua tests/run.lua`
2. If TTS tests specified: `./updateTTS.sh` then `>testall` in TTS
3. Run code-reviewer subagent before handover to Tester

## Open Questions

- [Any decisions Implementer needs to make]
- [Anything that might need clarification]
```

---

## Task Structure Template

For each task, include:

### 1. Files Section
```markdown
**Files:**
- Create: `exact/path/to/new_file.lua`
- Modify: `exact/path/to/existing.lua:123-145` (line range if known)
- Test: `tests/path/to/test.lua`
```

### 2. Test-First Steps

Always structure as:
1. Write failing test (with complete code)
2. Run to verify failure (with expected error)
3. Write minimal implementation (with complete code)
4. Run to verify pass
5. Checkpoint

### 3. Complete Code Examples

```lua
-- ❌ BAD: Vague instructions
-- "Add validation for the input"

-- ✅ GOOD: Complete, copy-paste ready
function Module.Validate(input)
    if not input then
        error("Input required")
    end
    if type(input) ~= "table" then
        error("Input must be table, got: " .. type(input))
    end
    return true
end
```

### 4. Exact Commands with Expected Output

```markdown
### Step 2: Run test to verify it fails

```bash
lua tests/run.lua
```

**Expected output:**
```
FAIL: specific behavior description
  Expected: 5
  Actual: nil
```
```

---

## Key Principles

| Principle | Application |
|-----------|-------------|
| **DRY** | Extract shared logic, reference existing patterns |
| **YAGNI** | Only implement what's needed now, no "future-proofing" |
| **TDD** | Test first, minimal implementation, refactor if needed |
| **Exact paths** | No ambiguity about which file to edit |
| **Complete code** | Copy-paste ready, not "add validation here" |
| **Verification steps** | Every step has expected outcome |

---

## Common Rationalizations to Reject

| Rationalization | Reality |
|-----------------|---------|
| "Implementer can figure out the details" | No. Vague handovers cause rework. Be explicit. |
| "TDD is overkill for simple tasks" | Every task gets test-first. No exceptions. |
| "Code example would be too long" | Long examples prevent misunderstanding. Include them. |
| "File paths are obvious" | Nothing is obvious. Write exact paths. |
| "They'll know what I mean" | They won't. Write it out. |
| "Verification steps slow things down" | Missing verification causes bugs. Include them. |

---

## Red Flags — Incomplete Plan

Stop and add more detail if you notice:

- Vague file paths ("somewhere in Kdm/")
- Missing code examples ("implement validation")
- No verification steps after tasks
- Skipping test-first structure
- "Figure out the best approach" language
- No expected output for test runs
- Missing TTS test specification when UI is involved

**If an Implementer with zero context couldn't follow your plan mechanically, it's not ready.**

---

## Integration with Workflow

### Before Creating Plan

1. Design decisions finalized (use `brainstorming` skill if not)
2. Understand existing patterns in codebase
3. Identify all files that will be touched

### After Creating Plan

1. Save to `handover/HANDOVER_ARCHITECT_IMPLEMENTER_<feature>.md`
2. Update `handover/QUEUE.md` with PENDING entry
3. Summarize handover in response (key points, task count)

Git commits require human approval.

### Implementer Workflow

Implementer follows plan task-by-task:
1. Read task, understand scope
2. Follow steps exactly
3. Verify each checkpoint
4. Use `code-reviewer` subagent after completing all tasks
5. Hand off to Tester

---

## TTS-Specific Considerations

When the feature involves TTS interactions, specify clearly:

```markdown
**Testing Requirements:**
- [ ] Headless tests for: business logic, data transformations
- [ ] TTS console tests for: UI rendering, Archive operations, deck manipulation

**TTS Test Specification:**
```lua
-- Add to TTSTests.ttslua ALL_TESTS table
{ name = "Feature: button appears after setup", bead = "kdm-xxx", fn = function(onComplete)
    Showdown.Setup("White Lion", "Level 1")
    Wait.condition(function()
        return FeatureButton.IsVisible()
    end, function()
        if FeatureButton.IsVisible() then
            log:Printf("TEST RESULT: PASSED")
        else
            log:Printf("TEST RESULT: FAILED - button not visible")
        end
        onComplete()
    end)
end },
```
```

---

## Example: Simple Feature

```markdown
# Add Monster Level Display Implementation Plan

**Goal:** Show current monster level on the showdown board

**Architecture:** Add `MonsterLevelDisplay` module that listens to Showdown events and renders level text using existing UI patterns.

**Files Overview:**
| File | Action | Purpose |
|------|--------|---------|
| `Kdm/MonsterLevelDisplay.ttslua` | Create | Display module |
| `Kdm/Showdown.ttslua` | Modify | Fire event with level |
| `tests/monster_level_display_test.lua` | Create | Unit tests |

**Testing Requirements:**
- [x] Headless tests for: level extraction, event handling
- [x] TTS console tests for: UI visibility after setup

---

## Task 1: Extract level from showdown data

**Files:**
- Create: `Kdm/MonsterLevelDisplay.ttslua`
- Test: `tests/monster_level_display_test.lua`

### Step 1: Write the failing test

```lua
-- tests/monster_level_display_test.lua
require("tests/framework")

Test.test("GetLevelText returns formatted level", function(t)
    local Display = require("Kdm/MonsterLevelDisplay")

    local text = Display.GetLevelText({ level = 2 })

    t:assertEqual(text, "Level 2")
end)
```

### Step 2: Run test to verify it fails

```bash
lua tests/run.lua
```

**Expected:** FAIL - module not found

### Step 3: Write minimal implementation

```lua
-- Kdm/MonsterLevelDisplay.ttslua
local MonsterLevelDisplay = {}

function MonsterLevelDisplay.GetLevelText(showdownData)
    return "Level " .. showdownData.level
end

return MonsterLevelDisplay
```

### Step 4: Run test to verify it passes

```bash
lua tests/run.lua
```

**Expected:** PASS

### Step 5: Checkpoint

- [ ] Test passes
- [ ] Implementation is minimal
- [ ] Ready for Task 2

---

## Task 2: [Continue with event integration...]
```

---

## References

- `PROCESS.md` — Architect handover requirements, TTS testing needs
- `kdm-test-patterns` skill — Testing patterns and conventions
- `kdm-coding-conventions` skill — Code style and module structure
- `handover/QUEUE.md` — Handover queue workflow

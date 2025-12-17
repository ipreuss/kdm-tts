---
name: test-driven-development
description: Strict test-first development using Red-Green-Refactor cycle. Use when implementing features, fixing bugs, refactoring, or making behavior changes. Enforces the Iron Law - NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST. Triggers on TDD, test-first, red-green-refactor, failing test, write test first.
---

# Test-Driven Development

**Iron Law:** "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"

If code precedes tests, delete it and start over. No exceptions without explicit user approval.

## When to Use

- New features
- Bug fixes
- Refactoring
- Any behavior changes

## When NOT to Use (requires user approval)

- Throwaway prototypes
- Pure configuration changes
- Generated code

---

## The Red-Green-Refactor Cycle

### RED Phase: Write Failing Test

Write ONE minimal test demonstrating desired behavior.

```lua
-- tests/monster_display_test.lua
Test.test("GetLevelText returns formatted level", function(t)
    local Display = require("Kdm/MonsterLevelDisplay")

    local text = Display.GetLevelText({ level = 2 })

    t:assertEqual(text, "Level 2")
end)
```

**Requirements:**
- One specific behavior per test
- Clear, descriptive name
- Uses real code (mocks only at TTS boundary)

### Verify RED

**MANDATORY:** Run the test.

```bash
lua tests/run.lua
```

Confirm:
- Test FAILS (not errors due to syntax)
- Failure message matches expectations
- Failure is due to missing feature

**If test passes immediately:** You're testing existing behavior. Fix the test.

### GREEN Phase: Write Minimal Code

Write the SIMPLEST code that makes the test pass.

```lua
-- Kdm/MonsterLevelDisplay.ttslua
local MonsterLevelDisplay = {}

function MonsterLevelDisplay.GetLevelText(data)
    return "Level " .. data.level
end

return MonsterLevelDisplay
```

**Don't:**
- Add extra features
- Over-engineer
- Refactor unrelated code

### Verify GREEN

**MANDATORY:** Run the test.

```bash
lua tests/run.lua
```

Confirm:
- Test PASSES
- All other tests still pass
- No errors or warnings

**If test fails:** Fix the implementation, NOT the test.

### REFACTOR Phase

Only after green:
- Remove duplication
- Improve naming
- Extract helpers

**Keep tests passing throughout.**

### REPEAT

Next failing test for next behavior.

---

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One behavior | "validates and formats and saves" |
| **Named** | Describes behavior | "test1", "testFunction" |
| **Real** | Uses production code | Heavy mocking |

---

## Bug Fix Pattern

1. **Write failing test** reproducing the bug
2. **Verify** test fails
3. **Fix** the bug
4. **Verify** test passes
5. Bug can **never recur** undetected

```lua
-- Reproduce the bug
Test.test("handles nil monster name", function(t)
    local result = Showdown.Setup(nil, "Level 1")
    t:assertEqual(result.error, "monster name required")
end)
```

---

## Common Rationalizations to Reject

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks; testing takes 30 seconds |
| "I'll test after" | Tests passing immediately prove nothing |
| "Already manually tested" | Manual testing isn't reproducible |
| "TDD slows me down" | TDD is faster than debugging in TTS |
| "Keep code as reference" | You'll adapt it — that's tests-after |

---

## Red Flags — Start Over

If you notice:

- Code written before tests
- Tests pass immediately
- Can't explain why test should fail
- "Just this once" exceptions
- Keeping code as "reference"

**Delete the code. Start with a failing test.**

---

## TTS-Specific TDD

| Test Type | Use For | Speed |
|-----------|---------|-------|
| Headless | Business logic, data transforms | ~2 sec |
| TTS Console | UI, Archive ops, deck handling | ~1 min |

**Prefer headless.** Only use TTS console tests when headless is impossible.

See `kdm-test-patterns` for detailed guidance.

---

## Verification Checklist

Before claiming "done":

- [ ] Every new function has a test
- [ ] Watched each test FAIL before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass
- [ ] All tests pass
- [ ] No errors or warnings

Can't check all boxes? You skipped TDD. Restart.

---

## Integration

- Implementer follows TDD for all changes
- Tester writes acceptance tests (TDD applies to test code too)
- Links to `verification-before-completion` for final check
- Links to `kdm-test-patterns` for test type guidance
- Git commits require human approval

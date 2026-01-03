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

## Phase 0: Coverage Assessment (BEFORE any changes)

**Before writing new code, assess existing test coverage of the code you will modify.**

This is NOT "do tests exist?" but "is coverage actually good?"

### Step 0a: Identify Code to Modify

List all files and functions that will change.

### Step 0b: Find Existing Tests

```bash
# Find tests for a module
lua tests/run.lua 2>&1 | grep -i "[module]"
# Or search test files
grep -r "ModuleName" tests/
```

### Step 0c: Assess Coverage Quality

For each function you will modify, answer:

| Question | If No → Action |
|----------|----------------|
| Does a test exist for this function? | Write characterization test |
| Does the test cover the code path I'm changing? | Write characterization test for that path |
| Does the test verify the behavior I need to preserve? | Write characterization test for that behavior |

**"Some tests exist" ≠ "Good coverage"**

### Step 0d: Add Characterization Tests (if needed)

Use `characterization-test-writer` agent to capture existing behavior BEFORE any changes.

**Triggers:**
- Function has no tests
- Tests don't cover the code path being modified
- Behavior is undocumented or surprising

### Step 0e: Use Seam-Finder (if needed)

If code is hard to test (TTS dependencies, global state), use `seam-finder` agent to identify injection points.

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

### COVERAGE REVIEW Phase

After refactoring, assess whether more tests are needed:

| Question | If Yes → Action |
|----------|-----------------|
| Did refactoring create new public functions? | Write unit tests for them |
| Are there edge cases not yet covered? | Add edge case tests |
| Did you discover undocumented behavior? | Add integration tests |
| Is the module now easier to test? | Consider deeper unit test coverage |

**Goal:** Each Red-Green-Refactor cycle should improve overall test coverage.

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

## Bug Found or Behavior Change Requested

**When a bug is discovered or behavior change is requested during development, STOP and write a test FIRST.**

This applies whether you found the bug yourself, the user reported it, or requirements changed mid-implementation.

### Step 1: Capture in a Test

**Always start with the lowest appropriate test level:**

| Change Type | Test Level | Example |
|-------------|------------|---------|
| Internal logic bug | Unit test | Calculation returns wrong value |
| Module interaction bug | Integration test | Data flows incorrectly between modules |
| User-visible behavior | Acceptance test | Feature doesn't work as specified |
| TTS-specific issue | TTS console test | UI doesn't render, object doesn't spawn |

**If user-noticeable:** Write acceptance test AND consider TTS test if it involves UI/spawning.

### Step 2: Verify Test Fails

Run the test to confirm it captures the bug/missing behavior:

```bash
lua tests/run.lua
```

The test MUST fail. If it passes, your test doesn't capture the issue.

### Step 3: Fix the Bug / Implement the Change

Only now write the production code.

### Step 4: Verify Test Passes

Run tests again. The bug can **never recur** undetected.

### Example: Bug Discovered During Development

```lua
-- You discover: Setup crashes when monster name is nil
-- STOP. Write the test FIRST:

Test.test("Setup returns error when monster name is nil", function(t)
    local result = Showdown.Setup(nil, "Level 1")
    t:assertEqual(result.error, "monster name required")
end)

-- Verify it fails, THEN fix the code
```

### Example: Behavior Change Requested

```lua
-- User says: "Actually, rewards should include strange resources for L3+"
-- STOP. Write the test FIRST:

Test.test("L3+ monsters include strange resources in rewards", function(t)
    local rewards = Rewards.GetFor("White Lion", 3)
    t:assertContains(rewards.resources, "strange")
end)

-- Verify it fails, THEN implement the change
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

**Phase 0 (Coverage Assessment):**
- [ ] Identified all code that will change
- [ ] Assessed existing test coverage (not just "tests exist")
- [ ] Added characterization tests for uncovered code paths

**Red-Green-Refactor:**
- [ ] Watched each test FAIL before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass
- [ ] Refactored while keeping tests green

**Coverage Review:**
- [ ] Every new function has a test
- [ ] Considered edge cases and integration tests
- [ ] All tests pass with no errors or warnings

Can't check all boxes? You skipped TDD. Restart.

---

## Integration

- Implementer follows TDD for all changes
- Tester writes acceptance tests (TDD applies to test code too)
- Links to `verification-before-completion` for final check
- Links to `kdm-test-patterns` for test type guidance
- Git commits require human approval

---
name: test-first-principles
description: Core testing principles and anti-patterns for writing effective tests. Use when writing tests, reviewing test quality, encountering test anti-patterns, or deciding between behavioral vs structural tests. Triggers on writing tests, test quality, anti-pattern, behavioral test, structural test, mock, stub, test smell.
---

# Test First Principles

Core principles for writing tests that catch bugs and serve as documentation.

## Test Hierarchy

| Layer | Purpose | Tools | Speed |
|-------|---------|-------|-------|
| **Unit Tests** | Test pure business logic in isolation | `tests/framework.lua`, stubs | ~2 seconds |
| **Integration Tests** | Verify cross-module interactions | TTSSpawner seam, module stubs | ~2 seconds |
| **Acceptance Tests** | Verify user-visible behavior end-to-end | `TestWorld`, `ArchiveSpy` | ~2 seconds |
| **TTS Console Tests** | Verify TTS environment interactions | `>testall`, `>testcurrent` | ~1 min each |

## Core Principles

1. **Headless tests strongly preferred** — Run in seconds, catch bugs before TTS launch
2. **TTS console tests when headless impossible** — Automated `>teststrain` style tests over manual verification
3. **Manual testing strongly discouraged** — Only when automated TTS tests are also impossible
4. **Tests must exercise real production code** — Never reimplement business logic in test helpers
5. **Spy pattern over manual state** — Intercept and verify calls, don't track state manually

## Behavioral vs Structural Tests

**Behavioral tests** verify *what happens* — they call production code and check outputs, spy calls, or state changes.

**Structural tests** verify *what the code looks like* — they read source files, match strings, or check exports exist.

### Rule: Prefer Behavioral Tests

Structural tests are almost always wrong for acceptance testing. If your test opens a source file with `io.open()`, it's structural.

### Test Smells (avoid these)

- Reading source code in tests
- String-matching against implementation
- Checking that a function "exists" without calling it
- Testing internal constants instead of observable behavior

### "I can't test this behaviorally" is almost always wrong

When you think a structural test is necessary, stop and ask:
1. What state changes after the action? (deck size, object count, position)
2. What calls should have been made? (spy on Archive, Container, spawner)
3. What can the user observe? (card appears, button changes, message shown)
4. Can I add a test interface to expose this? (Tester may add `_test` exports)

## Testing Anti-Patterns

### Anti-Pattern 1: Testing Mock Behavior

**Problem:** Assertions verify mocks exist, not real behavior.

```lua
-- BAD: Testing that the mock exists
t:assertNotNil(archiveMock)
t:assertEqual(archiveMock.name, "test-archive")
```

**Solution:** Test real component behavior with mocks providing dependencies.

```lua
-- GOOD: Testing real behavior, mock provides dependency
Archive.Test_SetSpawner(spawnerStub)
Archive.Take({ name = "Test Card", type = "Fighting Arts" })
t:assertEqual(#spawnerStub.takeCalls, 1)  -- Verify real code made the call
```

**Gate Question:** "Am I testing real behavior or mock existence?"

### Anti-Pattern 2: Test-Only Methods in Production

**Problem:** Adding methods only for test cleanup pollutes production.

```lua
-- BAD: Cleanup method only used by tests
function Archive.ClearAllForTesting()
    self._cards = {}
end
```

**Solution:** Place cleanup logic in test utilities. Use `_test` exports sparingly for exposing internals, not cleanup.

**Our Pattern:** `Module._test.Function` is OK for exposing internal functions for testing, but cleanup belongs in test files.

### Anti-Pattern 3: Mocking Without Understanding

**Problem:** Over-mocking eliminates side effects tests depend on.

```lua
-- BAD: Mocked everything, test proves nothing
local Archive = { Take = function() return {} end }
local Container = { AddCard = function() return true end }
-- Test passes but real integration is broken
```

**Solution:** Understand what real method does before mocking. Mock at TTS boundary only.

**Our Pattern:** Mock at TTS boundary (TTSSpawner), use real modules above.

### Anti-Pattern 4: Incomplete Mocks

**Problem:** Partial mocks missing fields real API provides.

```lua
-- BAD: Missing fields real TTS object has
local objectStub = { getName = function() return "Card" end }
-- Crashes when code calls objectStub.getPosition()
```

**Solution:** Mirror complete API response structure.

### Anti-Pattern 5: Tests as Afterthought

**Problem:** Writing tests after implementation provides false confidence.

**Solution:** TDD — write failing test first.

### Anti-Pattern Red Flags

Stop and reconsider if you notice:
- Assertions checking for test-specific identifiers
- Methods called only in test files (except `_test` exports)
- Mock setup >50% of test code
- Tests failing when mocks are removed
- Mocking "just to be safe"

## Real Data vs Mock Data

### Mock data is appropriate for:
- TTS objects and APIs (no real game engine in tests)
- External dependencies (network, file I/O)
- Timing and async behavior
- Unit tests testing isolated logic

### Mock data is NOT appropriate for:
- Business data the feature must correctly process
- Expansion data integration (card names, deck contents, resource types)
- Cross-module data wiring
- Acceptance tests that claim to verify "feature X works"

### Mutation Test: Would a Typo Fail This Test?

For data integration features, ask: "If I introduce a typo in the expansion data (e.g., 'Elder Cat Tooth' instead of 'Elder Cat Teeth'), would this test fail?" If no, the test isn't verifying what it claims.

## Test Helpers Must Match Production Scope

**Problem:** Test helpers that only check for Card objects miss cards that have merged into Decks.

**Solution:** Test helpers must handle the same object types as production code:

```lua
-- WRONG: Only counts Card objects
local function FindCardsInLocation(location)
    local cards = {}
    for _, obj in ipairs(location:AllObjects()) do
        if obj.tag == "Card" then
            table.insert(cards, obj)
        end
    end
    return cards
end

-- CORRECT: Counts both Cards and cards inside Decks
local function CountCardsInLocation(location)
    local count = 0
    for _, obj in ipairs(location:AllObjects()) do
        if obj.tag == "Card" then
            count = count + 1
        elseif obj.tag == "Deck" then
            count = count + obj.getQuantity()
        end
    end
    return count
end
```

## Test Naming Conventions

### Acceptance Tests
Prefix with `ACCEPTANCE:` to distinguish from unit tests:
```lua
Test.test("ACCEPTANCE: hunt cleanup removes decks with only hunt cards", function(t)
```

### Characterization Tests
Prefix with `CHARACTERIZATION:` when documenting existing behavior before modification:
```lua
Test.test("CHARACTERIZATION: Clean() ignores cards not matching type filter", function(t)
```

**After fixing a bug captured by characterization test:**
- Remove `CHARACTERIZATION:` prefix if test now documents expected behavior
- Or update the test to verify the NEW expected behavior

This prevents confusion about whether a test documents a bug or expected behavior.

## Test Quality Bar

- **Breaking production code must fail tests** — Verify by temporarily breaking code
- **Test helpers should be simple** — Complex helpers indicate design issues

### Verification: Mutation Testing

**Always verify tests are meaningful:** Temporarily break the mod logic and confirm the test fails.

```lua
-- In Campaign.ttslua, change max 5 → max 3:
local selected = Campaign.RandomSelect(unlockedFightingArts, 3)  -- was 5

-- Run tests - they MUST fail:
-- ✗ ACCEPTANCE: at most 5 strain fighting arts added
```

If breaking the mod doesn't break the test, the test is worthless.

## When to Use Stubs vs Real Modules

**Stub environment dependencies:**
- TTS objects and APIs (no real game engine in tests)
- File I/O, network calls
- Time-dependent behavior
- Complex UI rendering

**Use real modules for integration:**
- Business logic calling business logic
- Data transformations
- Module coordination and orchestration

**Critical rule:** Don't stub a module just to avoid "function not exported" errors — that defeats the purpose of the test.

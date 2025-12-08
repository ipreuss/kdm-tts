# Testing Strategy

This document defines testing patterns, principles, and guidelines for the KDM TTS mod. It complements `PROCESS.md` (workflow) and `CODING_STYLE.md` (code conventions).

---

## Test Hierarchy

We aim for **outstanding test quality** — investment in tests saves significant debugging time.

| Layer | Purpose | Tools | Speed |
|-------|---------|-------|-------|
| **Unit Tests** | Test pure business logic in isolation | `tests/framework.lua`, stubs | ~2 seconds |
| **Integration Tests** | Verify cross-module interactions | TTSSpawner seam, module stubs | ~2 seconds |
| **Acceptance Tests** | Verify user-visible behavior end-to-end | `TestWorld`, `ArchiveSpy` | ~2 seconds |
| **TTS Console Tests** | Verify TTS environment interactions | `>testall`, `>testfocus` | ~1 min each |

---

## Test Principles

1. **Headless tests strongly preferred** — Run in seconds, catch bugs before TTS launch
2. **TTS console tests when headless impossible** — Automated `>teststrain` style tests over manual verification
3. **Manual testing strongly discouraged** — Only when automated TTS tests are also impossible
4. **Tests must exercise real production code** — Never reimplement business logic in test helpers
5. **Spy pattern over manual state** — Intercept and verify calls, don't track state manually
6. **All code paths through spies** — Consistent verification across all test scenarios

---

## Behavioral vs Structural Tests

- **Behavioral tests** verify *what happens* — they call production code and check outputs, spy calls, or state changes
- **Structural tests** verify *what the code looks like* — they read source files, match strings, or check exports exist

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

**Tester may add test interfaces to production code** — exposing internal functions via `Module._test.Foo = Foo` or similar seams is permitted, as long as production logic is unchanged. This removes the excuse "I can't access that function."

If you identify a behavioral approach only after being challenged, you should have found it first. The default is behavioral — structural requires explicit justification approved by Product Owner.

---

## Test Quality Bar

- **Breaking production code must fail tests** — Verify by temporarily breaking code
- **Test helpers should be simple** — Complex helpers indicate design issues
- **`deckContains()` should be <15 lines** with no edge-case handling

---

## Cross-Module Integration Tests

**Principle:** When code in module A calls module B, there **must** be a headless integration test that exercises that call path. The test must actually execute the code path, not just check exports exist.

**Why this matters:** A recurring bug pattern is client code accessing fields/functions that aren't exported by other modules. These bugs only surface at TTS runtime, where they're expensive to debug (5-10 minute cycles). Headless integration tests catch them in seconds.

**Rule:** When implementing or changing code that calls another module:
1. Identify the cross-module boundary (A calls B)
2. Write/update a headless test that exercises A's code path through B
3. Modules further down the chain (B calls C) may be mocked if needed
4. The immediate dependency (B) must be the real module, not a stub

**Example:** Module A (Strain) calls Module B (Archive) which calls Module C (TTSSpawner):
- Test must use real Strain and real Archive
- TTSSpawner may be stubbed (it's the TTS boundary)
- This catches: missing exports in Archive, wrong function signatures, nil access errors

### ❌ Avoid: Export-Checking Tests
```lua
-- BAD: Brittle, reactive, no real value
Test.test("Module exports all functions", function(t)
    local Module = require("Module")
    t:assertNotNil(Module.FunctionA)  -- Just checks it exists
    t:assertNotNil(Module.FunctionB)  -- Doesn't verify it works
end)
```

### ✅ Prefer: True Integration Tests
```lua
-- GOOD: Actually executes the integration
Test.test("Strain->Archive card spawning integration", function(t)
    setupMinimalTTSStubs()
    local Strain = require("Kdm/Strain")

    -- ACTUALLY CALL Strain, which calls Archive internally
    local ok = Strain.Test._TakeRewardCard(Strain, {
        name = "Test Card",
        type = "Fighting Arts",
        position = { x = 0, y = 0, z = 0 },
        spawnFunc = function(card)
            t:assertNotNil(card)
        end
    })

    t:assertTrue(ok, "Integration should succeed")
end)
```

**Implementer responsibility:** When adding code that calls another module, the implementer must add an integration test covering that call path before handover. "Tester will add tests" is not acceptable for cross-module integration — these are implementation-level tests, not acceptance tests.

---

## TTS Console Test Commands

TTS tests are slower than headless tests, so two commands are available:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `>testall` | Run all TTS tests (~13 tests) | Before closing a bead, after major changes |
| `>testfocus` | Run only tests for current bead | During active development |

**Focused testing workflow:**
1. When starting work on a bead, update `FOCUS_BEAD` in `TTSTests.ttslua:86`
2. Use `>testfocus` during development for fast feedback (~2 tests vs ~13)
3. Run `>testall` before marking work complete

**Tagging tests with beads:**
```lua
-- In ALL_TESTS table:
{ name = "Test Name", bead = "kdm-xxx", fn = function(onComplete) ... end },
```

Tests without a `bead` field are regression tests (run with `>testall` only). Tests tagged with a bead run when that bead matches `FOCUS_BEAD`.

---

## TTS Visual Verification

When handing off UI features to Product Owner, include evidence that the UI renders correctly:
- Screenshot showing the element in TTS
- Or reference to passing TTS console test that verifies visibility

"Tests pass" is not sufficient for UI — show it works.

---

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

**Critical rule:** Don't stub a module just to avoid "function not exported" errors - that defeats the purpose of the test.

---

## Real Data vs Mock Data

**Mock data is appropriate for:**
- TTS objects and APIs (no real game engine in tests)
- External dependencies (network, file I/O)
- Timing and async behavior
- Unit tests testing isolated logic

**Mock data is NOT appropriate for:**
- Business data the feature must correctly process
- Expansion data integration (card names, deck contents, resource types)
- Cross-module data wiring
- Acceptance tests that claim to verify "feature X works"

**Mutation test:** For data integration features, ask: "If I introduce a typo in the expansion data (e.g., 'Elder Cat Tooth' instead of 'Elder Cat Teeth'), would this test fail?" If no, the test isn't verifying what it claims.

### E2E Testing Requirement for Data Integration

**Features that integrate with expansion data require at least one test using real expansion files.**

```lua
-- ❌ BAD: Mock data - won't catch typos in Core.ttslua
modules.Showdown.level = { resources = { strange = "Elder Cat Teeth" } }
local result = ResourceRewards.GetStrangeResource()
t:assertEqual(result, "Elder Cat Teeth")  -- Passes even if Core.ttslua is wrong

-- ✅ GOOD: Real data - will fail if Core.ttslua has typos
require("Kdm/Expansion/Core")  -- Load real expansion data
Showdown.Setup("White Lion", "Level 3")  -- Uses real data
local result = ResourceRewards.GetStrangeResource()
t:assertEqual(result, "Elder Cat Teeth")  -- Fails if Core.ttslua is wrong
```

**Tester checklist for data integration features:**
- [ ] At least one headless test loads real expansion data via `require("Kdm/Expansion/...")`
- [ ] Tests would fail if expansion data had typos

---

## TTSSpawner Test Seam Pattern

**Problem:** Missing module exports cause runtime nil errors that are expensive to debug (require TTS launch, 5-10 minute debug cycles).

**Solution:** For modules with TTS API dependencies, use the TTSSpawner pattern:

1. **Extract TTS calls** into `Util/TTSSpawner.ttslua`
2. **Add test seam** to module: `Module._spawner` field with `Test_SetSpawner()` / `Test_ResetSpawner()`
3. **Write integration tests** that verify exports exist by exercising real call paths

**Current implementations:** See `Archive.ttslua`, `Util/TTSSpawner.ttslua`, `tests/stubs/tts_spawner_stub.lua`

---

## TTS Adapter Pattern for Acceptance Tests

**Problem:** Acceptance tests that reimplement business logic test the test code, not the mod.

**Solution:** Extract pure business logic from TTS-dependent modules and call real mod code from acceptance tests.

**Pattern:**
1. **Extract pure logic** into testable functions (e.g., `Campaign.CalculateStrainRewards`)
2. **Expose via `_test` table** for acceptance test access
3. **TestWorld calls real mod code**, not duplicate implementations

**Key principle:** TestWorld should be thin (wiring only), not reimplement business logic.

**Verify exports before calling:** When writing tests that call functions via `_test` tables, always verify the function is actually exported before running the test. Check the module's `_test = { ... }` block to confirm the function is listed. Missing exports cause cryptic "attempt to index a nil value" errors at runtime.

**Verification:** If breaking the mod logic doesn't fail tests, the tests are worthless. Always verify by temporarily breaking logic.

**Current implementations:** See `Campaign.ttslua`, `tests/acceptance/test_world.lua`, `Util/TTSAdapter.lua`

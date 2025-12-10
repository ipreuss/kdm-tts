---
name: kdm-test-patterns
description: Testing patterns, guidelines, and anti-patterns for the KDM TTS mod. Covers behavioral vs structural tests, real vs mock data decisions, TTSSpawner test seam pattern, spy/stub patterns, TTS console test commands (>testall, >testfocus), test organization (tests/<area>_test.lua), testing anti-patterns to avoid, and when headless tests are sufficient vs when TTS console tests are needed. Use when writing or reviewing tests, implementing features with test requirements, or when user mentions testing, acceptance, unit, integration, spy, mock, stub, behavioral, structural, or anti-pattern.
---

# KDM Test Patterns

Consolidated testing knowledge for the KDM TTS mod project. This skill auto-activates when Tester, Implementer, or Reviewer works with tests.

## Test Hierarchy

**Investment in test quality saves significant debugging time.**

| Layer | Purpose | Tools | Speed |
|-------|---------|-------|-------|
| **Unit Tests** | Test pure business logic in isolation | `tests/framework.lua`, stubs | ~2 seconds |
| **Integration Tests** | Verify cross-module interactions | TTSSpawner seam, module stubs | ~2 seconds |
| **Acceptance Tests** | Verify user-visible behavior end-to-end | `TestWorld`, `ArchiveSpy` | ~2 seconds |
| **TTS Console Tests** | Verify TTS environment interactions | `>testall`, `>testfocus` | ~1 min each |

## Core Test Principles

1. **Headless tests strongly preferred** — Run in seconds, catch bugs before TTS launch
2. **TTS console tests when headless impossible** — Automated `>teststrain` style tests over manual verification
3. **Manual testing strongly discouraged** — Only when automated TTS tests are also impossible
4. **Tests must exercise real production code** — Never reimplement business logic in test helpers
5. **Spy pattern over manual state** — Intercept and verify calls, don't track state manually
6. **All code paths through spies** — Consistent verification across all test scenarios

---

## Testing Anti-Patterns

### Anti-Pattern 1: Testing Mock Behavior

**Problem:** Assertions verify mocks exist, not real behavior.

```lua
-- ❌ BAD: Testing that the mock exists
t:assertNotNil(archiveMock)
t:assertEqual(archiveMock.name, "test-archive")
```

**Solution:** Test real component behavior with mocks providing dependencies.

```lua
-- ✅ GOOD: Testing real behavior, mock provides dependency
Archive.Test_SetSpawner(spawnerStub)
Archive.Take({ name = "Test Card", type = "Fighting Arts" })
t:assertEqual(#spawnerStub.takeCalls, 1)  -- Verify real code made the call
```

**Gate Question:** "Am I testing real behavior or mock existence?"

### Anti-Pattern 2: Test-Only Methods in Production

**Problem:** Adding methods only for test cleanup pollutes production.

```lua
-- ❌ BAD: Cleanup method only used by tests
function Archive.ClearAllForTesting()
    self._cards = {}
end
```

**Solution:** Place cleanup logic in test utilities. Use `_test` exports sparingly for exposing internals, not cleanup.

```lua
-- ✅ GOOD: Cleanup in test file
local function resetArchiveState()
    Archive.Test_ResetSpawner()
    -- Reset via test seams, not production methods
end
```

**Our Pattern:** `Module._test.Function` is OK for exposing internal functions for testing, but cleanup belongs in test files.

### Anti-Pattern 3: Mocking Without Understanding

**Problem:** Over-mocking eliminates side effects tests depend on.

```lua
-- ❌ BAD: Mocked everything, test proves nothing
local Archive = { Take = function() return {} end }
local Container = { AddCard = function() return true end }
-- Test passes but real integration is broken
```

**Solution:** Understand what real method does before mocking. Mock at TTS boundary only.

```lua
-- ✅ GOOD: Real modules, stub only at TTS boundary
local Archive = require("Kdm/Archive")  -- Real module
Archive.Test_SetSpawner(ttsSpawnerStub)  -- Stub TTS boundary only
```

**Our Pattern:** Mock at TTS boundary (TTSSpawner), use real modules above.

### Anti-Pattern 4: Incomplete Mocks

**Problem:** Partial mocks missing fields real API provides.

```lua
-- ❌ BAD: Missing fields real TTS object has
local objectStub = { getName = function() return "Card" end }
-- Crashes when code calls objectStub.getPosition()
```

**Solution:** Mirror complete API response structure.

```lua
-- ✅ GOOD: All accessed fields present
local objectStub = {
    getName = function() return "Card" end,
    getPosition = function() return { x = 0, y = 0, z = 0 } end,
    getGUID = function() return "abc123" end,
}
```

### Anti-Pattern 5: Tests as Afterthought

**Problem:** Writing tests after implementation provides false confidence.

**Solution:** TDD — write failing test first. See `test-driven-development` skill.

### Anti-Patterns Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Asserting on mock elements | Test real component behavior |
| Test-only production methods | Move cleanup to test utilities |
| Mocking without understanding | Mock at TTS boundary only |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | Practice TDD |

### Anti-Pattern Red Flags

Stop and reconsider if you notice:

- Assertions checking for test-specific identifiers
- Methods called only in test files (except `_test` exports)
- Mock setup >50% of test code
- Tests failing when mocks are removed
- Mocking "just to be safe"
- Can't explain why the mock is necessary

---

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

**Tester may add test interfaces to production code** — exposing internal functions via `Module._test.Foo = Foo` or similar seams is permitted, as long as production logic is unchanged.

If you identify a behavioral approach only after being challenged, you should have found it first. The default is behavioral — structural requires explicit justification approved by Product Owner.

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

## TTSSpawner Test Seam Pattern

**Problem:** Missing module exports cause runtime nil errors that are expensive to debug (require TTS launch, 5-10 minute debug cycles).

**Solution:** For modules with TTS API dependencies, use the TTSSpawner pattern:

1. **Extract TTS calls** into `Util/TTSSpawner.ttslua`
2. **Add test seam** to module: `Module._spawner` field with `Test_SetSpawner()` / `Test_ResetSpawner()`
3. **Write integration tests** that verify exports exist by exercising real call paths

### Pattern Implementation

```lua
-- Util/TTSSpawner.ttslua
local TTSSpawner = {}

function TTSSpawner.TakeFromArchive(archiveObject, params)
    return archiveObject.takeObject({
        position = params.position,
        smooth = false,
        callback_function = params.callback
    })
end

return TTSSpawner

-- Archive.ttslua
local TTSSpawner = require("Kdm/Util/TTSSpawner")
Archive._spawner = TTSSpawner

function Archive.getSpawner()
    return Archive._spawner or TTSSpawner
end

function Archive.Test_SetSpawner(spawner)
    Archive._spawner = spawner
end

function Archive.Test_ResetSpawner()
    Archive._spawner = TTSSpawner
end
```

### Test Usage

```lua
-- Integration test
local tts_spawner_stub = require("tests/stubs/tts_spawner_stub")
local Archive = require("Kdm/Archive")

local spawner = tts_spawner_stub.create()
Archive.Test_SetSpawner(spawner)

-- Exercise real call path
Archive.Take({ name = "Test Card", type = "Fighting Arts" })

-- Verify calls made
t:assertEqual(#spawner.takeCalls, 1)
t:assertEqual(spawner.takeCalls[1].params.name, "Test Card")

Archive.Test_ResetSpawner()
```

**Current implementations:** See `Archive.ttslua`, `Util/TTSSpawner.ttslua`, `tests/stubs/tts_spawner_stub.lua`

## Spy Pattern

**Principle:** Intercept and verify calls, don't track state manually.

### Spy Implementation

Spies record all calls made to them, allowing tests to verify:
- Which methods were called
- What arguments were passed
- How many times calls were made
- The order of operations

```lua
-- ArchiveSpy example (from tests/acceptance/archive_spy.lua)
local ArchiveSpy = {}

function ArchiveSpy.create()
    local spy = {
        _calls = {
            fightingArtsAdd = {},
            verminAdd = {},
            -- ... more call tracking
        },
    }
    return spy
end

function ArchiveSpy:createFightingArtsArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName, onComplete)
            table.insert(spy._calls.fightingArtsAdd, { card = cardName })
            if onComplete then onComplete() end
            return true
        end,
    }
end

function ArchiveSpy:fightingArtAdded(cardName)
    for _, call in ipairs(self._calls.fightingArtsAdd) do
        if call.card == cardName then return true end
    end
    return false
end
```

### Stub vs Spy

| Pattern | Purpose | Returns | Records |
|---------|---------|---------|---------|
| **Stub** | Provide minimal responses | Fake data | No |
| **Spy** | Verify interactions | Fake data | Yes, all calls |

**When to use:**
- **Stub:** TTS objects, environment dependencies (minimal behavior needed)
- **Spy:** Archive modules, business logic integration (need to verify calls)

## Cross-Module Integration Tests

**Principle:** When code in module A calls module B, there **must** be a headless integration test that exercises that call path.

**Why:** Recurring bug pattern is client code accessing fields/functions that aren't exported. These bugs only surface at TTS runtime (5-10 minute cycles). Headless integration tests catch them in seconds.

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

**Implementer responsibility:** When adding code that calls another module, the implementer must add an integration test covering that call path before handover. "Tester will add tests" is not acceptable for cross-module integration.

## TTS Console Test Commands

TTS tests are slower than headless tests, so two commands are available:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `>testall` | Run all TTS tests (~13 tests) | Before closing a bead, after major changes |
| `>testfocus` | Run only tests for current bead | During active development |

### Focused Testing Workflow

1. When starting work on a bead, update `FOCUS_BEAD` in `TTSTests.ttslua:86`
2. Use `>testfocus` during development for fast feedback (~2 tests vs ~13)
3. Run `>testall` before marking work complete

### Tagging Tests with Beads

```lua
-- In ALL_TESTS table:
{ name = "Test Name", bead = "kdm-xxx", fn = function(onComplete) ... end },
```

Tests without a `bead` field are regression tests (run with `>testall` only). Tests tagged with a bead run when that bead matches `FOCUS_BEAD`.

## TTS Console Test Pattern: Snapshot/Action/Restore

**Pattern for TTS integration tests:**

```lua
-- 1. Save initial state
local snapshot = captureGameState()

-- 2. Perform action (call real public API)
Showdown.Setup("White Lion", "Level 1")

-- 3. Verify outcome (user-visible result)
Wait.condition(function()
    return ResourceRewards.IsButtonVisible()
end, function()
    log:Printf("TEST RESULT: PASSED")
    -- 4. Restore state
    restoreGameState(snapshot)
    onComplete()
end)
```

### Anti-Pattern: Data Validation Masquerading as Integration Test

```lua
-- ❌ Weak: Only validates data exists - never tests actual feature
local monster = Showdown.Test.MonsterByName("White Lion")
local level = findLevelByName(monster, "Level 1")
local rewards = level.showdown.resources
if rewards.basic == 4 and rewards.monster == 4 then
    log:Printf("TEST RESULT: PASSED")
end
-- Problem: Test passes even if button never appears because setup code is broken
```

### Proper Integration Test

```lua
-- ✅ Strong: Calls real entry point, events fire naturally, verifies user-visible outcome
Showdown.Setup("White Lion", "Level 1")  -- Real API, events fire naturally
Wait.condition(function()
    return ResourceRewards.IsButtonVisible()  -- User-visible outcome
end)
if ResourceRewards.IsButtonVisible() then
    log:Printf("TEST RESULT: PASSED")
end
```

**Why this matters:** Data validation tests give false confidence. They pass when data is correct but integration is broken. Real integration tests catch: event handlers not registered, module state not set before events, async timing issues, UI not updated after operations.

## TTS Visual Verification

When handing off UI features to Product Owner, include evidence that the UI renders correctly:
- Screenshot showing the element in TTS
- Or reference to passing TTS console test that verifies visibility

"Tests pass" is not sufficient for UI — show it works.

## Test Organization

```
tests/
├── framework.lua                       # Test framework
├── run.lua                            # Test runner (register all tests here!)
├── <area>_test.lua                    # Unit tests by area
├── <module>_integration_test.lua      # Cross-module integration tests
├── stubs/
│   ├── tts_spawner_stub.lua          # TTSSpawner test double
│   └── ui_stubs.lua                   # TTS UI stubs
└── acceptance/
    ├── test_world.lua                 # TestWorld facade
    ├── archive_spy.lua                # Archive spies for verification
    └── <feature>_acceptance_test.lua  # Acceptance tests by feature
```

**CRITICAL:** When creating a new test file, you MUST register it in `tests/run.lua` or it won't run!

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

## Test Quality Bar

- **Breaking production code must fail tests** — Verify by temporarily breaking code
- **Test helpers should be simple** — Complex helpers indicate design issues
- **`deckContains()` should be <15 lines** with no edge-case handling

### Verification: Mutation Testing

**Always verify tests are meaningful:** Temporarily break the mod logic and confirm the test fails.

```lua
-- In Campaign.ttslua, change max 5 → max 3:
local selected = Campaign.RandomSelect(unlockedFightingArts, 3)  -- was 5

-- Run tests - they MUST fail:
-- ✗ ACCEPTANCE: at most 5 strain fighting arts added
```

If breaking the mod doesn't break the test, the test is worthless.

## Acceptance Testing Principles

### Write Tests from the User's Perspective

**Ask:** "What can a user do? What do they see?"

**Good:**
```lua
Test.test("ACCEPTANCE: reaching a strain milestone unlocks its reward", ...)
Test.test("ACCEPTANCE: each milestone has a different reward", ...)
```

**Bad:**
```lua
Test.test("ACCEPTANCE: reachMilestone validates against MILESTONE_CARDS", ...)
Test.test("ACCEPTANCE: cannot reach a milestone that doesn't exist", ...)
```

### Test Outcomes, Not Mechanisms

**Good:** "the fighting arts deck contains Ethereal Pact"
**Bad:** "Archive.AddCard was called with 'Ethereal Pact'"

Users care about results, not how we achieved them.

### TestWorld Must Call Real Mod Code

**TestWorld should be thin (wiring only).** It must NOT reimplement business logic.

```lua
-- ❌ WRONG: Duplicating Logic
function TestWorld:startNewCampaign()
    local rewards = {}
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if self._milestones[milestone.title] then
            table.insert(rewards, milestone.consequences.fightingArt)
        end
    end
    self._decks["Fighting Arts"] = self:_randomSelect(rewards, 5)  -- DUPLICATE LOGIC!
end

-- ✅ CORRECT: Calling Real Code
function TestWorld:startNewCampaign()
    local rewards = self._campaignModule._test.CalculateStrainRewards(
        self._milestones,
        self._strainModule.MILESTONE_CARDS
    )
    self._decks["Fighting Arts"] = rewards.fightingArts
end
```

### Acceptance Test Naming Convention

| Prefix | Purpose | Example |
|--------|---------|---------|
| `ACCEPTANCE:` | User-visible behavior | "strain rewards are added to new campaign" |
| `ACCEPTANCE INFRA:` | TestWorld infrastructure validation | "TestWorld loads real milestone data" |
| `ACCEPTANCE SKELETON:` | Pattern/architecture proof | "TestWorld lifecycle works" |

Infrastructure tests may inspect internal state. True acceptance tests must only verify user-visible outcomes.

## TTS Adapter Pattern

**Problem:** Acceptance tests that reimplement business logic test the test code, not the mod.

**Solution:** Extract pure business logic from TTS-dependent modules and call real mod code from acceptance tests.

**Pattern:**
1. **Extract pure logic** into testable functions (e.g., `Campaign.CalculateStrainRewards`)
2. **Expose via `_test` table** for acceptance test access
3. **TestWorld calls real mod code**, not duplicate implementations

**Key principle:** TestWorld should be thin (wiring only), not reimplement business logic.

**Verify exports before calling:** When writing tests that call functions via `_test` tables, always verify the function is actually exported before running the test. Check the module's `_test = { ... }` block to confirm the function is listed.

**Current implementations:** See `Campaign.ttslua`, `tests/acceptance/test_world.lua`, `Util/TTSAdapter.lua`

## Code Review: Test Quality Checklist

### Cross-Module Integration Tests
- [ ] **Does new/changed code call functions from other modules?** If yes:
  - [ ] Integration test exists that exercises the real call path (A → B)
  - [ ] The immediate dependency (B) is not stubbed — only deeper dependencies (C) may be mocked
  - [ ] Test would fail if the called function were removed from B's exports

### Data Integration Tests
- [ ] **Does feature integrate with expansion data?** If yes:
  - [ ] At least one test uses real expansion data via `require("Kdm/Expansion/...")`
  - [ ] Tests would fail if expansion data had typos
  - [ ] Mock data is only used where appropriate (TTS objects, timing, etc.)
  - [ ] **Mutation test:** Would a typo in Core.ttslua cause this test to fail?

### TTS Console Test Review
- [ ] **Entry Point:** Does the test call the real public API, not just test helpers?
- [ ] **Event Flow:** If the feature uses events, does the test trigger them naturally (via source action), not manually fire them?
- [ ] **Outcome Verification:** Does the test verify user-visible results (UI state, spawned objects), not just internal state?
- [ ] **Mutation Test:** Would breaking the feature's code cause this test to fail?

### Test File Registration
- [ ] **For new test files:** Is the file registered in `tests/run.lua`?

## References

**Primary Sources:**
- `/Users/ilja/Documents/GitHub/kdm/TESTING.md` — Comprehensive testing strategy
- `/Users/ilja/Documents/GitHub/kdm/docs/ACCEPTANCE_TESTING_GUIDELINES.md` — Acceptance test principles
- `/Users/ilja/Documents/GitHub/kdm/CODE_REVIEW_GUIDELINES.md` — Test quality sections

**Example Implementations:**
- `Archive.ttslua` — TTSSpawner pattern
- `Util/TTSSpawner.ttslua` — TTS seam implementation
- `tests/stubs/tts_spawner_stub.lua` — Spy/stub example
- `tests/acceptance/archive_spy.lua` — Comprehensive spy implementation
- `tests/acceptance/test_world.lua` — TestWorld facade
- `tests/strain_archive_integration_test.lua` — Integration test example

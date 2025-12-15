---
name: acceptance-test-design
description: Designing acceptance tests that verify user-visible behavior using TestWorld and domain language. Use when writing acceptance tests, designing TestWorld, or verifying features from user perspective. Triggers on acceptance test, TestWorld, user-visible, domain language, ACCEPTANCE prefix, test from user perspective.
---

# Acceptance Test Design

Acceptance tests verify that features work from the user's perspective, using domain language and the TestWorld facade.

## Core Principle

**Ask:** "What can a user do? What do they see?"
**Not:** "How does the code work?"

## Test Naming Convention

| Prefix | Purpose | Example |
|--------|---------|---------|
| `ACCEPTANCE:` | User-visible behavior | "strain rewards are added to new campaign" |
| `ACCEPTANCE INFRA:` | TestWorld infrastructure validation | "TestWorld loads real milestone data" |
| `ACCEPTANCE SKELETON:` | Pattern/architecture proof | "TestWorld lifecycle works" |

Infrastructure tests may inspect internal state. True acceptance tests must only verify user-visible outcomes.

## Writing Tests from User's Perspective

**Good:**
```lua
Test.test("ACCEPTANCE: User can do X and sees Y", function(t)
    local world = TestWorld:new()

    -- Arrange: Set up the scenario
    world:setupCampaign(...)

    -- Act: Perform user action
    world:performAction(...)

    -- Assert: Verify observable outcome
    t:assertEqual(world:getVisibleResult(), expected)
end)
```

**Good test names:**
```lua
Test.test("ACCEPTANCE: reaching a strain milestone unlocks its reward", ...)
Test.test("ACCEPTANCE: each milestone has a different reward", ...)
```

**Bad test names:**
```lua
Test.test("ACCEPTANCE: reachMilestone validates against MILESTONE_CARDS", ...)
Test.test("ACCEPTANCE: cannot reach a milestone that doesn't exist", ...)
```

## Test Outcomes, Not Mechanisms

**Good:** "the fighting arts deck contains Ethereal Pact"
**Bad:** "Archive.AddCard was called with 'Ethereal Pact'"

Users care about results, not how we achieved them.

## TestWorld Must Call Real Mod Code

**TestWorld should be thin (wiring only).** It must NOT reimplement business logic.

```lua
-- WRONG: Duplicating Logic
function TestWorld:startNewCampaign()
    local rewards = {}
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if self._milestones[milestone.title] then
            table.insert(rewards, milestone.consequences.fightingArt)
        end
    end
    self._decks["Fighting Arts"] = self:_randomSelect(rewards, 5)  -- DUPLICATE LOGIC!
end

-- CORRECT: Calling Real Code
function TestWorld:startNewCampaign()
    local rewards = self._campaignModule._test.CalculateStrainRewards(
        self._milestones,
        self._strainModule.MILESTONE_CARDS
    )
    self._decks["Fighting Arts"] = rewards.fightingArts
end
```

## E2E Testing Requirement for Data Integration

**Features that integrate with expansion data require at least one test using real expansion files.**

```lua
-- BAD: Mock data - won't catch typos in Core.ttslua
modules.Showdown.level = { resources = { strange = "Elder Cat Teeth" } }
local result = ResourceRewards.GetStrangeResource()
t:assertEqual(result, "Elder Cat Teeth")  -- Passes even if Core.ttslua is wrong

-- GOOD: Real data - will fail if Core.ttslua has typos
require("Kdm/Expansion/Core")  -- Load real expansion data
Showdown.Setup("White Lion", "Level 3")  -- Uses real data
local result = ResourceRewards.GetStrangeResource()
t:assertEqual(result, "Elder Cat Teeth")  -- Fails if Core.ttslua is wrong
```

**Tester checklist for data integration features:**
- [ ] At least one headless test loads real expansion data via `require("Kdm/Expansion/...")`
- [ ] Tests would fail if expansion data had typos

## TTS Adapter Pattern

**Problem:** Acceptance tests that reimplement business logic test the test code, not the mod.

**Solution:** Extract pure business logic from TTS-dependent modules and call real mod code from acceptance tests.

**Pattern:**
1. **Extract pure logic** into testable functions (e.g., `Campaign.CalculateStrainRewards`)
2. **Expose via `_test` table** for acceptance test access
3. **TestWorld calls real mod code**, not duplicate implementations

**Verify exports before calling:** When writing tests that call functions via `_test` tables, always verify the function is actually exported before running the test.

## Spy Pattern for Verification

Spies record all calls made to them, allowing tests to verify:
- Which methods were called
- What arguments were passed
- How many times calls were made
- The order of operations

```lua
-- ArchiveSpy example
local ArchiveSpy = {}

function ArchiveSpy.create()
    local spy = {
        _calls = {
            fightingArtsAdd = {},
            verminAdd = {},
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

## Required File Header

For new acceptance test files:

```lua
---------------------------------------------------------------------------------------------------
-- Feature Name Acceptance Tests
--
-- [1-2 sentence description of what user can do]
--
-- SCOPE: What these tests verify
--   - [List key behaviors]
--
-- OUT OF SCOPE: What requires TTS console tests
--   - [List items not testable headlessly]
---------------------------------------------------------------------------------------------------
```

## File Organization

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

## Code Review Checklist

### Cross-Module Integration Tests
- [ ] **Does new/changed code call functions from other modules?** If yes:
  - [ ] Integration test exists that exercises the real call path (A → B)
  - [ ] The immediate dependency (B) is not stubbed
  - [ ] Test would fail if the called function were removed from B's exports

### Data Integration Tests
- [ ] **Does feature integrate with expansion data?** If yes:
  - [ ] At least one test uses real expansion data
  - [ ] Tests would fail if expansion data had typos
  - [ ] **Mutation test:** Would a typo in Core.ttslua cause this test to fail?

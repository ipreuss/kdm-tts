# Acceptance Testing Guidelines

**Date:** 2025-12-02  
**Status:** Living document

---

## Purpose

Acceptance tests verify the system behaves correctly **from the user's perspective**. They test what users can do, not how the code works internally.

---

## Core Principles

### 1. Write Tests from the User's Perspective

**Ask:** "What can a user do? What do they see?"

**Good:**
```lua
Test.test("ACCEPTANCE: reaching a strain milestone unlocks its reward", ...)
Test.test("ACCEPTANCE: each milestone has a different reward", ...)
Test.test("ACCEPTANCE: new campaign includes unlocked strain rewards", ...)
```

**Bad:**
```lua
Test.test("ACCEPTANCE: reachMilestone validates against MILESTONE_CARDS", ...)
Test.test("ACCEPTANCE: cannot reach a milestone that doesn't exist", ...)
Test.test("ACCEPTANCE: Archive.TakeFromDeck is called with correct params", ...)
```

The bad examples test implementation details or impossible user actions.

### 2. Users Can Only Do What the UI Allows

If a user can't do it through the interface, don't test it.

- Users can't type arbitrary milestone names — they select from a list
- Users can't call internal functions — they click buttons
- Users can't create invalid game states — the UI prevents it

Internal validation (like checking milestone names exist) is fine in TestWorld, but we don't write tests for those checks.

### 3. Test Outcomes, Not Mechanisms

**Good:** "the fighting arts deck contains Ethereal Pact"  
**Bad:** "Archive.AddCard was called with 'Ethereal Pact'"

Users care about results, not how we achieved them.

### 4. Use Domain Language

Tests should read like game actions, not code.

**Good:**
```lua
world:reachMilestone("Ethereal Culture Strain")
world:startNewCampaign()
world:fightingArtsDeck()
```

**Bad:**
```lua
world:setMilestoneState("Ethereal Culture Strain", true)
world:initCampaignModules({ expansions = {"Core"} })
world:getArchiveDeckByType("Fighting Arts")
```

### 5. Each Test Tells a Story

A test should describe a complete user scenario:

```lua
Test.test("ACCEPTANCE: strain rewards added to new campaign", function(t)
    local world = TestWorld.create()
    
    -- User has previously reached some milestones
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    
    -- User starts a new campaign
    world:startNewCampaign()
    
    -- The unlocked rewards are available
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Ethereal Pact"))
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Giant's Blood"))
    
    world:destroy()
end)
```

---

## Test Naming Convention

### Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `ACCEPTANCE:` | User-visible behavior | "strain rewards are added to new campaign" |
| `ACCEPTANCE INFRA:` | TestWorld infrastructure validation | "TestWorld loads real milestone data" |
| `ACCEPTANCE SKELETON:` | Pattern/architecture proof | "TestWorld lifecycle works" |

Infrastructure tests (`INFRA`, `SKELETON`) may inspect internal state. 
True acceptance tests (`ACCEPTANCE:`) must only verify user-visible outcomes.

### Format

`"<PREFIX>: <user action or outcome in plain English>"`

Examples:
- `"ACCEPTANCE: strain rewards are added to new campaign"`
- `"ACCEPTANCE: unchecking a milestone removes its reward"`
- `"ACCEPTANCE INFRA: TestWorld loads real milestone data"`
- `"ACCEPTANCE SKELETON: TestWorld lifecycle works"`

Avoid:
- Technical terms (`validates`, `delegates`, `calls`)
- Implementation details (`MILESTONE_CARDS`, `Archive`, `Container`)
- Negative tests for impossible actions (`cannot reach invalid milestone`)

---

## TestWorld API Design

TestWorld methods should mirror user actions:

| User Action | TestWorld Method |
|-------------|------------------|
| Check a milestone checkbox | `world:reachMilestone(title)` |
| Uncheck a milestone | `world:unreachMilestone(title)` |
| Start new campaign | `world:startNewCampaign(options)` |
| Look at fighting arts deck | `world:fightingArtsDeck()` |
| Check if deck has a card | `world:deckContains(deck, cardName)` |

Methods should use game terminology, not code terminology.

---

## Critical: TestWorld Must Call Real Mod Code

**TestWorld should be thin (wiring only).** It must NOT reimplement business logic.

### ❌ WRONG: Duplicating Logic
```lua
-- BAD: TestWorld reimplements Campaign.AddStrainRewards
function TestWorld:startNewCampaign()
    local rewards = {}
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if self._milestones[milestone.title] then
            table.insert(rewards, milestone.consequences.fightingArt)
        end
    end
    self._decks["Fighting Arts"] = self:_randomSelect(rewards, 5)  -- DUPLICATE LOGIC!
end
```

This tests whether TestWorld matches our assumptions, not whether the mod works.

### ✅ CORRECT: Calling Real Code
```lua
-- GOOD: TestWorld calls real Campaign logic
function TestWorld:startNewCampaign()
    local rewards = self._campaignModule._test.CalculateStrainRewards(
        self._milestones,
        self._strainModule.MILESTONE_CARDS
    )
    self._decks["Fighting Arts"] = rewards.fightingArts
end
```

This tests the actual mod code.

### Verification

**Always verify tests are meaningful:** Temporarily break the mod logic and confirm the test fails.

```lua
-- In Campaign.ttslua, change max 5 → max 3:
local selected = Campaign.RandomSelect(unlockedFightingArts, 3)  -- was 5

-- Run tests - they MUST fail:
-- ✗ ACCEPTANCE: at most 5 strain fighting arts added
```

If breaking the mod doesn't break the test, the test is worthless.

---

## What Acceptance Tests Are NOT For

1. **Edge cases in internal logic** — use unit tests
2. **Module integration** — use integration tests  
3. **Error handling for impossible states** — don't test
4. **Performance** — use benchmarks
5. **UI rendering** — out of scope (TTS handles this)

---

## File Organization

```
tests/acceptance/
├── test_world.lua              # TestWorld facade
├── tts_environment.lua         # TTS stub management
├── test_tts_adapter.lua        # Fake TTS adapter for tracking
├── walking_skeleton_test.lua   # Infrastructure proof
├── strain_acceptance_test.lua  # Strain milestone scenarios
└── campaign_setup_test.lua     # Campaign scenarios (future)
```

---

## References

- Design doc: `docs/DESIGN_HEADLESS_ACCEPTANCE_TESTS.md`
- Walking skeleton: `tests/acceptance/walking_skeleton_test.lua`
- "Growing Object-Oriented Software, Guided by Tests" — Freeman & Pryce
- "Specification by Example" — Gojko Adzic

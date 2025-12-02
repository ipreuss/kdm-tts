# Design Document: Headless Acceptance Testing with TestWorld

**Date:** 2025-12-02  
**Author:** Architect  
**Status:** Proposal (not yet scheduled)  
**Priority:** Low (future improvement)

---

## Overview

Enable headless acceptance tests that exercise realistic game scenarios without requiring Tabletop Simulator. Build on the existing TTSSpawner/Check seam infrastructure to create a `TestWorld` facade that manages game state initialization and provides high-level assertions.

---

## Goals

1. **Acceptance-level tests** - Test user-visible behavior, not implementation details
2. **Headless execution** - Run in `lua tests/run.lua` without TTS
3. **Readable scenarios** - Tests read like game actions, not code internals
4. **CI/CD compatible** - Can run in automated pipelines
5. **Incremental adoption** - Add coverage gradually without big-bang refactor

---

## Non-Goals

- FitNesse-style plain-text DSL (too much infrastructure for current needs)
- 100% TTS fidelity (acceptance tests validate logic, TTS console tests validate integration)
- Testing UI rendering (out of scope)

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Acceptance Test                              │
│  Test.acceptance("scenario", function(t)                        │
│      local world = TestWorld.create()                           │
│      world:reachMilestone("Ethereal Culture Strain")            │
│      world:startNewCampaign()                                   │
│      t:assertDeckContains(world:fightingArtsDeck(), "Ethereal") │
│  end)                                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        TestWorld                                 │
│  - Manages module initialization                                │
│  - Provides game action methods (reachMilestone, startCampaign) │
│  - Exposes state inspection (fightingArtsDeck, survivors)       │
│  - Handles cleanup between tests                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TTSEnvironment                              │
│  - Stubs ALL TTS globals (Wait, UI, Global, Physics, etc.)      │
│  - Provides fake object factory (createDeck, createCard, etc.)  │
│  - Simulates object containers (bags, decks, infinite)          │
│  - Extends existing TTSSpawner/Check seam pattern               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TestFixtures                                │
│  - Minimal expansion data (Core fighting arts, disorders, etc.) │
│  - Archive contents for spawning                                │
│  - Location coordinates                                         │
│  - Timeline templates                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. TestWorld (`tests/acceptance/test_world.lua`)

The main facade for acceptance tests. Manages game state and provides action methods.

```lua
local TestWorld = {}

function TestWorld.create(config)
    config = config or {}
    
    local world = {
        _env = TTSEnvironment.create(),
        _modules = {},
        _state = {
            milestones = {},
            survivors = {},
            settlement = {},
        },
    }
    setmetatable(world, { __index = TestWorld })
    
    -- Initialize TTS environment stubs
    world._env:install()
    
    -- Load modules with stubs in place
    world:_loadModules()
    
    return world
end

function TestWorld:destroy()
    self._env:uninstall()
    self:_unloadModules()
end

---------------------------------------------------------------------------------------------------
-- Game Actions
---------------------------------------------------------------------------------------------------

function TestWorld:reachMilestone(title)
    local Strain = self._modules.Strain
    -- Find milestone and mark as reached
    for i, milestone in ipairs(Strain.MILESTONE_CARDS) do
        if milestone.title == title then
            self._state.milestones[title] = true
            return true
        end
    end
    error("Unknown milestone: " .. title)
end

function TestWorld:startNewCampaign(options)
    options = options or {}
    local Campaign = self._modules.Campaign
    local Strain = self._modules.Strain
    
    -- Set up strain state before campaign init
    Strain.Init({ reached = self._state.milestones })
    
    -- Initialize campaign
    Campaign.New({
        expansions = options.expansions or { "Core" },
        campaign = options.campaign or "People of the Lantern",
    })
    
    return true
end

function TestWorld:addSurvivor(name, attributes)
    -- Create survivor with given attributes
    local survivor = {
        name = name,
        fightingArts = attributes.fightingArts or {},
        disorders = attributes.disorders or {},
        abilities = attributes.abilities or {},
    }
    table.insert(self._state.survivors, survivor)
    return survivor
end

---------------------------------------------------------------------------------------------------
-- State Inspection
---------------------------------------------------------------------------------------------------

function TestWorld:fightingArtsDeck()
    return self._env:getDeck("Fighting Arts")
end

function TestWorld:verminDeck()
    return self._env:getDeck("Vermin")
end

function TestWorld:timeline()
    return self._modules.Timeline.years
end

function TestWorld:survivor(name)
    for _, s in ipairs(self._state.survivors) do
        if s.name == name then return s end
    end
    return nil
end

---------------------------------------------------------------------------------------------------
-- Internal
---------------------------------------------------------------------------------------------------

function TestWorld:_loadModules()
    -- Clear and reload modules with stubs in place
    local moduleNames = {
        "Kdm/Archive",
        "Kdm/Strain", 
        "Kdm/Campaign",
        "Kdm/Timeline",
        "Kdm/Survivor",
        "Kdm/FightingArtsArchive",
        "Kdm/VerminArchive",
    }
    
    for _, name in ipairs(moduleNames) do
        package.loaded[name] = nil
    end
    
    self._modules = {
        Archive = require("Kdm/Archive"),
        Strain = require("Kdm/Strain"),
        Campaign = require("Kdm/Campaign"),
        Timeline = require("Kdm/Timeline"),
        -- ... etc
    }
end

function TestWorld:_unloadModules()
    -- Restore original modules
end

return TestWorld
```

### 2. TTSEnvironment (`tests/acceptance/tts_environment.lua`)

Comprehensive stub for all TTS globals and APIs.

```lua
local TTSEnvironment = {}

function TTSEnvironment.create()
    local env = {
        _originalGlobals = {},
        _objects = {},      -- Fake TTS objects by GUID
        _decks = {},        -- Named decks and their contents
        _spawnerCalls = {}, -- Record of spawn operations
    }
    setmetatable(env, { __index = TTSEnvironment })
    return env
end

function TTSEnvironment:install()
    -- Save and replace TTS globals
    self:_stubGlobal("Wait", self:_createWaitStub())
    self:_stubGlobal("UI", self:_createUIStub())
    self:_stubGlobal("Global", self:_createGlobalStub())
    self:_stubGlobal("Physics", self:_createPhysicsStub())
    
    -- Enable Check test mode
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(true)
    
    -- Install TTSSpawner stub
    local Archive = require("Kdm/Archive")
    Archive.Test_SetSpawner(self:_createSpawnerStub())
    
    -- Stub NamedObject
    package.loaded["Kdm/NamedObject"] = self:_createNamedObjectStub()
    
    -- Stub Location
    package.loaded["Kdm/Location"] = self:_createLocationStub()
    
    -- Stub Expansion with test fixtures
    package.loaded["Kdm/Expansion"] = self:_createExpansionStub()
end

function TTSEnvironment:uninstall()
    -- Restore all original globals
    for name, original in pairs(self._originalGlobals) do
        _G[name] = original
    end
    
    -- Disable Check test mode
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(false)
    
    -- Reset Archive spawner
    local Archive = require("Kdm/Archive")
    if Archive.Test_ResetSpawner then
        Archive.Test_ResetSpawner()
    end
end

---------------------------------------------------------------------------------------------------
-- Deck Management (for assertions)
---------------------------------------------------------------------------------------------------

function TTSEnvironment:getDeck(name)
    return self._decks[name] or { cards = {} }
end

function TTSEnvironment:addCardToDeck(deckName, cardName, cardType)
    self._decks[deckName] = self._decks[deckName] or { cards = {} }
    table.insert(self._decks[deckName].cards, {
        name = cardName,
        type = cardType,
    })
end

---------------------------------------------------------------------------------------------------
-- Stub Factories
---------------------------------------------------------------------------------------------------

function TTSEnvironment:_createWaitStub()
    return {
        frames = function(callback, frames)
            -- Execute immediately in tests
            if callback then callback() end
        end,
        time = function(callback, seconds)
            if callback then callback() end
        end,
        condition = function(callback, condition)
            if callback then callback() end
        end,
    }
end

function TTSEnvironment:_createPhysicsStub()
    return {
        cast = function(params)
            return {} -- No hits
        end,
    }
end

function TTSEnvironment:_createSpawnerStub()
    local self_env = self
    return {
        TakeFromArchive = function(archiveObject, params)
            table.insert(self_env._spawnerCalls, {
                archive = archiveObject,
                params = params,
            })
            return self_env:_createFakeObject({
                name = archiveObject.getName(),
                tag = "Deck",
            })
        end,
        PhysicsCast = function(params)
            return {}
        end,
        DestroyObject = function(obj)
            -- no-op
        end,
    }
end

function TTSEnvironment:_createFakeObject(config)
    local obj = {
        _name = config.name or "FakeObject",
        _guid = config.guid or ("fake-" .. tostring(math.random(100000))),
        _tag = config.tag or "Card",
        _contents = config.contents or {},
    }
    
    function obj.getName() return obj._name end
    function obj.getGUID() return obj._guid end
    function obj.tag() return obj._tag end
    function obj.getObjects() return obj._contents end
    function obj.destruct() end
    function obj.setLock() end
    
    function obj.takeObject(params)
        -- Simulate taking from container
        if #obj._contents > 0 then
            local item = table.remove(obj._contents, 1)
            if params.callback_function then
                params.callback_function(item)
            end
            return item
        end
        return nil
    end
    
    function obj.putObject(item)
        table.insert(obj._contents, item)
    end
    
    self._objects[obj._guid] = obj
    return obj
end

-- ... additional stub factories ...

return TTSEnvironment
```

### 3. TestFixtures (`tests/acceptance/fixtures/`)

Minimal game data for tests.

```lua
-- tests/acceptance/fixtures/core_data.lua

local CoreFixtures = {}

CoreFixtures.fightingArts = {
    "Ambidextrous", "Berserker", "Clutch Fighter", "Combo Master",
    -- ... core fighting arts
    -- Strain rewards:
    "Ethereal Pact", "Giant's Blood", "Backstabber", "Infinite Lives",
    "Shielderang", "Rolling Gait", "Infernal Rhythm", "Convalescer",
    "Armored Fist", "Dark Manifestation", "Stockist", "Sword Oath",
    "Story of Blood",
}

CoreFixtures.disorders = {
    "Aichmophobia", "Anxiety", "Apathetic", -- ...
}

CoreFixtures.archiveContents = {
    ["Fighting Arts Archive"] = {
        { name = "Fighting Arts", type = "Fighting Arts", contents = CoreFixtures.fightingArts },
    },
    ["Strain Rewards Archive"] = {
        -- Strain reward cards
    },
}

return CoreFixtures
```

### 4. Assertion Helpers (`tests/acceptance/assertions.lua`)

High-level assertions for game state.

```lua
local Assertions = {}

function Assertions.assertDeckContains(t, deck, cardName)
    for _, card in ipairs(deck.cards or {}) do
        if card.name == cardName then
            return true
        end
    end
    t:fail(string.format("Deck does not contain '%s'", cardName))
end

function Assertions.assertDeckNotContains(t, deck, cardName)
    for _, card in ipairs(deck.cards or {}) do
        if card.name == cardName then
            t:fail(string.format("Deck unexpectedly contains '%s'", cardName))
        end
    end
    return true
end

function Assertions.assertSurvivorHasFightingArt(t, survivor, artName)
    for _, art in ipairs(survivor.fightingArts or {}) do
        if art == artName then
            return true
        end
    end
    t:fail(string.format("Survivor '%s' does not have fighting art '%s'", 
        survivor.name, artName))
end

function Assertions.assertTimelineContains(t, timeline, year, eventName)
    local yearData = timeline[year]
    if not yearData then
        t:fail(string.format("Timeline has no year %d", year))
    end
    for _, event in ipairs(yearData.events or {}) do
        if event.name == eventName then
            return true
        end
    end
    t:fail(string.format("Timeline year %d does not contain '%s'", year, eventName))
end

return Assertions
```

---

## Example Acceptance Tests

### File: `tests/acceptance/strain_rewards_test.lua`

```lua
local Test = require("tests.framework")
local TestWorld = require("tests.acceptance.test_world")
local A = require("tests.acceptance.assertions")

---------------------------------------------------------------------------------------------------

Test.acceptance("Strain rewards: fighting arts added to new campaign", function(t)
    local world = TestWorld.create()
    
    -- Given: Two milestones have been reached in previous campaigns
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    
    -- When: A new campaign is started
    world:startNewCampaign({ expansions = { "Core" } })
    
    -- Then: The unlocked fighting arts are in the deck
    local faDeck = world:fightingArtsDeck()
    A.assertDeckContains(t, faDeck, "Ethereal Pact")
    A.assertDeckContains(t, faDeck, "Giant's Blood")
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.acceptance("Strain rewards: max 5 fighting arts selected", function(t)
    local world = TestWorld.create()
    
    -- Given: More than 5 milestones reached
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    world:reachMilestone("Opportunist Strain")
    world:reachMilestone("Trepanning Strain")
    world:reachMilestone("Hyper Cerebellum")
    world:reachMilestone("Marrow Transformation")
    world:reachMilestone("Memetic Symphony")
    
    -- When: A new campaign is started
    world:startNewCampaign()
    
    -- Then: Only 5 fighting arts are added (randomly selected)
    local faDeck = world:fightingArtsDeck()
    local strainArts = { 
        "Ethereal Pact", "Giant's Blood", "Backstabber", 
        "Infinite Lives", "Shielderang", "Rolling Gait", "Infernal Rhythm" 
    }
    local count = 0
    for _, art in ipairs(strainArts) do
        if world:deckContains(faDeck, art) then
            count = count + 1
        end
    end
    t:assertEqual(5, count, "Should have exactly 5 strain fighting arts")
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.acceptance("Strain milestone: Sword Oath adds timeline event", function(t)
    local world = TestWorld.create()
    
    -- Given: Campaign is in year 5
    world:startNewCampaign()
    world:advanceToYear(5)
    
    -- When: Sword Oath milestone is confirmed
    world:confirmMilestone("Sweat Stained Oath")
    
    -- Then: "Acid Storm" is added to year 6
    A.assertTimelineContains(t, world:timeline(), 6, "Acid Storm")
    
    world:destroy()
end)
```

---

## Implementation Phases

### Phase 1: Foundation (1 week)
- [ ] Create `tests/acceptance/` directory structure
- [ ] Implement basic `TTSEnvironment` with essential stubs
- [ ] Implement basic `TestWorld` with module loading
- [ ] Add `Test.acceptance()` to test framework
- [ ] Write 1-2 proof-of-concept tests

### Phase 2: Core Scenarios (1 week)
- [ ] Expand `TTSEnvironment` stubs as needed
- [ ] Add assertion helpers
- [ ] Implement strain milestone scenarios
- [ ] Implement campaign setup scenarios

### Phase 3: Fixtures & Polish (1 week)
- [ ] Create comprehensive test fixtures
- [ ] Add survivor management actions
- [ ] Add timeline manipulation actions
- [ ] Document patterns in ARCHITECTURE.md

### Phase 4: Coverage Expansion (ongoing)
- [ ] Add scenarios for other features as developed
- [ ] Refine TestWorld API based on usage
- [ ] Consider CI/CD integration

---

## Open Questions

1. **Scope of first implementation:** Start with just strain milestones, or broader?

2. **Fixture management:** Generate from actual expansion data, or maintain separately?

3. **Async simulation:** How to handle `Wait.frames()` - execute immediately or queue?

4. **State reset:** Between tests, reload modules or reset state in-place?

5. **Naming:** `TestWorld`, `GameSimulator`, `HeadlessGame`, or something else?

---

## Dependencies

- Existing TTSSpawner seam (`Util/TTSSpawner.ttslua`)
- Existing Check test mode (`Util/Check.ttslua`)
- Test framework (`tests/framework.lua`)

---

## Success Criteria

1. At least 5 acceptance tests running headlessly
2. Tests catch real bugs (validated by intentionally breaking code)
3. Test execution < 5 seconds total
4. New scenarios can be added in < 30 minutes
5. No TTS required for test execution

---

## References

- `tests/strain_archive_integration_test.lua` - Current integration test pattern
- `tests/stubs/tts_spawner_stub.lua` - Existing TTS stub
- FitNesse: http://fitnesse.org/ (inspiration, not direct implementation)
- "Growing Object-Oriented Software, Guided by Tests" - Freeman & Pryce

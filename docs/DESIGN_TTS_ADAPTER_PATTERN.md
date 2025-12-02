# Design Document: TTS Adapter Pattern for Testability

**Date:** 2025-12-02  
**Author:** Architect  
**Status:** Proposal  
**Priority:** High (architectural improvement)

---

## Problem Statement

### Current State

TestWorld reimplements business logic to simulate mod behavior:

```lua
-- TestWorld._calculateRewards() DUPLICATES Campaign.AddStrainRewards
function TestWorld:_calculateRewards(reached)
    local unlockedFightingArts = {}
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if reached[milestone.title] and milestone.consequences then
            if milestone.consequences.fightingArt then
                table.insert(unlockedFightingArts, milestone.consequences.fightingArt)
            end
        end
    end
    local selectedFightingArts = self:_randomSelect(unlockedFightingArts, 5)
    -- ...
end
```

### The Flaw

**We're testing whether TestWorld matches our assumptions about the mod, not whether the mod actually works.**

If the real `Campaign.AddStrainRewards` has a bug, our acceptance tests will pass because TestWorld has its own (potentially correct) implementation.

### Root Cause

Mod logic is tightly coupled to TTS API. We can't run real mod code without TTS, so we simulate it instead.

---

## Proposed Solution

### Adapter Pattern

Decouple mod business logic from TTS API using dependency injection.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Mod Business Logic                           │
│         (Strain, Campaign, Archive, Timeline, etc.)             │
│                              │                                   │
│                      uses interface                              │
│                              ▼                                   │
│                    ┌─────────────────┐                          │
│                    │   TTSAdapter    │                          │
│                    │   (interface)   │                          │
│                    └────────┬────────┘                          │
│                             │                                    │
│           implements        │         implements                 │
│              ┌──────────────┴──────────────┐                    │
│              ▼                              ▼                    │
│   ┌─────────────────────┐      ┌─────────────────────┐         │
│   │  RealTTSAdapter     │      │  TestTTSAdapter     │         │
│   │  (production)       │      │  (headless tests)   │         │
│   │  - calls TTS API    │      │  - simulates TTS    │         │
│   │  - spawns objects   │      │  - tracks calls     │         │
│   └─────────────────────┘      └─────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

### Key Insight

**TestWorld should wire REAL mod code with a TEST adapter, not reimplement mod logic.**

```lua
-- BEFORE (current): TestWorld reimplements logic
function TestWorld:startNewCampaign()
    local rewards = self:_calculateRewards(self._milestones)  -- DUPLICATE LOGIC
    for _, reward in ipairs(rewards) do
        table.insert(self._decks["Fighting Arts"], reward.name)
    end
end

-- AFTER (proposed): TestWorld runs REAL mod code
function TestWorld:startNewCampaign()
    -- Inject test adapter into real Campaign module
    Campaign.SetAdapter(self._adapter)
    
    -- Run REAL Campaign.AddStrainRewards
    Campaign.AddStrainRewards(self._milestones)
    
    -- Adapter captured what would have been spawned
end

function TestWorld:fightingArtsDeck()
    -- Query adapter for spawned cards
    return self._adapter:getSpawnedCards("Fighting Arts")
end
```

---

## Adapter Interface

### Core Operations

Based on analysis of mod code, the TTS operations fall into these categories:

```lua
TTSAdapter = {
    -- Object spawning
    spawnObject(params) -> object
    takeFromContainer(container, params) -> object
    putInContainer(container, object)
    destroyObject(object)
    
    -- Object queries
    getObjectByGUID(guid) -> object
    getObjectsByName(name) -> objects[]
    findObjectsInZone(zone) -> objects[]
    
    -- Physics
    physicsCast(params) -> hits[]
    
    -- Deck/Container operations
    getDeckContents(deck) -> cards[]
    shuffleDeck(deck)
    
    -- UI (may be separate adapter)
    showUI(element)
    hideUI(element)
    
    -- Wait/Timing
    waitFrames(count, callback)
    waitTime(seconds, callback)
    waitCondition(condition, callback)
}
```

### Test Adapter Behavior

The TestTTSAdapter simulates TTS behavior minimally:

```lua
TestTTSAdapter = {
    _spawnedObjects = {},
    _decks = {},
    _destroyedObjects = {},
    
    spawnObject = function(self, params)
        local obj = FakeObject.create(params)
        table.insert(self._spawnedObjects, obj)
        return obj
    end,
    
    takeFromContainer = function(self, container, params)
        -- Track what was taken
        local obj = FakeObject.create({ name = params.name })
        self:_recordTake(container, obj)
        return obj
    end,
    
    waitFrames = function(self, count, callback)
        -- Execute immediately in tests
        if callback then callback() end
    end,
    
    -- Query methods for assertions
    getSpawnedCards = function(self, deckType)
        return self._decks[deckType] or {}
    end,
}
```

---

## Migration Strategy

### Phase 1: Single Module Proof of Concept

**Target:** Campaign.AddStrainRewards

**Steps:**

1. **Extract TTS calls** from `Campaign.AddStrainRewards` into adapter interface
2. **Create adapter interface** in `Util/TTSAdapter.lua`
3. **Create RealTTSAdapter** that wraps actual TTS API
4. **Create TestTTSAdapter** for headless tests
5. **Refactor Campaign** to use adapter
6. **Update TestWorld** to inject TestTTSAdapter
7. **Verify** acceptance tests still pass (but now test REAL code)

### Phase 2: Expand to Related Modules

- Archive (card spawning)
- FightingArtsArchive (deck manipulation)
- VerminArchive (deck manipulation)
- Timeline (event scheduling)

### Phase 3: Broader Adoption

- Settlement management
- Survivor operations
- Showdown setup
- Monster AI

---

## Implementation Details

### Adapter Interface (`Util/TTSAdapter.lua`)

```lua
---------------------------------------------------------------------------------------------------
-- TTSAdapter: Interface for TTS operations
--
-- All mod code should use this adapter instead of calling TTS API directly.
-- This enables testing with a fake adapter that simulates TTS behavior.
---------------------------------------------------------------------------------------------------

local TTSAdapter = {}
TTSAdapter.__index = TTSAdapter

-- Singleton instance (swappable for tests)
local _instance = nil

function TTSAdapter.Get()
    if not _instance then
        _instance = TTSAdapter._createRealAdapter()
    end
    return _instance
end

function TTSAdapter.Set(adapter)
    _instance = adapter
end

function TTSAdapter.Reset()
    _instance = nil
end

---------------------------------------------------------------------------------------------------
-- Interface methods (implemented by Real and Test adapters)
---------------------------------------------------------------------------------------------------

function TTSAdapter:spawnObject(params)
    error("TTSAdapter:spawnObject must be implemented by subclass")
end

function TTSAdapter:takeFromContainer(container, params)
    error("TTSAdapter:takeFromContainer must be implemented by subclass")
end

function TTSAdapter:destroyObject(object)
    error("TTSAdapter:destroyObject must be implemented by subclass")
end

function TTSAdapter:waitFrames(count, callback)
    error("TTSAdapter:waitFrames must be implemented by subclass")
end

-- ... other interface methods

---------------------------------------------------------------------------------------------------
-- Real adapter (production)
---------------------------------------------------------------------------------------------------

function TTSAdapter._createRealAdapter()
    local adapter = setmetatable({}, TTSAdapter)
    
    function adapter:spawnObject(params)
        return spawnObject(params)  -- TTS global
    end
    
    function adapter:takeFromContainer(container, params)
        return container.takeObject(params)
    end
    
    function adapter:destroyObject(object)
        object.destruct()
    end
    
    function adapter:waitFrames(count, callback)
        Wait.frames(callback, count)
    end
    
    return adapter
end

return TTSAdapter
```

### Test Adapter (`tests/acceptance/test_tts_adapter.lua`)

```lua
---------------------------------------------------------------------------------------------------
-- TestTTSAdapter: Fake TTS adapter for headless testing
--
-- Simulates TTS behavior and tracks operations for assertions.
---------------------------------------------------------------------------------------------------

local TestTTSAdapter = {}
TestTTSAdapter.__index = TestTTSAdapter

function TestTTSAdapter.create()
    local adapter = {
        _spawnedObjects = {},
        _takenObjects = {},
        _destroyedObjects = {},
        _decks = {},
        _nextGuid = 1,
    }
    setmetatable(adapter, TestTTSAdapter)
    return adapter
end

function TestTTSAdapter:spawnObject(params)
    local obj = self:_createFakeObject(params)
    table.insert(self._spawnedObjects, {
        object = obj,
        params = params,
    })
    return obj
end

function TestTTSAdapter:takeFromContainer(container, params)
    local obj = self:_createFakeObject({
        name = params.guid or params.index or "taken_object",
    })
    table.insert(self._takenObjects, {
        container = container,
        object = obj,
        params = params,
    })
    
    -- Track deck additions
    if params.deckType then
        self._decks[params.deckType] = self._decks[params.deckType] or {}
        table.insert(self._decks[params.deckType], obj.getName())
    end
    
    if params.callback_function then
        params.callback_function(obj)
    end
    
    return obj
end

function TestTTSAdapter:destroyObject(object)
    table.insert(self._destroyedObjects, object)
end

function TestTTSAdapter:waitFrames(count, callback)
    -- Execute immediately in tests
    if callback then callback() end
end

---------------------------------------------------------------------------------------------------
-- Query methods for test assertions
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:getSpawnedObjects()
    return self._spawnedObjects
end

function TestTTSAdapter:getSpawnedCards(deckType)
    return self._decks[deckType] or {}
end

function TestTTSAdapter:wasObjectDestroyed(name)
    for _, obj in ipairs(self._destroyedObjects) do
        if obj.getName() == name then return true end
    end
    return false
end

---------------------------------------------------------------------------------------------------
-- Internal
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:_createFakeObject(params)
    local guid = "fake-" .. self._nextGuid
    self._nextGuid = self._nextGuid + 1
    
    return {
        _name = params.name or "FakeObject",
        _guid = guid,
        getName = function() return params.name or "FakeObject" end,
        getGUID = function() return guid end,
        destruct = function() end,
        setLock = function() end,
    }
end

return TestTTSAdapter
```

### Refactored Campaign Module (example)

```lua
-- Campaign.ttslua (partial refactor)

local TTSAdapter = require("Kdm/Util/TTSAdapter")

function Campaign.AddStrainRewards(reachedMilestones)
    local adapter = TTSAdapter.Get()
    
    -- Collect unlocked rewards (business logic - unchanged)
    local unlockedFightingArts = {}
    for _, milestone in ipairs(Strain.MILESTONE_CARDS) do
        if reachedMilestones[milestone.title] then
            if milestone.consequences and milestone.consequences.fightingArt then
                table.insert(unlockedFightingArts, milestone.consequences.fightingArt)
            end
        end
    end
    
    -- Select up to 5 randomly (business logic - unchanged)
    local selected = Campaign.RandomSelect(unlockedFightingArts, 5)
    
    -- Spawn cards (NOW USES ADAPTER)
    for _, artName in ipairs(selected) do
        Archive.Take({
            adapter = adapter,  -- Pass adapter through
            name = artName,
            type = "Fighting Arts",
            position = FightingArtsDeck.position,
        })
    end
end
```

### Updated TestWorld

```lua
-- tests/acceptance/test_world.lua

local TTSAdapter = require("Kdm/Util/TTSAdapter")
local TestTTSAdapter = require("tests.acceptance.test_tts_adapter")

function TestWorld.create()
    local world = {
        _adapter = TestTTSAdapter.create(),
        _milestones = {},
    }
    setmetatable(world, { __index = TestWorld })
    
    -- Inject test adapter
    TTSAdapter.Set(world._adapter)
    
    return world
end

function TestWorld:destroy()
    TTSAdapter.Reset()
end

function TestWorld:startNewCampaign()
    -- Run REAL Campaign code with test adapter
    Campaign.AddStrainRewards(self._milestones)
end

function TestWorld:fightingArtsDeck()
    -- Query adapter for what was spawned
    return self._adapter:getSpawnedCards("Fighting Arts")
end
```

---

## Benefits

1. **Tests verify REAL mod behavior** — bugs in Campaign.AddStrainRewards will fail tests
2. **No logic duplication** — TestWorld is thin, just wiring
3. **Easier maintenance** — change mod logic once, tests automatically verify it
4. **Better coverage** — test actual code paths, not simulations
5. **Incremental adoption** — migrate one module at a time

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Large refactor scope | Incremental migration, start with one module |
| Breaking production | RealTTSAdapter wraps existing TTS calls exactly |
| Test adapter complexity | Start simple, add behavior as needed |
| Module interdependencies | Map dependencies first, migrate leaf modules first |

---

## Success Criteria

### Phase 1 (Proof of Concept)

1. `Campaign.AddStrainRewards` uses adapter
2. Acceptance test runs REAL Campaign code
3. All 104 tests still pass
4. Test catches bug when we intentionally break Campaign logic

### Phase 2+

1. Additional modules migrated
2. No logic duplication in TestWorld
3. TestWorld methods are thin (< 10 lines each)

---

## Estimated Effort

| Phase | Effort | Description |
|-------|--------|-------------|
| Phase 1 | 1-2 days | Campaign.AddStrainRewards + adapter infrastructure |
| Phase 2 | 2-3 days | Archive, FightingArtsArchive, VerminArchive |
| Phase 3 | 1-2 weeks | Broader module coverage |

---

## Open Questions

1. **Adapter granularity:** One adapter for all TTS operations, or separate adapters (SpawningAdapter, UIAdapter, PhysicsAdapter)?

2. **Existing TTSSpawner:** We already have `Util/TTSSpawner.ttslua`. Should we expand it to full adapter, or create new?

3. **Module loading:** How do we ensure modules get the test adapter during test runs?

4. **Wait behavior:** Should test adapter execute callbacks immediately, or simulate async with a tick queue?

---

## References

- Current acceptance tests: `tests/acceptance/`
- Existing spawner seam: `Util/TTSSpawner.ttslua`
- Adapter pattern: https://refactoring.guru/design-patterns/adapter
- "Working Effectively with Legacy Code" — Michael Feathers

# SOLID Principle Violations and Testing Anti-Patterns Analysis

This document analyzes the KDM TTS codebase for violations of SOLID principles and patterns that complicate unit and headless acceptance testing.

## Executive Summary

The codebase exhibits several recurring anti-patterns:
1. **Open-Closed Principle violations** through type-checking if-else chains
2. **Tight coupling to TTS runtime** through direct API calls without abstraction
3. **Global mutable state** in module-level singletons
4. **Mixed responsibilities** combining business logic with TTS object manipulation
5. **Inconsistent dependency injection** despite existing Test_Set* seams

---

## 1. Open-Closed Principle (OCP) Violations

OCP states that software entities should be open for extension but closed for modification. These violations require modifying existing code to add new types.

### 1.1 Showdown.OnObjectPickUp/OnObjectDrop - Type-Based Dispatch

**Files**: `Sequence/Showdown.ttslua:785-828` and `832-877`

```lua
function Showdown.OnObjectPickUp(_, object)
    local type = object.getGMNotes()
    if type == "Player Figurine" then
        -- 16 lines of player figurine logic
    elseif type == "Minion Figurine" then
        -- 8 lines of minion figurine logic
    elseif type == "Monster Figurine" then
        -- 15 lines of monster figurine logic
    end
end

function Showdown.OnObjectDrop(_, object)
    local type = object.getGMNotes()
    if type == "Player Figurine" then
        -- player drop logic
    elseif type == "Monster Figurine" then
        -- monster drop logic
    elseif type == "Minion Figurine" then
        -- minion drop logic
    elseif type == "Terrain Tiles" then
        -- terrain drop logic
    end
end
```

**Problem**: Adding a new figurine type (e.g., "Companion Figurine") requires modifying both functions.

**Recommendation**: Use a handler registry pattern:
```lua
local pickupHandlers = {
    ["Player Figurine"] = function(object, overlay) ... end,
    ["Minion Figurine"] = function(object, overlay) ... end,
}
-- Extension: pickupHandlers["Companion Figurine"] = function(...) end
```

### 1.2 Campaign.Spawn - Archive Type Dispatch

**File**: `Sequence/Campaign.ttslua:1125-1141`

```lua
function Campaign.Spawn(name, type, position, context)
    if type == "Innovations" then
        object = context.innovationArchive:Take(...)
    elseif type == "Settlement Locations" then
        object = context.settlementLocationDeck:Take(...)
    else
        object = Archive.TakeObject(...)
    end
end
```

**Problem**: Each new archive type requires a new conditional branch.

**Recommendation**: Inject archive sources in context:
```lua
context.archiveSources = {
    ["Innovations"] = context.innovationArchive,
    ["Settlement Locations"] = context.settlementLocationDeck,
}
local source = context.archiveSources[type] or Archive
```

### 1.3 Campaign.SetupObjects - Tag-Based Object Handling

**File**: `Sequence/Campaign.ttslua:1145-1201`

```lua
if tag == "Card" or tag == "Tile" then
    -- card/tile spawning logic
elseif tag == "Deck" then
    -- deck grouping logic
else
    return log:Errorf("Unrecognized object tag...")
end
```

**Problem**: Adding new object tags requires modification.

### 1.4 Player.TakeNextLocation - Card Type Location Mapping

**File**: `Entity/Player.ttslua:916-939`

Hardcoded mapping between card types ("Disorders", "Fighting Arts", "Weapon Proficiencies") and location patterns.

### 1.5 Hunt Track Setup - Character Codes

**File**: `Sequence/Hunt.ttslua:486-495`

Uses character codes ('H', 'M', 'O', 'F', 'L') with if-else dispatch for hunt track elements.

---

## 2. Testability Anti-Patterns

### 2.1 Direct TTS Global API Calls

Functions directly call TTS globals instead of using injectable adapters.

| Location | API Call | Impact |
|----------|----------|--------|
| `Location/Location.ttslua:50` | `getAllObjects()` | Cannot test Location without TTS runtime |
| `Campaign.ttslua:463` | `spawnObject()` | Cannot test campaign orb creation |
| `Survivor.ttslua:1341,1350,1359` | `spawnObjectJSON()` | Cannot test survivor box spawning |
| `NamedObject.ttslua:213` | `getObjectFromGUID()` | Cannot test object lookup |

**Existing Pattern** (but not consistently used):
```lua
-- Archive.ttslua has injection point
Archive._spawner = nil
function Archive.Test_SetSpawner(spawner) ... end
local function getSpawner()
    return Archive._spawner or TTSSpawner
end
```

**Problem**: Most modules lack similar injection points.

### 2.2 Direct Wait.frames/Wait.time Calls

Over 200 direct timing calls throughout the codebase.

| File | Lines | Issue |
|------|-------|-------|
| `Campaign.ttslua` | 523, 929-1002 | Business logic wrapped in frame waits |
| `Showdown.ttslua` | 578, 705 | Object state changes in frame callbacks |
| `Hunt.ttslua` | 375-377 | UI state in frame callbacks |
| `Player.ttslua` | 66-75, 817 | Recurring timers at init |
| `Survivor.ttslua` | 1314-1353 | 4 nested Wait.frames for spawning |

**Problem**: TTSAdapter exists (`Util/TTSAdapter.lua:60-66`) but is not consistently used.

### 2.3 Long Functions with Multiple Responsibilities

| Function | File:Lines | Length | Mixed Concerns |
|----------|------------|--------|----------------|
| `Campaign.Import()` | Campaign.ttslua:929-1378 | ~450 lines | Trash → 11 decks → archive → survivors → timeline → strain |
| `Hunt.OnPartyArrival()` | Hunt.ttslua:245-341 | ~97 lines | Location query → deck extract → Y-sort → state → reveal |
| `Survivor.SpawnSurvivorBox()` | Survivor.ttslua:1300-1363 | ~63 lines | Archive → nested waits → putObject → figurine |

**Problem**: Cannot test individual concerns in isolation.

### 2.4 Module-Level Mutable State (Singletons)

Most modules store mutable state at module level:

```lua
-- Archive.ttslua
Archive.index = {}
Archive.keysByType = {}
Archive.containers = {}

-- Location.ttslua
Location.locationsByName = {}
Location.locationsByCell = {}
Location.locationsByObject = {}

-- Campaign.ttslua
Campaign.campaign = nil
Campaign.expansionsByName = {}
Campaign.campaigns = {}
```

**Problem**: Tests pollute each other's state, requiring careful setup/teardown.

### 2.5 Tight Module Coupling

Dependency chain: `Archive → Location → NamedObject → TTS Objects`

Testing Archive requires mocking 5+ modules (see `tests/archive_test.lua:35-69`):
```lua
local stubModules = {
    ["Kdm/Expansion"] = ...,
    ["Kdm/Location/Location"] = ...,
    ["Kdm/Location/NamedObject"] = ...,
    ["Kdm/Core/Log"] = ...,
    ["Kdm/Util/Container"] = ...,
}
```

### 2.6 Async Callbacks (spawnFunc) Without Promise Abstraction

**File**: `Archive/Archive.ttslua:271+`

```lua
Archive.Take({
    name = "Story of Blood",
    spawnFunc = function(obj)
        -- Callback executes during spawn
        -- Must do something with object NOW
    end
})
```

**Problem**: Tests must track callback execution manually, timing is critical.

---

## 3. Global State Summary

| Module | State Variables | Impact |
|--------|-----------------|--------|
| `Global.ttslua` | `KDM_VERSION`, `GLOBAL_OBJECT`, `initialized` | Runtime identity |
| `EventManager.ttslua` | `handlers`, `globalHandlers`, `_G[event]` | Global function mutation |
| `Archive.ttslua` | `index`, `keysByType`, `direct`, `containers` | Card lookup cache |
| `Location.ttslua` | `locationsByName`, `locationsByCell`, `locationsByObject` | Position tracking |
| `Player.ttslua` | `players` (4 entries) | Player registry |
| `Monster.ttslua` | `stats`, `tokenStats`, `statCounters` | Monster state |
| `Campaign.ttslua` | `campaign`, `expansionsByName`, `campaigns` | Campaign state |

---

## 4. Test Infrastructure Observations

### 4.1 What Works Well

1. **Test seams exist** - `Test_Set*` functions in some modules
2. **Characterization tests** - Good sandbox isolation in `tests/archive_test.lua`
3. **Archive spy** - Records operations for acceptance tests
4. **TestWorld facade** - Abstracts game actions

### 4.2 What Makes Testing Difficult

1. **Stub explosion** - TestWorld requires 15+ module stubs
2. **Bootstrap complexity** - Must stub all TTS globals (`tests/support/bootstrap.lua`)
3. **Timing synchronization** - Bootstrap makes Wait synchronous, losing ordering
4. **Incomplete mocks** - Archive spy returns empty decks, always 10 quantity

---

## 5. Recommendations Priority

### High Priority (Enables Testing)

1. **Consistent TTSAdapter usage** - Replace all direct `Wait.frames/time` calls
2. **Extract pure functions** - Separate business logic from TTS operations
3. **Complete injection seams** - Add Test_Set* for Location, NamedObject, Spawner

### Medium Priority (Improves Maintainability)

4. **Handler registries** - Replace type if-else chains with lookup tables
5. **Break up large functions** - Extract concerns into testable units
6. **Reduce module coupling** - Pass dependencies explicitly

### Lower Priority (Architectural)

7. **Promise/Future for async** - Replace spawnFunc callback pattern
8. **Event-based decoupling** - Reduce direct module dependencies
9. **State containers** - Consolidate module state for easier testing

---

## 6. Files Requiring Most Attention

| File | Issues | Test Difficulty |
|------|--------|-----------------|
| `Sequence/Showdown.ttslua` | OCP violations (2 handlers), direct TTS calls | HIGH |
| `Sequence/Campaign.ttslua` | OCP (3 locations), 450-line function, timing | HIGH |
| `Entity/Survivor.ttslua` | 4 nested Wait.frames, spawnObjectJSON | HIGH |
| `Sequence/Hunt.ttslua` | OCP (hunt track), long function | MEDIUM |
| `Entity/Player.ttslua` | Recurring timer, direct TTS calls | MEDIUM |
| `Location/Location.ttslua` | getAllObjects dependency | MEDIUM |

---

## Appendix: Specific Line References

### OCP Violations
- `Showdown.ttslua:785-828` - OnObjectPickUp type dispatch
- `Showdown.ttslua:832-877` - OnObjectDrop type dispatch
- `Campaign.ttslua:1125-1141` - Spawn archive type dispatch
- `Campaign.ttslua:1145-1201` - SetupObjects tag dispatch
- `Campaign.ttslua:632-661` - Import timeline event types
- `Player.ttslua:916-939` - TakeNextLocation card types
- `Hunt.ttslua:486-495` - Hunt track character codes

### Untestable Functions
- `Campaign.ttslua:929-1378` - Import (450 lines)
- `Survivor.ttslua:1300-1363` - SpawnSurvivorBox (nested waits)
- `Hunt.ttslua:245-341` - OnPartyArrival (mixed concerns)
- `Location.ttslua:50-61` - Init (getAllObjects)
- `Campaign.ttslua:463-471` - SpawnCampaignOrb (spawnObject)

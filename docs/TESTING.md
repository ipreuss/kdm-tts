# Testing Patterns

This document covers testing infrastructure, patterns, and strategies for the KDM TTS mod. For core architecture, see [ARCHITECTURE.md](../ARCHITECTURE.md). For TTS-specific patterns, see [TTS_PATTERNS.md](./TTS_PATTERNS.md).

---

## Running Tests

```bash
lua tests/run.lua
```

Tests live in `tests/` with fixtures in `tests/support/` and stubs in `tests/stubs/`.

---

## TTSSpawner Test Seam Pattern

**Problem:** Runtime nil errors from missing module exports are expensive to debug. They require full TTS launch (slow), only appear when specific code paths execute, and produce unhelpful stack traces ("attempt to call nil value"). Debug cycles take 5-10 minutes per attempt, sessions take 2-4 hours per bug.

**Solution:** Extract TTS-specific operations into `Util/TTSSpawner.ttslua`, allowing tests to inject fake spawners that catch missing exports in seconds via `lua tests/run.lua`.

**Implementation:**

```lua
-- Util/TTSSpawner.ttslua
local TTSSpawner = {}

function TTSSpawner.TakeFromArchive(archiveObject, params)
    return archiveObject.takeObject({
        position = params.position,
        rotation = params.rotation,
        smooth = params.smooth,
        callback_function = params.callback_function,
    })
end

return TTSSpawner
```

**Module using the seam (Archive.ttslua example):**

```lua
local TTSSpawner = require("Kdm/Util/TTSSpawner")

-- Test seam
Archive._spawner = nil

function Archive.Test_SetSpawner(spawner)
    Archive._spawner = spawner
end

local function getSpawner()
    return Archive._spawner or TTSSpawner
end

-- Use spawner instead of direct TTS calls
local function takeDirect(stateName)
    local spawner = getSpawner()
    local object = spawner.TakeFromArchive(archiveObject, params)
    -- ...
end

-- Export test functions
return {
    -- ... normal exports ...
    Test_SetSpawner = Archive.Test_SetSpawner,
    Test_ResetSpawner = Archive.Test_ResetSpawner,
}
```

**Integration test pattern:**

```lua
-- tests/strain_archive_integration_test.lua
Test.test("Strain→Archive integration: verifies exports exist", function(t)
    local Archive = require("Kdm/Archive")
    local Strain = require("Kdm/Strain")
    
    -- If this fails, it means Archive.TakeFromDeck is not exported
    -- Test fails immediately with clear error instead of hours of TTS debugging
    t:assertNotNil(Archive.TakeFromDeck, "Archive.TakeFromDeck must be exported")
    t:assertNotNil(Strain.Test._TakeRewardCard, "Strain test export must exist")
end)
```

**Benefits:**
- **Time savings:** 2-4 hours → <5 minutes per export bug
- **Clear errors:** "Archive.TakeFromDeck must be exported" instead of "attempt to call nil value"
- **Fast feedback:** `lua tests/run.lua` in seconds instead of TTS launch cycle
- **No behavior changes:** Existing code works unchanged (spawner defaults to TTSSpawner)

**When to use:**
- Modules that call TTS APIs directly (`takeObject`, `Physics.cast`, etc.)
- Cross-module integration points where exports must be verified
- Any code that historically had "attempt to call nil value" bugs

**When NOT to use:**
- Pure logic modules with no TTS dependencies
- UI-only modules (already testable via ui_stubs)
- Code with <5 call sites (overhead not worth it)

**Current implementations:**
- `Archive.ttslua` + `Util/TTSSpawner.ttslua`
- Test stub: `tests/stubs/tts_spawner_stub.lua`
- Integration tests: `tests/strain_archive_integration_test.lua`

---

## Check Test Mode Pattern

**Problem:** Many modules use `Check.Object`/`Check.ObjectOrNil` which enforce TTS `userdata` type. Our test stubs are Lua tables, so they fail these checks even with TTSSpawner seam in place.

**Solution:** Add test mode to Check module that accepts tables instead of userdata.

**Implementation:**

```lua
-- Util/Check.ttslua
Check._testMode = false

function Check.Test_SetTestMode(enabled)
    Check._testMode = enabled == true
end

function Check.Object(value, fmt, ...)
    if Check._testMode then
        return Check.Type(value, "table", fmt, ...)  -- Accept tables in test mode
    end
    return Check.Type(value, "userdata", fmt, ...)
end
```

**Test framework integration:**

```lua
-- tests/run.lua
local Check = require("Kdm/Util/Check")
Check.Test_SetTestMode(true)  -- Enable at test start

-- ... run tests ...

Check.Test_SetTestMode(false)  -- Disable at test end
assert(not Check.Test_IsTestMode(), "Test mode was not properly disabled")
```

**Benefits:**
- Single point of change - all modules using `Check.Object` automatically benefit
- Enables true integration testing with real Archive/Container logic
- No changes needed to production modules
- Test framework auto-manages test mode

**Risk mitigation:**
- Test mode is auto-disabled after test suite completes
- Assert verifies cleanup happened
- Not enabled in TTS environment (only in headless Lua tests)

---

## Integration Testing Strategy

### Philosophy

**Goal:** Execute real module logic (Strain, Archive, Container) while stubbing only the TTS environment layer (spawning, physics, object manipulation). This catches integration bugs (missing exports, incorrect parameters) in seconds via `lua tests/run.lua` instead of 5-10 minute TTS debug cycles.

**Anti-pattern:** Stubbing the module you're testing (e.g., stubbing Archive to test Archive). This tests the stub, not the code.

**Correct pattern:** Stub dependencies one layer below your module, then exercise real code paths through the module's public API.

### Stubbing Hierarchy

```
┌─────────────────────────────────────────┐
│           Test Code                      │
│  calls Strain.Test._TakeRewardCard()    │
└─────────────────┬───────────────────────┘
                  │ REAL CODE
                  ▼
┌─────────────────────────────────────────┐
│           Strain.ttslua                 │
│  calls Archive.TakeFromDeck()           │
└─────────────────┬───────────────────────┘
                  │ REAL CODE
                  ▼
┌─────────────────────────────────────────┐
│           Archive.ttslua                │
│  calls Container(), TTSSpawner          │
└─────────────────┬───────────────────────┘
                  │ REAL CODE
                  ▼
┌─────────────────────────────────────────┐
│         Container.ttslua                │
│  calls object.takeObject(), getObjects()│
└─────────────────┬───────────────────────┘
                  │ STUBBED
                  ▼
┌─────────────────────────────────────────┐
│      Fake TTS Objects (tables)          │
│  Returned by stubbed TTSSpawner         │
└─────────────────────────────────────────┘
```

### Module Stubbing Requirements

Integration tests must stub these modules **before** requiring the module under test:

| Module | Why Stubbed | Stub Returns |
|--------|-------------|--------------|
| `Kdm/NamedObject` | Returns TTS objects by name | Fake objects with `getName()`, `getGUID()` |
| `Kdm/Expansion` | Lists enabled expansions | `{ All = function() return {} end }` |
| `Kdm/Location` | Resolves position names | `{ Get = function() return { Center = fn } end }` |
| `_G.Physics` | Archive.Clean uses physics casts | `{ cast = function() return {} end }` |

### Stubbing Order

**Critical:** Stubs must be installed in `package.loaded` **before** requiring the module under test. Lua captures `require()` results in local variables at module load time.

```lua
-- 1. Save originals for cleanup
local origNamedObject = package.loaded["Kdm/NamedObject"]

-- 2. Install stub
package.loaded["Kdm/NamedObject"] = { Get = function(name) return fakeObject end }

-- 3. Clear cached module
package.loaded["Kdm/Archive"] = nil

-- 4. NOW require - Archive captures the stub
local Archive = require("Kdm/Archive")

-- 5. Cleanup in reverse
package.loaded["Kdm/NamedObject"] = origNamedObject
```

### Fake TTS Object Interface

TTS objects have a specific interface. Fakes must implement the methods used by real code:

```lua
-- Minimal bag/deck fake
{
    tag = "Bag",  -- or "Deck", "Infinite"
    getName = function() return "Archive Name" end,
    getGUID = function() return "fake-guid" end,
    getObjects = function()
        return {
            { name = "Card Name", gm_notes = "Card Type", guid = "card-guid", index = 1 },
        }
    end,
    takeObject = function(params)
        local card = { getName = fn, getGUID = fn, getGMNotes = fn }
        if params.callback_function then
            params.callback_function(card)
        end
        return card
    end,
    destruct = function() end,
    setLock = function() end,
}
```

**Critical fields:**
- `tag`: Container.ttslua checks this to determine behavior (line 117)
- `gm_notes`: Container searches by BOTH `name` AND `gm_notes` (lines 137-142)
- `callback_function`: Many TTS operations are async; callbacks must be invoked

### Common Pitfalls

1. **Type mismatch in gm_notes**
   - Container searches `entry.name == name AND entry.gm_notes == type`
   - If your fake returns `gm_notes = "Fighting Arts"` but code searches for `type = "Rewards"`, it won't find the card

2. **Missing exports**
   - Modules use explicit export tables (not `return Archive`)
   - Functions like `Archive.Key` may exist internally but not be exported
   - Test fails with "attempt to call nil" - add to module's return table

3. **Cached module state**
   - Lua caches `require()` results in `package.loaded`
   - Tests must clear `package.loaded["Kdm/Module"] = nil` before re-requiring
   - Also clear dependent modules to ensure fresh captures

4. **Global stubs (Physics)**
   - Some TTS APIs are globals, not modules
   - Stub via `_G.Physics = { cast = fn }`, not `package.loaded`
   - Remember to restore: `_G.Physics = origPhysics`

5. **Archive registration**
   - Archive lookup requires registration via `Archive.RegisterEntries()`
   - Key format is `"Type.Name"` (e.g., `"Rewards.Strain Rewards"`)
   - Registration must use correct archive name (e.g., "Core Archive" not "Strain Rewards Archive")

### Test Structure Template

```lua
Test.test("Module A → Module B integration", function(t)
    -- Save originals
    local origModuleC = package.loaded["Kdm/ModuleC"]
    local origGlobal = _G.SomeGlobal
    
    -- Stub dependencies
    package.loaded["Kdm/ModuleC"] = { ... }
    _G.SomeGlobal = { ... }
    
    -- Clear and reload modules under test
    package.loaded["Kdm/ModuleB"] = nil
    package.loaded["Kdm/ModuleA"] = nil
    local ModuleB = require("Kdm/ModuleB")
    local ModuleA = require("Kdm/ModuleA")
    
    -- Setup (inject test spawner, register test data)
    ModuleB.Test_SetSpawner(fakeSpawner)
    ModuleB.Init()
    ModuleB.RegisterEntries({ ... })
    
    -- Execute real code
    local result = ModuleA.SomeFunction({ ... })
    
    -- Cleanup BEFORE assertions (ensures cleanup on test failure)
    ModuleB.Test_ResetSpawner()
    _G.SomeGlobal = origGlobal
    package.loaded["Kdm/ModuleC"] = origModuleC
    
    -- Assert
    t:assertNotNil(result)
    t:assertTrue(#fakeSpawner.calls > 0)
end)
```

### When to Write Integration Tests

**DO write integration tests for:**
- Cross-module call chains (Strain → Archive → Container)
- Export verification (catch "attempt to call nil" before TTS)
- Complex data transformations across module boundaries

**DON'T write integration tests for:**
- Single-module logic (use unit tests)
- UI rendering (use TTS manual testing)
- Performance testing (TTS environment differs too much)

---

## Acceptance Testing

Acceptance tests verify user-visible behavior from the user's perspective. See `docs/ACCEPTANCE_TESTING_GUIDELINES.md` for detailed principles.

### Key Architecture Decisions

1. **TestWorld must call real mod code** — not reimplement business logic
2. **Use `Module._test` tables** to expose pure functions for testing
3. **TTSAdapter singleton** allows injecting test adapter for TTS operations

### File Structure

```
tests/acceptance/
├── test_world.lua              # TestWorld facade (thin wiring layer)
├── tts_environment.lua         # TTS stub management
├── test_tts_adapter.lua        # Fake TTS adapter for tracking operations
├── walking_skeleton_test.lua   # Infrastructure proof
└── strain_acceptance_test.lua  # Strain milestone scenarios
```

### Pattern: Extracting Pure Logic

Modules with TTS dependencies should extract pure business logic for testing:

```lua
-- Campaign.ttslua
function Campaign.CalculateStrainRewards(reached, milestoneCards)
    -- Pure logic, no TTS calls
    local unlockedFightingArts = {}
    for _, milestone in ipairs(milestoneCards) do
        if reached[milestone.title] and milestone.consequences then
            table.insert(unlockedFightingArts, milestone.consequences.fightingArt)
        end
    end
    return {
        fightingArts = Campaign.RandomSelect(unlockedFightingArts, 5),
        vermin = unlockedVermin,
    }
end

-- Expose for testing
Campaign._test = {
    CalculateStrainRewards = Campaign.CalculateStrainRewards,
}
```

### Pattern: TestWorld as Thin Wrapper

```lua
-- tests/acceptance/test_world.lua
function TestWorld:startNewCampaign()
    -- Call REAL Campaign logic - no duplicate business logic here
    local rewards = self._campaignModule._test.CalculateStrainRewards(
        self._milestones,
        self._strainModule.MILESTONE_CARDS
    )
    self._decks["Fighting Arts"] = rewards.fightingArts
    self._decks["Vermin"] = rewards.vermin
end
```

### Verification

Always verify acceptance tests are meaningful by temporarily breaking mod logic:

```lua
-- Change Campaign.CalculateStrainRewards max from 5 to 3
local selected = Campaign.RandomSelect(unlockedFightingArts, 3)  -- was 5

-- Test MUST fail:
-- ✗ ACCEPTANCE: at most 5 strain fighting arts added
```

If breaking the mod doesn't break the test, the test is testing TestWorld, not the mod.

### Related Documentation

- `docs/ACCEPTANCE_TESTING_GUIDELINES.md` — Principles and naming conventions
- `docs/DESIGN_TTS_ADAPTER_PATTERN.md` — Full adapter pattern design
- `Util/TTSAdapter.lua` — Singleton adapter implementation

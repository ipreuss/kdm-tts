---
name: legacy-code-testing
description: Techniques for safely modifying untested code, based on "Working Effectively with Legacy Code" by Michael Feathers. Use when working with code that lacks tests, adding coverage to existing functionality, refactoring safely, or breaking dependencies for testability. Triggers on terms like legacy, untested, no tests, characterization test, seam, break dependency, refactor safely, sprout method, wrap method.
---

# Legacy Code Testing Techniques

Patterns for safely modifying code that lacks adequate test coverage, adapted from Michael Feathers' "Working Effectively with Legacy Code" for this Lua/TTS codebase.

## The Legacy Code Dilemma

> "Legacy code is code without tests." — Michael Feathers

The catch-22: You need tests to change code safely, but you need to change code to add tests.

**Solution:** Break dependencies incrementally using seams.

---

## Core Techniques

### 1. Characterization Tests

**Purpose:** Document what code *actually does* before changing it.

**Process:**
1. Write a test that calls the code
2. Let it fail to see actual output
3. Update assertion to match actual behavior
4. Repeat for edge cases

```lua
-- Characterization test: What does this function actually return?
Test.test("Archive.Take returns container object", function(t)
    local result = Archive.Take({ name = "Fighting Arts" })
    -- First run: see what result actually is
    -- Then update assertion to match reality
    t:assertNotNil(result)
    t:assertEqual(result.type, "Deck")
end)
```

**Key insight:** Don't assume behavior is correct — document what it *is*.

### 2. Seams

A **seam** is a place where you can alter behavior without editing the code at that location.

#### Link Seams (Module Replacement)

Replace modules at require time:

```lua
-- In test setup
package.loaded["Kdm/Archive"] = {
    Take = function(params) return mockDeck end,
    Clean = function() end,
}
-- Now require the module under test
local Strain = require("Kdm/Strain")  -- Gets mock Archive
```

**Project example:** `tests/acceptance/tts_environment.lua`

#### Object Seams (Dependency Injection)

Pass dependencies instead of hardcoding them:

```lua
-- BEFORE: Hard dependency
function Module.DoThing()
    local deck = Archive.Take({ name = "Cards" })
    -- ...
end

-- AFTER: Injectable dependency
function Module.DoThing(archiveModule)
    archiveModule = archiveModule or Archive  -- Default to real
    local deck = archiveModule.Take({ name = "Cards" })
end
```

**Project pattern:** `Archive.Test_SetSpawner()` / `Archive.Test_ResetSpawner()`

```lua
-- Production: uses real TTS spawning
Archive.Take({ name = "Deck" })

-- Test: inject fake spawner
Archive.Test_SetSpawner(fakeSpawner)
Archive.Take({ name = "Deck" })  -- Uses fake
Archive.Test_ResetSpawner()
```

### 3. Sprout Method

Add new behavior in a new, fully-tested function.

```lua
-- BEFORE: Need to add validation to existing function
function Module.ProcessCard(card)
    -- 50 lines of untested code
    deck.putObject(card)
end

-- AFTER: Sprout new tested function
function Module.ValidateCard(card)  -- NEW: Fully tested
    assert(card, "card required")
    assert(card.getName, "must be TTS object")
    return card.getName() ~= ""
end

function Module.ProcessCard(card)
    if not Module.ValidateCard(card) then return end  -- One-line change
    -- 50 lines of untested code
    deck.putObject(card)
end
```

### 4. Wrap Method

Preserve the original, wrap with new behavior.

```lua
-- BEFORE: Need to add logging
function Module.Save()
    return { data = self.data }
end

-- AFTER: Wrap original
function Module._SaveCore()  -- Renamed original
    return { data = self.data }
end

function Module.Save()  -- New wrapper
    log:Debugf("Saving module state")
    local result = Module._SaveCore()
    log:Debugf("Saved %d bytes", #Json.encode(result))
    return result
end
```

### 5. Extract and Override

For object-oriented code, extract method then override in test subclass.

```lua
-- Production
function Monster:SpawnAI()
    local card = Archive.Take({ name = self.aiDeck })
    self:PlaceCard(card)
end

-- Extract the dependency
function Monster:GetArchive()
    return Archive
end

function Monster:SpawnAI()
    local card = self:GetArchive().Take({ name = self.aiDeck })
    self:PlaceCard(card)
end

-- Test: Override
local TestMonster = setmetatable({}, { __index = Monster })
function TestMonster:GetArchive()
    return mockArchive
end
```

---

## The Legacy Code Change Algorithm

1. **Identify change points** — Where does the change need to happen?
2. **Find test points** — Where can you observe the effects?
3. **Break dependencies** — Use seams to isolate the code
4. **Write tests** — Characterization tests first, then change tests
5. **Make changes and refactor** — Now safe to modify

---

## Project-Specific Seams

### TTSSpawner Pattern

**Files:** `Util/TTSSpawner.ttslua`, `Archive.Test_SetSpawner()`

Extracts TTS spawn operations into an injectable module:

```lua
-- TTSSpawner.ttslua
local TTSSpawner = {}

function TTSSpawner.SpawnFromArchive(archive, params)
    return archive.takeObject(params)
end

return TTSSpawner
```

```lua
-- Archive.ttslua
local TTSSpawner = require("Kdm/Util/TTSSpawner")
Archive._spawner = TTSSpawner

function Archive.Test_SetSpawner(spawner)
    Archive._spawner = spawner
end

function Archive.Test_ResetSpawner()
    Archive._spawner = TTSSpawner
end
```

### UI Stubs

**File:** `tests/stubs/ui_stubs.lua`

Replaces TTS UI system for headless testing:

```lua
local ui_stubs = {}

function ui_stubs.setup()
    -- Replace global UI
    UI = {
        setAttribute = function() end,
        getValue = function() return "" end,
    }
end

return ui_stubs
```

### Module Stubbing via package.loaded

**File:** `tests/acceptance/tts_environment.lua`

```lua
-- Stub before requiring dependent module
package.loaded["Kdm/Archive"] = mockArchive
package.loaded["Kdm/NamedObject"] = mockNamedObject

-- Now load module under test
local Campaign = require("Kdm/Campaign")
```

### Test Export Pattern

**Pattern:** `Module._test` table for internal function access

```lua
-- Production module
local Module = {}

local function internalHelper(x)
    return x * 2
end

function Module.PublicFunction(x)
    return internalHelper(x) + 1
end

-- Test access without polluting public API
Module._test = {
    internalHelper = internalHelper,
}

return Module
```

---

## Common Dependency Types

| Dependency | Seam Strategy |
|------------|---------------|
| TTS spawn/take | TTSSpawner pattern |
| TTS UI calls | ui_stubs replacement |
| Archive operations | Test_SetSpawner or module stub |
| Other modules | package.loaded replacement |
| Global state | Extract to parameter |
| Callbacks/async | Spy pattern with synchronous test |

---

## When to Apply These Techniques

**High value:**
- Before fixing a bug (characterization test prevents regression)
- Before adding feature to existing module (seam isolates changes)
- When test requires TTS runtime (extract TTS dependency)

**Lower priority:**
- Pure functions (already testable)
- New code (write tests first instead)
- Code scheduled for deletion

---

## References

- `ARCHITECTURE.md` "Future Refactor Opportunities" — Known modules needing seams
- `TESTING.md` "TTSSpawner Test Seam Pattern" — Detailed pattern documentation
- `CODING_STYLE.md` "Integration Testing ROI" — Cost/benefit of seam investment
- `.claude/agents/seam-finder.md` — Agent that analyzes modules for seam opportunities

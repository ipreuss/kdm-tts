---
name: kdm-coding-conventions
description: Lua coding conventions for the KDM TTS mod. Use when writing Lua code, implementing functions, creating modules, reviewing code, or when user mentions Lua, module exports, error handling, patterns, conventions, style, SOLID principles, guard clauses, or fail-fast philosophy.
---

# KDM Coding Conventions

Consolidated coding style and patterns for the Kingdom Death Monster Tabletop Simulator mod (Lua/TTS).

## Module Export Pattern

**CRITICAL: Always return the module table directly**

```lua
local Module = {}
function Module.Foo() ... end
Module.state = nil
return Module  -- ✅ Standard pattern
```

**NEVER use explicit export tables:**
```lua
return { Foo = Module.Foo }  -- ❌ Causes "forgotten export" bugs
```

**Why:** Dynamic field assignments (Module.field = value) only work with direct returns. Explicit exports cause bugs where cross-module state is invisible.

**Status:** Migration in progress (bead kdm-0e0). ~48 modules still use explicit exports.

## Fail-Fast Philosophy

**Design for debuggability: code should fail in obvious ways when something is wrong**

- **Silent failures are the enemy** - they hide problems until data corruption
- **Better to crash during development** than corrupt user data in production
- **Avoid defensive abstractions** - don't add helpers "just in case"
- **Let errors bubble up naturally** - stack trace should point to source
- **Trust your module contracts** - if all Save() return tables, don't nil-check

## Error Handling Patterns

**Core principle: Better to crash visibly than corrupt data silently**

### Use Assertions for Fatal Errors

For conditions that indicate broken mod setup or game state:

```lua
-- Required archives/decks missing
local deck = Archive.Take({name = "Fighting Arts"})
assert(deck, "Fighting Arts deck not found - mod setup error")

-- Essential TTS objects
assert(Check.Str(params.location, "location is required"))
local locationName = params.location

-- Required parameters
function ApplyState(object, stateName)
    assert(object, "object is required")
    assert(stateName, "stateName is required")
    assert(type(object.getStates) == "function", "object must support states")
    -- ... apply state ...
end
```

### Use Guard Clauses for Recoverable Conditions

Only for truly optional/recoverable situations:

```lua
-- Optional behavior where nil is valid
local expansion = Archive.Take({name = "Dragon King", lenient = true})
if not expansion then
    log:Debugf("Dragon King expansion not installed, skipping")
    return
end

-- User-driven operations that might legitimately fail
-- Feature-specific resources that don't break core gameplay
```

### Avoid pcall in Production Code

**pcall obscures errors and makes debugging harder**

- Use assertions/guards to validate conditions instead
- **Acceptable pcall uses (rare):**
  - Protecting against TTS API failures in recoverable contexts
  - Testing code that expects to catch errors (assertError in tests)
- **Document why** when using pcall - explain what can fail and why it's recoverable
- **Never** use pcall to suppress critical failures (save/load, essential resources)

## Function Contract Design

**Make requirements explicit with assertions - don't silently accept invalid inputs**

```lua
-- ❌ BAD: Lenient - accepts anything
function ApplyState(object, stateName)
    if not object or not stateName then
        return object  -- Silently does nothing
    end
    if type(object.getStates) ~= "function" then
        return object
    end
    -- ... apply state ...
end

-- ✅ GOOD: Tight contract - requires valid inputs
function ApplyState(object, stateName)
    assert(object, "object is required")
    assert(stateName, "stateName is required")
    assert(type(object.getStates) == "function", "object must support states")
    -- ... apply state ...
end
```

**Benefits:**
- Function signature documents exact requirements
- Misuse fails immediately at call site with clear message
- No confusion about whether nil/invalid inputs are valid
- Eliminates redundant validation when callers already check

## Async Operation Return Values

**Functions that orchestrate async operations via callbacks MUST return success/failure indicators:**

```lua
-- ❌ BAD: No return value
function Module.SpawnCard(params)
    Archive.TakeFromDeck({
        name = params.cardName,
        spawnFunc = function(card)
            params.onComplete(card)
        end
    })
end  -- Returns nil - caller can't tell if operation started

-- ✅ GOOD: Return boolean success
function Module.SpawnCard(params)
    local success = Archive.TakeFromDeck({
        name = params.cardName,
        spawnFunc = function(card)
            params.onComplete(card)
        end
    })
    return success  -- Caller knows if operation initiated
end
```

## SOLID Principles

### Single Responsibility Principle (SRP)

**Modules/scripts own one reason to change**

- File size guidelines:
  - < 300 lines: Good
  - 300-500 lines: Watch
  - 500-1000 lines: Review - likely mixing responsibilities
  - > 1000 lines: Split - almost certainly violates SRP
- Test-only exports indicate SRP violation - the function belongs in a different module

### Open/Closed Principle (OCP)

**Extend via new modules/objects instead of deep conditionals**

Use polymorphism over type-based conditionals:

```lua
-- ❌ BAD: Type-based conditionals
if element.type == "title" then
    totalHeight = totalHeight + element.titleHeight
elseif element.type == "section" then
    totalHeight = totalHeight + element.sectionHeight
-- Adding new types requires modifying this function
end

-- ✅ GOOD: Polymorphism
totalHeight = totalHeight + element:calculateHeight()
```

### Liskov Substitution Principle (LSP)

**Shared interfaces behave consistently**

### Interface Segregation Principle (ISP)

**Expose narrow APIs**

Less critical in Lua - focus on clarity over strict segregation.

### Dependency Inversion Principle (DIP)

**Depend on abstractions instead of concrete implementations**

Example: Depend on Kdm/Log interface instead of specific logger implementation.

## Clarity First

- Make code self-explanatory before documentation
- Prefer named constants/enums over raw booleans/strings
- Remove magic values - give them names
- Comments are last resort when structure/names can't convey intent

## Test-Only Helper Pattern

**Expose test-only helpers under Module._test table:**

```lua
-- ✅ Preferred pattern
Module._test = {
    stubUi = function() ... end,
    resetState = function() ... end,
}

-- ❌ Avoid: underscore prefix alone
function Module._TestStubUi() ... end
```

## Naming Conventions

- **PascalCase** for module tables (Monster, Timeline)
- **camelCase** for locals and functions
- Match file/module names to primary class/concept
- Use intention-revealing names over abbreviations

## Module Structure

- Keep public APIs at top of file
- Place private helpers below
- Require modules via stable paths: `require("Kdm/Gear")`
- Avoid circular dependencies

### Variable Declaration Order for Closures

**CRITICAL:** Module-level locals must be declared **before** any function that references them.

```lua
-- ❌ WRONG: Variable declared after function that uses it
local Module = {}

function Module.Init()
    -- This closure captures FOCUS_BEAD at definition time
    someCallback = function()
        print(FOCUS_BEAD)  -- Captures nil! Variable doesn't exist yet
    end
end

local FOCUS_BEAD = "kdm-123"  -- Too late - closure already captured nil

-- ✅ CORRECT: Declare before functions that reference it
local FOCUS_BEAD = "kdm-123"  -- Declared first

local Module = {}

function Module.Init()
    someCallback = function()
        print(FOCUS_BEAD)  -- Captures the actual value
    end
end
```

**Why:** Lua closures capture variable references at **definition time**, not call time. If a function is defined before a local variable is declared, the closure captures `nil`.

## Paradigm Preference

**Default to object-oriented Lua:**

```lua
-- Similar to Weapon.ttslua pattern
local Gear = {}
function Gear:new(params)
    local gear = {
        name = params.name,
        -- ...
    }
    setmetatable(gear, {__index = self})
    return gear
end

function Gear:activate()
    -- Use colon for methods that need self
end

function Gear.isValid(params)
    -- Use dot for functions that don't need self
end
```

**If OO doesn't fit:** Use pure functions with clear inputs/outputs.

**Imperative scripts:** Only when above are impractical (glue code, bootstrap).

## Guard Clause Philosophy

**Use guard clauses only for realistic cases - avoid defensive programming**

```lua
-- ❌ BAD: Defensive - caller always provides valid deck
function processDeck(deck)
    if deck == nil then return end  -- When would this happen?
    if deck.cards == nil then return end  -- Structure guarantees this
end

-- ✅ GOOD: Realistic guard
function processDeck(deck)
    if #deck.cards == 0 then return end  -- Empty deck is valid but nothing to do
end
```

**Good guard clause:** Validates user input, external API responses, optional parameters.
**Bad guard clause:** Checks internal state that code structure already guarantees.

## Cross-Module Integration Tests

**MANDATORY: When your code calls functions from another module, write a headless integration test:**

```lua
-- Module A calls Module B
-- Test MUST exercise: A → B (real code, not stubs)
-- Module C (B's dependency) may be stubbed if needed
```

**Why:** Client code accessing unexported fields/functions only fails at TTS runtime (5-10 min debug cycles). Headless tests catch these in seconds.

**Implementer responsibility** - write these before handover.

## Refactoring Guidelines

- Work in small, safe steps - commit after each improvement
- Move toward smaller files, slimmer modules, shorter functions
- Remove duplication aggressively
- Opportunistically simplify nearby complexity when touching code

## TTSSpawner Test Seam Pattern

**When to invest (~1 hour):**
- ✅ Modules with TTS API calls (Archive, Campaign, Timeline)
- ✅ Cross-module integrations prone to export bugs
- ✅ Historical sources of "attempt to call nil value" errors
- ❌ Pure logic modules with no TTS dependencies
- ❌ UI-only modules (use ui_stubs instead)
- ❌ Code with <5 call sites

**Payback:** First export bug caught saves 2-4 hours. With 5-10 bugs per feature, investment pays for itself 10-40x.

**Pattern:** Extract TTS operations to separate seam (Util/TTSSpawner.ttslua), add Test_SetSpawner injection point.

## Documentation Strategy

1. **Self-speaking code** - expressive names, small logic, minimal comments
2. **Executable specifications** - encode behavior in automated tests
3. **In-code comments** - only when intent can't be expressed through structure
4. **External docs** - broader explanations (ARCHITECTURE.md, FAQ.md, ADRs)

**Always update every relevant document when behavior changes.**

## Common Patterns

### Check Module Pattern

Use Check module for validation:

```lua
assert(Check.Str(params.location, "location is required"))
assert(Check.Table(data, "data must be a table"))
```

### Logging Pattern

```lua
local log = require("Kdm/Log").ForModule("ModuleName")
log:Debugf("Processing %s", itemName)
log:Errorf("Failed to load %s", resourceName)
```

Enable debug output via console: `>debug ModuleName on`

### Event Pattern

Emit synthetic events instead of calling deep internals:

```lua
EventManager.ON_SURVIVOR_STAT_CHANGED
EventManager.ON_SHOWDOWN_STARTED
EventManager.ON_PLAYER_COLOR_CHANGED
```

## Related Documentation

- **ARCHITECTURE.md** - Full module export pattern rationale, module map, system architecture
- **CODE_REVIEW_GUIDELINES.md** - Review checklist, SOLID analysis, breaking changes
- **PROCESS.md** - Role-based workflow, change management
- **docs/TESTING.md** - Testing infrastructure, integration test strategy
- **docs/TTS_PATTERNS.md** - TTS-specific patterns, debugging approaches

## Real Code Examples

Copy-paste ready patterns from this codebase. These are production code, not hypotheticals.

### Example 1: Clean Module Structure

From `Trash.ttslua` — a well-structured module under 150 lines:

```lua
local NamedObject = require("Kdm/NamedObject")
local Archive = require("Kdm/Archive")
local Location = require("Kdm/Location")
local log = require("Kdm/Log").ForModule("Trash")

local Trash = {}

function Trash.IsInTrash(name, type)
    log:Debugf("Checking if %s '%s' is in trash", type, name)
    for _, object in ipairs(Trash.getObjects()) do
        if object.name == name and object.gm_notes == type then
            log:Debugf("%s '%s' is in trash", type, name)
            return true
        end
    end
    return false
end

function Trash.getObjects()
    return NamedObject.Get("Trash").getObjects()
end

function Trash.Export()
    local content = {}
    for _, object in ipairs(Trash.getObjects()) do
        table.insert(content, { name = object.name, type = object.gm_notes })
    end
    return content
end

function Trash.Import(content)
    local trash = NamedObject.Get("Trash")
    trash.reset()
    local position = trash.getPosition()
    position.y = position.y + 2
    for _, object in ipairs(content or {}) do
        Archive.TakeObject({ name = object.name, type = object.type, position = position})
    end
    Archive.Clean()
end

return Trash  -- Direct return, not explicit export table
```

**Key points:**
- Requires at top, module table declaration, functions, return at bottom
- `return Trash` (direct) not `return { IsInTrash = Trash.IsInTrash }` (explicit)
- Log module created with `ForModule("Trash")` for filtered debug output
- Single responsibility: trash container operations only

### Example 2: OOP with Inheritance

From `Gear.ttslua` and `Weapon.ttslua` — base class and subclass:

```lua
-- Gear.ttslua (base class)
local Gear = {}
local gearByName = {}

function Gear:new(gear)
    gear = gear or {}
    self.__index = self
    setmetatable(gear, self)
    if gear.name then
        gear.canonicalName = gear.canonicalName or gear.name
        Gear.register(gear)
    end
    return gear
end

function Gear.register(gear)
    log:Debugf("Gear.register(%s)", gear.name)
    assert(not gearByName[gear.name], string.format("Gear %s was already registered", gear.name))
    gearByName[gear.name] = gear
end

function Gear.getByName(name)
    return gearByName[name]
end

return Gear
```

```lua
-- Weapon.ttslua (subclass)
local Gear = require("Kdm/Gear")
local log = require("Kdm/Log").ForModule("Weapon")

local Weapon = Gear:new()  -- Inherit from Gear

function Weapon.Init()
    for _, expansion in ipairs(Expansion.All()) do
        for name, stats in pairs(expansion.weaponStats or {}) do
            stats.isWeapon = true
            Weapon:new({ name = name, stats = stats })
        end
    end
end

function Weapon:__tostring()
    return string.format("%s[%s] (%d/%d/%d)",
        self.name, self.canonicalName,
        self.stats.speed, self.stats.accuracy, self.stats.strength)
end

return Weapon
```

**Key points:**
- `Gear:new()` pattern with `self.__index = self` for method inheritance
- Subclass created via `Gear:new()` — inherits all base methods
- Registry pattern with `gearByName` for lookup by name
- `__tostring` metamethod for debug output

### Example 3: Check Module for Validation

From `Location.ttslua` — using Check module for assertions:

```lua
function Location.Get(locationOrName)
    if type(locationOrName) == "table" then
        assert(Location.Is(locationOrName))
        return locationOrName
    end

    assert(Check.Str(locationOrName))
    local location = Location.locationsByName[locationOrName:lower()]
    assert(Check(location, "Unknown location: %s", locationOrName))
    return location
end

function Location.ObjectLocations(object)
    assert(Check.Object(object))
    return Location.locationsByObject[object]
end

-- From Timeline.ttslua
function Timeline.CheckEvent(yearIndex, eventIndex)
    assert(Check.Num(yearIndex))
    assert(Check.Num(eventIndex))
    -- ...
end
```

**Key points:**
- `Check.Str(x)` validates string, returns the value for chaining
- `Check.Num(x)` validates number
- `Check.Object(x)` validates TTS object
- `Check(condition, format, ...)` for custom assertions with messages
- Fail-fast: invalid input crashes immediately with clear error

### Example 4: Test-Only Helper Pattern

From `Timeline.ttslua` — exposing internals for testing:

```lua
-- At end of module, before return
Timeline._test = {
    -- Expose private functions for unit testing
    SortedKeys = SortedKeys,
    AddBaseSearchEntry = AddBaseSearchEntry,
    NamesEqual = NamesEqual,

    -- Expose public functions that are hard to test via public API
    RebuildSearchTrie = Timeline.RebuildSearchTrie,

    -- Getter functions for internal state inspection
    GetTrie = function() return Timeline.trie end,
    GetCurrentSettlementEventNames = function() return Timeline.currentSettlementEventNames end,

    -- Dependency injection seams for isolation
    SetLocationGet = TestSetLocationGet,
    ResetLocationGet = TestResetLocationGet,
    SetContainerFunction = TestSetContainerFunction,
    ResetContainerFunction = TestResetContainerFunction,
}

return Timeline
```

**Key points:**
- All test helpers under `Module._test` table
- Private functions exposed directly: `SortedKeys = SortedKeys`
- State getters as functions: `GetTrie = function() return Timeline.trie end`
- Dependency injection seams for stubbing: `SetLocationGet`, `ResetLocationGet`
- Placed just before `return` statement

### Example 5: Guard Clauses vs Assertions

From `Trash.ttslua` — realistic guard clauses:

```lua
function Trash.AddCard(cardName, cardType, deckLocation)
    local trash = NamedObject.Get("Trash")
    if not trash then
        log:Errorf("Trash container not found")
        return false  -- Guard: external dependency might not exist
    end

    local location = Location.Get(deckLocation)
    if not location then
        log:Errorf("Deck location '%s' not found", deckLocation)
        return false  -- Guard: user-provided location might be invalid
    end

    local deck = location:FirstObject({ types = { cardType } })
    if not deck then
        log:Errorf("No %s deck found at %s", cardType, deckLocation)
        return false  -- Guard: deck might not exist at location
    end

    -- ... find card in deck ...

    if not cardIndex then
        log:Debugf("%s '%s' not found in deck at %s", cardType, cardName, deckLocation)
        return false  -- Guard: card might not be in deck (not an error)
    end

    -- ... take and move card ...
    return true
end
```

**Key points:**
- Guards for external dependencies that might not exist
- Guards for user-provided data that might be invalid
- `return false` signals recoverable failure (not crash)
- `log:Errorf` for unexpected failures, `log:Debugf` for expected "not found"
- Contrast with assertions: `assert(Check.Str(name))` for programming errors

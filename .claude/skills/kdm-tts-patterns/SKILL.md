---
name: kdm-tts-patterns
description: Tabletop Simulator (TTS) Lua patterns for Kingdom Death Monster mod. Covers async spawn callbacks, object lifecycle, deck operations, putObject behavior, coordinate system, Archive.Clean timing, and common TTS debugging patterns. Use when working with TTS code, spawn operations, decks, archives, callbacks, destroyed objects, <Unknown Error>, timing issues, or coordinate positioning.
---

# KDM TTS Patterns

TTS-specific implementation patterns, gotchas, and debugging approaches for the Kingdom Death Monster Tabletop Simulator mod.

## Async Spawn Callbacks

**Critical:** TTS object spawning uses asynchronous callbacks. Code after a spawn call runs BEFORE the spawned object exists.

```lua
-- WRONG - deck goes into archive before card is added
local card = container:Take({
    spawnFunc = function(card)
        deck.putObject(card)  -- Called LATER
    end,
})
archive.putObject(deck)  -- Called IMMEDIATELY - deck has no card yet!

-- CORRECT - wait for spawn to complete
container:Take({
    spawnFunc = function(card)
        deck.putObject(card)
        archive.putObject(deck)  -- Now card is in deck
    end,
})
```

This applies to:
- `object.takeObject({ callback_function = ... })`
- `Container:Take({ spawnFunc = ... })`
- `Archive.Take({ spawnFunc = ... })`

Any logic depending on the spawned object must be inside the callback or use `Wait.frames`.

## Object Lifecycle

### Destroyed Objects Cause <Unknown Error>

**Problem:** `<Unknown Error>` in TTS console typically means code tried to operate on a destroyed object.

**Common causes:**
- Async callback tries to use an object that was destroyed
- Object reference held across frames after the object was destroyed
- `destruct()` called on an object, then later code tries to use it

**Debugging:** Add logging before operations to track object GUIDs and identify which object was destroyed prematurely. Check if object references are `null` in async callbacks.

### putObject() Copies, Not Moves

**Problem:** TTS's `deck.putObject(card)` does NOT move the card into the deck - it **copies** the card data into the deck, leaving the original card object in place.

**Symptoms:**
- "Stray" cards appearing at staging positions after deck operations
- Cards falling through the table (y coordinate going negative)
- Duplicate cards accumulating over multiple test runs

**Solution:** Always destroy the original card after `putObject()`:
```lua
targetDeck.putObject(card)
card.destruct()  -- Destroy the original - putObject copied it
```

## Archive.Clean() and Concurrent Operations

**Problem:** `Archive.Clean()` destroys all spawned archive objects at staging positions. If multiple async operations are running concurrently, one operation's `Archive.Clean()` can destroy objects another operation still needs.

**Symptoms:**
- `<Unknown Error>` in async callback
- Object reference becomes `null` between when it was captured and when callback fires
- Error occurs "after everything completes" - actually occurs when delayed callback fires

**Example Bug:**
```lua
-- This code had a bug:
function ExecuteConsequences(milestone)
    -- Operation 1: Async - callback fires later
    ApplyFightingArt(cardName, function()
        SpawnFightingArtForSurvivor(cardName)  -- Uses Fighting Arts deck
    end)

    -- Operation 2: Runs immediately, doesn't wait for Operation 1
    SpawnStrangeResource("Iron")  -- Calls Archive.Clean()!
    -- Archive.Clean() destroys Fighting Arts deck
    -- Later, Operation 1's callback fires, but deck is null → <Unknown Error>
end
```

**Solution:** Chain operations that use `Archive.Clean()` so they don't overlap:
```lua
function ExecuteConsequences(milestone)
    if consequences.fightingArt then
        ApplyFightingArt(cardName, function()
            SpawnFightingArtForSurvivor(cardName)
            -- Run other spawn operations AFTER fightingArt completes
            if consequences.strangeResource then
                SpawnStrangeResource(consequences.strangeResource)
            end
        end)
    else
        -- No fightingArt, safe to run immediately
        if consequences.strangeResource then
            SpawnStrangeResource(consequences.strangeResource)
        end
    end
end
```

**Debugging approach:**
1. Add logging to identify when async callbacks fire relative to other operations
2. Log object references (`tostring(obj)`) - `null` indicates destroyed object
3. Create a TTS test command (e.g., `>testplottwist`) to reproduce the issue consistently
4. Trace which `Archive.Clean()` call destroys the needed object

## Deck and Archive Operations

### Archive Two-Level Structure

The Archive system has a two-level structure:

**Level 1: Archive → Deck/Container**
- `Archive.Take({ name = "Misc AI", type = "AI" })` looks up the archive using `Archive.Key(name, type)`
- The key maps to an archive name (e.g., `"Core Archive"`) via `Archive.index`
- The archive container is spawned and cached in `Archive.containers`

**Level 2: Container → Individual Card**
- `Container:Take({ name = "Card Name", type = "Card Type" })` searches inside the spawned deck
- **Critical**: Search requires BOTH `name` AND `gm_notes` (type) to match exactly

**Common failure modes:**
1. **Archive name mismatch**: Passing an explicit `archive` parameter that doesn't exist as a TTS object
2. **Card name typo**: Card names in the TTS save file must match exactly what the code expects
3. **Type mismatch**: A deck's `gm_notes` differs from its cards' `gm_notes`
4. **Cached container depletion**: `Archive.Take` removes objects from cached containers. Multiple calls for the same object fail unless `Archive.Clean()` is called between them to spawn a fresh container.

**Debugging steps:**
1. Check `savefile_backup.json` for exact `Nickname` and `GMNotes` values
2. Trace whether the code passes an explicit `archive` parameter (usually wrong) or lets auto-resolution work (usually right)
3. If taking the same object twice, ensure `Archive.Clean()` is called between takes

### Infinite Archives

**Behavior:** Infinite archives (bags with infinite contents) have special rules:

1. **Can't put objects back directly** - `infiniteArchive.putObject(obj)` does nothing unless `reset()` is called first
2. **reset() empties the archive** - After `reset()`, `putObject` works but the archive loses its original contents
3. **Pattern for returning decks**: After modifying a deck taken from an infinite archive, call `archive.reset()` then `archive.putObject(deck)` to restore it

**Common infinite archives:**
- Core Archive (infinite)
- Fighting Arts Archive (infinite)
- Vermin Archive (infinite)

**Identifying:** Check `template_workshop.json` to see object configurations.

### Deck Lifecycle Pattern

Many card decks follow a three-stage lifecycle:

1. **Construction** - Cards collected from enabled expansion archives and combined into a single deck
2. **Archive Storage** - Constructed deck stored in a dedicated archive container which acts as the canonical source
3. **Board Spawn** - Deck spawned from archive to its board location for player use

**Reset Flow:** Players can reset a deck at any time via `Deck.ResetDeck()`, which:
- Clears the current board deck
- Spawns a fresh copy from the archive
- Shuffles if needed

**Implication for runtime modifications:** Any permanent changes to deck contents must modify the deck **inside the archive**, not just the board copy. Otherwise changes are lost on reset.

Pattern:
1. Take the deck from the archive
2. Add/remove cards
3. Put the modified deck back in the archive
4. Optionally spawn a fresh copy to the board

## Coordinate System

TTS uses a **left-handed coordinate system** when viewed from above:

```
        -Z (away from you)
           ↑
           |
+X ←——————+——————→ -X
(left)     |        (right)
           ↓
        +Z (toward you)

Y = height above table (positive = up)
```

**Key points:**
- **Positive X goes LEFT** (counterintuitive!)
- **Positive Z goes DOWN** (toward you)
- **Y = 0** is below the table surface; typical spawn height is Y = 1-2

**Reference positions (world coordinates):**

| Location | Center X | Center Z | Notes |
|----------|----------|----------|-------|
| Table center | 0 | 0 | Origin |
| Settlement Board | 0 | 0 | Centered at origin |
| Showdown Board | 0 | ~0.7 | Slightly south of center |
| Hunt Board | 0 | ~-50 | Far north |
| Rulebooks | ~15 | 0 | East of settlement |
| Resource Rewards spawn | -10 | 0 | West of settlement |

**Common Y values:**
- Table surface: ~0.6
- Card spawn height: 1-2
- Showdown board surface: ~10.74

**Tips:**
- Use `>showpos` command to get coordinates of selected objects
- Use `>showloc <name>` to highlight a named location
- LocationData.ttslua contains all defined locations with coordinates

## Common Debugging Patterns

### "attempt to call a nil value"

When a function exists but calling it throws this error:
1. **Check the module's return statement** - Lua modules must explicitly export functions in their `return { ... }` table
2. Debug pattern: `log:Debugf("Module.Function: %s", tostring(Module.Function))` - if this prints `nil`, the function isn't exported
3. **Root cause:** Missing function in the return statement at the end of the module file

**Preferred pattern:** Return the module table directly (`return Module`) instead of explicit export tables to avoid this issue.

### Module Export vs Internal Table

**Problem:** `Module.field = value` assignments are not visible to other modules via `require()`

**Root cause:** When a module uses `return {...}` with explicit exports, dynamic assignments go to the **internal** `local Module = {}` table, not the **exported** table:
```lua
local Module = {}  -- Internal table

function Module.DoThing()
    Module.state = "done"  -- Assigns to INTERNAL table
end

return {
    DoThing = Module.DoThing,
    -- state is NOT exported!
}
```

**Solution:** Return the internal table directly:
```lua
return Module  -- Now Module.state is visible to other modules
```

### Archive Resource Leaks

When subsequent `Archive.Take()` calls fail after initial success:
1. **Check if `deck.destruct()` and `Archive.Clean()` are called** after extracting items from spawned decks
2. **Pattern:** Functions that call `Archive.Take()` must clean up:
   ```lua
   local deck = Archive.Take({...})
   -- Extract what you need
   local card = container:Take({...})
   -- MUST cleanup before returning
   deck.destruct()
   Archive.Clean()
   ```
3. **Root cause:** Leaving spawned deck objects or containers cached causes:
   - Subsequent calls find empty cached containers instead of spawning fresh ones
   - Objects spawn at same location forming decks, making individual `destruct()` calls fail

### CardCustom Type Triggers Import Dialog

**Problem:** When putting a `CardCustom` type object (single custom card, not part of a deck) into a deck, TTS may show the "CUSTOM CARD" import dialog with empty URL fields.

**Symptoms:**
- Empty "CUSTOM CARD" dialog appearing during card transfers
- Dialog shows empty Face/Back URL fields
- Tests pass but dialog is visually distracting

**Cause:** `CardCustom` objects have different internal handling than cards that were originally part of decks.

**Investigation approach:** Check card's type via `object.type` - cards from decks are typically `Card`, standalone custom cards are `CardCustom`.

### Deck Formation at Same Position

**Problem:** Spawning multiple cards at same location creates a deck; can't `destruct()` individual cards

**Solution:** Either spawn at different positions, or destroy first card before spawning second

**Debug tip:** If cleanup fails silently, check if objects have auto-grouped into a deck

## Player Object References

**Problem:** Player objects aren't stable references between different TTS callbacks.

**Solutions:**
1. Compare `player.color` strings instead of object references
2. Better: Eliminate player tracking for shared campaign state (milestones, settlement progress)

## Checkbox Interaction Pattern

**Problem:** TTS automatically toggles checkbox visual state on click before calling the onClick handler.

**Solution:** Revert checkbox state in handler, show confirmation dialog, then explicitly set final state.
```lua
onClick = function(_, player)
    -- TTS has already auto-toggled the checkbox
    checkbox:Check(false)  -- Revert to unchecked
    showConfirmationDialog()
    -- On confirm: checkbox:Check(true)
end
```

## Dialog API Usage

**Correct Methods**:
- `dialog:ShowForPlayer(player)` - show to specific player
- `dialog:ShowForAll()` - show to all players
- `dialog:HideForAll()` - hide from all players

**Common Error:** Using `dialog:Show()` or `dialog:Hide()` (these methods don't exist in PanelKit).

## UI setAttribute After ApplyToObject

**Problem:** Calling `Show()`/`Hide()` immediately after `ApplyToObject()` causes `Object reference not set to an instance of an object`

**Root cause:** TTS hasn't finished processing the XML from `setXmlTable()` when `setAttribute()` is called. The element doesn't exist in TTS's internal state yet.

**Solution:** Set initial visibility via `active` param instead of calling `Hide()` in Init:
```lua
-- WRONG: Timing issue
local button = ui:Button({id = "Foo", ...})
ui:ApplyToObject()
button:Hide()  -- FAILS - element doesn't exist yet

-- CORRECT: Set initial state in params
local button = ui:Button({id = "Foo", ..., active = false})
ui:ApplyToObject()
-- Button starts hidden, no Hide() call needed
```

**When Show/Hide is safe:** After `PostInit()` or inside event handlers (UI has been processed by then)

## Debug Logging

### Retention Policy
**Debug statements do NOT need to be removed** if:
- Their execution cost is negligible (simple string formatting, no loops)
- The module's debug logging can be disabled via `Log.ttslua`

**Benefits of keeping debug statements:**
- Future debugging is faster (no need to re-add the same logging)
- Debug paths are already tested and working
- Reduces risk of introducing bugs when re-adding logging later

### Enabling Logging for a Module
When adding `log:Debugf()` statements, you must also enable the module in `Log.ttslua`:

```lua
local DEBUG_MODULES = {
    ["MyModule"] = true,  -- Add/uncomment the module you're debugging
}
```

**CRITICAL:** Without this step, your debug output will not appear.

### Logging Pattern
```lua
local Log = require("Log")
local log = Log.ForModule("MyModule")

log:Debugf("Variable X = %s", tostring(x))
log:Debugf("Function exists: %s", tostring(SomeModule.SomeFunction ~= nil))
```

## Progressive Debug Logging Strategy

When functions don't execute, add logging **backwards through the call chain**:

```lua
-- 1. Start at the deepest point that should execute
function Archive.TakeFromDeck(params)
    log:Debugf("[DEBUG] TakeFromDeck START") -- Never appears? Check caller
    -- ...
end

-- 2. Add logging to the caller
function Strain:_TakeFromRewardsDeck(params)
    log:Debugf("[DEBUG] _TakeFromRewardsDeck START") -- Appears? Check function exists
    log:Debugf("[DEBUG] Archive.TakeFromDeck exists: %s", tostring(Archive.TakeFromDeck ~= nil))
    Archive.TakeFromDeck({...})
end

-- 3. Check at call site
log:Debugf("[DEBUG] Strain.Test._TakeRewardCard exists: %s", tostring(Strain.Test._TakeRewardCard ~= nil))
local ok = Strain.Test._TakeRewardCard(Strain, {...})
```

**Pattern:** Work backwards from where execution stops until you find the nil value or missing export.

## Save File Inspection

The TTS save file (`template_workshop.json`) contains all object data and can be inspected:
1. **Use Python/jq to query the JSON** for specific objects by GUID or name
2. **Compare working vs broken objects** to find property differences
3. **Key properties to check:**
   - `Name`: Object type (`Card`, `CardCustom`, `Deck`, etc.)
   - `CustomDeck`: Card image sheet definitions with `FaceURL`, `BackURL`, `NumWidth`, `NumHeight`
   - `ContainedObjects`: Items inside decks/bags

## Fail Fast Philosophy

**Fail fast with meaningful errors** - Don't silently ignore missing dependencies; log and fail clearly.

Function existence checks should be rare and only used for:
- **Test environment compatibility** - where modules genuinely might not exist
- **Optional features** - where the functionality is truly optional, not required
- **Never** for hiding missing required dependencies - those should fail fast with clear error messages

Use `assert(obj, "helpful message")` to fail loud and reveal timing issues.

## Return Value Discipline

Functions that orchestrate async operations via callbacks must still return success/failure:

```lua
-- BAD: No return value
function Module.DoSomething(params)
    SomeAsync.Call({
        callback = function(result)
            params.onComplete(result) -- Callback executes
        end
    })
end -- Caller gets nil

-- GOOD: Return boolean for caller to check
function Module.DoSomething(params)
    local success = SomeAsync.Call({
        callback = function(result)
            params.onComplete(result)
        end
    })
    return success -- Caller can check if operation started
end
```

Even when the actual result comes via callback, return a boolean indicating whether the operation was initiated successfully.

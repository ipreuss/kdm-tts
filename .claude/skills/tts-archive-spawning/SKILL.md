---
name: tts-archive-spawning
description: Spawning objects from TTS archives with async callbacks and cleanup. Use when working with Archive.Take, spawn callbacks, async operations, or Archive.Clean. Triggers on Archive.Take, spawn, spawnFunc, callback, async, Archive.Clean, infinite archive.
---

# TTS Archive Spawning

Patterns for spawning objects from the Archive system with proper async handling and cleanup.

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

## Archive Two-Level Structure

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

## Archive.Clean() Patterns

**Always call Archive.Clean() after Archive.Take operations:**

```lua
local deck = Archive.Take({...})
-- Extract what you need
local card = container:Take({...})
-- MUST cleanup before returning
deck.destruct()
Archive.Clean()
```

**Clean on BOTH success and error paths:**

```lua
if not cardIndex then
    log:Errorf("Card '%s' not found in Strain Rewards deck.", cardName)
    if archive then
        archive.putObject(brDeck)  -- Return deck to archive
    end
    Archive.Clean()  -- Still clean up even on error!
    return false
end
```

**Clean inside loops when taking same card type multiple times:**

```lua
for _, card in ipairs(cards) do
    Archive.TakeObject({
        name = card.name,
        type = card.type,
        location = location,
        height = height,
        spawnFunc = function(cardObject)
            survivorBoxObject.putObject(cardObject)
        end
    })
    height = height + 0.5

    -- Must clean up after each Take() since a survivor
    -- could have more than one of the same card
    Archive.Clean()
end
```

## Infinite Archives

**Behavior:** Infinite archives (bags with infinite contents) have special rules:

1. **Can't put objects back directly** — `infiniteArchive.putObject(obj)` does nothing unless `reset()` is called first
2. **reset() empties the archive** — After `reset()`, `putObject` works but the archive loses its original contents
3. **Pattern for returning decks**: After modifying a deck taken from an infinite archive, call `archive.reset()` then `archive.putObject(deck)` to restore it

**Common infinite archives:**
- Core Archive (infinite)
- Fighting Arts Archive (infinite)
- Vermin Archive (infinite)

**Identifying:** Check `template_workshop.json` to see object configurations.

**Wait.frames for infinite archives:**
```lua
Archive.Take({
    name = "Survivor Sheet",
    type = "Survivor Sheet",
    location = playerPrefix.." Survivor Sheet",
    spawnFunc = function(survivorSheetObject)
        -- Wait.frames needed when taking from infinite containers
        -- to ensure objects have unique identity
        Wait.frames(function()
            log:Debugf("Created survivor sheet %s", survivorSheetObject.getGUID())
            -- ... use the object
        end, 1)
    end,
})
```

## Archive Resource Leaks

When subsequent `Archive.Take()` calls fail after initial success:
1. **Check if `deck.destruct()` and `Archive.Clean()` are called** after extracting items from spawned decks
2. **Root cause:** Leaving spawned deck objects or containers cached causes:
   - Subsequent calls find empty cached containers instead of spawning fresh ones
   - Objects spawn at same location forming decks, making individual `destruct()` calls fail

## Protected Calls with Cleanup

```lua
local success, err = xpcall(function()
    -- ... complex setup code that might error ...
end, debug.traceback)

Showdown.settingUp = false  -- ALWAYS reset state, even on error

if not success then
    log:Errorf("Showdown setup failed: %s", tostring(err))
    Archive.Clean()  -- Cleanup any partial spawns
    return false
end
```

## Return Value Discipline

Functions that orchestrate async operations via callbacks must still return success/failure:

```lua
-- BAD: No return value
function Module.DoSomething(params)
    SomeAsync.Call({
        callback = function(result)
            params.onComplete(result)
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

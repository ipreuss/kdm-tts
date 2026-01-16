# Archive - Object Spawning System

## Modules
- `Archive.ttslua` - Central spawning system with caching
- `BasicResourcesArchive.ttslua` - Basic resource deck management
- `DisordersArchive.ttslua` - Disorders deck
- `FightingArtsArchive.ttslua` - Fighting arts deck
- `SevereInjuriesArchive.ttslua` - Severe injuries deck
- `StrangeResourcesArchive.ttslua` - Strange resources deck
- `VerminArchive.ttslua` - Vermin deck

## Key Patterns

### Archive.Take (ASYNC!)
```lua
Archive.Take({
    archive = "Fighting Arts",
    archiveEntry = "Timeless Eye",
    location = Location.Get("Fighting Arts Discard"),
    spawnFunc = function(card)
        -- card is spawned, do something
    end
})
```

### Two-Level Structure
Archive -> Container (infinite bag) -> Cards
Archive caches containers for faster subsequent spawns.

### Archive.Clean
Call after spawn sequences to clean up temporary objects:
```lua
Archive.Clean()
```

## Common Errors
- `Archive.Take returns nil` - Check archiveEntries in Expansion module
- `Object destroyed in callback` - Archive.Clean called too early
- `Card not found` - Name mismatch with archiveEntries

## TTS Event Limitations

### onObjectSpawn Does Not Fire for Archive.Take

TTS's `onObjectSpawn` global event does **not** fire when `Archive.Take` spawns objects. Any code relying on `onObjectSpawn` to detect Archive.Take spawns will silently fail.

**Workaround:** Call `Location.OnEnter(object)` after spawning to manually trigger drop handlers:

```lua
Archive.Take({
    archive = "Survivor Boxes",
    archiveEntry = boxEntry,
    location = location,
    spawnFunc = function(survivorBoxObject)
        -- Manually trigger location entry since onObjectSpawn doesn't fire
        Location.OnEnter(survivorBoxObject)
        -- ... rest of spawn callback
    end
})
```

**Reference:** See `Entity/Survivor.ttslua:1309-1311` for the pattern discovered during kdm-407.

**Why this matters:** Drop handlers registered via `Location` (e.g., `OnObjectDroppedOnSurvivorSheet`) depend on location entry events. Without manual `OnEnter`, these handlers never execute for Archive.Take spawns.

## Dependencies
- Location (spawn positions)
- Expansion (archiveEntries definitions)
- NamedObject (GUID registry)

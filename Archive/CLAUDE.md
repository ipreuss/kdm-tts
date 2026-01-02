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

## Dependencies
- Location (spawn positions)
- Expansion (archiveEntries definitions)
- NamedObject (GUID registry)

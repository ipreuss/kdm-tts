---
name: archive-system
description: KDM Archive system for spawning cards from infinite containers. Use when working with Archive.Take(), Archive.Clean(), archive caching, async spawn operations, or understanding the two-level archive structure. Triggers on Archive.Take, Archive.Clean, archive caching, spawn card, infinite container.
---

# Archive System

## When to Use

Use when:
- Spawning cards from archives
- Understanding why cards aren't found
- Working with async archive operations
- Managing archive caching and cleanup
- Debugging archive-related errors

## Two-Level Structure

**Critical concept**: The archive system has two levels:

### Level 1: Archive Container
An infinite bag/deck registered via `guidNames`:
```lua
guidNames = { ["abc123"] = "Gorm Archive" }
```

### Level 2: Contents
What's inside that archive container, registered via `archiveEntries`:
```lua
archiveEntries = {
    archive = "Gorm Archive",  -- Points to guidNames entry
    entries = {
        { "Gorm Fighting Arts", "Fighting Arts" },  -- [name, type]
        { "Gormery Gear", "Gear" },
    },
}
```

## How Archive.Take() Works

1. Looks up key `"Fighting Arts.Gorm Fighting Arts"` → finds `"Gorm Archive"`
2. Opens the Gorm Archive infinite container
3. Takes the "Gorm Fighting Arts" deck from inside it
4. **Caches** the container for subsequent operations
5. `Archive.Clean()` destroys cached containers when done

## Archive Caching and Async Operations

**Problem**: `Archive.Take()` caches spawned containers. Multiple async operations can conflict.

**Wrong pattern:**
```lua
Archive.Take({ name = "Card 1", type = "Gear" })  -- Spawns & caches container
Archive.Take({ name = "Card 2", type = "Gear" })  -- Reuses cached container
-- If first operation is async, second fails: "card not found"
```

**Correct pattern** (chain via callbacks):
```lua
Archive.Take({
    name = "Card 1",
    type = "Gear",
    onComplete = function()
        Archive.Take({
            name = "Card 2",
            type = "Gear",
        })
    end,
})
```

**For card transfers:**
```lua
Archive.TransferCardBetweenDecks({
    sourceDeckName = "Source",
    targetArchiveName = "Target Archive",
    cardName = "Card Name",
    onComplete = function()
        -- Next operation here
    end,
})
```

## Archive.Clean()

Destroys all cached archive containers. Call after completing a batch of operations.

**When to call:**
- After Hunt cleanup
- After Showdown setup completes
- After resource reward spawning
- Any time you're done with archive operations

## Deck Lifecycle

Many decks follow this pattern:

1. **Construction** — Built from expansion components
2. **Archive Storage** — Stored in dedicated archive
3. **Board Spawn** — Spawned to board for player use

**Reset flow:**
- `Deck.ResetDeck()` clears board deck
- Spawns fresh copy from archive
- Modifications must be made **inside the archive**, not just board deck

## Common Issues

### "Card not found in archive"
See `card-not-found` skill for debugging steps.

### Operations conflicting
Chain via `onComplete` callbacks instead of parallel calls.

### Stale containers
Call `Archive.Clean()` between logical operation groups.

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Archive.ttslua` — Archive registration and spawning
- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — archiveEntries definitions

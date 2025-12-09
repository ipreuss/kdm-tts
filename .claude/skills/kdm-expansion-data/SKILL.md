---
name: kdm-expansion-data
description: Kingdom Death Monster TTS mod expansion data structure and conventions. Use when working with expansion files, gear stats, monster definitions, archive entries, card decks, resource rewards, or troubleshooting "card not found" errors. Covers Core, Gorm, Dragon King, Spidicules, and all other expansions.
---

# KDM Expansion Data Structure

## When to Use This Skill

Auto-activates when working with:
- Expansion files (`Expansion/*.ttslua`)
- Gear, weapon, armor stats
- Monster definitions and showdown setup
- Archive system and card spawning
- Settlement locations and innovations
- Resource rewards, fighting arts, disorders
- "Card not found" errors
- Adding new expansion content

## Expansion File Structure

All expansion files follow this standard pattern:

```lua
return {
    name = "Expansion Name",

    -- What cards/decks this expansion provides
    components = {
        ["Category"] = "Deck Name",
        -- Multiple decks: ["Category"] = { "Deck 1", "Deck 2" }
    },

    -- Timeline events (auto-added to campaign timeline)
    timelineEvents = {
        { year = 1, name = "Event Name", type = "RulebookEvent" },
    },

    -- Gear location mappings
    settlementLocationGear = {
        ["Location Name"] = "Gear Deck Name",
        -- Multiple decks: ["Location"] = { "Deck 1", "Deck 2" }
    },

    -- Armor stats for BattleUi
    armorStats = {
        ["Armor Name"] = { head = 2, arms = 2, body = 2, waist = 2, legs = 2 },
        -- Set bonus: modifier = true
    },

    -- Weapon stats for BattleUi
    weaponStats = {
        ["Weapon Name"] = { speed = 2, accuracy = 7, strength = 3 },
        -- Special properties: paired = true, deadly = 1, slow = true, sharp = true
    },

    -- Combined gear (shields, etc.)
    gearStats = {
        ["Item Name"] = {
            isArmor = true, head = 1, arms = 1, body = 1, waist = 1, legs = 1,
            isWeapon = true, speed = 2, accuracy = 7, strength = 3,
            -- Special: cursed = true, irreplaceable = true
        },
    },

    -- GUID mappings for TTS objects
    guidNames = { ["abc123"] = "Archive Name" },

    -- Archive registration (two-level structure)
    archiveEntries = {
        archive = "Archive Container Name",
        entries = {
            { "Deck Name", "Type" },
            -- Types: "Gear", "Fighting Arts", "Disorders", "Armor Sets",
            -- "Monster Resources", "Innovations", "Settlement Locations",
            -- "Rulebook", "AI", "Hit Locations", "Monster Hunt Events"
        },
    },

    -- Monster definitions
    monsters = { ... },

    -- Campaign-specific data (if expansion defines a campaign)
    campaigns = { ... },
}
```

## Archive System: Two-Level Structure

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

**How it works:**
1. `Archive.Take()` looks up the key `"Fighting Arts.Gorm Fighting Arts"` → finds `"Gorm Archive"`
2. Opens the Gorm Archive infinite container
3. Takes the "Gorm Fighting Arts" deck from inside it
4. Caches the container for subsequent operations
5. Calls `Archive.Clean()` to destroy cached containers when done

## Card Naming Conventions

**CRITICAL**: Card names in expansion data MUST exactly match TTS save file names.

### Variant Handling

Physical cards often have suffixes for variants:
- `"Bone Hatchet [left]"` — actual TTS card name
- `"Bone Hatchet [right]"` — actual TTS card name
- `"Bone Hatchet"` — canonical name in expansion data

**System behavior:**
- Expansion data defines stats once: `["Bone Hatchet"] = { speed = 2, ... }`
- `Gear.cannonicalFor()` strips `[bracket]` suffixes
- `Gear.getByName()` inherits stats from canonical entry
- BattleUi counts by canonical name for paired weapon bonuses

**Rule**: Only define the canonical name (without suffix) in expansion stats.

## Common Card Types

Standard GMNotes types used throughout:

| Type | Used For |
|------|----------|
| `"Gear"` | Equipment cards (weapons, items, armor) |
| `"Fighting Arts"` | Survivor fighting arts |
| `"Secret Fighting Arts"` | Rare fighting arts |
| `"Disorders"` | Survivor disorders |
| `"Severe Injuries"` | Permanent injuries |
| `"Armor Sets"` | Complete armor set decks |
| `"Monster Resources"` | Monster-specific resources |
| `"Strange Resources"` | Rare/special resources |
| `"Basic Resources"` | Common resources |
| `"Innovations"` | Settlement innovations |
| `"Settlement Locations"` | Location cards |
| `"Settlement Events"` | Timeline settlement events |
| `"Monster Hunt Events"` | Hunt phase events |
| `"Rulebook"` | Rulebook reference cards |
| `"AI"` | Monster AI decks |
| `"Hit Locations"` | Monster hit location decks |
| `"Terrain"` | Terrain card decks |
| `"Terrain Tiles"` | Physical terrain tiles |

## Adding New Expansion Content

### Step 1: Create/Modify Expansion File

File: `Expansion/YourExpansion.ttslua`

```lua
return {
    name = "Your Expansion",

    components = {
        ["Fighting Arts"] = "Your Expansion Fighting Arts",
        ["Gear"] = "Your Expansion Gear",
    },

    guidNames = { ["guid123"] = "Your Expansion Archive" },

    archiveEntries = {
        archive = "Your Expansion Archive",
        entries = {
            { "Your Expansion Fighting Arts", "Fighting Arts" },
            { "Your Expansion Gear", "Gear" },
        },
    },

    armorStats = {
        ["Your Armor"] = { head = 2, arms = 2, body = 2, waist = 2, legs = 2 },
    },

    weaponStats = {
        ["Your Weapon"] = { speed = 2, accuracy = 7, strength = 3 },
    },
}
```

### Step 2: Verify TTS Template

**Before defining stats, verify the card exists:**

1. Open the TTS save file or use `>interact <archive-name>`
2. Check exact card names (including any `[variant]` suffixes)
3. Only add stats for cards that physically exist in the template

**Why**: Prevents "card not found" errors and configuration drift.

### Step 3: Test Archive Registration

```lua
-- In TTS console
>debug Archive on
>interact Your Expansion Archive
```

Verify:
- Archive container spawns
- Contains expected decks
- Card names match exactly

## Troubleshooting "Card Not Found"

### Error Pattern
```
Couldn't find [CardName] (Gear) in archive [ArchiveName]
```

### Diagnostic Steps

**1. Check archive registration:**
```lua
-- Does the archive entry exist?
archiveEntries = {
    archive = "Correct Archive Name",  -- Must match guidNames
    entries = {
        { "Exact Card Name", "Correct Type" },
    },
}
```

**2. Check GUID mapping:**
```lua
-- Does the GUID point to the right container?
guidNames = { ["abc123"] = "Archive Name" }
```

**3. Verify TTS card name:**
- Spawn the archive: `>interact Archive Name`
- Manually inspect contents
- Check for typos, extra spaces, case sensitivity
- Look for unexpected `[variant]` suffixes

**4. Check type matching:**
```lua
-- GMNotes must match exactly
Archive.Take({ name = "Card Name", type = "Gear" })
-- Card in TTS must have GMNotes = "Gear"
```

**5. Review variant handling:**
```lua
-- If card is "Item [special]", define as:
weaponStats = {
    ["Item"] = { ... }  -- Canonical name only
}
-- System will auto-match variants
```

## Archive Caching and Async Operations

**Problem**: `Archive.Take()` caches spawned containers. Multiple async operations can conflict.

**Wrong pattern:**
```lua
Archive.Take({ name = "Card 1", type = "Gear" })  -- Spawns & caches container
Archive.Take({ name = "Card 2", type = "Gear" })  -- Reuses cached container
-- If first operation is async, second fails: "card not found"
```

**Correct pattern** (for archive modules):
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

**Why**: Archive operations spawn containers, take cards asynchronously, then call `Archive.Clean()`. Chain operations via callbacks to avoid conflicts.

## Promo Content Integration

**Principle**: Bundle promo content into the most appropriate major expansion.

Examples:
- White Box items → Core expansion
- Promo survivors → Core expansion
- Expansion-specific promos → That expansion's file

**Why**: Avoids proliferation of tiny expansion files. Keeps related content together.

## Component Categories

Standard `components` keys:

| Key | Purpose |
|-----|---------|
| `"Abilities"` | Survivor abilities deck |
| `"Fighting Arts"` | Fighting arts deck |
| `"Secret Fighting Arts"` | Secret fighting arts |
| `"Disorders"` | Disorders deck |
| `"Severe Injuries"` | Severe injuries deck |
| `"Weapon Proficiencies"` | Weapon proficiency cards |
| `"Armor Sets"` | Armor set decks |
| `"Vermin"` | Vermin cards |
| `"Strange Resources"` | Strange resources deck |
| `"Basic Resources"` | Basic resources deck |
| `"Monster Resources"` | Monster-specific resources |
| `"Terrain"` | Terrain card deck |
| `"Terrain Tiles"` | Physical terrain tiles |
| `"Hunt Events"` | Hunt event cards |
| `"Settlement Events"` | Settlement event cards |
| `"Innovations"` | Innovation cards |
| `"Settlement Locations"` | Settlement location cards |
| `"Rare Gear"` | Special gear cards |
| `"Pattern Gear"` | Craftable pattern gear |
| `"Seed Pattern Gear"` | Seed patterns |

## Settlement Location Gear

Maps location names to gear decks spawned when that location is built:

```lua
settlementLocationGear = {
    ["Bone Smith"] = "Bone Smith Gear",  -- Single deck
    ["Giga-Catarium"] = { "Catarium Gear", "Giga-Catarium Gear" },  -- Multiple
}
```

**How it's used:**
- When settlement location is activated
- Spawns associated gear deck(s) to board
- Players can craft from available gear

## Terrain System

### Terrain Cards vs Tiles

**Terrain cards** (in deck):
```lua
terrain = {
    ["2 Tall Grass"] = { terrainTile = "Tall Grass", count = 2 },
}
```

**Terrain tiles** (physical objects):
```lua
terrainTileSizes = {
    ["Tall Grass"] = { x = 2, y = 2 },  -- Grid squares
}
```

**Special terrain** (with attached objects):
```lua
terrain = {
    ["Egg Sacs"] = {
        terrainTile = "Egg Sac",
        count = "*",  -- Special: multiple, quantity varies
        miscObject = { name = "Spiderling", type = "Minion Figurine" },
    },
}
```

## Monster Definitions

Complex structure for showdown setup:

```lua
monsters = {
    {
        name = "Monster Name",
        size = { x = 3, y = 3 },  -- Board grid size
        rules = { "Rulebook Name", 5 },  -- [book, page state]
        huntTrack = { "M", "M", "H", "H", "M", "O", "H" },  -- M/H/O markers
        position = "(12, 9)",  -- Grid coordinates
        playerPositions = { "(11, 16)", "(12, 16)" },

        fixedTerrain = {
            {
                terrain = "2 Tall Grass",
                positions = { "(9.5, 6.5)" },
                rotations = { { x = 0, y = 180, z = 0 } },
            },
        },
        randomTerrain = 2,  -- Number of random terrain cards

        levels = {
            {
                name = "Level 1",
                level = 1,
                monsterHuntPosition = 4,  -- Hunt track position
                showdown = {
                    basic = 8,  -- Basic AI cards
                    advanced = 2,  -- Advanced AI cards
                    movement = 6,
                    toughness = 8,
                    resources = { basic = 4, monster = 4 },
                },
            },
        },
    },
}
```

## Resource Rewards Pattern

Resource rewards spawn from **existing decks on showdown board**, not fresh archive decks.

**Why**: If events during showdown allowed players to take resources early, those cards should not be available as rewards.

**Implementation**: `ResourceRewards.ttslua` inspects board decks, doesn't call `Archive.Take()`.

## Deck Lifecycle

Many decks follow this pattern:

1. **Construction** — Built from expansion components via `Campaign.SetupDeckFromExpansionComponents()`
2. **Archive Storage** — Stored in dedicated archive (e.g., "Fighting Arts Archive")
3. **Board Spawn** — Spawned to board location for player use

**Reset flow:**
- `Deck.ResetDeck()` clears board deck
- Spawns fresh copy from archive
- Any modifications must be made **inside the archive**, not just board deck

**Example** (Strain fighting arts):
```lua
-- Wrong: modifies board deck (lost on reset)
boardDeck.putObject(card)

-- Correct: modifies archive deck
FightingArtsArchive.AddCard(cardName, function()
    -- Then optionally spawn to board
end)
```

## Future Direction: Node System

**Current**: Expansion-based organization (Core, Gorm, Dragon King, etc.)

**Planned** (Campaigns of Death): Node-based system representing actual content dependencies and unlock conditions.

**Impact**: May refactor component registration and timeline event handling. Archive system likely remains similar.

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Expansion definitions
- `/Users/ilja/Documents/GitHub/kdm/Archive.ttslua` — Archive registration and card spawning
- `/Users/ilja/Documents/GitHub/kdm/Campaign.ttslua` — Component assembly and deck construction
- `/Users/ilja/Documents/GitHub/kdm/Gear.ttslua` — Gear stats lookup and variant handling
- `/Users/ilja/Documents/GitHub/kdm/Weapon.ttslua` — Weapon stats lookup
- `/Users/ilja/Documents/GitHub/kdm/Armor.ttslua` — Armor stats lookup
- `/Users/ilja/Documents/GitHub/kdm/ARCHITECTURE.md` — System overview (section: "Expansion Content Organization")

## Quick Reference Checklist

When adding new expansion content:

- [ ] Card names match TTS save file exactly
- [ ] GUID registered in `guidNames`
- [ ] Archive entries use correct type strings
- [ ] Only canonical names (no `[variant]` suffixes) in stats
- [ ] Verify cards exist in TTS template before adding stats
- [ ] Test with `>debug Archive on` and `>interact <archive>`
- [ ] Use async callbacks for multi-card operations
- [ ] Promo content bundled into appropriate expansion
- [ ] Settlement location gear mapped correctly
- [ ] Terrain cards and tiles properly sized

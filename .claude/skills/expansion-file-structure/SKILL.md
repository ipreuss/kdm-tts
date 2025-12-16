---
name: expansion-file-structure
description: Creating and modifying KDM expansion files (Expansion/*.ttslua). Use when adding new expansion content, defining components, archiveEntries, guidNames, settlementLocationGear, or timelineEvents. Triggers on new expansion, expansion file, components, archiveEntries, guidNames.
---

# Expansion File Structure

## When to Use

Use when:
- Creating a new expansion file
- Adding content to existing expansion
- Defining components, archive entries, or GUID mappings
- Setting up settlement location gear mappings
- Adding timeline events

## Standard Expansion File Template

All expansion files follow this pattern in `Expansion/*.ttslua`:

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

    -- GUID mappings for TTS objects
    guidNames = { ["abc123"] = "Archive Name" },

    -- Archive registration (two-level structure)
    archiveEntries = {
        archive = "Archive Container Name",
        entries = {
            { "Deck Name", "Type" },
        },
    },

    -- Monster definitions (see monster-definitions skill)
    monsters = { ... },

    -- Armor/weapon stats (see gear-stats skill)
    armorStats = { ... },
    weaponStats = { ... },
}
```

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

## Common Card Types (GMNotes)

| Type | Used For |
|------|----------|
| `"Gear"` | Equipment cards |
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
| `"AI"` | Monster AI decks |
| `"Hit Locations"` | Monster hit location decks |

## Settlement Location Gear

Maps location names to gear decks spawned when built:

```lua
settlementLocationGear = {
    ["Bone Smith"] = "Bone Smith Gear",  -- Single deck
    ["Giga-Catarium"] = { "Catarium Gear", "Giga-Catarium Gear" },  -- Multiple
}
```

## Promo Content Integration

**Principle**: Bundle promo content into the most appropriate major expansion.

- White Box items → Core expansion
- Promo survivors → Core expansion
- Expansion-specific promos → That expansion's file

**Why**: Avoids proliferation of tiny expansion files.

## Adding New Expansion Checklist

- [ ] Create `Expansion/YourExpansion.ttslua`
- [ ] Define `name` field
- [ ] Add `components` for each deck type
- [ ] Register GUID in `guidNames`
- [ ] Add `archiveEntries` pointing to guidNames entry
- [ ] Verify card names match TTS save file exactly
- [ ] Test with `>interact <archive-name>` in TTS

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Expansion definitions
- `/Users/ilja/Documents/GitHub/kdm/Campaign.ttslua` — Component assembly

# Expansion - Expansion Content Definitions

## Structure
Each expansion file defines:
- `monsters` - Monster definitions with hunt/showdown config
- `campaigns` - Campaign configurations
- `archiveEntries` - Card archive mappings
- `guidNames` - TTS object GUID mappings
- `settlementLocationGear` - Settlement location gear availability
- `timelineEvents` - Timeline event definitions
- `armorStats`, `weaponStats`, `gearStats` - Equipment stats

## Creating New Expansion
```lua
local Expansion = {
    name = "My Expansion",
    monsters = {
        ["Monster Name"] = {
            size = { x = 2, y = 2 },
            levels = { ... },
            hunt = { ... },
            showdown = { ... },
        }
    },
    archiveEntries = {
        ["Card Name"] = { archive = "Archive Name", entry = "Card Name" }
    },
}

return Expansion
```

## Monster Definition
See `monster-definitions` skill for detailed structure including:
- Hunt track configuration
- Showdown terrain and positions
- Resource rewards by level

## Gear Stats
See `gear-stats` skill for armor/weapon/gear stat patterns.

## Loading
Expansions are loaded by `Expansion.ttslua` orchestrator.
Enable/disable via Campaign setup dialog.

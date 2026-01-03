# Entity - Game Entities

## Modules
- `Monster.ttslua` - Monster state, stats, AI deck management
- `Survivor.ttslua` - Survivor sheets, lifetime stats, gear grid
- `Player.ttslua` - Player seat management, survivor box linking
- `HuntParty.ttslua` - Hunt party composition and selection

## Key Patterns

### Survivor Access
```lua
local survivor = Survivor.Get(survivorSheet)
survivor:SetStat("survival", 3)
local name = survivor.name
```

### Player-Survivor Link
```lua
local player = Player.Get(ordinal)  -- 1-4
local survivor = player.survivorSheet:Survivor()
```

### Monster State
```lua
Monster.SetLevel(monsterName, level)
local stats = Monster.GetStats()
```

## State Persistence
All entities implement `Init(saveState)` and `Save()` for persistence.
State is serialized via `Global.onSave()`.

## Dependencies
- Location (board positions)
- Archive (card spawning)
- EventManager (state change events)

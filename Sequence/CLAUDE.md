# Sequence - Game Flow Management

## Modules
- `Campaign.ttslua` - Campaign setup, import/export, expansion selection
- `Hunt.ttslua` - Hunt phase automation
- `Showdown.ttslua` - Showdown setup, terrain, monster placement
- `ShowdownAftermath.ttslua` - Post-showdown consequences
- `Settlement.ttslua` - Settlement phase, location management
- `Timeline.ttslua` - Year progression, milestone tracking
- `Strain.ttslua` - Strain milestone system

## Game Flow
```
Campaign Setup -> Settlement -> Hunt -> Showdown -> Aftermath -> Settlement...
                     ^                                              |
                     |______________________________________________|
```

## Key Patterns

### State Machines
Each sequence module manages its own state:
```lua
Hunt.Start(monsterName, level)
Hunt.GetPhase()  -- "setup", "hunting", "ambush", etc.
```

### Event Integration
```lua
EventManager.AddHandler("onShowdownStart", function(monster, level) ... end)
EventManager.AddHandler("onShowdownEnd", function(victory) ... end)
```

## State Persistence
Campaign, Timeline, Strain implement Save/Init for game state persistence.

## Dependencies
- Archive (spawning)
- Location (board management)
- Entity modules (Monster, Survivor, Player)
- Ui modules (dialogs, battle UI)

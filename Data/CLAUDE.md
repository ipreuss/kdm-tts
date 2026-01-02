# Data - Game Data & Manipulation

## Modules
- `Deck.ttslua` - Deck manipulation (shuffle, draw, adjust)
- `Terrain.ttslua` - Terrain card/tile definitions
- `ElementSizes.ttslua` - UI element size constants
- `ResourceRewards.ttslua` - Monster reward configuration
- `StrainRewardsConstants.ttslua` - Strain reward tables
- `ConsequenceApplicator.ttslua` - Milestone/event consequence application
- `Trash.ttslua` - Discard pile tracking

## Key Patterns

### Deck Operations
```lua
Deck.Shuffle("AI Deck")
Deck.DrawTo("Hunt Events", Location.Get("Hunt Event"))
Deck.Remove("AI Deck", "Claw")  -- remove specific card
```

### Resource Rewards
```lua
ResourceRewards.Spawn(monsterName, level, location)
```

### Consequence Application
```lua
ConsequenceApplicator.Apply({
    type = "disorder",
    target = survivorSheet
})
```

## Dependencies
- Archive (card spawning)
- Location (spawn positions)
- Expansion (reward definitions)

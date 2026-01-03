# Util - Low-Level Utilities

## Modules
- `Check.ttslua` - Assertion and validation helpers
- `Container.ttslua` - TTS deck/card container wrapper
- `array.ttslua` - Array utility functions
- `CircularArray.ttslua` - Circular buffer implementation
- `EventManager.ttslua` - Event pub/sub system
- `Grid.ttslua` - Grid positioning calculations
- `Names.ttslua` - Random name generation
- `ObjectState.ttslua` - TTS object state persistence
- `Overlay.ttslua` - Movement overlay visualization
- `Trie.ttslua` - Prefix tree for search/autocomplete
- `TTSSpawner.ttslua` - TTS object spawning wrapper
- `RulesNavButtonKit.ttslua` - Rulebook navigation UI components
- `Util.ttslua` - General utilities (formatting, arrays, highlighting)

## Key Patterns

### Check (Assertions)
```lua
Check.ObjectType(obj, "Card", "Expected card")
Check.Str(name, "name")
Check.Num(value, "value")
```

### Container (Deck/Card Wrapper)
```lua
local container = Container.Create(deckOrCard)
container:Take({ position = pos, callback = function(card) ... end })
```

### EventManager
```lua
EventManager.AddHandler("onObjectPickUp", function(player, obj) ... end)
EventManager.FireEvent("customEvent", arg1, arg2)
```

## Design Principles
- No game domain knowledge
- Pure infrastructure/helpers
- Minimal dependencies between utils

---
name: monster-definitions
description: Defining KDM monsters for Hunt and Showdown setup including size, levels, terrain, hunt track, and player positions. Use when adding new monsters, modifying showdown setup, working with terrain cards/tiles, or configuring hunt track markers. Triggers on monster definition, showdown setup, hunt track, terrain, monster level, player positions.
---

# Monster Definitions

## When to Use

Use when:
- Adding a new monster to an expansion
- Configuring showdown board setup
- Setting up hunt track markers
- Defining terrain placement
- Configuring monster levels and AI

## Monster Definition Structure

```lua
monsters = {
    {
        name = "Monster Name",
        size = { x = 3, y = 3 },  -- Board grid size
        rules = { "Rulebook Name", 5 },  -- [book, page state]
        huntTrack = { "M", "M", "H", "H", "M", "O", "H" },  -- Track markers
        position = "(12, 9)",  -- Monster grid coordinates
        playerPositions = { "(11, 16)", "(12, 16)", "(13, 16)", "(14, 16)" },

        fixedTerrain = { ... },
        randomTerrain = 2,  -- Number of random terrain cards

        levels = { ... },
    },
}
```

## Hunt Track Markers

```lua
huntTrack = { "M", "M", "H", "H", "M", "O", "H" }
```

| Marker | Meaning |
|--------|---------|
| `"M"` | Monster event |
| `"H"` | Hunt event |
| `"O"` | Overwhelming darkness |

## Position Format

Grid positions use string format: `"(x, y)"`

```lua
position = "(12, 9)"  -- Monster at grid 12, 9
playerPositions = { "(11, 16)", "(12, 16)", "(13, 16)", "(14, 16)" }
```

## Terrain System

### Fixed Terrain

Specific terrain placed at defined positions:

```lua
fixedTerrain = {
    {
        terrain = "2 Tall Grass",  -- Terrain card name
        positions = { "(9.5, 6.5)", "(14.5, 6.5)" },
        rotations = { { x = 0, y = 180, z = 0 }, { x = 0, y = 0, z = 0 } },
    },
},
```

### Random Terrain

Number of random terrain cards to draw:

```lua
randomTerrain = 2,
```

### Terrain Cards vs Tiles

**Terrain cards** (define what to spawn):
```lua
terrain = {
    ["2 Tall Grass"] = { terrainTile = "Tall Grass", count = 2 },
}
```

**Terrain tiles** (physical board pieces):
```lua
terrainTileSizes = {
    ["Tall Grass"] = { x = 2, y = 2 },  -- Grid squares
}
```

### Special Terrain (with attached objects)

```lua
terrain = {
    ["Egg Sacs"] = {
        terrainTile = "Egg Sac",
        count = "*",  -- Variable quantity
        miscObject = { name = "Spiderling", type = "Minion Figurine" },
    },
}
```

## Monster Levels

```lua
levels = {
    {
        name = "Level 1",
        level = 1,
        monsterHuntPosition = 4,  -- Position on hunt track
        showdown = {
            basic = 8,      -- Basic AI cards
            advanced = 2,   -- Advanced AI cards
            legendary = 0,  -- Legendary AI cards
            movement = 6,
            toughness = 8,
            speed = 0,      -- Speed modifier
            damage = 0,     -- Damage modifier
            accuracy = 0,   -- Accuracy modifier
            luck = 0,       -- Luck modifier
            resources = { basic = 4, monster = 4 },
        },
    },
    {
        name = "Level 2",
        level = 2,
        monsterHuntPosition = 8,
        showdown = {
            basic = 10,
            advanced = 6,
            movement = 7,
            toughness = 11,
            resources = { basic = 4, monster = 5 },
        },
    },
}
```

## Rulebook Reference

```lua
rules = { "Core Rules", 71 }  -- [rulebook name, page state]
```

Page state corresponds to the multi-state object in TTS. See `rulebook-verification` skill for looking up actual page content.

## Complete Example

```lua
{
    name = "White Lion",
    size = { x = 2, y = 2 },
    rules = { "Core Rules", 47 },
    huntTrack = { "M", "H", "H", "M", "H", "O", "H" },
    position = "(12, 9)",
    playerPositions = { "(11, 16)", "(12, 16)", "(13, 16)", "(14, 16)" },

    fixedTerrain = {
        {
            terrain = "2 Tall Grass",
            positions = { "(9.5, 6.5)", "(14.5, 6.5)" },
            rotations = { { x = 0, y = 180, z = 0 }, { x = 0, y = 0, z = 0 } },
        },
    },
    randomTerrain = 2,

    levels = {
        {
            name = "Level 1",
            level = 1,
            monsterHuntPosition = 4,
            showdown = {
                basic = 7,
                advanced = 2,
                movement = 6,
                toughness = 8,
                resources = { basic = 4, monster = 4 },
            },
        },
    },
}
```

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Monster definitions
- `/Users/ilja/Documents/GitHub/kdm/Showdown.ttslua` — Showdown setup logic
- `/Users/ilja/Documents/GitHub/kdm/Hunt.ttslua` — Hunt track setup
- `/Users/ilja/Documents/GitHub/kdm/Terrain.ttslua` — Terrain placement

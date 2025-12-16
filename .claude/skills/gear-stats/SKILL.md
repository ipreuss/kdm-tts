---
name: gear-stats
description: Adding armor, weapon, and gear stats to KDM expansion files for BattleUi display. Use when defining armorStats, weaponStats, gearStats, or handling card name variants with [bracket] suffixes. Triggers on armorStats, weaponStats, gearStats, BattleUi, paired weapon, variant, canonical name.
---

# Gear Stats

## When to Use

Use when:
- Adding armor stats to expansion
- Adding weapon stats to expansion
- Working with combined gear (shields, etc.)
- Understanding variant handling (`[left]`, `[right]` suffixes)
- Troubleshooting BattleUi stat display

## Armor Stats

```lua
armorStats = {
    ["Armor Name"] = { head = 2, arms = 2, body = 2, waist = 2, legs = 2 },
    -- Set bonus: modifier = true (adds to existing armor, doesn't replace)
    ["Lantern Helm"] = { head = 1, modifier = true },
}
```

**Fields:**
- `head`, `arms`, `body`, `waist`, `legs` — Armor values (integers)
- `modifier = true` — Adds to base armor instead of replacing

## Weapon Stats

```lua
weaponStats = {
    ["Weapon Name"] = { speed = 2, accuracy = 7, strength = 3 },
}
```

**Special properties:**
- `paired = true` — Weapon counts as paired (bonus when two equipped)
- `deadly = 1` — Deadly X value
- `slow = true` — Slow weapon
- `sharp = true` — Sharp weapon

**Example with properties:**
```lua
["Bone Dagger"] = { speed = 3, accuracy = 7, strength = 1, paired = true },
["Butcher Cleaver"] = { speed = 2, accuracy = 5, strength = 5, deadly = 1, slow = true },
```

## Combined Gear (gearStats)

For items that are both armor AND weapon (shields, etc.):

```lua
gearStats = {
    ["Round Leather Shield"] = {
        isArmor = true, head = 0, arms = 1, body = 1, waist = 0, legs = 0,
        isWeapon = true, speed = 1, accuracy = 8, strength = 1,
    },
}
```

**Special flags:**
- `cursed = true` — Cannot be removed
- `irreplaceable = true` — Cannot be replaced

## Variant Handling (CRITICAL)

Physical cards often have suffixes for art variants:
- `"Bone Hatchet [left]"` — actual TTS card name
- `"Bone Hatchet [right]"` — actual TTS card name
- `"Bone Hatchet"` — canonical name in expansion data

**System behavior:**
1. Expansion data defines stats once: `["Bone Hatchet"] = { speed = 2, ... }`
2. `Gear.cannonicalFor()` strips `[bracket]` suffixes
3. `Gear.getByName()` inherits stats from canonical entry
4. BattleUi counts by canonical name for paired weapon bonuses

**Rule**: Only define the canonical name (without suffix) in expansion stats.

**Wrong:**
```lua
weaponStats = {
    ["Bone Hatchet [left]"] = { speed = 2, accuracy = 7, strength = 2 },
    ["Bone Hatchet [right]"] = { speed = 2, accuracy = 7, strength = 2 },  -- Duplicate!
}
```

**Correct:**
```lua
weaponStats = {
    ["Bone Hatchet"] = { speed = 2, accuracy = 7, strength = 2 },  -- Both variants inherit
}
```

## Before Adding Stats

**Always verify the card exists in TTS:**

1. Open TTS or use `>interact <archive-name>`
2. Check exact card names (including any `[variant]` suffixes)
3. Only add stats for cards that physically exist

**Why**: Prevents configuration drift and misleading stat entries.

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Stat definitions
- `/Users/ilja/Documents/GitHub/kdm/Gear.ttslua` — Gear lookup and variant handling
- `/Users/ilja/Documents/GitHub/kdm/Weapon.ttslua` — Weapon stats lookup
- `/Users/ilja/Documents/GitHub/kdm/Armor.ttslua` — Armor stats lookup

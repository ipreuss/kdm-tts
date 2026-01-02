# Equipment - Gear System

## Modules
- `Armor.ttslua` - Armor card stat registration
- `Weapon.ttslua` - Weapon card stat registration
- `Gear.ttslua` - General gear card registration

## Key Patterns

### Stat Registration
Equipment modules register card stats from Expansion data:
```lua
Armor.Register(cardName, { head = 1, body = 2, ... })
Weapon.Register(cardName, { speed = 2, accuracy = 6, strength = 3 })
```

### BattleUi Integration
Stats registered here are displayed in BattleUi during showdown.
Card name variants (e.g., "[Paired]" suffix) are handled automatically.

## Expansion Integration
Stats defined in `Expansion/<name>.ttslua` under:
- `armorStats = {}`
- `weaponStats = {}`
- `gearStats = {}`

## Dependencies
- Expansion (stat definitions)
- BattleUi (stat display)

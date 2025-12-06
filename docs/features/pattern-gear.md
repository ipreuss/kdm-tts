# Pattern Gear

**Status:** ✅ Complete (13 acceptance tests)
**Last Updated:** 2025-12-06

## Overview

Pattern Gear is a crafting system from the Gambler's Chest expansion. Patterns are recipe cards that allow players to craft unique gear items. There are two types of patterns:

- **Seed Patterns** — Drawn randomly when a survivor reaches Understanding 3. The deck is shuffled so players cannot choose which pattern they receive.
- **Patterns** — Acquired when specific game events instruct the player to gain a named pattern. The deck is not shuffled, allowing players to search for the specific card.

Each pattern type has a corresponding gear deck containing the craftable items.

## User Stories

1. **As a player**, when my survivor reaches Understanding 3, I want to draw a random Seed Pattern so I can learn a unique crafting recipe.
2. **As a player**, when an event instructs me to gain a specific pattern, I want to search the Patterns deck for that card so I can add it to my settlement.
3. **As a player**, I want to store pattern cards in my settlement storage so they persist across lantern years.
4. **As a player**, when I have the required resources, I want to craft gear from my patterns using the Pattern Gear decks.
5. **As a player**, when I export my campaign, I want my patterns and crafted pattern gear to be saved.
6. **As a player**, when I import a campaign, I want my patterns and crafted pattern gear to be restored to their locations.

## Behavior

### Gaining Seed Patterns (Random)

1. Survivor reaches Understanding 3
2. Player draws from the top of the Seed Patterns deck (shuffled)
3. Player places the Seed Pattern card in settlement storage
4. Pattern card shows crafting requirements and the gear it produces

### Gaining Patterns (Directed)

1. An event instructs the player to gain a specific pattern (e.g., "Gain the Lantern Halberd pattern")
2. Player searches the Patterns deck (not shuffled) for the named card
3. Player places the Pattern card in settlement storage

### Crafting Pattern Gear

1. Player checks a pattern card for crafting requirements
2. If requirements are met, player takes the corresponding gear from:
   - **Seed Pattern Gear deck** — for items from Seed Patterns
   - **Pattern Gear deck** — for items from Patterns
3. Crafted gear is handled by the existing gear system (equip to survivors, store in settlement)

### Storing Patterns and Gear

- Pattern cards are stored in settlement resource storage (same snapping points as resources)
- Crafted pattern gear is stored in settlement gear storage (same as other gear)
- Equipped pattern gear uses survivor gear grids (same as other gear)

### Campaign Export/Import

On export:
- Pattern cards in settlement storage are saved with their location
- Crafted pattern gear in settlement gear storage is saved
- Equipped pattern gear on survivors is saved

On import:
- All four pattern decks are created from expansion data
- Seed Patterns deck is shuffled
- Patterns, Seed Pattern Gear, and Pattern Gear decks are not shuffled
- Saved pattern cards and gear are restored to their original locations

## Deck Locations

| Deck | Board | Position | Notes |
|------|-------|----------|-------|
| Seed Patterns | Showdown Board | Deck Grid Row 0, Col 0 | Shuffled on campaign start |
| Patterns | Showdown Board | Deck Grid Row 0, Col 1 | Not shuffled (searchable) |
| Seed Pattern Gear | Settlement Board | Below main area | Not shuffled |
| Pattern Gear | Settlement Board | Below Seed Pattern Gear | Not shuffled |

See `docs/DECK_LAYOUT.md` for coordinate reference.

## Shuffle Behavior

| Deck | Shuffled? | Reason |
|------|-----------|--------|
| Seed Patterns | ✅ Yes | Random draw at Understanding 3 |
| Patterns | ❌ No | Players search for specific cards |
| Seed Pattern Gear | ❌ No | Players search for crafted gear |
| Pattern Gear | ❌ No | Players search for crafted gear |

## Acceptance Criteria

### Deck Creation
- [x] New campaign creates Seed Patterns deck
- [x] New campaign creates Patterns deck
- [x] New campaign creates Seed Pattern Gear deck
- [x] New campaign creates Pattern Gear deck

### Shuffle Behavior
- [x] Seed Patterns deck is shuffled during import
- [x] Patterns deck is NOT shuffled during import
- [x] Seed Pattern Gear deck is NOT shuffled during import
- [x] Pattern Gear deck is NOT shuffled during import

### Export/Import - Settlement Storage
- [x] Pattern card in settlement storage is restored on import
- [x] Patterns card in settlement storage is restored on import
- [x] Pattern gear in settlement gear storage is restored on import

### Export/Import - Survivor Grids
- [x] Equipped pattern gear on survivor is restored on import
- [x] Multiple pattern cards across locations are restored on import

## Technical Notes

For implementation details, see:
- `Campaign.ttslua` — Deck creation via `SetupDeckFromExpansionComponents()`
- `Deck.ttslua` — Deck spawning and shuffle logic
- `LocationData.ttslua` — Deck positions for all four pattern decks
- `Expansion/Core.ttslua` — Pattern deck archive mappings
- `Archive.ttslua` — Card spawning for import/export
- `tests/acceptance/pattern_gear_acceptance_test.lua` — 13 acceptance tests
- `TTSTests/PatternTests.ttslua` — TTS console tests for shuffle verification

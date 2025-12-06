# Settlement

**Status:** 📄 Outline
**Last Updated:** 2025-12-06

## Overview

Settlement features handle settlement locations, gear crafting, resource management, and settlement-phase endeavors.

## User Stories

*To be documented*

## Behavior

### Settlement Locations
*To be documented*

### Gear Crafting
*To be documented*

### Resource Management
*To be documented*

### Pattern Gear System

Patterns are recipe cards gained through specific game events (e.g., "Gain the Lantern Halberd pattern"). Unlike Seed Patterns which are drawn randomly at Understanding 3, Patterns are acquired when an event explicitly instructs the player to gain a specific pattern.

**User workflow:**
1. An event instructs the player to gain a specific pattern (e.g., "Gain the Lantern Halberd pattern")
2. Player searches the Patterns deck (not shuffled) for the named card
3. Player places the Pattern card in settlement storage (manual placement)
4. When crafting, player manually takes the gear from the Pattern Gear deck
5. Crafted gear is handled by the existing gear system

**Key characteristics:**
- **Patterns deck:** Not shuffled (searchable for specific cards)
- **Pattern Gear deck:** Contains craftable gear from patterns
- **Storage:** Pattern cards are placed in settlement storage manually (board area with snapping points)
- **Crafting:** Manual process — player takes gear from Pattern Gear deck
- **Export/Import:** Pattern cards in storage are included in campaign export/import

**Deck locations:**
- Patterns deck: Settlement Board top row, position 8 (east of Seed Patterns)
- Pattern Gear deck: Settlement Board second row, position 1

See `docs/DECK_LAYOUT.md` for full deck position reference.

## UI Elements

*To be documented*

## Acceptance Criteria

*To be documented*

## Technical Notes

For implementation details, see:
- `Settlement.ttslua`
- `Location.ttslua`
- `Gear.ttslua`

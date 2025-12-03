# Trash System

**Status:** ✅ Complete  
**Last Updated:** 2025-12-03

## Overview

The Trash system provides a way to permanently remove cards from game decks without requiring players to interact directly with the Archive system. Cards placed in the Trash container are excluded when decks are rebuilt from their archives.

## User Stories

1. **As a player**, I want to remove cards from decks permanently (e.g., when a game effect says "archive this card") without dealing with complex archive management.
2. **As a player**, I want trashed cards to stay removed even after deck resets or game reloads.
3. **As a player**, I want trashed cards to persist when I export and import a campaign.
4. **As a player**, I want trashed cards to be restored if I start a new campaign.

## Behavior

### Manual Card Removal

1. Player drags a card from a deck (e.g., Settlement Events)
2. Player drops the card into the Trash container
3. Card remains in Trash
4. When the deck is next rebuilt from its archive, the trashed card is excluded

### Automatic Card Removal (via Strain Milestones)

Some strain milestones trigger automatic card removal:
1. Milestone consequence specifies a card to trash (e.g., "Heat Wave")
2. Mod moves the card from its deck to the Trash container
3. Mod triggers deck rebuild to apply the change immediately

### Deck Rebuild Behavior

When `Deck.AdjustToTrash()` is called:
1. Checks Trash container for cards matching the deck type
2. Removes matching cards from the deck being built
3. Cards remain in Trash (not consumed)

### Save/Load/Export/Import

- Trash contents are saved with the campaign via `Trash.Export()`
- On load, `Trash.Import()` recreates trashed cards in the container
- **Export/Import preserves Trash** — trashed cards remain trashed in the imported campaign
- Starting a **new** campaign clears the Trash

## Supported Deck Types

Any deck that uses `Deck.AdjustToTrash()` respects the Trash system:

| Deck | Card Type (gm_notes) | Example Usage |
|------|---------------------|---------------|
| Settlement Events | `"Settlement Events"` | Archive Heat Wave (Atmospheric Change milestone) |
| Hunt Events | `"Hunt Events"` | Various hunt event removal effects |
| Monster Hunt Events | `"Monster Hunt Events"` | Monster-specific event removal |

## API

### Trash.IsInTrash(name, type)

Check if a card is in the Trash.

```lua
if Trash.IsInTrash("Heat Wave", "Settlement Events") then
    -- Card is trashed
end
```

### Trash.Export()

Returns Trash contents for campaign save.

```lua
local trashData = Trash.Export()
-- Returns: { { name = "Heat Wave", type = "Settlement Events" }, ... }
```

### Trash.Import(content)

Restores Trash contents from campaign save.

```lua
Trash.Import(savedTrashData)
```

### Trash.AddCard(cardName, cardType) — *Planned*

Programmatically move a card to Trash.

```lua
Trash.AddCard("Heat Wave", "Settlement Events")
```

### Trash.RemoveCard(cardName, cardType) — *Planned*

Programmatically remove a card from Trash (to restore it).

```lua
Trash.RemoveCard("Heat Wave", "Settlement Events")
```

## Integration Points

### Deck.AdjustToTrash(deck, cardNames, archives, type)

Called during deck setup to exclude trashed cards:

```lua
Deck.AdjustToTrash(settlementEventsDeck, cardNames, { "Future Settlement Events" }, "Settlement Events")
```

### Campaign.SetupSettlementEventsDeck(cardNames)

Rebuilds Settlement Events deck, respecting Trash:

```lua
Campaign.SetupSettlementEventsDeck(nil)  -- nil = use current deck contents
```

## Technical Notes

**Key Files:**
- `Trash.ttslua` — Core Trash module
- `Deck.ttslua` — `Deck.AdjustToTrash()` function
- `Campaign.ttslua` — Campaign save/load integration
- `Hunt.ttslua` — Hunt event deck integration

**Named Object:**
- Trash container GUID registered in `NamedObject.ttslua` as `"Trash"`

**Architecture:**
- See `ARCHITECTURE.md` section "Trash System for Card Removal"

## Acceptance Criteria

- [ ] Cards dropped in Trash container stay there
- [ ] Trashed cards excluded when deck rebuilt from archive
- [ ] Trash contents persist across save/load
- [ ] Trash contents persist across export/import
- [ ] Starting new campaign clears Trash
- [ ] Trash.IsInTrash correctly identifies trashed cards

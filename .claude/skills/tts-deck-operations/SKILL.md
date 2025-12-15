---
name: tts-deck-operations
description: Working with TTS decks and cards - extraction, collapse behavior, merging, and putObject patterns. Use when working with decks, takeObject, card extraction, card merging, deck collapse, or putObject. Triggers on deck, takeObject, card extraction, getQuantity, card merge, putObject, deck collapse.
---

# TTS Deck Operations

Patterns and gotchas when working with TTS deck and card objects.

## Deck Extraction Order

**Problem:** Extracting cards from the bottom of a deck causes the deck object to physically shift/fall.

**Solution:** Always extract from the top (highest index) first:

```lua
-- CORRECT: Extract top cards first (highest index)
for i = deck.getQuantity(), 1, -1 do
    local card = deck.takeObject({
        position = targetPosition,
        index = i - 1,  -- 0-indexed
    })
end

-- WRONG: Extracting bottom cards first causes deck to shift
for i = 1, deck.getQuantity() do
    deck.takeObject({ index = 0 })  -- Deck physically moves!
end
```

**Also:** Process deck objects BEFORE individual cards at a location. If you move a card that's underneath a deck, the deck shifts unexpectedly.

## Deck Collapse Behavior (2→1 Cards)

**Problem:** When a TTS Deck has 2 cards and you call `takeObject()`, the remaining single card causes the Deck to "collapse" into a Card object.

**Symptoms:**
- Loop iteration fails after first extraction from 2-card deck
- `deck.getQuantity()` throws error (Card doesn't have this method)
- Code expecting `tag == "Deck"` breaks

**Solution:** Check `obj.tag` before each extraction and handle the collapsed card directly:

```lua
local function extractAllCards(deckOrCard, targetPosition)
    local cards = {}

    while deckOrCard do
        if deckOrCard.tag == "Deck" then
            -- Still a deck, extract one card
            local card = deckOrCard.takeObject({ position = targetPosition })
            table.insert(cards, card)

            -- After extraction, check if deck collapsed
            if deckOrCard.getQuantity and deckOrCard.getQuantity() == 0 then
                -- Deck destroyed itself after last card
                deckOrCard = nil
            end
        elseif deckOrCard.tag == "Card" then
            -- Deck collapsed to single card, move it directly
            deckOrCard.setPosition(targetPosition)
            table.insert(cards, deckOrCard)
            deckOrCard = nil
        else
            break  -- Unknown object type
        end
    end

    return cards
end
```

**Key insight:** The object reference stays valid but `obj.tag` changes from `"Deck"` to `"Card"`.

## TTS Card Merging Behavior

**Problem:** TTS automatically merges cards of the same type (same `GMNotes`) into a Deck object when placed at identical positions.

**Symptoms:**
- Code checking only `obj.tag == "Card"` misses stacked cards
- Card count appears lower than expected
- Two cards placed at same spot become one deck

**Key distinctions:**
- Cards with **same GMNotes** → merge into Deck when stacked
- Cards with **different GMNotes** (e.g., Monster Hunt Event + Special Hunt Event) → remain separate

**Solution:** Always handle both Card and Deck objects:

```lua
local function countCardsAtLocation(location)
    local count = 0
    for _, obj in ipairs(location:AllObjects()) do
        if obj.tag == "Card" then
            count = count + 1
        elseif obj.tag == "Deck" then
            count = count + obj.getQuantity()
        end
    end
    return count
end
```

## putObject() Copies, Not Moves

**Problem:** TTS's `deck.putObject(card)` does NOT move the card into the deck — it **copies** the card data into the deck, leaving the original card object in place.

**Symptoms:**
- "Stray" cards appearing at staging positions after deck operations
- Cards falling through the table (y coordinate going negative)
- Duplicate cards accumulating over multiple test runs

**Solution:** Always destroy the original card after `putObject()`:
```lua
targetDeck.putObject(card)
card.destruct()  -- Destroy the original - putObject copied it
```

## CardCustom Type Issues

**Problem:** When putting a `CardCustom` type object (single custom card, not part of a deck) into a deck, TTS may show the "CUSTOM CARD" import dialog with empty URL fields.

**Symptoms:**
- Empty "CUSTOM CARD" dialog appearing during card transfers
- Dialog shows empty Face/Back URL fields
- Tests pass but dialog is visually distracting

**Cause:** `CardCustom` objects have different internal handling than cards that were originally part of decks.

**Investigation approach:** Check card's type via `object.type` — cards from decks are typically `Card`, standalone custom cards are `CardCustom`.

## Deck Lifecycle Pattern

Many card decks follow a three-stage lifecycle:

1. **Construction** — Cards collected from enabled expansion archives and combined into a single deck
2. **Archive Storage** — Constructed deck stored in a dedicated archive container which acts as the canonical source
3. **Board Spawn** — Deck spawned from archive to its board location for player use

**Reset Flow:** Players can reset a deck at any time via `Deck.ResetDeck()`, which:
- Clears the current board deck
- Spawns a fresh copy from the archive
- Shuffles if needed

**Implication for runtime modifications:** Any permanent changes to deck contents must modify the deck **inside the archive**, not just the board copy. Otherwise changes are lost on reset.

**Pattern:**
1. Take the deck from the archive
2. Add/remove cards
3. Put the modified deck back in the archive
4. Optionally spawn a fresh copy to the board

## Deck Formation at Same Position

**Problem:** Spawning multiple cards at same location creates a deck; can't `destruct()` individual cards

**Solution:** Either spawn at different positions, or destroy first card before spawning second

**Debug tip:** If cleanup fails silently, check if objects have auto-grouped into a deck

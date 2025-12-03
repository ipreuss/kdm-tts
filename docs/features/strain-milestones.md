# Strain Milestones

**Status:** ✅ Complete (13 milestones), 🚧 In Progress (14th milestone)  
**Last Updated:** 2025-12-03

## Overview

Strain milestones are permanent achievements that unlock rewards persisting across campaigns. When a player meets a milestone's condition during gameplay, they can mark it as reached, triggering automated reward distribution. These rewards carry forward to future campaigns.

## User Stories

1. **As a player**, I want to track which strain milestones I've unlocked so I can see my long-term progress.
2. **As a player**, when I reach a milestone condition, I want the mod to automatically add the reward to the appropriate deck so I don't forget.
3. **As a player**, I want to receive a copy of the fighting art for the triggering survivor so I can immediately use it.
4. **As a player**, when starting a new campaign, I want my previously unlocked rewards to be added automatically.
5. **As a player**, I want to be able to undo a mistakenly checked milestone and have the rewards removed.
6. **As a player**, I want to see what manual steps I need to take (stat penalties, disorders, etc.) clearly displayed.

## Behavior

### Viewing Milestones

1. Open the strain milestones panel via the global UI
2. Panel displays all 13 strain milestones with:
   - Checkbox indicating reached/unreached
   - Title
   - Condition text describing how to unlock

### Reaching a Milestone

1. Player checks an unreached milestone checkbox
2. **Confirmation dialog** appears showing:
   - Milestone title
   - Flavor text (story)
   - Rules text (game effects)
   - Manual steps required (in red, if any)
   - "Confirm Milestone" and "Cancel" buttons
3. On confirm:
   - Milestone marked as reached
   - **Automated rewards execute** (see Consequence Types)
   - Log message confirms actions taken
4. On cancel:
   - Milestone remains unreached
   - No changes made

### Unchecking a Milestone (Undo)

1. Player unchecks a reached milestone checkbox
2. **Undo confirmation dialog** appears showing:
   - Milestone title
   - Warning that rewards will be removed
   - Which fighting art will be removed from the deck
   - "Remove Rewards" and "Keep Rewards" buttons
3. On confirm:
   - Milestone marked as unreached
   - **Automated rewards reversed** (cards removed from decks)
   - Log message tells player to manually remove card from survivor
4. On cancel:
   - Milestone remains reached
   - No changes made

### New Campaign Setup

1. When creating/importing a new campaign:
   - Mod checks which milestones are marked as reached
   - Collects fighting arts from reached milestones
   - **If more than 5 fighting arts unlocked**: randomly selects 5
   - Spawns selected fighting arts to the Fighting Arts deck
   - Spawns vermin cards to the Vermin deck
2. Option: "Clear strain milestones" checkbox resets all milestones for fresh start

## Consequence Types

| Type | Automation | Example |
|------|------------|---------|
| Add fighting art to deck | ✅ Automated | "Ethereal Pact" added to Fighting Arts deck |
| Spawn copy for survivor | ✅ Automated | Card spawns south of showdown board; player assigns to survivor |
| Add vermin to deck | ✅ Automated | "Fiddler Crab Spider" added to Vermin deck |
| Add timeline event | ✅ Automated | "Acid Storm" scheduled on next lantern year |
| Trash settlement event | ✅ Automated | "Heat Wave" moved to Trash, removed from deck |
| Add basic resource | ✅ Automated | "Lump of Atnas" added to Basic Resources deck |
| Survivor gains disorder | 📋 Manual | Reminder shown; player adds disorder card |
| Survivor gains proficiency | 📋 Manual | Reminder shown; player updates survivor sheet |
| Survivor suffers injury | 📋 Manual | Reminder shown; player applies injury |
| Survivor stat penalty | 📋 Manual | Reminder shown; player updates stats |
| Add strange resource | 📋 Manual | Reminder shown; player adds to storage |

### Trash System for Card Removal

Some milestones require removing cards from regular game decks (e.g., archiving "Heat Wave" from Settlement Events). This uses the **Trash system** — see `docs/features/trash.md` for full documentation.

**Summary:** Cards are moved to the Trash container; when decks rebuild from archives, trashed cards are excluded. Undo removes from Trash and triggers rebuild to restore.

## UI Elements

### Strain Milestones Panel
- **Location:** Global UI, accessible via menu
- **Size:** 540x540 pixels, scrollable
- **Contents:** List of milestone rows with checkbox, title, condition

### Confirmation Dialog
- **Trigger:** Checking an unreached milestone
- **Size:** 650px wide, height adapts to content
- **Sections:** Title, Story (italic), Game Effect, Manual Steps (red), Buttons

### Undo Dialog
- **Trigger:** Unchecking a reached milestone
- **Size:** 540px wide
- **Modal:** Yes (blocks other interaction)
- **Contents:** Warning message, fighting art name, confirmation buttons

## Card Source

**Strain Rewards archive** (in Core) contains cards that are *added* to decks:
- All 13 strain fighting arts
- Fiddler Crab Spider (vermin)
- Lump of Atnas (basic resource)

**Regular game decks** — some milestones remove cards from these using the Trash system:
- Settlement Events deck (e.g., "Heat Wave")

## Milestones Reference

| # | Title | Fighting Art | Other Rewards |
|---|-------|--------------|---------------|
| 1 | Ethereal Culture Strain | Ethereal Pact | — |
| 2 | Giant's Strain | Giant's Blood | — |
| 3 | Opportunist Strain | Backstabber | -1 STR, -1 EVA (manual) |
| 4 | Trepanning Strain | Infinite Lives | — |
| 5 | Hyper Cerebellum | Shielderang | 3 Shield proficiency, Weak Spot disorder (manual) |
| 6 | Marrow Transformation | Rolling Gait | — |
| 7 | Memetic Symphony | Infernal Rhythm | — |
| 8 | Surgical Sight | Convalescer | Blind injury (manual) |
| 9 | Ashen Claw Strain | Armored Fist | Fiddler Crab Spider (vermin) |
| 10 | Carnage Worms | Dark Manifestation | — |
| 11 | Material Feedback Strain | Stockist | — |
| 12 | Sweat Stained Oath | Sword Oath | Acid Storm (timeline) |
| 13 | Plot Twist | Story of Blood | 1 Iron (manual) |
| 14 | Atmospheric Change | — | Archive Heat Wave (trash), Add Lump of Atnas (basic resource) |

## Acceptance Criteria

### Milestone Confirmation
- [ ] Checking unreached milestone shows confirmation dialog
- [ ] Dialog displays title, flavor text, rules text, manual steps
- [ ] Confirming adds fighting art to Fighting Arts deck
- [ ] Confirming spawns copy south of showdown board
- [ ] Log message instructs player to give card to survivor
- [ ] Canceling makes no changes

### Milestone Undo
- [ ] Unchecking reached milestone shows undo dialog
- [ ] Dialog is modal and shows which card will be removed
- [ ] Confirming removes fighting art from deck
- [ ] Log message instructs player to remove card from survivor
- [ ] Canceling makes no changes

### New Campaign
- [ ] Reached milestones have rewards added to decks automatically
- [ ] More than 5 fighting arts → only 5 randomly selected
- [ ] Vermin cards added to Vermin deck
- [ ] "Clear strain milestones" option resets all milestones

### Edge Cases
- [ ] Vermin reward (Ashen Claw) adds to Vermin deck on confirm
- [ ] Timeline event (Sweat Stained Oath) schedules Acid Storm
- [ ] Stateful cards (Story of Blood) resolve correctly
- [ ] Trash settlement event (Atmospheric Change) removes Heat Wave from deck
- [ ] Add basic resource (Atmospheric Change) adds Lump of Atnas to Basic Resources

## Technical Notes

For implementation details, see:
- `Strain.ttslua` — UI and consequence execution
- `GameData/StrainMilestones.ttslua` — Milestone definitions
- `FightingArtsArchive.ttslua` — Fighting arts deck add/remove operations
- `VerminArchive.ttslua` — Vermin deck add/remove operations
- `BasicResourcesArchive.ttslua` — Basic resources deck add/remove operations
- `Trash.ttslua` — Trash system for removing cards from regular decks
- `Campaign.ttslua` — `AddStrainRewards()` for new campaign setup
- `ARCHITECTURE.md` — Module relationships, Trash System documentation

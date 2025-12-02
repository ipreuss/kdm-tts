# Kingdom Death: Monster TTS Mod — Product Specification

This document defines *what* the mod does from a user perspective. It serves as the functional specification for the development team (Product Owner, Architect, Implementer, Reviewer).

For *how* the mod is built, see [ARCHITECTURE.md](../ARCHITECTURE.md).

## Purpose

This mod automates campaign management, survivor tracking, and encounter setup for Kingdom Death: Monster in Tabletop Simulator. It aims to reduce bookkeeping overhead while preserving the tactile experience of the physical game.

## Target Users

- KDM players who own the physical game and want a digital option for remote play
- Groups who want automated tracking without manual spreadsheets
- Solo players managing multiple survivors

## Feature Index

Each feature has its own specification document in `features/`:

| Feature | Status | Description |
|---------|--------|-------------|
| [Strain Milestones](features/strain-milestones.md) | ✅ Complete | Track and automate strain milestone rewards across campaigns |
| [Campaign Management](features/campaign.md) | 📄 Outline | Campaign setup, export/import, expansion selection |
| [Survivors](features/survivors.md) | 📄 Outline | Survivor sheets, survivor board, markers, notes |
| [Hunt Phase](features/hunt.md) | 📄 Outline | Hunt event automation, random events |
| [Showdown Phase](features/showdown.md) | 📄 Outline | Showdown setup, terrain spawning, monster stats |
| [Battle UI](features/battle-ui.md) | 📄 Outline | Weapon display, hit locations, turn tracking |
| [Timeline](features/timeline.md) | 📄 Outline | Timeline events, settlement phase, milestones |
| [Settlement](features/settlement.md) | 📄 Outline | Settlement locations, gear crafting, resources |

**Status legend:**
- ✅ Complete — Fully specified and implemented
- 🚧 Partial — Implemented but spec incomplete
- 📄 Outline — Spec placeholder, implementation exists
- 📋 Planned — Not yet implemented

## Cross-Cutting Concerns

### Console Commands

Users interact with the mod via in-game chat commands prefixed with `>`. Type `>help` to see available commands.

Key commands:
- `>search <term>` — Search rules, gear, events
- `>testall` — Run TTS acceptance tests (for verification)

### Persistence

- **Save/Load**: All mod state persists in the TTS save file automatically
- **Export/Import**: Campaigns can be exported to JSON and imported into fresh saves
- **Cross-campaign state**: Some features (e.g., strain milestones) persist across campaigns unless explicitly reset

### Expansion Support

The mod supports official KDM expansions. Expansions are enabled per-campaign during setup and affect:
- Available quarries and nemeses
- Gear, fighting arts, disorders
- Timeline events and settlement locations
- Monster AI and hit location decks

## Document Conventions

Each feature specification should include:

1. **Overview** — What the feature does, in plain language
2. **User Stories** — Key use cases from the player's perspective
3. **Behavior** — Detailed expected behavior, step by step
4. **UI Elements** — Dialogs, boards, buttons involved
5. **Acceptance Criteria** — Testable conditions for "done"
6. **Status** — Implementation state and known limitations

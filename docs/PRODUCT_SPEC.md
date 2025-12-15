# Kingdom Death: Monster TTS Mod — Product Specification

This document defines *what* the mod does from a user perspective. It serves as the functional specification for the development team (Product Owner, Architect, Implementer, Reviewer).

For *how* the mod is built, see [ARCHITECTURE.md](../ARCHITECTURE.md).

## Purpose

This mod automates campaign management, survivor tracking, and encounter setup for Kingdom Death: Monster in Tabletop Simulator. It aims to reduce bookkeeping overhead while preserving the tactile experience of the physical game.

## Target Users

- KDM players who own the physical game and want a digital option for remote play
- Groups who want automated tracking without manual spreadsheets
- Solo players managing multiple survivors

## Feature Documentation

**Primary documentation is executable acceptance tests** in `tests/acceptance/`. Tests serve as living documentation that cannot become stale.

### Acceptance Tests (Living Documentation)

| Feature | Test File | Description |
|---------|-----------|-------------|
| Strain Milestones | `strain_acceptance_test.lua` | Track and automate strain milestone rewards across campaigns |
| Pattern Gear | `pattern_gear_acceptance_test.lua` | Pattern and Seed Pattern crafting system from Gambler's Chest |
| Resource Rewards | `resource_rewards_acceptance_test.lua` | Post-showdown resource spawning (basic, monster, strange) |
| Weapon Pairing | `weapon_pairing_acceptance_test.lua` | Paired weapon mechanics including cross-name pairing |

### Static Documentation (Reference Only)

Detailed markdown specs exist for some features in `features/`. These are **reference only** — tests are the authoritative source for behavior.

| Feature | Status | Notes |
|---------|--------|-------|
| [Strain Milestones](features/strain-milestones.md) | ✅ Complete | Detailed reference |
| [Pattern Gear](features/pattern-gear.md) | ✅ Complete | Detailed reference |
| [Trash System](features/trash.md) | ✅ Complete | Card removal system |

Other `features/*.md` files are stubs and may be removed in future cleanup.

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

## Documentation Philosophy

**Executable tests over static documents.**

Acceptance tests are the authoritative source for feature behavior:
- They cannot become stale (tests fail if behavior changes)
- They use domain language readable by non-programmers
- They demonstrate exactly what the feature does

Static markdown docs are reserved for:
- **Reference tables** (milestone lists, consequence types)
- **Complex user workflows** that span multiple features
- **Historical context** when needed

# Kingdom Death: Monster TTS Mod — Architecture Overview

This document captures the current architecture, major systems, and design conventions of the Kingdom Death: Monster Tabletop Simulator mod. It is meant to be the first stop before making non-trivial changes: scan it to understand where a concern should live, what state it owns, and how it cooperates with the rest of the mod.

## Scope And Audience
- **Audience**: maintainers who already know Kingdom Death rules and Tabletop Simulator scripting basics.
- **Focus**: gameplay automation, UI systems, save/load contracts, and supporting tooling.
- **Out of scope**: art assets, card scans, and exhaustive API references.

## Runtime Snapshot
| Item | Details |
| --- | --- |
| Entry point | `Global.ttslua` compiled/bundled into the mod (`updateTTS.sh`). |
| Language | Lua 5.1 with Tabletop Simulator APIs. |
| Module layout | Files require via `require("Kdm/<Module>")` and are bundled with `luabundler`. |
| Persistence | `onSave` aggregates per-module `Save()` payloads into one JSON blob (`Global.ttslua:35-47`). |
| UI stack | Custom DSL in `Ui.ttslua` builds XML trees for 2D (global) and 3D (object) UI roots (`Ui.ttslua:31-188`). |
| Events | `EventManager` wraps TTS globals to provide pub/sub hooks plus synthetic events (`Util/EventManager.ttslua:7-70`). |
| Tooling | `updateTTS.sh` backs up the current save, bundles scripts, compresses them, and injects them into the save (`updateTTS.sh:1-57`). |

## Lifecycle At A Glance
`Global.onLoad` is the single boot script and is responsible for both dependency ordering and state hydration (`Global.ttslua:51-109`).

```
TTS onLoad
  └─ Console/Expansion/logging init
      └─ Core data providers (Gear, Armor, NamedObject, Terrain, Ui, Weapon)
          └─ Content registries (Archive, Location, Deck)
              └─ Gameplay subsystems (Hunt, Monster, Rules, Settlement, Survivor, Player, Showdown, BattleUi)
                  └─ UX overlays (GlobalUi, Timeline, Campaign, MilestoneBoard, MessageBox)
                      └─ PostInit phase (Wait.frames) wires event handlers
```

Key points:
- **Deterministic order matters**. For example, UI modules are instantiated before `MessageBox.Init()` so the overlay renders on top of other XML (`Global.ttslua:92-95`).
- **Two-phase initialization**. Any module that touches instantiated UI or waits for other systems registers its handlers inside `Wait.frames(..., 20)` (e.g., `BattleUi.PostInit`, `Player.PostInit`).
- **Save/Load symmetry**. Each subsystem exposes `Init(saveState)` and `Save()`; `Global.onSave` simply collects their outputs, letting modules own their JSON schema (`Global.ttslua:35-44`).

## UI Framework

The mod includes a custom UI framework built on top of TTS's XML UI system:

- **PanelKit**: Core dialog and panel creation utilities
- **LayoutManager**: Handles positioning and sizing of UI elements
- **ClassicDialog**: Standardized dialog chrome with KDM styling

### UI Color Palette

Standard colors are defined in `Ui.ttslua` and should be used consistently:

| Constant | Value | Usage |
|----------|-------|-------|
| `Ui.LIGHT_BROWN` | `#bbb4a1` | Text on dark backgrounds, button labels |
| `Ui.MID_BROWN` | `#7f7059` | Secondary backgrounds |
| `Ui.DARK_BROWN` | `#453824` | Primary button/panel backgrounds |
| `Ui.LIGHT_RED` | `#E96C6C` | Warning/error highlights |
| `Ui.DARK_RED` | `#831010` | Critical warnings |
| `Ui.LIGHT_GREEN` | `#90ee90` | Success/positive highlights |

### Standard UI Components

**ResetButton** (`Ui:ResetButton`) - Used for deck/gear reset buttons on boards:
```lua
ui:ResetButton({
    id = "MyButton",
    topLeft = { x = 1.0, y = 2.0 },
    bottomRight = { x = 1.5, y = 3.0 },
    onClick = function() ... end,
    text = "Reset",      -- optional, defaults to "Reset"
    fontSize = 120,      -- optional, defaults to 120
    rotation = "0 0 270" -- optional, for vertical text
})
```

Creates a Panel (DARK_BROWN) + Button (invisible click area) + Text (LIGHT_BROWN).

**Rotation Values** for 3D UI elements:
- `"0 0 180"` - Default (text reads normally when viewed from default camera)
- `"0 0 270"` - Rotated 90° counterclockwise (vertical text, reads bottom-to-top)

### Layout System Design

The UI framework uses a two-stage approach to handle TTS's constraint that dialog dimensions cannot be changed after creation:

#### Stage 1: Pre-calculation
```lua
-- Build a reusable specification and calculate required space
local spec = LayoutManager.Specification()
spec:AddTitle({ height = 35 })
spec:AddSection({ labelHeight = 30, contentHeight = 60 })
spec:AddButtonRow({ height = 45 })

local dialogHeight = spec:CalculateDialogHeight({
    padding = 15,
    spacing = 12,
})
```

#### Stage 2: Dialog Creation
```lua
-- Create dialog with pre-calculated size
local dialog = PanelKit.Dialog({ width = 650, height = dialogHeight })

-- Build layout with the same specification (and optional callbacks)
local layout = PanelKit.VerticalLayout({ parent = dialog })
spec:Render(layout)
```

#### Critical Measurements
- **TTS Overhead**: 195px additional space needed beyond content
  - Includes dialog chrome, internal margins, safe positioning
  - Measured empirically: content=355px + overhead=195px = total=550px
- **Element Heights**: Title=35px, Section=25px(label)+content, Button=45px, Spacing=configurable
- **Validation**: Use `layout:GetUsedHeight()` to verify calculations match reality

#### Implementation Lessons

**Fail Fast vs Defensive Programming**: The codebase uses fail-fast error handling rather than silent fallbacks. For example, missing function calls throw errors immediately rather than being caught with existence checks like `if Player and Player.getPlayers then`. This makes debugging easier by surfacing issues at their source.

**Type Safety in Calculations**: Layout calculations must use proper numeric types. If "attempt to perform arithmetic on table value" errors occur, this indicates a logic error where a table is being passed instead of a number. Such errors should be debugged and fixed at their source rather than masked with `tonumber()` conversions, which would obscure the root cause and likely produce incorrect results.

**Sequential Dependencies**: Pre-calculation must happen before any UI creation since TTS dialog dimensions are immutable. The LayoutManager.CalculateLayoutHeight() simulates the actual layout process to determine space requirements.

## Module Map
| Category | Modules | Responsibilities |
| --- | --- | --- |
| Infrastructure | `Util/*`, `Log`, `Console`, `EventManager`, `Ui` | Safety helpers, logging, chat console, event bus, UI builder. |
| Board & Assets | `NamedObject`, `Location`, `LocationData`, `Archive`, `Deck`, `Expansion` | Locate physical objects, describe board regions, index archive bags, spawn decks, enable expansions. |
| Domain: Campaign & Timeline | `Campaign`, `Timeline`, `Timeline/Hunt/Showdown ties` | Configure campaigns, enable expansions, drive settlement timeline UI, manage survival actions/milestones. |
| Domain: Survivors & Players | `Survivor`, `Player`, `BattleUi`, `MilestoneBoard`, `GlobalUi` | Survivor records, survivor boxes/sheets, player board linkage, battle HUD, quick navigation buttons. |
| Domain: Encounters | `Hunt`, `Showdown`, `Monster`, `Settlement`, `Terrain`, `Weapon`, `Gear`, `Armor` | Hunt flow, showdown setup, monster stats/decks, settlement locations, terrain and gear metadata. |
| UI Components | `Ui`, `GlobalUi`, `MessageBox`, `BattleUi`, `Rules`, `Bookmarks` | Low-level UI DSL plus composable panels and overlays. |
| Tooling | `updateTTS.sh`, `restoreBackup.sh`, `template_workshop.json` | Bundle scripts, push backups, generate workshop template. |

### Gear Variant Handling

Physical gear cards in TTS often have variant names (e.g., `"Bone Hatchet [left]"`, `"Bone Hatchet [right]"`) while expansion code defines canonical names (`"Bone Hatchet"`). The system handles this via:

1. **Canonical Name Resolution** (`Gear.cannonicalFor`): Strips bracket suffixes from card names. `"Bone Hatchet [left]"` becomes `"Bone Hatchet"`.
2. **Stats Inheritance** (`Gear.getByName`): When looking up a variant, the system finds the canonical name's stats and creates a virtual gear entry that inherits from it.
3. **Paired Weapon Bonus** (`BattleUi`): Counts weapons by canonical name. If 2+ weapons share the same canonical name and have `paired = true`, the speed bonus is applied.

This pattern allows expansion data to define stats once per weapon type while supporting multiple physical card variants in the TTS template.

### Settlement Event Search
- **Single source of truth**: The settlement event search trie is populated exclusively from the physical Settlement Events deck on the board. Expansion definitions no longer list settlement event names.
- **Why**: keeps the UI in lockstep with the actual cards present in a campaign (including custom/remixed decks) and avoids keeping large hardcoded arrays synchronized with assets.
- **Behavior**: if the deck is missing (or unreadable), settlement events simply disappear from search results until the deck is restored; other timeline events remain searchable.
- **Flow**: `Timeline.RefreshSettlementEventSearchFromDeck()` inspects the deck (via `Container(deck):Objects()`), filters to cards whose `gm_notes` equals `"Settlement Events"`, derives a sorted name list, and feeds it into `Timeline.RebuildSearchTrie()`.
- **Implications**: campaign import/export and deck setup must keep the Settlement Events deck accurate, because any edits (e.g., trashing cards) immediately affect the search UI.

## Infrastructure Highlights
- **EventManager** intercepts TTS global callbacks (e.g., `onObjectDrop`) and fans them out to registered handlers while preserving original return values (`Util/EventManager.ttslua:25-56`). Synthetic enumerations (like `ON_PLAYER_SURVIVOR_LINKED`) let modules broadcast high-level intents without relying on raw TTS callbacks.
- **Logging & debugging** use the module-scoped logger (`Log.ttslua:1-108`). Enabling debug output per module is done through the chat console (`>debug <module> on`).
- **Console commands** are prefixed with `>` in chat; `Console.Init` tokenizes the command, looks up handlers, and prevents the message from reaching other systems (`Console.ttslua:17-58`). This is used throughout for maintenance commands (e.g., `showloc`, `interact`).
- **UI DSL** constructs XML programmatically so UI definitions stay in Lua. Every UI object shares helper constructors such as `Panel`, `Text`, `Button`, `CheckButton`, etc., which handle the verbose XML attributes (`Ui.ttslua:31-190`). 3D overlays can be created via `Ui.Create3d`, but most boards use the 2D root.

## Board & Asset Management
- **NamedObject** gives symbolic names to GUIDs for every important object, including boards, archives, and player markers, and can mark them non-interactable to prevent accidental deletion (`NamedObject.ttslua:11-190`). Expansion packs register their own GUID/name pairs at runtime.
- **Location** maps named board regions (like "Player 1 Gear" or "Innovation Deck") to world coordinates, tracks which physical objects reside there, and exposes helper commands to visualize/hint at contents (`Location.ttslua:23-199`). Drop/pickup handlers are used heavily by automation (e.g., Player stats updating when tokens enter a location).
- **Archive** indexes infinite bags/decks so scripts can spawn resources by logical key instead of GUIDs. It merges base data with any expansion overrides and exposes helpers to pull cards into temporary containers and combine them back into decks (`Archive.ttslua:13-90`).
- **Expansion** loads every data-only module under `Expansion/`, keeps track of which ones are enabled, and exposes convenience filters for "enabled only" lists (`Expansion.ttslua:1-87`). Campaign configuration later consumes that data.

### Deck Lifecycle Pattern

Many card decks (Fighting Arts, Disorders, etc.) follow a three-stage lifecycle:

1. **Construction** - Cards collected from enabled expansion archives and combined into a single deck (`Campaign.SetupDeckFromExpansionComponents`)
2. **Archive Storage** - Constructed deck stored in a dedicated archive container (e.g., "Fighting Arts Archive") which acts as the canonical source
3. **Board Spawn** - Deck spawned from archive to its board location for player use

**Reset Flow**: Players can reset a deck at any time via `Deck.ResetDeck()` (line 61-76), which:
- Clears the current board deck
- Spawns a fresh copy from the archive
- Shuffles if needed

**Implication for runtime modifications**: Any permanent changes to deck contents (e.g., adding Strain reward fighting arts) must modify the deck **inside the archive**, not just the board copy. Otherwise changes are lost on reset. The pattern is:
1. Take the deck from the archive
2. Add/remove cards
3. Put the modified deck back in the archive
4. Optionally spawn a fresh copy to the board

This ensures all future resets include the modifications.

### Archive Container Caching

`Archive.Take` caches spawned containers in `Archive.containers` to avoid repeatedly spawning the same deck during a multi-card operation. However, this caching creates a hazard when multiple async operations need the same deck:

**Problem scenario:**
```lua
FightingArtsArchive.AddCard(cardName)  -- Takes card from Strain Rewards (async)
Strain:SpawnFightingArtForSurvivor(cardName)  -- Also needs Strain Rewards
```

The second call gets the cached container, but the first call already took the card from it → "card not found" error.

**Wrong fix:** Calling `Archive.Clean()` between operations destroys objects that async callbacks still need, causing TTS `<Unknown Error>`.

**Correct pattern:** Chain async operations via callbacks:
```lua
FightingArtsArchive.AddCard(cardName, function()
    Strain:SpawnFightingArtForSurvivor(cardName)
end)
```

**Implementation:** Archive functions that do async deck operations (`AddCard`, etc.) accept an optional `onComplete` callback parameter that fires after the operation completes and `Archive.Clean()` has run.

### Trash System for Card Removal

Players sometimes need to permanently remove cards from decks (e.g., archiving a Settlement Event as a game consequence). Rather than having them interact directly with the Archive system, the mod provides a **Trash container**:

**How it works:**
1. Players (or automation) put removed cards into the "Trash" container
2. When decks are rebuilt from archives, `Deck.AdjustToTrash()` checks the Trash and excludes matching cards
3. Trash contents are saved/loaded with campaigns via `Trash.Export()`/`Trash.Import()`

**Key files:**
- `Trash.ttslua` - `IsInTrash(name, type)`, `Export()`, `Import()`
- `Deck.ttslua` - `Deck.AdjustToTrash(deck, cardNames, archives, type)` filters cards present in Trash
- `Campaign.ttslua` - `Campaign.SetupSettlementEventsDeck()` uses `Deck.AdjustToTrash`

**Pattern for programmatic card removal:**
```lua
-- To "archive" (permanently remove) a card:
1. Take the card from its deck
2. Put it in the Trash container
3. Trigger deck rebuild (which will exclude trashed cards)

-- To undo:
1. Remove the card from Trash (destruct it)
2. Trigger deck rebuild (which will restore it from archive)
```

**When to use Trash vs Archive modules:**
- **Trash system**: For removing cards that exist in the normal game decks (e.g., Settlement Events, Hunt Events)
- **Archive modules** (FightingArtsArchive, VerminArchive): For adding/removing cards from Strain Rewards or similar special sources

## Domain Systems
### Campaign & Timeline
- `Campaign.Init` merges expansion metadata, builds the campaign-selection UI, wires export/import helpers, and registers providers survivors rely on (character deck, innovation checker, survival limit) (`Campaign.ttslua:46-65`).
- Campaign state keeps track of unlocked mode, selected expansions, and settlement numbers; `Campaign.EXPORT_VERSION` is bumped any time serialized state changes (`Campaign.ttslua:27`).
- `Timeline` holds settlement progression, survival actions, milestones, quarries, and notes. It seeds default "unspecified" events with a trie matcher so shorthand text searches can find auto-filled entries (`Timeline.ttslua:20-166`). It also merges expansion timelines (rulebooks, monsters) when initializing (`Timeline.ttslua:170-199`).

### Survivors, Players, And Battle UI
- `Survivor` defines the survivor data model, manages survivor boxes/sheets in the world, handles card slots, and owns cosmetic markers/notes (`Survivor.ttslua:15-200`). Initialization hydrates survivors, reconnects them to live objects by GUID, and keeps lookup tables by ID/object.
- `Player` represents each player board/area (four by default), keeps transient stats (armor, injuries, tokens), and reacts to physical interactions on the table. It listens for collisions and container events to determine when a token flip or movement should update stats or unlink cards (`Player.ttslua:45-192`). Color changes propagate to interested systems via `EventManager.ON_PLAYER_COLOR_CHANGED`.
- `BattleUi` renders the floating battle panel, exposes per-player controls (end turn, show/hide weapons), mirrors survivor stats, and responds to showdown lifecycle events to show/hide itself (`BattleUi.ttslua:25-172`). Hidden weapons per survivor are persisted via `BattleUi.Save()` and rehydrated after load.
- `GlobalUi` renders the top-left launcher buttons for Campaign, Hunt, Showdown, and Timeline overlays, ensuring only one panel (except Timeline) is visible at a time (`GlobalUi.ttslua:13-66`).

### Encounters And Rules
- `Hunt`, `Showdown`, and `Monster` manage their respective decks, setup flows, and UI. Monsters broadcast stat changes that systems like `BattleUi` listen to via `EventManager.ON_MONSTER_STAT_CHANGED` (`BattleUi.ttslua:142-165`).
- `Rules`, `Bookmarks`, `Archive`, `Deck`, and `Gear/Weapon/Armor` modules encapsulate searchable datasets and spawn automation for all cards and components used during settlement and battles.
- `Terrain`, `LocationGrid`, `MilestoneBoard`, and `Settlement` provide board-specific helpers (snap points, overlays, milestone shortcuts). They primarily build UI via the shared DSL and manipulate NamedObject-managed assets.

## UI Patterns
- All UI is declared in Lua and ultimately applied via `Ui.Get2d():ApplyToObject()` once all panels are described (`Global.ttslua:97-99`). Modules generally keep a reference to their root panel and expose `Show/Hide` helpers.
- Message boxes, dialogs, and long-lived overlays reuse `MessageBox` so they always render above other XML elements (`MessageBox.ttslua:13-43`).
- Drag-move is implemented where needed by modifying panel attributes (e.g., `BattleUi.panel` toggles `allowDragging` so players can reposition the HUD (`BattleUi.ttslua:57-60`)).
- UI interactions frequently defer heavy logic to provider modules (e.g., Campaign UI toggles expansions but defers actual enabling to `Expansion.SetEnabled`). Keep UI code thin.

## Persistence Contracts
- Every subsystem decides its own JSON schema. Examples:
  - `Survivor.Save()` stores survivor stats plus GUIDs for boxes/sheets so it can relink to physical objects on load.
  - `Player.Save()` persists which survivor sheet/figurine is linked and temporary injuries (`Player.ttslua:80-101`).
  - `Timeline.Save()` (not shown above) records survival actions, milestones, years, etc., which are later rehydrated in `Timeline.InitState` (`Timeline.ttslua:113-166`).
  - `BattleUi.Save()` keeps per-survivor hidden/visible weapon state (`BattleUi.ttslua:176-182`).
- Because `Global.onSave` simply marshals module outputs, schema changes are localized. When evolving a schema, bump any related export/import version and provide migration inside the owning module.

## Event Model
Synthetic events are defined centrally and should be preferred to ad-hoc cross-module calls. Common ones include:

| Event | Emitted By | Consumers |
| --- | --- | --- |
| `ON_PLAYER_SURVIVOR_LINKED` / `UNLINKED` | `Player` when survivor sheets are attached/detached | `BattleUi`, `Survivor`, other UIs. |
| `ON_SURVIVOR_STAT_CHANGED` | `Survivor` when a stat or checkbox changes | `BattleUi`, `Player`, automation that depends on stats. |
| `ON_MONSTER_STAT_CHANGED` | `Monster` | Battle UI, showdown overlays. |
| `ON_SHOWDOWN_STARTED/ENDED` | `Showdown` | `BattleUi`, `GlobalUi`, timeline hints. |
| `ON_PLAYER_COLOR_CHANGED` | `Player` (refresh timer) | `BattleUi` color dots, board markers. |

When extending the game flow, prefer emitting a new event constant in `EventManager` so you keep coupling loose.

## Tooling & Build Process
- `updateTTS.sh` backs up the active save, commits diffs to `savefile_backup.json`, creates a JSON template, bundles all Lua via `luabundler`, minifies with `luasrcdiet`, JSON-encodes the final script, and inserts it back into the save (`updateTTS.sh:1-52`). You should run it whenever you need to push the latest script bundle into Tabletop Simulator.
- `template_workshop.json` is the placeholder-laden save file so the bundler can inject the compiled script.
- `restoreBackup.sh` reverses the process if you need to roll back the injected Lua quickly.

## Working Guidelines
1. **Pick the right module**. If you are touching survivors, start inside `Survivor.ttslua` or `SurvivorBoard` UIs instead of bolting logic onto `Global`.
2. **Respect initialization order**. New systems should slot into `Global.onLoad` near their dependencies and, if they register event handlers, wait until `PostInit` so the UI hierarchy already exists.
3. **Emit events instead of calling deep internals**. If a change affects multiple systems, add a new event constant in `EventManager` and let downstream modules decide what to do.
4. **Keep UI creation declarative**. Use the helpers in `Ui.ttslua` for every panel/text/button. This keeps styling consistent and makes it easier to refactor colors/fonts.
5. **Schema evolution**. When adding new persistent fields, implement backwards-compatible hydration inside the module and, if exports/imports are affected, bump `Campaign.EXPORT_VERSION` (or other file-format constants) and extend `Campaign.ConvertToLatestVersion()` so older campaign exports conform to the latest schema.
6. **Log liberally when debugging**. Create a module logger via `Log.ForModule("ModuleName")` so you can toggle debug output through the console without spamming every user.
7. **Mind the physical table**. If you spawn or move objects, always route through `NamedObject` and `Location` so automation such as cleanup and warnings continue to work.

## Strain Milestones — Implementation (Complete)

Strain milestones unlock permanent benefits when specific in-game conditions are met. **Status: Fully implemented.**

### Implementation Summary

| Feature | Module | Status |
|---------|--------|--------|
| UI to view/check milestones | `Strain.ttslua` | ✅ |
| Confirmation dialog with flavor/rules text | `Strain.ttslua` | ✅ |
| Manual steps shown in dialog | `Strain.ttslua` | ✅ |
| Add fighting art to deck on confirm | `FightingArtsArchive.AddCard()` | ✅ |
| Spawn copy for survivor (south of board) | `Strain:SpawnFightingArtForSurvivor()` | ✅ |
| Remove fighting art on uncheck | `FightingArtsArchive.RemoveCard()` | ✅ |
| Add vermin to deck | `VerminArchive.AddCard()` | ✅ |
| Schedule timeline event | `Timeline.ScheduleEvent()` | ✅ |
| New campaign: add unlocked rewards | `Campaign.AddStrainRewards()` | ✅ |
| New campaign: random 5 if >5 unlocked | `Campaign.RandomSelect()` | ✅ |
| Clear milestones option | `Campaign.clearStrainMilestones` | ✅ |

### Key Files
- `Strain.ttslua` — UI, confirmation flow, consequence execution
- `GameData/StrainMilestones.ttslua` — Milestone definitions with structured `consequences`
- `FightingArtsArchive.ttslua` — Add/remove fighting arts from deck
- `VerminArchive.ttslua` — Add/remove vermin from deck
- `Campaign.ttslua` — `AddStrainRewards()` for new campaign setup

### Card Source
All reward cards spawn from the **"Strain Rewards"** archive entry in Core.

### Persistence
- Milestone state persists across campaigns unless cleared via checkbox
- On new campaign, unlocked rewards are automatically added (max 5 fighting arts, randomly selected)

## Future Refactor Opportunities

We keep a running list of refactors that surfaced during reviews so the insights are not lost even if they weren’t part of the immediate change:

1. **Campaign import/export modularization**
   - *Migrations*: extract version-to-version transformations into a dedicated module (e.g., `CampaignMigrations`) so each migration is testable, and `Campaign.ConvertToLatestVersion` becomes a dispatcher instead of a monolith.
   - *Dependency injection*: allow `Campaign.Import` to accept a dependency table (Strain, Archive, Expansion, etc.) so integration tests can stub collaborators without `debug.getupvalue`.
   - *Importer/Exporter split*: break the current 1,100+ line `Campaign.ttslua` into focused modules (`CampaignImporter`, `CampaignExporter`, `CampaignSetup`) to isolate responsibilities and simplify testing.

2. **Test seam helpers**
   - Introduce reusable stub builders for Campaign import/export tests to avoid duplicating the 20+ stubs required today.

3. **Archive module violates Single Responsibility Principle** *(Identified: 2025-12-01, Partially addressed: 2025-12-02)*
   - **Problem**: Archive mixes pure business logic (finding cards, state management) with external dependencies (TTS spawning, physics casts), making integration tests impossible without stubbing the entire module
   - **Solution**: Extract TTS interactions into separate seam
     - ✅ Created `Util/TTSSpawner.ttslua` for spawning operations
     - ✅ Added `Archive.Test_SetSpawner` seam for integration testing
     - ❌ `Archive.Clean()` still uses `Physics.cast` directly (minor - only affects cleanup)
   - **Benefit**: Integration tests can now use real Archive logic with fake spawner
   - **Reference**: "Working Effectively with Legacy Code" by Michael Feathers (seams pattern)
   - **Remaining work**: Wrap `Physics.cast` in TTSSpawner for full testability (low priority)

4. **Strain module SOLID violations** *(Identified: 2025-12-03)*
   - **Problem**: `Strain.ttslua` mixes UI management, state persistence, and consequence execution. Tests require 460+ lines of stubs that duplicate production logic.
   - **Symptoms**:
     - Tests break when implementation changes (testing implementation, not behavior)
     - Stubs must reimplement `Archive.TakeFromDeck` logic
     - No clear boundary between business logic and TTS interaction
   - **Suggested Solution**:
     - Extract `ConsequenceExecutor` module for orchestration (DIP + SRP)
     - Split into `StrainState.ttslua` (pure state) + `StrainUi.ttslua` (UI) + `Strain.ttslua` (facade)
     - Add dependency injection to `Strain.Init(saveState, deps)`
   - **Benefit**: Tests inject simple fakes without `package.loaded` manipulation; reduces test maintenance
   - **Priority**: P3 — Current design works; prefer acceptance tests for new features
   - **Reference**: Code review 2025-12-03

When touching any of these areas, try to land at least one of the above improvements (Boy Scout Rule), and update this section if new opportunities are identified.

## Appendix: Frequently Referenced Files
- `Global.ttslua` — bootstraps everything, handles save/load, houses top-level helpers.
- `Ui.ttslua` — XML generation DSL for both 2D and 3D UI.
- `Util/EventManager.ttslua` — hooks TTS callbacks, defines synthetic events.
- `NamedObject.ttslua` & `Location.ttslua` — mapping between GUIDs/world coordinates and logical names.
- `Campaign.ttslua`, `Timeline.ttslua`, `Survivor.ttslua`, `Player.ttslua`, `BattleUi.ttslua` — primary gameplay subsystems most contributors touch first.
- `updateTTS.sh` — bundling pipeline; run this before exporting to Tabletop Simulator Workshop.

---

## Related Documentation

- **[docs/TTS_PATTERNS.md](docs/TTS_PATTERNS.md)** — TTS-specific implementation patterns, debugging approaches, and gotchas
- **[docs/TESTING.md](docs/TESTING.md)** — Testing infrastructure, integration test strategy, and test seam patterns

Keep this document close when planning future work; updating it when adding a new subsystem pays for itself the next time you (or someone else) needs to understand how the mod hangs together.

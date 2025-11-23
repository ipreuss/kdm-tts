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
5. **Schema evolution**. When adding new persistent fields, implement backwards-compatible hydration inside the module and, if exports/imports are affected, bump `Campaign.EXPORT_VERSION` or any other file-format constants.
6. **Log liberally when debugging**. Create a module logger via `Log.ForModule("ModuleName")` so you can toggle debug output through the console without spamming every user.
7. **Mind the physical table**. If you spawn or move objects, always route through `NamedObject` and `Location` so automation such as cleanup and warnings continue to work.

## Appendix: Frequently Referenced Files
- `Global.ttslua` — bootstraps everything, handles save/load, houses top-level helpers.
- `Ui.ttslua` — XML generation DSL for both 2D and 3D UI.
- `Util/EventManager.ttslua` — hooks TTS callbacks, defines synthetic events.
- `NamedObject.ttslua` & `Location.ttslua` — mapping between GUIDs/world coordinates and logical names.
- `Campaign.ttslua`, `Timeline.ttslua`, `Survivor.ttslua`, `Player.ttslua`, `BattleUi.ttslua` — primary gameplay subsystems most contributors touch first.
- `updateTTS.sh` — bundling pipeline; run this before exporting to Tabletop Simulator Workshop.

## TTS-Specific Implementation Patterns

### Checkbox Interaction Pattern
**Problem**: TTS automatically toggles checkbox visual state on click before calling the onClick handler.

**Solution**: Revert checkbox state in handler, show confirmation dialog, then explicitly set final state.
```lua
onClick = function(_, player)
    -- TTS has already auto-toggled the checkbox
    checkbox:Check(false)  -- Revert to unchecked
    showConfirmationDialog()
    -- On confirm: checkbox:Check(true)
end
```

### Dialog API Usage
**Correct Methods**: 
- `dialog:ShowForPlayer(player)` - show to specific player
- `dialog:ShowForAll()` - show to all players  
- `dialog:HideForAll()` - hide from all players

**Common Error**: Using `dialog:Show()` or `dialog:Hide()` (these methods don't exist in PanelKit).

### Player Object References
**Problem**: Player objects aren't stable references between different TTS callbacks.

**Solutions**:
1. Compare `player.color` strings instead of object references
2. Better: Eliminate player tracking for shared campaign state (milestones, settlement progress)

### Shared vs Personal UI Design
**Campaign-level UI** (visible to all players):
- Settlement milestones, timeline events, campaign progress
- Use `ShowForAll()` and allow any player to interact

**Player-specific UI** (individual sheets):
- Survivor sheets, player boards, personal inventory
- Use `ShowForPlayer(player)` and track player ownership

### TTS Debugging Approach
**Essential Patterns**:
- Add comprehensive debug logging with module-specific toggles in `Log.DEBUG_MODULES`
- **Fail fast with meaningful errors** - Don't silently ignore missing dependencies; log and fail clearly
- Log state changes at each step to trace execution flow
- Use `./updateTTS.sh` for rapid iteration and testing

**Function Existence Checks** should be rare and only used for:
- **Test environment compatibility** - where modules genuinely might not exist
- **Optional features** - where the functionality is truly optional, not required
- **Never** for hiding missing required dependencies - those should fail fast with clear error messages

### Runtime Error Diagnosis
**When encountering "attempt to call a nil value"**:
1. Add debug logging at the error point to identify what is nil
2. Work backward through execution with targeted logging
3. Test simple hypotheses before complex architectural changes
4. Often the root cause is simpler than initial assumptions (missing function vs. module loading issue)

Keep this document close when planning future work; updating it when adding a new subsystem pays for itself the next time you (or someone else) needs to understand how the mod hangs together.

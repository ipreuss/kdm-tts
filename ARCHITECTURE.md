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

## Strain Milestones — Requirements

Strain milestones unlock permanent benefits when specific in-game conditions are met. The UI already supports viewing and checking milestones; this section documents the requirements for implementing milestone consequences.

### Card Source
All reward cards (fighting arts, vermin, etc.) are spawned from the **"Strain Rewards"** archive entry in Core.

### Key Concept: "The Survivor"
When a milestone says "the survivor gains X," this refers to **the survivor who triggered the milestone condition**. The confirmation dialog should prompt the user to select which survivor triggered it if not already known.

### Persistence Across Campaigns
- When a milestone is reached, cards are added to decks **immediately** in the current campaign
- On **new campaign start**, all previously unlocked milestone rewards are automatically added to the appropriate decks
- **Exception:** If more than 5 fighting arts are unlocked, only 5 are randomly chosen and added to the new campaign's fighting art deck
- Strain milestone state persists across campaigns unless explicitly reset

### Consequence Types and Automation

| Consequence Type | Automation | Priority | Notes |
|------------------|------------|----------|-------|
| Add fighting art to deck | **Automated** | P1 | Spawn card from "Strain Rewards" archive to fighting art deck |
| Survivor gains fighting art | **Automated** | P1 | Spawn card to triggering survivor's grid |
| Add to timeline | **Automated** | P2 | Insert event at specified year |
| Add to vermin deck | **Automated** | P2 | Spawn card from "Strain Rewards" archive to vermin deck |
| Survivor gains disorder | Manual | P3 | Show reminder; user handles |
| Survivor gains weapon proficiency | Manual | P3 | Show reminder; user handles |
| Survivor suffers injury | Manual | P3 | Show reminder; user handles |
| Survivor suffers stat penalty | Manual | P3 | Show reminder; user handles |
| Add strange resource | Manual | P3 | Show reminder; user handles |

### Acceptance Criteria (P1 — Fighting Arts)

**On milestone confirm:**
1. Spawn the fighting art card from "Strain Rewards" and add it to the settlement's fighting art deck.
2. Spawn a second copy south of the battle grid.
3. Display message telling player to add the card to the triggering survivor.

**On milestone uncheck:**
1. Remove the fighting art from the settlement's fighting art deck (search and destroy).
2. Display message telling player to remove the card from the survivor who has it.

### Acceptance Criteria (New Campaign Setup)

1. On new campaign creation, check which strain milestones are marked as reached.
2. Collect all fighting arts from reached milestones.
3. If more than 5 fighting arts are unlocked, randomly select 5.
4. Spawn the selected fighting arts from "Strain Rewards" to the fighting art deck.
5. Spawn any other permanent rewards (vermin cards, etc.) to their respective decks.

### Acceptance Criteria (P2 — Timeline/Vermin)

1. "Add Acid Storm to next lantern year" → insert the event on timeline automatically.
2. "Add Fiddler Crab Spider to vermin deck" → spawn card from "Strain Rewards" to vermin deck.

### Deferred (P3 — Manual)

For these, show a clear reminder in the confirmation dialog listing what the user must do manually:
- Disorders, weapon proficiency, injuries, stat penalties, strange resources.

## Future Refactor Opportunities

We keep a running list of refactors that surfaced during reviews so the insights are not lost even if they weren’t part of the immediate change:

1. **Campaign import/export modularization**
   - *Migrations*: extract version-to-version transformations into a dedicated module (e.g., `CampaignMigrations`) so each migration is testable, and `Campaign.ConvertToLatestVersion` becomes a dispatcher instead of a monolith.
   - *Dependency injection*: allow `Campaign.Import` to accept a dependency table (Strain, Archive, Expansion, etc.) so integration tests can stub collaborators without `debug.getupvalue`.
   - *Importer/Exporter split*: break the current 1,100+ line `Campaign.ttslua` into focused modules (`CampaignImporter`, `CampaignExporter`, `CampaignSetup`) to isolate responsibilities and simplify testing.

2. **Test seam helpers**
   - Introduce reusable stub builders for Campaign import/export tests to avoid duplicating the 20+ stubs required today.

When touching any of these areas, try to land at least one of the above improvements (Boy Scout Rule), and update this section if new opportunities are identified.

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

### Archive System Debugging

The Archive system has a two-level structure that's important to understand when debugging "card not found" errors:

**Level 1: Archive → Deck/Container**
- `Archive.Take({ name = "Misc AI", type = "AI" })` looks up the archive using `Archive.Key(name, type)`
- The key maps to an archive name (e.g., `"Core Archive"`) via `Archive.index`
- The archive container is spawned and cached in `Archive.containers`

**Level 2: Container → Individual Card**
- `Container:Take({ name = "Card Name", type = "Card Type" })` searches inside the spawned deck
- **Critical**: Search requires BOTH `name` AND `gm_notes` (type) to match exactly (`Container.ttslua:137-142`)

**Common failure modes**:
1. **Archive name mismatch**: Passing an explicit `archive` parameter that doesn't exist as a TTS object (e.g., `"Strain Rewards"` is a deck inside Core Archive, not an archive itself)
2. **Card name typo**: Card names in the TTS save file must match exactly what the code expects
3. **Type mismatch**: A deck's `gm_notes` differs from its cards' `gm_notes` (e.g., deck is `"Rewards"` but cards inside are `"Fighting Arts"`)
4. **Cached container depletion**: `Archive.Take` removes objects from cached containers. Multiple calls for the same object fail unless `Archive.Clean()` is called between them to spawn a fresh container.

**Debugging steps**:
1. Check `savefile_backup.json` for exact `Nickname` and `GMNotes` values
2. Trace whether the code passes an explicit `archive` parameter (usually wrong) or lets auto-resolution work (usually right)
3. Compare to working patterns like `Showdown.ttslua:376` which takes "Misc AI" without explicit archive
4. If taking the same object twice, ensure `Archive.Clean()` is called between takes

**Pattern for mixed-type decks**: When a deck contains cards of different types (like Strain Rewards containing Fighting Arts, Vermin, and Resources), search by name only within that specific deck rather than relying on type matching.

### TTS Spawn Callbacks Are Async

**Critical:** TTS object spawning uses asynchronous callbacks. Code after a spawn call runs BEFORE the spawned object exists.

```lua
-- WRONG - deck goes into archive before card is added
local card = container:Take({
    spawnFunc = function(card)
        deck.putObject(card)  -- Called LATER
    end,
})
archive.putObject(deck)  -- Called IMMEDIATELY - deck has no card yet!

-- CORRECT - wait for spawn to complete
container:Take({
    spawnFunc = function(card)
        deck.putObject(card)
        archive.putObject(deck)  -- Now card is in deck
    end,
})
```

This applies to:
- `object.takeObject({ callback_function = ... })`
- `Container:Take({ spawnFunc = ... })`
- `Archive.Take({ spawnFunc = ... })`

Any logic depending on the spawned object must be inside the callback or use `Wait.frames`.

Keep this document close when planning future work; updating it when adding a new subsystem pays for itself the next time you (or someone else) needs to understand how the mod hangs together.

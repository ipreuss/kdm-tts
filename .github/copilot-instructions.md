# Copilot Coding Agent Instructions

## Repository Overview

This is a **Kingdom Death: Monster mod for Tabletop Simulator (TTS)** — a Lua-based automation layer for the board game. The codebase provides campaign management, survivor tracking, settlement phases, hunt/showdown automation, and a custom UI system.

- **Language:** Lua 5.1 (TTS runtime) / Lua 5.4 (local tests)
- **Size:** ~15,000 lines across 104 source files (`.ttslua` for TTS, `.lua` for tests)
- **Entry point:** `Global.ttslua` (bundled into TTS save via `luabundler`)

## Build & Test Commands

### Running Tests (ALWAYS do this before and after changes)
```bash
lua tests/run.lua
```
- Runs 121+ unit/integration tests in ~2 seconds
- **Must pass before any PR**
- Add new tests as `tests/<area>_test.lua` and register in `tests/run.lua`

### Bundling for TTS (manual smoke testing)
```bash
./updateTTS.sh
```
- Bundles scripts into TTS save file
- Requires: `luabundler`, `jq` (both installed locally)
- Creates backup in `savefile_backup.json`

### Restoring Backup
```bash
./restoreBackup.sh
```

## Project Layout

```
├── *.ttslua              # Core modules (Campaign, Strain, Survivor, Timeline, etc.)
├── Global.ttslua         # Entry point - defines onLoad, onSave, initialization order
├── GameData/             # Data tables (StrainMilestones.ttslua, CampaignMigrations.ttslua)
├── Expansion/            # One file per expansion (Core.ttslua, DragonKing.ttslua, etc.)
├── Ui/                   # UI helpers (PanelKit.ttslua, LayoutManager.ttslua)
├── Util/                 # Reusable utilities (Check.ttslua, Container.ttslua, EventManager.ttslua)
├── tests/                # Test suite
│   ├── run.lua           # Test runner - lists all test files
│   ├── framework.lua     # Assertion library
│   ├── stubs/            # TTS API stubs for headless testing
│   ├── support/          # Bootstrap and JSON utilities
│   └── acceptance/       # High-level acceptance tests
├── docs/                 # Design docs (TESTING.md, TTS_PATTERNS.md)
└── handover/             # Role-based context for multi-session work
```

## Key Architecture Facts

1. **Module loading:** Files use `require("Kdm/<Module>")` pattern. The bootstrap adds a custom searcher for `.ttslua` files.

2. **Initialization order matters:** `Global.onLoad` initializes modules in dependency order. New modules must slot correctly.

3. **Two-phase init:** Modules needing UI or event handlers register them in `Wait.frames(..., 20)` PostInit phase.

4. **State persistence:** Each module owns its Save/Load schema. `onSave()` collects payloads from Campaign, Expansion, Monster, Player, Survivor, Timeline, BattleUi, Strain.

5. **UI framework:** Custom DSL in `Ui.ttslua` builds XML. Use `PanelKit.ttslua` for dialogs. Dimensions must be pre-calculated (immutable after creation).

6. **TTS async callbacks:** Spawn operations are async. Logic depending on spawned objects must be inside callbacks.

## Coding Conventions

- **Fail fast:** Use `assert()` for required parameters, not silent fallbacks
- **Module naming:** `PascalCase` for module tables, `camelCase` for locals
- **Colon methods:** Only when function needs `self`
- **Test helpers:** Place under `Module._test` table or `Module.Test`
- **Comments:** Explain "why" not "what"; prefer self-documenting code

## Testing Patterns

1. **TTSSpawner seam:** Modules with TTS API calls use `Util/TTSSpawner.ttslua` for testability. Inject fake spawner via `Module.Test_SetSpawner()`.

2. **Check test mode:** Tests enable `Check.Test_SetTestMode(true)` so table stubs pass userdata checks.

3. **Stub order matters:** Install stubs in `package.loaded` BEFORE requiring modules (Lua caches at load time).

4. **Integration tests:** Exercise real module logic, stub only TTS environment layer.

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| "attempt to call nil value" | Check module exports; function may exist but not be in return table |
| `<Unknown Error>` in TTS | Code operating on destroyed object; add GUID logging |
| Card not found in archive | Verify exact `Nickname` and `GMNotes` in `savefile_backup.json` |
| UI dialog wrong size | Pre-calculate height with `LayoutManager.Specification()` before creation |
| Stray cards after deck ops | Call `card.destruct()` after `deck.putObject(card)` — putObject copies, not moves |

## Workflow Requirements

1. **Test-first:** Add/update tests before changing behavior
2. **Run tests:** `lua tests/run.lua` must pass
3. **Update docs:** If changing behavior documented in README, ARCHITECTURE.md, or docs/
4. **No git operations:** Human maintainer handles commits/pushes
5. **Closing signature:** ALWAYS end every conversation with a session summary and closing signature:
```
**═══════════════════════════════════════**
**║        [ROLE NAME] ROLE END          ║**
**║        YYYY-MM-DD HH:MM UTC          ║**
**═══════════════════════════════════════**
```

## Files to Read First

For any task, start with:
- `PROCESS.md` — Development workflow and role definitions
- `ARCHITECTURE.md` — System design and module responsibilities
- `docs/TESTING.md` — Test infrastructure and patterns
- `handover/IMPLEMENTATION_STATUS.md` — Current work in progress

Trust these instructions. Only search further if information is incomplete or produces errors.

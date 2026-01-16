# KDM TTS Mod

## Quick Commands
- Build & Deploy: `./updateTTS.sh`

## Testing Quick Reference

### Welcher Test-Typ?

| Ich will testen... | Test-Typ | Befehl |
|-------------------|----------|--------|
| Reine Logik, Berechnungen, Datenstrukturen | Headless | `lua tests/run.lua` |
| TTS-Objekte, UI, Spawning, Archive | TTS Console | `testall` |
| Nur einen bestimmten Test | TTS Console | `testfocus <pattern>` |
| Nur Tests für aktuellen Bead | TTS Console | `testpriority` |

### Headless Tests (Terminal)

```bash
lua tests/run.lua                    # Alle Tests
lua tests/run.lua SurvivorTest       # Ein Test-File
lua tests/run.lua -v                 # Verbose
```

Dateien: `tests/*_test.lua`

### TTS Console Tests (Im Spiel)

```
testall                              # Alle TTS-Tests
testfocus <pattern>                  # Tests mit Pattern im Namen
testpriority                         # Tests für FOCUS_BEAD
teststop                             # Laufende Tests abbrechen
```

Dateien: `TTSTests/*Tests.ttslua`

**Wichtig:** Nach Code-Änderungen erst `./updateTTS.sh` ausführen!

Siehe `TESTING.md` für Test-Strategie und Patterns.

## Architecture Overview
Modular Lua codebase for Tabletop Simulator Kingdom Death: Monster automation.
Uses `luabundler` to compile modules into single script.

## Directory Structure
```
kdm-tts/
├── Core/        # Infrastructure: Console, Log
├── Location/    # Board management: Location, NamedObject
├── Archive/     # Spawning system: Archive, *Archive modules
├── Entity/      # Game entities: Monster, Survivor, Player
├── Equipment/   # Gear tracking: Armor, Weapon, Gear
├── Sequence/    # Game flow: Campaign, Hunt, Showdown, Timeline
├── Ui/          # UI framework and components
├── Data/        # Game data: Deck, Terrain, Rewards
├── Util/        # Low-level utilities
├── Expansion/   # Expansion content definitions
├── GameData/    # Migrations and static data
├── TTSTests/    # TTS integration tests
└── tests/       # Headless unit/acceptance tests
```

## Key Patterns
- Module structure: `local M = {} ... return M`
- Init ordering: Expansion -> Location -> Archive -> Entities -> Sequences
- Events: EventManager for Pick/Drop, Showdown Start/End
- UI: PanelKit for dialogs, LayoutManager for XML layout

## Require Convention
All modules use `require("Kdm/<path>")` pattern:
- `require("Kdm/Core/Log")` - Core module
- `require("Kdm/Location/Location")` - Location module
- `require("Kdm/Util/Check")` - Utility module

## Subdirectory Documentation
Each subdirectory contains its own CLAUDE.md with domain-specific patterns.

---

## Git Operations - Human Approval Required

Git write operations require human approval before execution.

**Allowed (read-only, no approval needed):**
- `git status`, `git diff`, `git log`, `git show`

**Allowed with human approval:**
- `git add`, `git commit`, `git push`

**Forbidden (never execute):**
- `git stash`, `git reset`, `git rebase`, `git push --force`

**Commit format:**
```
[type]: [description]

[optional body]

Bead: kdm-xxx
```
**Types:** feat, fix, refactor, test, docs, chore

---

## Session Startup Protocol

On every new session:
1. Read `PROCESS.md` for role-based workflow
2. Check `handover/QUEUE.md` for PENDING handovers
3. Ask user to select role (Product Owner, Architect, Implementer, Reviewer, Debugger, Tester, Team Coach)
4. Read `ROLES/<SELECTED_ROLE>.md`
5. If PENDING handover exists, acknowledge it
6. End session with closing signature per PROCESS.md

---

## Beads Workflow

Uses `bd` for issue tracking. `.beads/` directory committed by human maintainer.
Ignore `bd sync` - single working copy project.

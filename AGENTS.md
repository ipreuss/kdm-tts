# Repository Guidelines

## Project Structure & Module Organization
- Core gameplay scripts (`Campaign.ttslua`, `Strain.ttslua`, `Settlement.ttslua`, etc.) live at the repo root and are required via `Kdm/<Module>`.
- `GameData/` holds data tables (e.g., `StrainMilestones.ttslua`, campaign migrations) while `Expansion/` contains one file per expansion.
- UI helpers sit under `Ui/` (`PanelKit.ttslua`, `LayoutManager.ttslua`); reusable helpers live under `Util/`.
- `TTSTests.ttslua` powers the in-game console harness; Lua specs live in `tests/` with fixtures/utilities inside `tests/support/`.
- Cross-role context lives in `handover/`; read those docs before touching the corresponding subsystems.

## Build, Test, and Development Commands
- `lua tests/run.lua` – runs the full unit suite; add new specs as `tests/<area>_test.lua` and register them in `tests/run.lua`.
- `>testhelp` / `>teststrain <Card>` – issued via the TTS chat to list console harnesses or exercise the Strain reward workflow; every console test snapshots, mutates, then restores state.
- `./updateTTS.sh` – syncs the repo scripts into the Tabletop Simulator save for manual smoke tests.
- `./restoreBackup.sh` – reverts the bundled save if experimentation corrupts the working copy.

## Coding Style & Naming Conventions
- Follow `CODING_STYLE.md`: favor intention-revealing names, named constants over magic values, and guard clauses that fail loudly.
- Modules use `PascalCase` tables, locals prefer `camelCase`, and colon methods are reserved for logic that needs `self`. Test-only helpers live under `Module.Test`.
- Keep functions short, rely on OO-style Lua patterns (see `Weapon.ttslua`), and let tests/documentation reflect behavior instead of inline comments.

## Testing Guidelines
- Start every behavioral change with a failing test (unit or harness) per `PROCESS.md`; keep specs near the code they cover (e.g., strain logic in `tests/strain_test.lua`).
- Acceptance tests go through `TTSTests.ttslua`; document any new console command’s snapshot/action/restore loop in `README.md`, and when feasible, add headless equivalents so CI can catch regressions without launching TTS.
- Ensure new systems integrate with the regression suite before running in TTS.

## Commit & Pull Request Guidelines
- Before a PR, run `lua tests/run.lua`, update any impacted docs (README, ARCHITECTURE, FAQ), and refresh `handover/LATEST_REVIEW.md` after each review cycle.
- PR descriptions should state intent, linked issues, touched UIs, required screenshots, and manual verification steps; keep commits focused (refactors separate from feature changes), and remember that any non-read-only git commands (commit, push, reset) are performed by a human maintainer.
- Never merge behavior without tests; confirm Campaign/Strain flows still pass their specs and note any manual smoke tests in the PR body.

## Agent-Specific Instructions
- Codex contributors default to the **Implementer** role: no git operations, follow the architect’s plan, and escalate requirement or design changes back through the proper role.
- Before coding, read `PROCESS.md`, `handover/HANDOVER_ARCHITECT.md`, `handover/HANDOVER_IMPLEMENTER.md`, and `handover/IMPLEMENTATION_STATUS.md`; they define scope, state, and expectations.
- Produce an implementation plan, secure confirmation, add/adjust tests first, then modify production code; keep handover docs updated if the implementation status changes.

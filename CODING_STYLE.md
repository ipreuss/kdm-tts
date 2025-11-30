# Coding Style Guide

This document captures the shared conventions for working on the KDM Tabletop Simulator scripts. Follow it for all new code and whenever refactoring existing code.

## Clarity First
- Make code self-explanatory before reaching for documentation: prefer named constants/enums over raw booleans/strings, intention-revealing function arguments, and small helpers over inline ambiguity.
- Remove magic values; give them names where they are defined.
- Comments are a last resort when structure and names cannot convey intent.
- Expose test-only helpers with a leading underscore (e.g., `_TestStubUi`) and keep them clearly segregated from production APIs.
  - Preferred pattern: place test-only helpers under a `Module._test` table (e.g., `Module._test.stubUi`) so intent is explicit and separated from runtime APIs.

## Error Handling
- **Prefer assertions over guard clauses** to fail fast and make errors visible.
- Use `assert(Check.Something(value, "message"))` pattern for required parameters and preconditions.
- **Use assertions for fatal errors** that indicate broken mod setup or game state:
  - Required archives/decks missing from save file (mod designer error)
  - Essential TTS objects that should always exist (broken save file)
  - Required locations/components missing (mod installation problem)
  - Invalid game state that prevents core functionality
- **Use guard clauses only for recoverable conditions**:
  - Optional behavior where nil/false is a valid return (e.g., `lenient` parameter)
  - User-driven operations that might legitimately fail
  - Feature-specific resources that don't break core gameplay
- **Guideline:** If the game cannot reasonably continue without this resource/condition, use assertion. The "programmer" includes both code developers and mod designers setting up the game content.
- Example to **avoid** (guard clause for required parameter):
  ```lua
  local locationName = params.location
  if not locationName then
      return nil
  end
  ```
- Example to **prefer** (assertion for required parameter):
  ```lua
  assert(Check.Str(params.location, "location is required"))
  local locationName = params.location
  ```
- Example to **prefer** (assertion for essential resource):
  ```lua
  local deck = Archive.Take({name = "Fighting Arts"})
  assert(deck, "Fighting Arts deck not found in archive - mod setup error")
  ```
- Example of **correct guard clause** (optional/recoverable):
  ```lua
  local expansion = Archive.Take({name = "Dragon King", lenient = true})
  if not expansion then
      log:Debugf("Dragon King expansion not installed, skipping")
      return
  end
  ```

## Documentation Strategy
1. **Self-speaking code** – choose expressive names, extract helper methods/objects, and keep logic small enough to read without comments. Prefer removing ambiguity over adding prose.
2. **Executable specifications** – encode behavior in automated tests (unit, integration, or high-level regression scripts) so readers can run them to learn and verify intent.
3. **In-code comments** – add precise comments when intent cannot be expressed through structure (edge cases, domain rules, performance constraints). Keep them near the code they explain.
4. **External docs** – when broader explanations are needed (architecture decisions, data formats, workflows) capture them in Markdown files such as `ARCHITECTURE.md`, `FAQ.md`, or new ADRs.

> **Always update every relevant document when behavior changes.** That includes tests, comments, READMEs, and diagrams touched by the change.

## Design Principles
- Favor **simple, composable units** (KISS); avoid cleverness.
- Apply **SOLID**:
  - Single Responsibility: modules/scripts own one reason to change.
  - Open/Closed: extend via new modules/objects instead of deep conditionals.
  - Liskov Substitution: shared interfaces behave consistently.
  - Interface Segregation: expose narrow APIs.
  - Dependency Inversion: depend on abstractions (e.g., `Kdm/Log`) instead of concrete implementations.
- Embrace XP/pragmatic practices: frequent refactoring, collective ownership, relentless automation, and clear naming.

## Refactoring Expectations
- Work in **small, safe steps**; commit after every logical improvement.
- Continuously move toward **smaller files, slimmer modules, and shorter functions**. Extract helpers, split files into folders (e.g., `Expansion/`), and isolate responsibilities.
- Remove duplication aggressively; prefer composition over copy/paste.
- When touching code, opportunistically simplify nearby complexity if the impact is easy to verify.

## Paradigm Preference
- Default to **object-oriented Lua**, similar to the pattern in `Weapon.ttslua`, where behaviors live alongside data via colon-methods and constructors (`Gear:new()`).
  - Only use the colon (`:`) call/definition form when the function truly depends on `self`. If the logic doesn’t access instance state, define it with a dot (`.`) and call it likewise so it’s obvious that no implicit receiver is used.
- If OO is not a fit, use **pure functions** with clear inputs/outputs.
- Use **imperative scripts** only when the above are impractical (e.g., glue code, bootstrap routines).
- Hide mutation inside objects and expose intention-revealing methods. Use metatables sparingly and encapsulate TTS API interactions within objects.

## Naming, Structure, and Modules
- Match file/module names to their primary class or concept (`Monster`, `Timeline`). Use `PascalCase` for module tables and `camelCase` for locals unless Lua/TTS APIs dictate otherwise.
- Keep public APIs at the top of the file; place private helpers below.
- Require modules via stable paths (`require("Kdm/Gear")`) and avoid circular dependencies; introduce intermediate abstractions if needed.
- Group related files under folders (e.g., `Expansion/`) and prefer `init`/`Init` entry points for bootstrap code.

## Comments and External Notes
- Comment “why”, not “what”. Reference rules or page numbers when logic encodes official KDM behavior.
- For runbooks, editor workflows, or onboarding notes, prefer Markdown files under the repository root. Link between docs when useful.

## Testing and Verification
- Add or update tests for any behavioral change, even if the original code lacked coverage.
- Lean on deterministic tests when possible; wrap TTS interactions in adapters that can be mocked.
- Document how to run tests (commands, scripts) inside README sections if they change.

## Workflow Expectations
See `PROCESS.md` for the full change-management loop (test-first, safety net, PR checklist). Highlights:
- Coordinate changes through pull requests with clear descriptions and checklists of updated docs/tests.
- Before opening a PR, run relevant tests and sanity-check TTS scripts locally (see `updateTTS.sh` workflow).
- When reviews trigger follow-ups, keep commits clean and focused; avoid mixing refactors with feature changes unless validated by tests.

Following these conventions keeps the project understandable for future contributors and reduces regressions as we continue to expand the simulator.

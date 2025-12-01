# Coding Style Guide

This document captures the shared conventions for working on the KDM Tabletop Simulator scripts. Follow it for all new code and whenever refactoring existing code.

## Clarity First
- Make code self-explanatory before reaching for documentation: prefer named constants/enums over raw booleans/strings, intention-revealing function arguments, and small helpers over inline ambiguity.
- Remove magic values; give them names where they are defined.
- Comments are a last resort when structure and names cannot convey intent.
- Expose test-only helpers with a leading underscore (e.g., `_TestStubUi`) and keep them clearly segregated from production APIs.
  - Preferred pattern: place test-only helpers under a `Module._test` table (e.g., `Module._test.stubUi`) so intent is explicit and separated from runtime APIs.

## Fail Fast - Make Wrong States Unrepresentable
- **Design for debuggability**: code should fail in obvious ways when something is wrong.
- **Silent failures are the enemy**: they hide problems until it's too late (data corruption, broken game state).
- **Better to crash during development** than corrupt user data in production.
- **Avoid defensive abstractions**: don't add helper functions "just in case" - if you need error handling, use assertions/guards directly.
- **Let errors bubble up naturally**: don't wrap errors in multiple layers - the stack trace should point directly to the source.
- **Trust your module contracts**: if all Save() functions return tables, don't add nil checks - let violations crash immediately.

## Prefer Tight Function Contracts Over Lenient Behavior
- **Make requirements explicit with assertions**: don't silently accept invalid inputs and return "safe" defaults.
- **Don't duplicate caller validation**: if callers already check conditions, don't re-check inside the function.
- **Example to avoid** (lenient - accepts anything):
  ```lua
  function ApplyState(object, stateName)
      if not object or not stateName then
          return object  -- Silently does nothing
      end
      if type(object.getStates) ~= "function" then
          return object  -- Silently does nothing
      end
      -- ... apply state ...
  end
  ```
- **Example to prefer** (tight contract - requires valid inputs):
  ```lua
  function ApplyState(object, stateName)
      assert(object, "object is required")
      assert(stateName, "stateName is required")
      assert(type(object.getStates) == "function", "object must support states")
      -- ... apply state ...
  end
  ```
- **Benefits:**
  - Function signature documents exact requirements
  - Misuse fails immediately at call site with clear message
  - No confusion about whether nil/invalid inputs are valid
  - Eliminates redundant validation when callers already check

## Error Handling Philosophy
**Core principle: Better to crash visibly than corrupt data silently.**

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
- **Avoid pcall in production code** - it obscures errors and makes debugging harder:
  - Use assertions/guards to validate conditions instead of catching errors
  - **Acceptable pcall uses (rare):**
    - Protecting against TTS API failures in recoverable contexts (e.g., reading optional deck state)
    - Testing code that expects to catch errors (see `assertError` in test framework)
  - **Document why** when using pcall - add comment explaining what can fail and why it's recoverable
  - If you find yourself catching errors to convert them to nil returns, use guard clauses instead
  - **Never** use pcall to suppress critical failures (save/load, essential resource initialization) - these should fail loudly
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

## Return Values for Async Operations

Functions that orchestrate async operations via callbacks **must still return success/failure indicators**:

```lua
-- ❌ BAD: No return value
function Module.SpawnCard(params)
    Archive.TakeFromDeck({
        name = params.cardName,
        spawnFunc = function(card)
            params.onComplete(card)  -- Result comes via callback
        end
    })
end  -- Returns nil - caller can't tell if operation started

-- ✅ GOOD: Return boolean success
function Module.SpawnCard(params)
    local success = Archive.TakeFromDeck({
        name = params.cardName,
        spawnFunc = function(card)
            params.onComplete(card)  -- Result still via callback
        end
    })
    return success  -- Caller knows if operation initiated
end
```

**Rationale:**
- Even when results come asynchronously, callers need to know if the operation **started successfully**
- Returning boolean allows callers to distinguish "operation pending" from "operation failed to start"
- Consistent with existing patterns in Archive, Strain, and other modules

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

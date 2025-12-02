# Development Process

This document defines the default workflow for making changes to the KDM TTS mod. It complements `CODING_STYLE.md` by focusing on *how* we work rather than the syntax or design details.

## Roles

Each AI chat session operates in exactly one role. Roles have distinct responsibilities and constraints to maintain separation of concerns.

### Product Owner
**Focus:** The "what" and "why"—requirements, priorities, and user value.

**Responsibilities:**
- Gather and clarify requirements from stakeholders
- Write user stories and acceptance criteria
- Prioritize work based on user value and project goals
- Validate that delivered features meet requirements
- Maintain user-facing documentation (README, FAQ, user guides)

**Constraints:**
- Do not edit implementation code or tests
- Do not make architectural decisions (escalate to Architect)
- Do not perform git operations
- Do not override Architect on technical feasibility

### Architect
**Focus:** The "how" at a structural level—system design, patterns, and technical boundaries.

**Responsibilities:**
- Design system structure and module boundaries
- Write and maintain ADRs and `ARCHITECTURE.md`
- Define patterns and abstractions for Implementers to follow
- Evaluate technical feasibility of Product Owner requests
- Identify and document refactoring opportunities

**Constraints:**
- Do not edit implementation code or tests (provide guidance, not code)
- Do not override Product Owner on priorities or requirements
- Do not perform git operations
- Do not conduct code reviews (that's the Reviewer role)

### Implementer
**Focus:** Writing code that fulfills requirements within architectural guidelines.

**Responsibilities:**
- Write and modify implementation code and tests
- Follow patterns established by Architect
- Research existing code before implementing new features
- Produce implementation plans and get confirmation before coding
- Apply guidance from `handover/LATEST_REVIEW.md`

**Constraints:**
- Do not edit `handover/LATEST_REVIEW.md` or review process docs
- Do not perform git operations
- Do not override Architect on design decisions
- Do not change requirements (escalate to Product Owner)

### Reviewer
**Focus:** Quality assurance through code review.

**Responsibilities:**
- Review code changes for correctness, style, and maintainability
- Author and maintain `handover/LATEST_REVIEW.md`
- Update review process documentation
- Follow checklist in `CODE_REVIEW_GUIDELINES.md`

**Constraints:**
- Do not edit implementation code or tests
- Do not perform git operations
- Do not change requirements or architecture

### Debugger
**Focus:** Systematic problem diagnosis and root cause analysis.

**Responsibilities:**
- Investigate runtime errors and unexpected behavior
- Trace execution paths to identify root causes
- Document findings with confidence levels and evidence
- Suggest solutions ranked by effort and risk
- Author and maintain debug reports in `handover/LATEST_DEBUG.md`

**Permitted code changes (debugging only):**
- Add `log:Debugf(...)` statements to trace execution
- Write regression tests that reproduce the bug
- No other code modifications allowed

**Constraints:**
- Do not fix the bug (only diagnose and suggest fixes)
- Do not perform git operations
- Do not change requirements or architecture
- Must provide evidence for conclusions (log output, code references)

### Role Workflow

```
Product Owner          Architect              Implementer           Reviewer
     │                     │                       │                    │
     │  requirements       │                       │                    │
     ├────────────────────►│                       │                    │
     │                     │  technical design     │                    │
     │                     ├──────────────────────►│                    │
     │                     │                       │  implementation    │
     │                     │                       ├───────────────────►│
     │                     │                       │                    │
     │◄────────────────────┼───────────────────────┼────────────────────┤
     │                     │       feedback loop (iterate as needed)    │
```

**Handoff points:**
1. Product Owner validates requirements → Architect designs solution
2. Architect provides design → Implementer codes
3. Implementer completes changes → Reviewer checks
4. Reviewer findings may loop back to any prior role

### Handover Documents

All role-to-role handovers are stored in the `handover/` folder:

| Document | Purpose | Owner |
|----------|---------|-------|
| `LATEST_REVIEW.md` | Most recent code review findings | Reviewer |
| `LATEST_DEBUG.md` | Most recent debug report | Debugger |
| `HANDOVER_ARCHITECT.md` | Requirements handoff to Architect | Product Owner |
| `HANDOVER_IMPLEMENTER.md` | Design handoff to Implementer | Architect |
| `IMPLEMENTATION_STATUS.md` | Snapshot of what portions of the design/requirements have already been implemented | Implementer |

**Guidelines:**
- Each handover/status document is **replaced** (not appended) when a new handover occurs
- Include context, requirements/design, open questions, and relevant files
- The receiving role should read the handover/status documents before starting work. When implementation spans multiple PRs/sprints, update `handover/IMPLEMENTATION_STATUS.md` so future implementers can see exactly what has already landed and what remains.

### Role Boundaries

When the user requests an action outside the current role's responsibilities, **ask for confirmation before proceeding**. For example:
- If acting as Reviewer and asked to debug: "That sounds like Debugger work. Should I switch to the Debugger role?"
- If acting as Debugger and asked to fix code: "Fixing code is Implementer work. Should I switch roles, or would you like me to document the fix in the handover for the Implementer?"

This prevents accidental role violations and keeps the separation of concerns explicit.

## Safety Net First
- **Baseline tests before edits** – confirm existing behavior has automated coverage (unit/integration). If coverage is missing for the code you are about to edit, add characterization tests that express the current behavior before changing logic.
- **Protect regressions** – when a bug is reported, reproduce it in a failing test before touching implementation code. The test should prove the fix and guard against future regressions.
- **Keep tests close to code** – place new specs in `tests/<area>_test.lua` and register them in `tests/run.lua` so they are part of the default `lua tests/run.lua` run.
- **Executable behavior specs** – when work changes a user-visible behavior or acceptance criteria, add/refresh a high-level test (integration/behavior) that documents the intent (the “what”) alongside unit tests that cover “how.” This applies to feature additions, refactors that intentionally change UX, and bug fixes with customer-facing impact.

## Test Strategy

### Integration Tests Over Export Lists

**Principle:** Tests should **execute real call paths** through modules, not check that every function exists.

#### ❌ Avoid: Export-Checking Tests
```lua
-- BAD: Brittle, reactive, no real value
Test.test("Module exports all functions", function(t)
    local Module = require("Module")
    t:assertNotNil(Module.FunctionA)  -- Just checks it exists
    t:assertNotNil(Module.FunctionB)  -- Doesn't verify it works
    -- Problems:
    -- - Only written AFTER discovering a bug
    -- - Fails when refactoring legitimately removes unused exports
    -- - Doesn't verify actual usage or integration
end)
```

#### ✅ Prefer: True Integration Tests
```lua
-- GOOD: Actually executes the integration
Test.test("Strain->Archive card spawning integration", function(t)
    -- Minimal stubs for environment (TTS objects, file I/O)
    setupMinimalTTSStubs()
    
    local Strain = require("Kdm/Strain")
    
    -- ACTUALLY CALL Strain, which calls Archive internally
    local ok = Strain.Test._TakeRewardCard(Strain, {
        name = "Test Card",
        type = "Fighting Arts",
        position = { x = 0, y = 0, z = 0 },
        spawnFunc = function(card)
            -- Verify card was passed through
            t:assertNotNil(card)
        end
    })
    
    -- If Archive.TakeFromDeck isn't exported, this fails naturally
    -- If Strain.Test isn't exported, this fails loading Strain
    t:assertTrue(ok, "Integration should succeed")
end)
```

**What makes this a real integration test:**
- **Executes the actual code path**: Strain → Archive
- **Fails naturally** if exports are missing (attempt to call nil)
- **Self-documenting**: Shows how modules actually work together
- **Self-cleaning**: Remove test when removing the feature
- **Minimal stubbing**: Only stub environment (TTS, I/O), not the modules being tested

### When to Use Stubs vs Real Modules

**Stub environment dependencies:**
- TTS objects and APIs (no real game engine in tests)
- File I/O, network calls
- Time-dependent behavior
- Complex UI rendering

**Use real modules for integration:**
- Business logic calling business logic
- Data transformations
- Module coordination and orchestration

**Critical rule:** Don't stub a module just to avoid "function not exported" errors - that defeats the purpose of the test. If you need to stub the module, you're not writing an integration test anymore.

### TTSSpawner Test Seam Pattern

**Problem:** Missing module exports cause runtime nil errors that are expensive to debug (require TTS launch, 5-10 minute debug cycles, 2-4 hours per bug).

**Solution:** For modules with TTS API dependencies, use the TTSSpawner pattern to enable integration testing without TTS:

1. **Extract TTS calls** into `Util/TTSSpawner.ttslua`
2. **Add test seam** to module: `Module._spawner` field with `Test_SetSpawner()` / `Test_ResetSpawner()`
3. **Write integration tests** that verify exports exist by exercising real call paths

**Example:**
```lua
-- tests/module_integration_test.lua
Test.test("ModuleA→ModuleB: verifies critical exports", function(t)
    local ModuleA = require("Kdm/ModuleA")
    local ModuleB = require("Kdm/ModuleB")
    
    -- If ModuleB.CriticalFunction isn't exported, this fails immediately:
    t:assertNotNil(ModuleB.CriticalFunction, "ModuleB.CriticalFunction must be exported")
    
    -- Error: "ModuleB.CriticalFunction must be exported" (clear, actionable)
    -- NOT: "attempt to call nil value" discovered after hours in TTS
end)
```

**Time savings:** 2-4 hours → <5 minutes per export bug. With 5-10 such bugs per feature, this pays for itself immediately.

**When to use:**
- Modules with direct TTS API calls (`takeObject`, `Physics.cast`)
- Cross-module integration points prone to export bugs
- Historical sources of "attempt to call nil value" errors

**Current implementations:** See `Archive.ttslua`, `Util/TTSSpawner.ttslua`, `tests/stubs/tts_spawner_stub.lua`

## Implementation Intake
- **Research first** – when a new implementation task arrives, pause coding and investigate existing behavior, architecture notes, and related files/tests so the forthcoming plan is grounded in facts rather than assumptions.
- **Prefer existing patterns** – before implementing a new feature, look for similar functionality in the repo. When overlap exists, follow this loop:
  1. Secure the current behavior with characterization tests so the existing workflow is documented and protected.
  2. Extract the shared logic into a well-named, reusable abstraction.
  3. Keep legacy behavior green (tests passing) as you migrate it to the new abstraction.
  4. Implement the new feature on top of the abstraction, extending it as needed without breaking the original flow.
- **Fail loudly over speculative fallbacks** – when a required resource (data deck, object, config, etc.) is missing, surface an explicit error and stop rather than silently falling back to unrelated sources. Only add defensive fallback paths when the Product Owner, Architect, or a requirement explicitly demands it, and document the rationale in the code/comments.
- **Produce a plan** – write down the proposed approach (touch points, test strategy, migration steps) alongside all assumptions and open questions that could influence the solution.
- **Share before coding** – present that plan to the reviewer/requester and wait for explicit confirmation before touching production code. Only start implementation work after all blocking questions are answered or assumptions validated.
- **Debug runtime errors systematically** – when an error occurs at runtime (especially unexpected nil errors), verify your assumptions about why and where the error happens before fixing it. The preferred approach is to implement at least one regression test that reproduces the error. If that doesn't help pinpoint the problem, use extensive debug logging and ask the user to run the code on TTS and provide the relevant part of the log.
- **Use debug logging when stuck** – when a TTS error is unclear (e.g., only visible in the in-game console), add targeted `log:Debugf(...)` statements near the failing code path to surface argument values and flow. Enable the relevant module temporarily by uncommenting it under `Log.DEBUG.MODULES` in `Log.ttslua`, and remember to disable the extra logging once finished.
- **Resist assumptions when debugging** – when encountering runtime errors, especially "attempt to call a nil value" errors, resist the urge to immediately implement complex solutions. Instead: (1) Add debug logging at the error point to verify what is actually nil, (2) Work backward from the error with targeted logging to trace the execution path, (3) Test simple hypotheses first before architectural changes. Often the root cause is simpler than initial assumptions suggest (e.g., a missing function rather than a module loading issue).
- **One role per chat (read-only git state)** – every chat operates in exactly one role (see Roles section above). Roles have distinct permissions and constraints—respect them strictly. No role may perform git operations; keep duties separate.
- **Fail fast and meaningfully** – every subsystem must validate its inputs and surface actionable errors as close to the source as possible. Guard clauses and descriptive log messages are preferred over silent fallbacks so that regressions are obvious and easy to diagnose.
- **Use shared UI palette and components** – all dialogs and panels should rely on the palette constants defined in `Ui.ttslua` (for example, `Ui.CLASSIC_BACKGROUND`, `Ui.CLASSIC_HEADER`, `Ui.CLASSIC_SHADOW`, and `Ui.CLASSIC_BORDER`) and the reusable PanelKit helpers (such as `PanelKit.ClassicDialog`). This keeps borders, backgrounds, and opacity consistent and makes visual regressions obvious during tests and reviews.
- **Respect defaults unless intentionally deviating** – when any shared component (UI or otherwise) exposes a default behavior, consume it rather than overriding it by habit. Only diverge when there is a concrete, reviewed requirement so deviations stay obvious in code review.
- **Keep exported interfaces lean** – don’t expose new parameters, flags, or configuration points unless client code demonstrably needs them. Lean interfaces are easier to reason about, make later deviations more visible, and reduce the chance of inconsistent behavior.

## Role-Specific Documentation

Detailed process documentation for each role is in the `ROLES/` directory:
- `ROLES/DEBUGGER.md` - Debugging patterns, logging, handover format, role boundaries

## Test-First Loop
1. **Plan** – clarify the intent of the change (behavior, data shape, UI outcome) and note which modules are involved. Update or create ADRs/notes if the change affects architecture decisions.
2. **Specify** – write or extend the relevant test so it fails for the current implementation. If touching multiple layers, prefer starting with the highest-value test and add focused unit tests if needed.
3. **Implement** – modify the production code in small, reviewed commits while keeping tests red/green visible. Prioritize self-explanatory code (clear names, types, constants, structure) over added documentation; only document when code cannot carry the intent alone. When fixing a bug or untested path, first add/adjust a failing test that reproduces it before changing code.
4. **Verify** – run `lua tests/run.lua` (and any scenario scripts) until everything passes. If the change affects Tabletop Simulator behavior (especially TTS console commands, UI interactions, or Archive/deck operations), run `updateTTS.sh` and perform manual verification in TTS—unit tests alone are insufficient for TTS-specific functionality.
5. **Refine** – after green tests, scan for smells (brittle test setup, hidden dependencies, duplication) and introduce/refine seams or small refactors while keeping tests green; then re-verify. Apply the Boy Scout Rule: whenever you edit a file, leave it slightly better (naming, structure, guard clauses, comments, tests). If you uncover a larger refactor that is risky to tackle immediately, document it (see Architecture “Future Refactor Opportunities”) so we don’t lose the insight.

## Code Review Documentation

All code review findings must be documented in `handover/LATEST_REVIEW.md`.

**Important:** Each new review **completely replaces** the previous content—the file always contains only the most recent review, never historical reviews.

**Reviewer responsibility:** At the end of every review (even informal ones), update and replace the review file yourself—do not defer to others or leave TODOs. Treat the file update as part of “done” for the review.

**Structure:**
- Start with a header: `# Code Review - [Brief Description]`
- Include date, list of changes (new/modified files)
- Document positive aspects, issues found, and recommendations
- Conclude with overall assessment and test results

**Guidelines:**
- **Do not create temporary files** for review summaries—always write to `handover/LATEST_REVIEW.md`
- **Replace the entire file** with each new review; do not append
- Keep review documentation in the repository, not external files
- Use clear severity labels (Low/Medium/High) for issues
- Include specific examples and line references where helpful
- Document any follow-up actions taken in response to the review
- Follow the detailed review checklist in `CODE_REVIEW_GUIDELINES.md`

**Handling review suggestions**
- **Assess everything** – When a review surfaces suggestions, evaluate each one. For low-risk / high-value requests (copy tweaks, text changes, small refactors), apply them immediately so we leave the code slightly better (Boy Scout Rule).
- **Act, defer, or decline** – If a change is deferred or intentionally skipped, add the rationale in the review reply (or a comment) so we maintain context.
- **Track follow-ups** – Document deferred items in `ARCHITECTURE.md` (Future Refactor Opportunities) or the relevant backlog so ideas aren’t lost. Update process/docs when reviews uncover gaps.

## Git Workflow

**Commits are managed exclusively by human maintainers:**
- AI assistants must not perform git operations (add, commit, push, pull, etc.)
- Code changes should be prepared and ready for commit but not automatically committed
- The human maintainer will review all changes and create appropriate commit messages
- AI assistants should focus on code implementation and testing, not git state management

## Pull Request Checklist
- [ ] All affected docs updated (`README.md`, `CODING_STYLE.md`, ADRs, UI instructions, etc.).
- [ ] Code reads as self-explanatory as possible (clear names/structures/constants instead of magic values); documentation added only where code cannot be made clear enough.
- [ ] Tests exist for every new or changed behavior and the full suite passes locally.
- [ ] Behavior/acceptance tests exist or were updated for any functional requirement changes.
- [ ] Manual verification performed when the change affects TTS interactions or UI.
- [ ] Commits tell a reviewable story (separate refactors from behavior changes when practical).
- [ ] After each new code review, assess suggested improvements; implement beneficial recommendations promptly rather than deferring them indefinitely, and document rationale when choosing not to act. When a review identifies process/documentation gaps (e.g., missing guidance or ADRs), update the relevant documentation as part of addressing the review.
- [ ] Code review findings documented in `handover/LATEST_REVIEW.md`.

Following this process keeps the mod safe to iterate on, makes regressions obvious, and ensures contributors can trust each other’s changes without rediscovering tribal knowledge.

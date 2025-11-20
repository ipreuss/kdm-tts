# Development Process

This document defines the default workflow for making changes to the KDM TTS mod. It complements `CODING_STYLE.md` by focusing on *how* we work rather than the syntax or design details.

## Safety Net First
- **Baseline tests before edits** – confirm existing behavior has automated coverage (unit/integration). If coverage is missing for the code you are about to edit, add characterization tests that express the current behavior before changing logic.
- **Protect regressions** – when a bug is reported, reproduce it in a failing test before touching implementation code. The test should prove the fix and guard against future regressions.
- **Keep tests close to code** – place new specs in `tests/<area>_test.lua` and register them in `tests/run.lua` so they are part of the default `lua tests/run.lua` run.
- **Executable behavior specs** – when work changes a user-visible behavior or acceptance criteria, add/refresh a high-level test (integration/behavior) that documents the intent (the “what”) alongside unit tests that cover “how.” This applies to feature additions, refactors that intentionally change UX, and bug fixes with customer-facing impact.

## Implementation Intake
- **Research first** – when a new implementation task arrives, pause coding and investigate existing behavior, architecture notes, and related files/tests so the forthcoming plan is grounded in facts rather than assumptions.
- **Produce a plan** – write down the proposed approach (touch points, test strategy, migration steps) alongside all assumptions and open questions that could influence the solution.
- **Share before coding** – present that plan to the reviewer/requester and wait for explicit confirmation before touching production code. Only start implementation work after all blocking questions are answered or assumptions validated.
- **Use debug logging when stuck** – when a TTS error is unclear (e.g., only visible in the in-game console), add targeted `log:Debugf(...)` statements near the failing code path to surface argument values and flow. This is often faster than guessing and helps pinpoint nils/missing callbacks during load.

## Test-First Loop
1. **Plan** – clarify the intent of the change (behavior, data shape, UI outcome) and note which modules are involved. Update or create ADRs/notes if the change affects architecture decisions.
2. **Specify** – write or extend the relevant test so it fails for the current implementation. If touching multiple layers, prefer starting with the highest-value test and add focused unit tests if needed.
3. **Implement** – modify the production code in small, reviewed commits while keeping tests red/green visible. Prioritize self-explanatory code (clear names, types, constants, structure) over added documentation; only document when code cannot carry the intent alone. When fixing a bug or untested path, first add/adjust a failing test that reproduces it before changing code.
4. **Verify** – run `lua tests/run.lua` (and any scenario scripts) until everything passes. If the change affects Tabletop Simulator behavior, run `updateTTS.sh` and perform a quick manual smoke test.
5. **Refine** – after green tests, scan for smells (brittle test setup, hidden dependencies, duplication) and introduce/refine seams or small refactors while keeping tests green; then re-verify.

## Code Review Documentation

All code review findings must be documented in `LATEST_REVIEW.md` at the repository root.

**Important:** Each new review **completely replaces** the previous content—`LATEST_REVIEW.md` always contains only the most recent review, never historical reviews.

**Reviewer responsibility:** At the end of every review (even informal ones), update and replace `LATEST_REVIEW.md` yourself—do not defer to others or leave TODOs. Treat the file update as part of “done” for the review.

**Structure:**
- Start with a header: `# Code Review - [Brief Description]`
- Include date, list of changes (new/modified files)
- Document positive aspects, issues found, and recommendations
- Conclude with overall assessment and test results

**Guidelines:**
- **Do not create temporary files** for review summaries—always write to `LATEST_REVIEW.md`
- **Replace the entire file** with each new review; do not append
- Keep review documentation in the repository, not external files
- Use clear severity labels (Low/Medium/High) for issues
- Include specific examples and line references where helpful
- Document any follow-up actions taken in response to the review

**Example:**
```markdown
# Code Review - Feature Name

## Date
2025-11-18

## Changes
- Modified: Feature.lua
- New: tests/feature_test.lua

## Positive Aspects
...

## Issues & Recommendations
...

## Summary
Overall Assessment: ✅ Approved
```

## Pull Request Checklist
- [ ] All affected docs updated (`README.md`, `CODING_STYLE.md`, ADRs, UI instructions, etc.).
- [ ] Code reads as self-explanatory as possible (clear names/structures/constants instead of magic values); documentation added only where code cannot be made clear enough.
- [ ] Tests exist for every new or changed behavior and the full suite passes locally.
- [ ] Behavior/acceptance tests exist or were updated for any functional requirement changes.
- [ ] Manual verification performed when the change affects TTS interactions or UI.
- [ ] Commits tell a reviewable story (separate refactors from behavior changes when practical).
- [ ] After each new code review, assess suggested improvements; implement beneficial recommendations promptly rather than deferring them indefinitely, and document rationale when choosing not to act. When a review identifies process/documentation gaps (e.g., missing guidance or ADRs), update the relevant documentation as part of addressing the review.
- [ ] Code review findings documented in `LATEST_REVIEW.md`.

Following this process keeps the mod safe to iterate on, makes regressions obvious, and ensures contributors can trust each other’s changes without rediscovering tribal knowledge.

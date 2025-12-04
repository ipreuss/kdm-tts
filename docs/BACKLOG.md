# Product Backlog

This backlog captures feature ideas and improvements for future consideration. Items are added as they arise and prioritized during planning.

**Owner:** Product Owner  
**Last Updated:** 2025-12-04

## Backlog Items

| ID | Area | Description | Priority | Status | Notes |
|----|------|-------------|----------|--------|-------|
| 1 | Strain Milestones | Auto-spawn disorder, injury, and strange resource cards (like fighting arts) instead of requiring manual search | P2 | In Progress | Currently these are manual steps shown in confirmation dialog; spawning cards would improve UX consistency |
| 2 | Strain Milestones | Add "Atmospheric Change" strain milestone | P1 | Done | Completed 2025-12-04; all acceptance tests passing |
| 3 | Strain Milestones | Fix undo dialog text for non-fighting-art milestones | P1 | Done | Completed 2025-12-04; `BuildUndoMessage()` generates dynamic text based on actual consequences |
| 4 | Code Quality | Strain module SOLID refactoring | P2 | Done | Completed 2025-12-04; extracted `ConsequenceApplicator` module (110 lines, 10 methods). Both `Strain` and `Campaign` now delegate to it. Code duplication eliminated. |
| 5 | Testing | Acceptance tests should exercise ExecuteConsequences/ReverseConsequences (Phase 1) | P2 | Done | Completed 2025-12-04; `startNewCampaign()` calls real `AddStrainRewards()`, `deckContains()` simplified to spy-only queries (~12 lines). All code paths now go through spies. |
| 6 | Gear | Pattern gear implementation | P1 | New | High priority — details TBD |

## Epics

Larger features that will need breakdown into smaller items.

| ID | Epic | Description | Priority | Status |
|----|------|-------------|----------|--------|
| E1 | White Gigalion | Full support for White Gigalion expansion | — | New |
| E2 | Killenium Butcher | Implementation of Killenium Butcher nemesis | — | New |
| E3 | Nukealope | Implementation of Nukealope quarry/nemesis | — | New |
| E4 | Black Knight + Squires | Black Knight nemesis including Squires campaign | — | New |

## Priority Legend

- **P1** — High value, implement soon
- **P2** — Medium value, implement when capacity allows
- **P3** — Low value or nice-to-have
- **—** — Not yet prioritized

## Status Legend

- **New** — Idea captured, not yet analyzed
- **Ready** — Analyzed and ready for implementation
- **In Progress** — Currently being worked on
- **Done** — Implemented (move to feature spec)
- **Deferred** — Intentionally postponed
- **Rejected** — Decided not to implement (document reason)

## Process

1. Anyone can add ideas to this backlog
2. Product Owner reviews and prioritizes periodically
3. Items marked "Ready" can be picked up by Architect for design
4. Completed items are removed and documented in the relevant feature spec

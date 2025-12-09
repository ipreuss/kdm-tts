# Acceptance Testing Guidelines

For comprehensive acceptance testing patterns, see the **`kdm-test-patterns`** skill (auto-loads when writing tests).

The skill covers test principles, TestWorld patterns, naming conventions, and the "real code not duplicate logic" requirement.

---

## Project-Specific Scope

### In Scope (Headless Acceptance Tests)

- **Business logic and state transitions** — rewards added to decks, timeline events scheduled
- **Game rules** — max 5 fighting arts, milestone consequences applied correctly
- **Data integrity** — milestone data loads, rewards match milestones

### Out of Scope (TTS Console Tests)

- **UI interactions** — dialogs, buttons, checkbox clicks
- **Log messages** — console output, debug logs
- **Card spawning visuals** — physical card placement, animations
- **TTS object manipulation** — deck operations, archive access

UI behavior is verified via TTS console tests (`>testall`, `>testfocus`). See `TTSTests.ttslua` for the snapshot/action/restore pattern.

---

## File Organization

```
tests/acceptance/
├── test_world.lua              # TestWorld facade
├── tts_environment.lua         # TTS stub management
├── test_tts_adapter.lua        # Fake TTS adapter for tracking
├── archive_spy.lua             # Archive module spies for verification
├── walking_skeleton_test.lua   # Infrastructure proof
├── strain_acceptance_test.lua  # Strain milestone scenarios
└── campaign_setup_test.lua     # Campaign scenarios (future)
```

---

## Known Gaps

### Code Duplication: `ExecuteConsequences` vs `AddStrainRewards`

**Issue:** Both contain similar archive interaction logic.

**Status:** Documented as Backlog Item #6 (Phase 2). Extract shared `ConsequenceApplicator` module.

# Testing Strategy

For comprehensive testing patterns, see the **`kdm-test-patterns`** skill (auto-loads when writing or reviewing tests).

The skill covers:
- Test hierarchy (unit, integration, acceptance, TTS console)
- Behavioral vs structural tests
- Real data vs mock data decisions
- TTSSpawner test seam pattern
- Spy/stub patterns
- Cross-module integration testing
- TTS console test patterns

---

## Quick Reference

**Commands:**
```bash
lua tests/run.lua          # Run all headless tests (~2 seconds)
```

**TTS Console:**
| Command | Purpose |
|---------|---------|
| `>testall` | Run all TTS tests |
| `>testrun <name>` | Run single test by exact name |
| `>testsuite <bead>` | Run all tests for a bead |
| `>testsuite list` | List beads with test counts and titles |
| `>testsuite domains` | List domains with test counts |
| `>testsuite domain <name>` | Run all tests for a domain |
| `>testcurrent` | Run tests for FOCUS_BEAD only |
| `>testpriority` | Run FOCUS_BEAD first, then others if pass |
| `>testerrordetect` | Verify error log detection works (intentional failure test) |
| `>testhelp` | Show all available test commands |

---

## Test File Structure

```
tests/
├── run.lua                    # Test runner (register new tests here!)
├── framework.lua              # Test framework
├── support/
│   └── bootstrap.lua          # Test environment setup
├── stubs/
│   ├── tts_stubs.lua          # TTS API stubs
│   ├── ui_stubs.lua           # UI stubs
│   └── tts_spawner_stub.lua   # TTSSpawner stub
├── acceptance/
│   ├── test_world.lua         # TestWorld facade
│   └── *_acceptance_test.lua  # Acceptance tests
└── *_test.lua                 # Unit/integration tests
```

**Critical:** Register new test files in `tests/run.lua` or they won't run!

---

## TTS Test Registration

TTS console tests require two-step registration:

1. **Add test function** in `TTSTests/<Area>Tests.ttslua`
2. **Register in `ALL_TESTS`** in `TTSTests/TestRegistry.ttslua`:
   ```lua
   { name = "Test Name", bead = "kdm-xxx", domain = "showdown", fn = function(onComplete) ... end },
   ```

**Fields:**
- `name` — Test name (required)
- `bead` — Bead ID or array of IDs for `>testsuite <bead>` (optional)
- `domain` — Functional area: settlement, showdown, hunt, campaign, survivor, ui (optional)
- `fn` — Test function with `onComplete` callback (required)

Tests without a `bead` field are regression tests (run with `>testall` only).

---

## Verification Test Pattern

**For tests that must intentionally fail** (e.g., verifying detection mechanisms work):

1. **Keep separate from `ALL_TESTS`** — Don't add to `>testall` suite
2. **Create dedicated command** — e.g., `>testerrordetect`
3. **Interpret failure as success** — Command reports PASSED when test fails as expected

**Example:** Error log detection verification (`>testerrordetect`)
- Test intentionally logs an error and expects the framework to detect it
- If test reports FAILED → error detection works → verification PASSED
- If test reports PASSED → error detection broken → verification FAILED

**Why this pattern?** Including intentional-failure tests in `>testall` would always show failures, causing confusion. Dedicated commands make the intent clear.

---

## Current Test Seam Implementations

| Module | Seam | Stub |
|--------|------|------|
| Archive | `Archive.Test_SetSpawner()` | `tts_spawner_stub.lua` |
| UI modules | N/A | `ui_stubs.lua` |

For workflow, see `PROCESS.md`. For code conventions, see `CODING_STYLE.md`.

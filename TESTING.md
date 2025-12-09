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
| `>testfocus` | Run tests for current bead only |

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
2. **Register in `ALL_TESTS`** in `TTSTests.ttslua`:
   ```lua
   { name = "Test Name", bead = "kdm-xxx", fn = function(onComplete) ... end },
   ```

Tests without a `bead` field are regression tests (run with `>testall` only).

---

## Current Test Seam Implementations

| Module | Seam | Stub |
|--------|------|------|
| Archive | `Archive.Test_SetSpawner()` | `tts_spawner_stub.lua` |
| UI modules | N/A | `ui_stubs.lua` |

For workflow, see `PROCESS.md`. For code conventions, see `CODING_STYLE.md`.

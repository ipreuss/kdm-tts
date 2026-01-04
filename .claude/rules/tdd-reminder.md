---
paths: ["**/*.ttslua", "tests/**/*.lua"]
---

# TDD Reminder

## Iron Law

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST**

If code precedes tests, delete it and start over.

## Before Changing Code

1. **Coverage Assessment** - Not "do tests exist?" but "is coverage GOOD?"
2. For each function you will modify:
   - Tests exist for this function?
   - Tests cover the code path being changed?
   - Tests verify the behavior being preserved?
3. **If no** → Add characterization tests BEFORE changes

## Red-Green-Refactor

1. **RED**: Write ONE failing test
2. **Verify FAIL**: Run `lua tests/run.lua` - must fail for expected reason
3. **GREEN**: Write MINIMAL code to pass
4. **Verify PASS**: Run tests - must pass
5. **REFACTOR**: Clean up while keeping tests green
6. **COVERAGE REVIEW**: Need more unit/integration tests?

## Bug Found Mid-Development?

**STOP. Write test FIRST.**

| Change Type | Test Level |
|-------------|------------|
| Internal logic | Unit test |
| Module interaction | Integration test |
| User-visible | Acceptance test |
| TTS-specific | TTS console test |

## Full Reference

See `test-driven-development` skill for complete workflow and examples.

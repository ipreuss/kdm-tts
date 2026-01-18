---
name: tts-console-testing
description: Writing and running TTS console tests for in-game verification. Use when writing TTS tests, using testall/testcurrent commands, verifying TTS-specific behavior, or setting up FOCUS_BEAD. Triggers on TTS test, testall, testcurrent, console test, TTS verification, FOCUS_BEAD, TTSTests.
---

# TTS Console Testing

Patterns for writing automated tests that run inside Tabletop Simulator.

## When TTS Tests Are Needed

TTS console tests are needed when headless tests are insufficient:
- UI rendering and visibility
- Object spawning and positioning
- Card manipulation (flip, move)
- Archive operations with real TTS objects
- Visual verification requirements

## Test Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `>testall` | Run all TTS tests (~13 tests) | Before closing a bead, after major changes |
| `>testrun <name>` | Run single test by exact name | Testing one specific test |
| `>testcurrent` | Run only tests for FOCUS_BEAD | During active development |
| `>testpriority` | Run FOCUS_BEAD first, then others | Quick verification before testall |

### Focused Testing Workflow

1. When starting work on a bead, update `FOCUS_BEAD` in `TTSTests.ttslua`
2. Use `>testcurrent` during development for fast feedback
3. Run `>testall` before marking work complete

```lua
local FOCUS_BEAD = "kdm-xxx"  -- Update to current bead
```

## Test Registration (Two Steps Required)

### Step 1: Register console command

In module file (`TTSTests/<Module>Tests.ttslua`):

```lua
function ModuleTests.Register()
    Console.AddCommand("testfeature", function(args)
        ModuleTests.TestFeatureName()
    end, "Description for help text")
end
```

### Step 2: Add to ALL_TESTS registry

In `TTSTests.ttslua`:

```lua
local ALL_TESTS = {
    -- ...existing tests...
    { name = "Feature Name", bead = "kdm-xxx", fn = function(onComplete)
        ModuleTests.TestFeatureName(onComplete)
    end },
}
```

## Tagging Tests with Beads

```lua
-- Single bead (string):
{ name = "White Lion Rewards", bead = "kdm-w1k", fn = ... },

-- Multiple beads (array):
{ name = "White Lion Rewards", bead = { "kdm-w1k", "kdm-rhc" }, fn = ... },
```

Tests with multiple beads run when ANY of their beads match `FOCUS_BEAD`.

## Test Pattern: Snapshot/Action/Restore

```lua
function ModuleTests.TestSomething(onComplete)
    log:Printf("=== TEST: TestSomething ===")

    -- 1. Save initial state (optional)
    local before = countSomething()

    -- 2. Perform action (call real public API)
    Showdown.Setup("White Lion", "Level 1")

    -- 3. Wait for async operations
    Wait.frames(function()
        -- 4. Verify outcome (user-visible result)
        local passed = checkCondition()

        log:Printf("TEST RESULT: %s", passed and "PASSED" or "FAILED")
        if onComplete then onComplete(passed) end
    end, 30)  -- Wait frames for async operations
end
```

## Test Pattern with Wait.condition

For tests that need to wait for a specific state:

```lua
Showdown.Setup("White Lion", "Level 1")
Wait.condition(function()
    return ResourceRewards.IsButtonVisible()
end, function()
    if ResourceRewards.IsButtonVisible() then
        log:Printf("TEST RESULT: PASSED")
    else
        log:Printf("TEST RESULT: FAILED - button not visible")
    end
    onComplete()
end)
```

## Anti-Pattern: Data Validation Masquerading as Integration Test

```lua
-- BAD: Only validates data exists - never tests actual feature
local monster = Showdown.Test.MonsterByName("White Lion")
local level = findLevelByName(monster, "Level 1")
local rewards = level.showdown.resources
if rewards.basic == 4 and rewards.monster == 4 then
    log:Printf("TEST RESULT: PASSED")
end
-- Problem: Test passes even if button never appears because setup code is broken
```

## Proper Integration Test

```lua
-- GOOD: Calls real entry point, events fire naturally, verifies user-visible outcome
Showdown.Setup("White Lion", "Level 1")  -- Real API, events fire naturally
Wait.condition(function()
    return ResourceRewards.IsButtonVisible()  -- User-visible outcome
end)
if ResourceRewards.IsButtonVisible() then
    log:Printf("TEST RESULT: PASSED")
end
```

**Why this matters:** Data validation tests give false confidence. Real integration tests catch: event handlers not registered, module state not set before events, async timing issues, UI not updated after operations.

## TTS Visual Verification

When handing off UI features to Product Owner, include evidence that the UI renders correctly:
- Screenshot showing the element in TTS
- Or reference to passing TTS console test that verifies visibility

"Tests pass" is not sufficient for UI — show it works.

## Hunt Track Layout Verification

**Problem:** Hunt track layouts vary by monster and level. Tests hardcoding positions based on incorrect memory fail.

**Solution:** Always verify track layout before hardcoding positions:

1. Read `Expansion/Core.ttslua` to verify track layout
2. Note monster figurine positions (can cause collisions)
3. Don't assume "empty spaces" — verify what's actually there

Example: White Lion Level 1 track is `M,M,H,H,M,O,H,M,M,H,H` — position 6 is the only 'O'.

## Simulating Drops in Tests

Use `setPosition()` + `Location.OnEnter()` to simulate drops:

```lua
local function simulateDrop(object, location)
    local targetPos = location:Center()
    targetPos.y = targetPos.y + 1
    object.setPosition(targetPos)
    Location.OnEnter(object)  -- Triggers drop handlers
end
```

This tests the full integration path rather than bypassing drop handler registration.

## TTS Console Lowercases Input

**Problem:** TTS console automatically lowercases all user input.

**Impact:** Commands taking user-provided strings must use case-insensitive matching:

```lua
-- WRONG: Case-sensitive comparison
if input == testName then

-- CORRECT: Case-insensitive comparison
if string.lower(input) == string.lower(testName) then
```

## TTS Console Output Timing

**Problem:** When analyzing TTS console output with multiple game loads, test results may be from OLD code, not current changes.

**How to verify:**
1. Find the **last** "Loading complete" message in console output
2. Only test results **AFTER** this timestamp are from current code
3. Results **BEFORE** are from previous code versions — ignore them

**Common mistake:** Analyzing test failures that occurred before the latest `./updateTTS.sh` and game reload. Always check timing first.

## File Organization

```
TTSTests/
├── TTSTests.ttslua          # Main registry, testall/testcurrent/testpriority commands
├── ResourceRewardsTests.ttslua
├── HuntTests.ttslua
└── <Module>Tests.ttslua     # Module-specific test files
```

**CRITICAL:** New test files must be registered in both:
1. The module's `Register()` function (for console commands)
2. `TTSTests.ttslua` ALL_TESTS table (for testall/testcurrent)

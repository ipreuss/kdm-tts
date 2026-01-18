# TTSTests - TTS Console Integration Tests

## Running Tests
In TTS chat console:
```
>testall              # Run all tests
>testrun <name>       # Run single test by exact name
>testcurrent          # Run tests for FOCUS_BEAD
>testpriority         # FOCUS_BEAD first, then all
```

## Structure
- `TestRegistry.ttslua` - Test runner and registration
- `TestSetup.ttslua` - Common test setup utilities
- `TestErrorCapture.ttslua` - Error capture for assertions
- `*Tests.ttslua` - Test suites by domain

## Writing Tests
```lua
local Tests = {}

function Tests.testSomething()
    -- Setup
    local obj = Archive.Take({ ... })

    -- Verify
    assert(obj ~= nil, "Object should spawn")
    assert(obj.getName() == "Expected Name")
end

return Tests
```

## Test Registration
Tests auto-register when file is required:
```lua
-- In TestRegistry.ttslua
local BattleTests = require("Kdm/TTSTests/BattleTests")
RegisterTests("Battle", BattleTests)
```

## FOCUS_BEAD
Set `FOCUS_BEAD = "kdm-xxx"` in TestSetup to run only tests for specific bead.

## Best Practices
- Test TTS-specific behavior (UI, spawning, physics)
- Use headless tests for pure logic
- Clean up spawned objects in tests

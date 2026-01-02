# tests - Headless Unit & Acceptance Tests

## Structure
```
tests/
├── acceptance/     # Acceptance tests with TestWorld
├── stubs/          # Mock/stub implementations
├── support/        # Test helpers and utilities
└── *_test.lua      # Unit test files
```

## Running Tests
```bash
busted tests/           # Run all tests
busted tests/foo_test.lua  # Run specific test file
```

## Test Patterns

### Unit Tests
```lua
describe("ModuleName", function()
    it("should do something", function()
        local result = Module.DoSomething()
        assert.are.equal(expected, result)
    end)
end)
```

### Acceptance Tests (TestWorld)
```lua
describe("ACCEPTANCE: Feature Name", function()
    local world

    before_each(function()
        world = TestWorld.Create()
    end)

    it("verifies user-visible behavior", function()
        world:SetupCampaign("People of the Lantern")
        world:StartHunt("White Lion", 1)
        assert.is_true(world:IsInPhase("hunt"))
    end)
end)
```

## Stubs
- `stubs/tts_stub.lua` - TTS API mock
- `stubs/archive_stub.lua` - Archive spawning mock

## Best Practices
- Test behavior, not implementation
- Use domain language in acceptance tests
- Prefer TestWorld for integration scenarios

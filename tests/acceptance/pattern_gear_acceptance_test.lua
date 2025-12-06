---------------------------------------------------------------------------------------------------
-- Pattern Gear Acceptance Tests
--
-- Tests for Pattern Gear System (Backlog Item #6) user-visible behavior.
--
-- These tests follow the established pattern:
--   1. TestWorld injects spies at TTS boundary (Archive modules)
--   2. TestWorld calls REAL production code (Campaign.Import)
--   3. Tests verify outcomes via spy records
--
-- SCOPE:
--   - Pattern decks are created during campaign import
--   - Correct shuffle behavior (Seed Patterns shuffled, Patterns not shuffled)
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local TestWorld = require("tests.acceptance.test_world")

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Campaign Import creates pattern decks
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: new campaign creates Seed Patterns deck", function(t)
    local world = TestWorld.create()

    world:importCampaign()  -- Calls REAL Campaign.Import code

    t:assertTrue(world:deckExists("Seed Patterns"),
        "Seed Patterns deck should be created during campaign import")

    world:destroy()
end)

Test.test("ACCEPTANCE: new campaign creates Patterns deck", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertTrue(world:deckExists("Patterns"),
        "Patterns deck should be created during campaign import")

    world:destroy()
end)

Test.test("ACCEPTANCE: new campaign creates Seed Pattern Gear deck", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertTrue(world:deckExists("Seed Pattern Gear"),
        "Seed Pattern Gear deck should be created during campaign import")

    world:destroy()
end)

Test.test("ACCEPTANCE: new campaign creates Pattern Gear deck", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertTrue(world:deckExists("Pattern Gear"),
        "Pattern Gear deck should be created during campaign import")

    world:destroy()
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Shuffle behavior
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Seed Patterns deck is shuffled during import", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertTrue(world:deckWasShuffled("Seed Patterns"),
        "Seed Patterns deck should be shuffled")

    world:destroy()
end)

Test.test("ACCEPTANCE: Patterns deck is NOT shuffled during import", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertFalse(world:deckWasShuffled("Patterns"),
        "Patterns deck should NOT be shuffled")

    world:destroy()
end)

Test.test("ACCEPTANCE: Seed Pattern Gear deck is NOT shuffled during import", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertFalse(world:deckWasShuffled("Seed Pattern Gear"),
        "Seed Pattern Gear deck should NOT be shuffled")

    world:destroy()
end)

Test.test("ACCEPTANCE: Pattern Gear deck is NOT shuffled during import", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertFalse(world:deckWasShuffled("Pattern Gear"),
        "Pattern Gear deck should NOT be shuffled")

    world:destroy()
end)

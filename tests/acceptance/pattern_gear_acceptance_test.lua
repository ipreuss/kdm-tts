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

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Pattern cards in settlement storage (Export/Import)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: pattern card in settlement storage is restored on import", function(t)
    local world = TestWorld.create()

    -- Import campaign with a Seed Pattern card in Settlement Resource storage
    world:importCampaign({
        objectsByLocation = {
            ["Settlement Resource 3"] = {
                { name = "Hollowlink Pumpkin", type = "Seed Patterns", tag = "Card" }
            }
        }
    })

    t:assertTrue(world:objectWasSpawned("Hollowlink Pumpkin", "Seed Patterns"),
        "Seed Pattern card should be spawned from settlement storage")

    world:destroy()
end)

Test.test("ACCEPTANCE: Patterns card in settlement storage is restored on import", function(t)
    local world = TestWorld.create()

    -- Import campaign with a Patterns card in Settlement Resource storage
    world:importCampaign({
        objectsByLocation = {
            ["Settlement Resource 5"] = {
                { name = "Voluptuous Bodysuit", type = "Patterns", tag = "Card" }
            }
        }
    })

    t:assertTrue(world:objectWasSpawned("Voluptuous Bodysuit", "Patterns"),
        "Patterns card should be spawned from settlement storage")

    world:destroy()
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Pattern gear in settlement storage (Export/Import)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: pattern gear in settlement gear storage is restored on import", function(t)
    local world = TestWorld.create()

    -- Import campaign with Pattern Gear in Settlement Gear storage
    -- Pattern Gear has type "Gear" (not "Pattern Gear")
    world:importCampaign({
        objectsByLocation = {
            ["Settlement Gear 2"] = {
                { name = "Screaming Costume", type = "Gear", tag = "Card" }
            }
        }
    })

    t:assertTrue(world:objectWasSpawned("Screaming Costume", "Gear"),
        "Pattern gear should be spawned from settlement gear storage")

    world:destroy()
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Equipped pattern gear on survivors (Export/Import)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: equipped pattern gear on survivor is restored on import", function(t)
    local world = TestWorld.create()

    -- Import campaign with Pattern Gear equipped on a survivor
    world:importCampaign({
        objectsByLocation = {
            ["Player 1 Gear 5"] = {
                { name = "Brazen Bat", type = "Gear", tag = "Card" }
            }
        }
    })

    t:assertTrue(world:objectWasSpawned("Brazen Bat", "Gear"),
        "Equipped pattern gear should be spawned on survivor")

    world:destroy()
end)

Test.test("ACCEPTANCE: multiple pattern cards across locations are restored on import", function(t)
    local world = TestWorld.create()

    -- Import campaign with pattern cards in multiple locations
    world:importCampaign({
        objectsByLocation = {
            ["Settlement Resource 1"] = {
                { name = "Dextral Crabaxe", type = "Seed Patterns", tag = "Card" }
            },
            ["Settlement Gear 4"] = {
                { name = "Sword of Doom", type = "Gear", tag = "Card" }
            },
            ["Player 2 Gear 3"] = {
                { name = "Mighty Bone Axe", type = "Gear", tag = "Card" }
            }
        }
    })

    t:assertTrue(world:objectWasSpawned("Dextral Crabaxe", "Seed Patterns"),
        "Seed Pattern in storage should be spawned")
    t:assertTrue(world:objectWasSpawned("Sword of Doom", "Gear"),
        "Pattern gear in settlement storage should be spawned")
    t:assertTrue(world:objectWasSpawned("Mighty Bone Axe", "Gear"),
        "Equipped pattern gear should be spawned")

    world:destroy()
end)

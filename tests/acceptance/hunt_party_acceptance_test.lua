---------------------------------------------------------------------------------------------------
-- Hunt Party Acceptance Tests (kdm-gmk)
--
-- User story: When departing survivors have custom figurines, the hunt party token shows
-- scaled-down copies of those figurines arranged in a formation that moves as a group.
--
-- SCOPE: What these tests verify (headless)
--   - Formation position calculation for 1-4 survivors
--   - Figurine collection filters survivors correctly
--   - Module state management
--
-- OUT OF SCOPE: What requires TTS console tests
--   - Visual appearance of figurines at 50% scale
--   - addAttachment() grouping behavior
--   - Movement as unit when dragging base token
--   - Auto-reveal integration with drop handlers
--   - Cleanup destroying all objects
--   - Dynamic removal when survivor destroyed
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local HuntParty = require("Kdm/HuntParty")

---------------------------------------------------------------------------------------------------
-- Formation Acceptance Tests
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Single survivor places figurine at center", function(t)
    -- GIVEN: One survivor in the party
    -- WHEN: Formation is calculated
    local positions = HuntParty.GetFormation(1)

    -- THEN: Figurine should be centered
    t:assertEqual(1, #positions)
    t:assertEqual(0, positions[1].x, "Single figurine should be at center x")
    t:assertEqual(0, positions[1].z, "Single figurine should be at center z")
end)

Test.test("ACCEPTANCE: Two survivors place figurines side by side", function(t)
    -- GIVEN: Two survivors in the party
    -- WHEN: Formation is calculated
    local positions = HuntParty.GetFormation(2)

    -- THEN: Figurines should be arranged side-by-side (Z axis when facing east)
    t:assertEqual(2, #positions)
    t:assertTrue(positions[1].z < positions[2].z, "First figurine should be to the left (negative z)")
    t:assertEqual(positions[1].x, positions[2].x, "Both figurines should be at same x")
end)

Test.test("ACCEPTANCE: Four survivors form 2x2 grid facing monster", function(t)
    -- GIVEN: Four survivors in the party (max hunt party size)
    -- WHEN: Formation is calculated
    local positions = HuntParty.GetFormation(4)

    -- THEN: Figurines should form 2x2 grid with front row toward monster (negative z)
    t:assertEqual(4, #positions)

    -- Front row should have negative z (toward monster)
    t:assertTrue(positions[1].z < 0, "Front left should face monster")
    t:assertTrue(positions[2].z < 0, "Front right should face monster")

    -- Back row should have positive z
    t:assertTrue(positions[3].z > 0, "Back left should be behind")
    t:assertTrue(positions[4].z > 0, "Back right should be behind")
end)

---------------------------------------------------------------------------------------------------
-- Figurine Collection Acceptance Tests
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Only survivors with figurines are included", function(t)
    -- GIVEN: A mixed party where some have figurines and some don't
    local survivors = {
        { id = 1, name = "Alice", FigurineJSON = function() return '{"Name":"Alice Model"}' end },
        { id = 2, name = "Bob", FigurineJSON = function() return nil end },
        { id = 3, name = "Carol", FigurineJSON = function() return '{"Name":"Carol Model"}' end },
        { id = 4, name = "Dave", FigurineJSON = function() return nil end },
    }

    -- WHEN: Figurines are collected
    local collected = HuntParty.CollectFigurines(survivors)

    -- THEN: Only survivors with figurines should be included
    t:assertEqual(2, #collected, "Should only have 2 survivors with figurines")
    t:assertEqual(1, collected[1].id, "First should be Alice")
    t:assertEqual(3, collected[2].id, "Second should be Carol")
end)

Test.test("ACCEPTANCE: Empty party when no figurines available", function(t)
    -- GIVEN: All survivors lack custom figurines
    local survivors = {
        { id = 1, FigurineJSON = function() return nil end },
        { id = 2, FigurineJSON = function() return nil end },
    }

    -- WHEN: Figurines are collected
    local collected = HuntParty.CollectFigurines(survivors)

    -- THEN: Collection should be empty (fallback to standard token)
    t:assertEqual(0, #collected)
end)

---------------------------------------------------------------------------------------------------
-- State Management Tests
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: GetBaseObject returns nil before Create", function(t)
    -- GIVEN: Module is freshly loaded (no party created)
    -- Ensure clean state
    HuntParty.baseObject = nil
    HuntParty.figurinesBySurvivorId = {}

    -- WHEN: Querying for base object
    local base = HuntParty.GetBaseObject()

    -- THEN: Should return nil
    t:assertNil(base, "No base object should exist before Create")
end)

Test.test("ACCEPTANCE: Cleanup resets module state", function(t)
    -- GIVEN: Some state exists (simulate after Create)
    HuntParty.baseObject = { isDestroyed = function() return true end }
    HuntParty.figurinesBySurvivorId = { [1] = "fake", [2] = "fake" }

    -- WHEN: Cleanup is called
    HuntParty.Cleanup()

    -- THEN: State should be reset
    t:assertNil(HuntParty.baseObject, "Base object should be nil after cleanup")
    t:assertEqual(0, next(HuntParty.figurinesBySurvivorId) and 1 or 0,
        "Figurine mapping should be empty after cleanup")
end)

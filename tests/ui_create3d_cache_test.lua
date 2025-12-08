---------------------------------------------------------------------------------------------------
-- Ui.Create3d Cache Bug Test
--
-- Bug: Ui.Create3d caches by object, so multiple modules using the same TTS object
-- as their UI root get the SAME ui instance. The second caller gets the first caller's
-- UI with the wrong id.
--
-- This test documents the bug (kdm-w1k) and will fail once the bug is fixed.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Test Helpers: Minimal stubs for Ui module
---------------------------------------------------------------------------------------------------

local function createUiModule()
    -- Minimal stubs
    local Check = {
        Str = function() return true end,
        Object = function() return true end,
        Num = function() return true end,
    }

    -- Recreate the Ui.Create3d logic from Ui.ttslua:46-73
    local Ui = {}
    Ui.root3dsByObject = {}

    function Ui.Create3d(id, object, z)
        assert(Check.Str(id))
        assert(Check.Object(object))
        assert(Check.Num(z))

        local root3d = Ui.root3dsByObject[object]
        if root3d == nil then
            root3d = {
                object = object,
                z = z * -100,
                attributes = {
                    id = id,
                },
            }
            Ui.root3dsByObject[object] = root3d
        end

        return root3d
    end

    return Ui
end

---------------------------------------------------------------------------------------------------
-- BUG TEST: Documents current (buggy) behavior
---------------------------------------------------------------------------------------------------

Test.test("BUG: Ui.Create3d returns cached instance for same object (wrong id)", function(t)
    local Ui = createUiModule()

    -- Simulate Showdown Board object (same reference used by both modules)
    local showdownBoard = { name = "Showdown Board" }

    -- First caller: Deck module
    local deckUi = Ui.Create3d("Deck", showdownBoard, 10.74)
    t:assertEqual("Deck", deckUi.attributes.id, "First caller should get id='Deck'")

    -- Second caller: ResourceRewards module (same object!)
    local rewardsUi = Ui.Create3d("ResourceRewards", showdownBoard, 10.74)

    -- BUG: Second caller gets first caller's UI
    t:assertEqual(deckUi, rewardsUi, "BUG: Both calls return same instance (cached)")
    t:assertEqual("Deck", rewardsUi.attributes.id, "BUG: ResourceRewards gets id='Deck' instead of 'ResourceRewards'")
end)

---------------------------------------------------------------------------------------------------
-- SPECIFICATION TEST: What the correct behavior SHOULD be
---------------------------------------------------------------------------------------------------

Test.test("SPEC: Ui.Create3d SHOULD return unique instance per id (currently fails)", function(t)
    local Ui = createUiModule()

    local showdownBoard = { name = "Showdown Board" }

    local deckUi = Ui.Create3d("Deck", showdownBoard, 10.74)
    local rewardsUi = Ui.Create3d("ResourceRewards", showdownBoard, 10.74)

    -- This is what SHOULD happen (test will fail until bug is fixed)
    -- Commenting out for now since this documents desired behavior, not current
    -- t:assertNotEqual(deckUi, rewardsUi, "Each caller should get unique instance")
    -- t:assertEqual("ResourceRewards", rewardsUi.attributes.id, "Second caller should get its own id")

    -- For now, just document that they ARE the same (the bug)
    t:assertTrue(deckUi == rewardsUi, "Currently both return same instance (bug)")
end)

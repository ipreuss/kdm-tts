-- Acceptance tests for monster list refresh after expansion changes
-- Bead: kdm-8cn
--
-- Verifies that Hunt and Showdown monster lists are refreshed when
-- Campaign.Import() enables new expansions.

local Test = require("tests.framework")
local TestWorld = require("tests.acceptance.test_world")

--------------------------------------------------------------------------------
-- Test: Campaign.Import refreshes Hunt monster list
--------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Campaign.Import refreshes Hunt monster list", function(t)
    local world = TestWorld.create()

    -- Import a campaign using default parameters
    world:importCampaign()

    t:assertTrue(world:huntRefreshMonsterListCalled(),
        "Hunt.RefreshMonsterList should be called during Campaign.Import")

    world:destroy()
end)

--------------------------------------------------------------------------------
-- Test: Campaign.Import refreshes Showdown monster list
--------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Campaign.Import refreshes Showdown monster list", function(t)
    local world = TestWorld.create()

    world:importCampaign()

    t:assertTrue(world:showdownRefreshMonsterListCalled(),
        "Showdown.RefreshMonsterList should be called during Campaign.Import")

    world:destroy()
end)

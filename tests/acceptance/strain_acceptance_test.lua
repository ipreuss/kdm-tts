---------------------------------------------------------------------------------------------------
-- Strain Acceptance Tests
--
-- Tests for strain milestone user-visible behavior.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local TestWorld = require("tests.acceptance.test_world")

---------------------------------------------------------------------------------------------------
-- INFRASTRUCTURE TESTS (validate TestWorld loads real data)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE INFRA: TestWorld loads real milestone data", function(t)
    local world = TestWorld.create()
    
    -- Reach a milestone
    local ok = world:reachMilestone("Ethereal Culture Strain")
    t:assertTrue(ok, "Should be able to reach milestone")
    t:assertTrue(world:isReached("Ethereal Culture Strain"))
    
    -- The milestone's fighting art reward is now available
    t:assertEqual("Ethereal Pact", world:milestoneReward("Ethereal Culture Strain"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE INFRA: TestWorld queries milestone rewards correctly", function(t)
    local world = TestWorld.create()
    
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    
    t:assertEqual("Ethereal Pact", world:milestoneReward("Ethereal Culture Strain"))
    t:assertEqual("Giant's Blood", world:milestoneReward("Giant's Strain"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------
-- USER-VISIBLE BEHAVIOR TESTS
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: strain rewards are added to new campaign", function(t)
    local world = TestWorld.create()
    
    -- User has previously reached milestones
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    
    -- User starts a new campaign  
    world:startNewCampaign()
    
    -- The unlocked rewards are in the fighting arts deck
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Ethereal Pact"))
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Giant's Blood"))
    
    world:destroy()
end)

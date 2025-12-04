---------------------------------------------------------------------------------------------------
-- Strain Acceptance Tests
--
-- Tests for strain milestone user-visible behavior (game state changes).
--
-- SCOPE: These tests verify business logic and state transitions:
--   - Rewards added to decks when milestones are reached/confirmed
--   - Timeline events scheduled at correct years
--   - Undo removes rewards correctly
--
-- OUT OF SCOPE: UI interactions (dialogs, log messages, card spawning visuals).
-- UI behavior is verified via TTS console tests (>teststrain, >teststrainvermin, etc.)
-- See TTSTests.ttslua for the snapshot/action/restore test pattern.
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

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: new campaign works with no milestones reached", function(t)
    local world = TestWorld.create()
    
    -- User starts campaign without reaching any milestones
    world:startNewCampaign()
    
    -- Fighting arts deck has no strain rewards
    t:assertFalse(world:deckContains(world:fightingArtsDeck(), "Ethereal Pact"))
    t:assertFalse(world:deckContains(world:fightingArtsDeck(), "Giant's Blood"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: at most 5 strain fighting arts added to new campaign", function(t)
    local world = TestWorld.create()
    
    -- User reaches more than 5 milestones with fighting art rewards
    world:reachMilestone("Ethereal Culture Strain")   -- Ethereal Pact
    world:reachMilestone("Giant's Strain")            -- Giant's Blood
    world:reachMilestone("Opportunist Strain")        -- Backstabber
    world:reachMilestone("Trepanning Strain")         -- Infinite Lives
    world:reachMilestone("Hyper Cerebellum")          -- Shielderang
    world:reachMilestone("Marrow Transformation")     -- Rolling Gait
    world:reachMilestone("Memetic Symphony")          -- Infernal Rhythm
    
    world:startNewCampaign()
    
    -- Only 5 fighting arts should be added (randomly selected)
    local deck = world:fightingArtsDeck()
    t:assertEqual(5, #deck, "Should have exactly 5 strain fighting arts")
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: strain vermin rewards are added to new campaign", function(t)
    local world = TestWorld.create()
    
    -- User reaches a milestone with vermin reward
    world:reachMilestone("Ashen Claw Strain")  -- Fiddler Crab Spider (vermin) + Armored Fist (fighting art)
    
    world:startNewCampaign()
    
    -- Both rewards are added
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Armored Fist"))
    t:assertTrue(world:deckContains(world:verminDeck(), "Fiddler Crab Spider"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: confirming Sword Oath adds Acid Storm to next year", function(t)
    local world = TestWorld.create()
    
    -- Campaign is in year 5
    world:advanceToYear(5)
    
    -- User confirms Sweat Stained Oath milestone
    world:confirmMilestone("Sweat Stained Oath")
    
    -- Acid Storm is scheduled for year 6 (current + offset 1)
    t:assertTrue(world:timelineContains(6, "Acid Storm"), 
        "Acid Storm should be added to year 6")
    
    -- Fighting art was also added
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Sword Oath"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: unchecking milestone removes rewards", function(t)
    local world = TestWorld.create()
    
    -- Confirm a milestone
    world:confirmMilestone("Ethereal Culture Strain")
    t:assertTrue(world:deckContains(world:fightingArtsDeck(), "Ethereal Pact"))
    
    -- Uncheck the milestone
    world:uncheckMilestone("Ethereal Culture Strain")
    
    -- Reward is removed
    t:assertFalse(world:deckContains(world:fightingArtsDeck(), "Ethereal Pact"))
    t:assertFalse(world:isReached("Ethereal Culture Strain"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: unchecking milestone removes timeline event", function(t)
    local world = TestWorld.create()
    
    -- Campaign is in year 3
    world:advanceToYear(3)
    
    -- Confirm Sweat Stained Oath (has timeline event)
    world:confirmMilestone("Sweat Stained Oath")
    t:assertTrue(world:timelineContains(4, "Acid Storm"))
    
    -- Uncheck the milestone
    world:uncheckMilestone("Sweat Stained Oath")
    
    -- Timeline event is removed
    t:assertFalse(world:timelineContains(4, "Acid Storm"))
    t:assertFalse(world:deckContains(world:fightingArtsDeck(), "Sword Oath"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Atmospheric Change trashes Heat Wave and adds Lump of Atnas", function(t)
    local world = TestWorld.create()
    
    world:confirmMilestone("Atmospheric Change")
    
    -- Heat Wave should be trashed
    t:assertTrue(world:settlementEventTrashed("Heat Wave"))
    
    -- Lump of Atnas should be added to basic resources
    t:assertTrue(world:deckContains(world:basicResourcesDeck(), "Lump of Atnas"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: unchecking Atmospheric Change restores Heat Wave", function(t)
    local world = TestWorld.create()
    
    world:confirmMilestone("Atmospheric Change")
    world:uncheckMilestone("Atmospheric Change")
    
    -- Heat Wave should be restored (removed from trash)
    t:assertFalse(world:settlementEventTrashed("Heat Wave"))
    
    -- Lump of Atnas should be removed
    t:assertFalse(world:deckContains(world:basicResourcesDeck(), "Lump of Atnas"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: new campaign with Atmospheric Change has correct deck state", function(t)
    local world = TestWorld.create()
    
    -- User has previously reached Atmospheric Change milestone
    world:reachMilestone("Atmospheric Change")
    
    -- User starts a new campaign
    world:startNewCampaign()
    
    -- Heat Wave should already be trashed in new campaign
    t:assertTrue(world:settlementEventTrashed("Heat Wave"),
        "Heat Wave should be trashed when starting new campaign with Atmospheric Change reached")
    
    -- Lump of Atnas should be in basic resources
    t:assertTrue(world:deckContains(world:basicResourcesDeck(), "Lump of Atnas"),
        "Lump of Atnas should be in basic resources deck")
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Atmospheric Change shows no manual steps", function(t)
    local world = TestWorld.create()
    
    local milestone = world:getMilestone("Atmospheric Change")
    t:assertNotNil(milestone, "Atmospheric Change milestone should exist")
    
    -- Atmospheric Change has no manual steps (unlike other milestones)
    local manualSteps = milestone.consequences and milestone.consequences.manual
    t:assertNil(manualSteps, "Atmospheric Change should have no manual steps")
    
    world:destroy()
end)

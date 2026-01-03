---------------------------------------------------------------------------------------------------
-- Strain Spawn Rewards Tests
--
-- Tests that disorder, severe injury, and strange resource consequences SPAWN cards
-- directly from their respective archives via Archive.Take(), rather than trying to 
-- transfer from the Strain Rewards deck.
--
-- FIXED: Strain.ttslua now uses SpawnDisorder, SpawnSevereInjury, SpawnStrangeResource
-- which call Archive.Take() directly, bypassing the broken archive module AddCard functions.
--
-- REGRESSION: ExecuteConsequences chains spawn consequences inside fightingArt callback
-- to avoid concurrent Archive.Clean() calls destroying objects still in use.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Test: Verify Strain exports ExecuteConsequences for testing
---------------------------------------------------------------------------------------------------

Test.test("FIXED: Strain.Test.ExecuteConsequences is available for acceptance testing", function(t)
    package.loaded["Kdm/Sequence/Strain"] = nil
    
    -- Load minimal stubs
    package.loaded["Kdm/Archive/Archive"] = { Take = function() end, Clean = function() end, TakeFromDeck = function() end }
    package.loaded["Kdm/Location/Location"] = { Get = function() return nil end }
    
    local Strain = require("Kdm/Sequence/Strain")
    
    t:assertNotNil(Strain.Test, "Strain should export Test table")
    t:assertNotNil(Strain.Test.ExecuteConsequences, "Strain.Test should have ExecuteConsequences")
end)

---------------------------------------------------------------------------------------------------
-- Integration test: Verify spawn-only cards are NOT in Strain Rewards deck data
---------------------------------------------------------------------------------------------------

Test.test("VERIFY: Strain Rewards deck should only contain transferable cards", function(t)
    -- Load milestone data to find what cards should be in Strain Rewards
    local milestones = require("Kdm/GameData/StrainMilestones")
    
    local strainRewardsCards = {}
    local spawnOnlyCards = {}
    
    for _, milestone in ipairs(milestones) do
        local c = milestone.consequences
        if c then
            -- These go into Strain Rewards deck (transferable)
            if c.fightingArt then
                strainRewardsCards[c.fightingArt] = "fightingArt"
            end
            if c.vermin then
                strainRewardsCards[c.vermin] = "vermin"
            end
            
            -- These should NOT be in Strain Rewards (spawn from own archives)
            if c.disorder then
                spawnOnlyCards[c.disorder] = "disorder"
            end
            if c.severeInjury then
                spawnOnlyCards[c.severeInjury] = "severeInjury"
            end
            if c.strangeResource then
                spawnOnlyCards[c.strangeResource] = "strangeResource"
            end
        end
    end
    
    -- Verify the spawn-only cards are NOT expected in Strain Rewards
    for card, conseqType in pairs(spawnOnlyCards) do
        t:assertNil(strainRewardsCards[card],
            string.format("%s (%s consequence) should not be in Strain Rewards deck", card, conseqType))
    end
    
    -- Verify we found the expected spawn-only cards
    t:assertNotNil(spawnOnlyCards["Weak Spot"], "Should find Weak Spot disorder in milestones")
    t:assertNotNil(spawnOnlyCards["Blind"], "Should find Blind severe injury in milestones")
    t:assertNotNil(spawnOnlyCards["Iron"], "Should find Iron strange resource in milestones")
end)

---------------------------------------------------------------------------------------------------
-- REGRESSION TEST: Spawn consequences must run AFTER fightingArt callback completes
--
-- Bug (2024-12): When a milestone had both fightingArt and strangeResource consequences,
-- SpawnStrangeResource ran immediately and called Archive.Clean(), which destroyed the
-- Fighting Arts deck before ApplyFightingArt's async callback could use it.
--
-- Fix: ExecuteConsequences now chains spawn consequences inside the fightingArt callback.
-- This test verifies that ordering by checking the call sequence.
--
-- Key insight: In TTS, ApplyFightingArt's callback fires LATER (async). If spawn consequences
-- run outside the callback, they execute BEFORE the callback fires, causing the race condition.
---------------------------------------------------------------------------------------------------

Test.test("REGRESSION: spawn consequences run inside fightingArt callback, not concurrently", function(t)
    -- Track call order
    local callOrder = {}
    local pendingCallback = nil
    
    -- Create fake ConsequenceApplicator that simulates ASYNC behavior
    -- The callback is stored and NOT invoked immediately (simulating TTS async)
    local fakeConsequenceApplicator = {
        ApplyFightingArt = function(cardName, onComplete)
            table.insert(callOrder, "ApplyFightingArt_called")
            -- Store callback but DON'T invoke it yet (simulates TTS async)
            pendingCallback = onComplete
            table.insert(callOrder, "ApplyFightingArt_returned")
        end,
        ApplyVermin = function() end,
        ApplyTimelineEvent = function() end,
        TrashSettlementEvent = function() end,
        AddBasicResource = function() end,
    }
    
    -- Track spawn function calls
    local fakeArchive = {
        Take = function() end,
        Clean = function() end,
        TakeFromDeck = function(params)
            table.insert(callOrder, "TakeFromDeck_" .. (params.name or "unknown"))
        end,
    }
    
    -- Save and stub modules
    local origCA = package.loaded["Kdm/Data/ConsequenceApplicator"]
    local origArchive = package.loaded["Kdm/Archive/Archive"]
    local origLocation = package.loaded["Kdm/Location/Location"]
    local origStrain = package.loaded["Kdm/Sequence/Strain"]
    
    package.loaded["Kdm/Data/ConsequenceApplicator"] = fakeConsequenceApplicator
    package.loaded["Kdm/Archive/Archive"] = fakeArchive
    package.loaded["Kdm/Location/Location"] = { Get = function() return nil end }
    package.loaded["Kdm/Sequence/Strain"] = nil
    
    local Strain = require("Kdm/Sequence/Strain")
    
    -- Execute consequences for a milestone with BOTH fightingArt AND strangeResource
    local milestone = {
        title = "Test Plot Twist",
        consequences = {
            fightingArt = "Story of Blood",
            strangeResource = "Iron",
        },
    }
    
    Strain.Test.ExecuteConsequences(milestone)
    
    -- At this point, ExecuteConsequences has returned.
    -- In the BUGGY version, TakeFromDeck_Iron would already be in callOrder.
    -- In the FIXED version, TakeFromDeck_Iron should NOT be in callOrder yet
    -- because it's inside the callback which hasn't fired.
    
    local ironCalledBeforeCallback = false
    for _, call in ipairs(callOrder) do
        if call == "TakeFromDeck_Iron" then
            ironCalledBeforeCallback = true
        end
    end
    
    -- Now simulate the async callback firing (like TTS would do later)
    if pendingCallback then
        table.insert(callOrder, "callback_invoked")
        pendingCallback()
    end
    
    -- Restore modules
    package.loaded["Kdm/Data/ConsequenceApplicator"] = origCA
    package.loaded["Kdm/Archive/Archive"] = origArchive
    package.loaded["Kdm/Location/Location"] = origLocation
    package.loaded["Kdm/Sequence/Strain"] = origStrain
    
    -- THE KEY ASSERTION: Iron spawn must NOT happen before the callback is invoked
    t:assertFalse(ironCalledBeforeCallback,
        "REGRESSION: SpawnStrangeResource must run INSIDE fightingArt callback, not before. " ..
        "If Iron was called before callback, Archive.Clean() would destroy shared objects. " ..
        "Call order: " .. table.concat(callOrder, " -> "))
    
    -- Verify Iron WAS called (after callback)
    local ironCalledAfterCallback = false
    local foundCallback = false
    for _, call in ipairs(callOrder) do
        if call == "callback_invoked" then foundCallback = true end
        if call == "TakeFromDeck_Iron" and foundCallback then
            ironCalledAfterCallback = true
        end
    end
    
    t:assertTrue(ironCalledAfterCallback,
        "SpawnStrangeResource should have been called after callback. " ..
        "Call order: " .. table.concat(callOrder, " -> "))
end)

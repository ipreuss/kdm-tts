---------------------------------------------------------------------------------------------------
-- TestWorld: Facade for acceptance tests
-- 
-- Manages game state and provides high-level actions for test scenarios.
-- Uses TestTTSAdapter to track TTS operations without actually calling TTS.
-- Uses ArchiveSpy to intercept archive calls and verify real execution code.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = require("tests.acceptance.tts_environment")
local TTSAdapter = require("Kdm/Util/TTSAdapter")
local TestTTSAdapter = require("tests.acceptance.test_tts_adapter")
local ArchiveSpy = require("tests.acceptance.archive_spy")

local TestWorld = {}

function TestWorld.create()
    local world = {
        _adapter = TestTTSAdapter.create(),
        _archiveSpy = ArchiveSpy.create(),
        _env = nil,
        _milestones = {},
        _strainModule = nil,
        _campaignModule = nil,
        _currentYear = 1,
    }
    setmetatable(world, { __index = TestWorld })
    
    -- Install test adapter FIRST (before modules load)
    TTSAdapter.Set(world._adapter)
    
    -- Install archive spies BEFORE loading modules
    world:_installArchiveSpies()
    
    world._env = TTSEnvironment.create()
    world._env:install()
    world:_loadModules()
    
    return world
end

function TestWorld:destroy()
    TTSAdapter.Reset()
    self._env:uninstall()
end

---------------------------------------------------------------------------------------------------
-- Archive Spy Installation
---------------------------------------------------------------------------------------------------

function TestWorld:_installArchiveSpies()
    package.loaded["Kdm/Archive"] = self._archiveSpy:createArchiveStub()
    package.loaded["Kdm/FightingArtsArchive"] = self._archiveSpy:createFightingArtsArchiveStub()
    package.loaded["Kdm/VerminArchive"] = self._archiveSpy:createVerminArchiveStub()
    package.loaded["Kdm/BasicResourcesArchive"] = self._archiveSpy:createBasicResourcesArchiveStub()
    package.loaded["Kdm/DisordersArchive"] = self._archiveSpy:createDisordersArchiveStub()
    package.loaded["Kdm/SevereInjuriesArchive"] = self._archiveSpy:createSevereInjuriesArchiveStub()
    package.loaded["Kdm/StrangeResourcesArchive"] = self._archiveSpy:createStrangeResourcesArchiveStub()
    package.loaded["Kdm/Trash"] = self._archiveSpy:createTrashStub()
    package.loaded["Kdm/Timeline"] = self._archiveSpy:createTimelineStub(function()
        return self._currentYear
    end)
end

---------------------------------------------------------------------------------------------------
-- Module Loading
---------------------------------------------------------------------------------------------------

function TestWorld:_loadModules()
    -- Clear cached modules to get fresh load with stubs in place
    -- The archive modules are already stubbed via _installArchiveSpies
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    package.loaded["Kdm/Strain"] = nil
    package.loaded["Kdm/Campaign"] = nil
    
    self._strainModule = require("Kdm/Strain")
    self._campaignModule = require("Kdm/Campaign")
end

---------------------------------------------------------------------------------------------------
-- Game Actions
---------------------------------------------------------------------------------------------------

function TestWorld:reachMilestone(title)
    -- Validate against real milestone data
    local milestone = self._strainModule.FindMilestone(title)
    if not milestone then
        error("Unknown milestone: " .. title .. " (not in MILESTONE_CARDS)")
    end
    
    self._milestones[title] = true
    return true
end

function TestWorld:confirmMilestone(title)
    local milestone = self._strainModule.FindMilestone(title)
    if not milestone then
        error("Unknown milestone: " .. title)
    end
    
    -- Mark as reached
    self._milestones[title] = true
    
    -- Call REAL ExecuteConsequences (archive calls go to spies)
    self._strainModule.Test.ExecuteConsequences(milestone)
    
    return true
end

function TestWorld:uncheckMilestone(title)
    local milestone = self._strainModule.FindMilestone(title)
    if not milestone then
        error("Unknown milestone: " .. title)
    end
    
    -- Must have been reached
    if not self._milestones[title] then
        error("Milestone not reached: " .. title)
    end
    
    -- Mark as not reached
    self._milestones[title] = nil
    
    -- Call REAL ReverseConsequences (archive calls go to spies)
    self._strainModule.Test.ReverseConsequences(milestone)
    
    return true
end

function TestWorld:startNewCampaign()
    -- Set up Strain state so Campaign.AddStrainRewards reads correct milestones
    self._strainModule.Test.SetReachedMilestones(self._milestones)
    
    -- Call REAL Campaign.AddStrainRewards (archive calls go to spies)
    self._campaignModule.AddStrainRewards()
end

---------------------------------------------------------------------------------------------------
-- State Inspection
---------------------------------------------------------------------------------------------------

function TestWorld:isReached(title)
    return self._milestones[title] == true
end

function TestWorld:advanceToYear(year)
    self._currentYear = year
end

function TestWorld:timelineContains(year, eventName)
    -- Check spy: scheduled at specific year AND NOT removed
    local scheduled = self._archiveSpy:timelineEventScheduled(eventName, year)
    local removed = self._archiveSpy:timelineEventRemoved(eventName)
    return scheduled and not removed
end

function TestWorld:milestoneReward(title)
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if milestone.title == title then
            return milestone.consequences and milestone.consequences.fightingArt
        end
    end
    return nil
end

function TestWorld:settlementEventTrashed(cardName)
    return self._archiveSpy:trashAdded(cardName)
       and not self._archiveSpy:trashRemoved(cardName)
end

function TestWorld:fightingArtsDeck()
    return "Fighting Arts"
end

function TestWorld:fightingArtsCount()
    return self._archiveSpy:fightingArtsAddedCount()
end

function TestWorld:verminDeck()
    return "Vermin"
end

function TestWorld:basicResourcesDeck()
    return "Basic Resources"
end

function TestWorld:deckContains(deck, cardName)
    if deck == "Fighting Arts" then
        return self._archiveSpy:fightingArtAdded(cardName)
           and not self._archiveSpy:fightingArtRemoved(cardName)
    elseif deck == "Vermin" then
        return self._archiveSpy:verminAdded(cardName)
           and not self._archiveSpy:verminRemoved(cardName)
    elseif deck == "Basic Resources" then
        return self._archiveSpy:basicResourceAdded(cardName)
           and not self._archiveSpy:basicResourceRemoved(cardName)
    end
    return false
end

return TestWorld

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
        _decks = {},
        _currentYear = 1,
        _timeline = {},
        _trashedSettlementEvents = {},
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
    package.loaded["Kdm/FightingArtsArchive"] = self._archiveSpy:createFightingArtsArchiveStub()
    package.loaded["Kdm/VerminArchive"] = self._archiveSpy:createVerminArchiveStub()
    package.loaded["Kdm/BasicResourcesArchive"] = self._archiveSpy:createBasicResourcesArchiveStub()
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

---------------------------------------------------------------------------------------------------
-- State Inspection
---------------------------------------------------------------------------------------------------

function TestWorld:isReached(title)
    return self._milestones[title] == true
end

function TestWorld:advanceToYear(year)
    self._currentYear = year
end

function TestWorld:timeline()
    return self._timeline
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
    -- Check spy: trashed AND NOT restored (via trashRemove)
    local trashed = self._archiveSpy:trashAdded(cardName)
    local restored = self._archiveSpy:trashRemoved(cardName)
    if trashed and not restored then
        return true
    end
    -- Also check local state for startNewCampaign
    return self._trashedSettlementEvents[cardName] == true
end

---------------------------------------------------------------------------------------------------
-- Campaign Actions
---------------------------------------------------------------------------------------------------

function TestWorld:startNewCampaign()
    -- Build list of reached milestones
    local reached = {}
    for title, _ in pairs(self._milestones) do
        reached[title] = true
    end
    
    -- Call REAL Campaign logic to calculate rewards
    local rewards = self._campaignModule.CalculateStrainRewards(
        reached,
        self._strainModule.MILESTONE_CARDS
    )
    
    -- Track in deck state
    self._decks = self._decks or {}
    self._decks["Fighting Arts"] = rewards.fightingArts or {}
    self._decks["Vermin"] = rewards.vermin or {}
    
    -- Apply trashed settlement events
    for _, cardName in ipairs(rewards.trashSettlementEvents or {}) do
        self._trashedSettlementEvents[cardName] = true
    end
    
    -- Apply added basic resources
    self._decks["Basic Resources"] = self._decks["Basic Resources"] or {}
    for _, cardName in ipairs(rewards.addBasicResources or {}) do
        table.insert(self._decks["Basic Resources"], cardName)
    end
end

function TestWorld:fightingArtsDeck()
    -- Return local deck for count operations (startNewCampaign populates this)
    return self._decks and self._decks["Fighting Arts"] or {}
end

function TestWorld:verminDeck()
    -- Return local deck for count operations
    return self._decks and self._decks["Vermin"] or {}
end

function TestWorld:deckContains(deck, cardName)
    -- Determine which deck we're checking
    local deckName = nil
    
    -- Get actual deck references for comparison
    local faDeck = self._decks and self._decks["Fighting Arts"]
    local vDeck = self._decks and self._decks["Vermin"]
    local brDeck = self._decks and self._decks["Basic Resources"]
    
    if type(deck) == "string" then
        deckName = deck
    elseif faDeck and deck == faDeck then
        deckName = "Fighting Arts"
    elseif vDeck and deck == vDeck then
        deckName = "Vermin"
    elseif brDeck and deck == brDeck then
        deckName = "Basic Resources"
    elseif type(deck) == "table" and #deck == 0 then
        -- Empty table passed - could be any deck, check all spies
        -- This handles the case where fightingArtsDeck() returns {} because _decks is empty
        if self._archiveSpy:fightingArtAdded(cardName) and not self._archiveSpy:fightingArtRemoved(cardName) then
            return true
        end
        if self._archiveSpy:verminAdded(cardName) and not self._archiveSpy:verminRemoved(cardName) then
            return true
        end
        if self._archiveSpy:basicResourceAdded(cardName) and not self._archiveSpy:basicResourceRemoved(cardName) then
            return true
        end
        return false
    end
    
    if deckName == "Fighting Arts" then
        if self._archiveSpy:fightingArtAdded(cardName) and not self._archiveSpy:fightingArtRemoved(cardName) then
            return true
        end
        local localDeck = self._decks and self._decks["Fighting Arts"] or {}
        for _, card in ipairs(localDeck) do
            if card == cardName then return true end
        end
        return false
    end
    if deckName == "Vermin" then
        if self._archiveSpy:verminAdded(cardName) and not self._archiveSpy:verminRemoved(cardName) then
            return true
        end
        local localDeck = self._decks and self._decks["Vermin"] or {}
        for _, card in ipairs(localDeck) do
            if card == cardName then return true end
        end
        return false
    end
    if deckName == "Basic Resources" then
        if self._archiveSpy:basicResourceAdded(cardName) and not self._archiveSpy:basicResourceRemoved(cardName) then
            return true
        end
        local localDeck = self._decks and self._decks["Basic Resources"] or {}
        for _, card in ipairs(localDeck) do
            if card == cardName then return true end
        end
        return false
    end
    
    -- Legacy: array-based deck iteration (for non-empty tables)
    if type(deck) == "table" then
        for _, card in ipairs(deck) do
            if card == cardName then
                return true
            end
        end
    end
    return false
end

function TestWorld:basicResourcesDeck()
    return self._decks and self._decks["Basic Resources"] or {}
end

return TestWorld

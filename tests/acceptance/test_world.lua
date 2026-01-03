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
    -- Archive modules (spied)
    package.loaded["Kdm/Archive/Archive"] = self._archiveSpy:createArchiveStub()
    package.loaded["Kdm/Archive/FightingArtsArchive"] = self._archiveSpy:createFightingArtsArchiveStub()
    package.loaded["Kdm/Archive/VerminArchive"] = self._archiveSpy:createVerminArchiveStub()
    package.loaded["Kdm/Archive/BasicResourcesArchive"] = self._archiveSpy:createBasicResourcesArchiveStub()
    package.loaded["Kdm/Archive/DisordersArchive"] = self._archiveSpy:createDisordersArchiveStub()
    package.loaded["Kdm/Archive/SevereInjuriesArchive"] = self._archiveSpy:createSevereInjuriesArchiveStub()
    package.loaded["Kdm/Archive/StrangeResourcesArchive"] = self._archiveSpy:createStrangeResourcesArchiveStub()
    package.loaded["Kdm/Data/Trash"] = self._archiveSpy:createTrashStubWithImport()
    package.loaded["Kdm/Sequence/Timeline"] = self._archiveSpy:createTimelineStub(function()
        return self._currentYear
    end)

    -- Additional modules needed for Campaign.Import
    package.loaded["Kdm/Sequence/Showdown"] = self._archiveSpy:createShowdownStub()
    package.loaded["Kdm/Sequence/Hunt"] = self._archiveSpy:createHuntStub()
    package.loaded["Kdm/Expansion"] = self._archiveSpy:createExpansionStub()
    package.loaded["Kdm/Ui/Rules"] = self._archiveSpy:createRulesStub()
    package.loaded["Kdm/Location/Location"] = self._archiveSpy:createLocationStub()
    package.loaded["Kdm/Entity/Survivor"] = self._archiveSpy:createSurvivorStub()
    package.loaded["Kdm/GameData/CampaignMigrations"] = self._archiveSpy:createCampaignMigrationsStub()
    package.loaded["Kdm/Location/NamedObject"] = self._archiveSpy:createNamedObjectStub()
    package.loaded["Kdm/Util/Container"] = self._archiveSpy:createContainerModuleStub()
    package.loaded["Kdm/Entity/Player"] = self._archiveSpy:createPlayerStub()

    -- Global Wait stub for TTS async
    Wait = self._archiveSpy:createWaitStub()
end

---------------------------------------------------------------------------------------------------
-- Module Loading
---------------------------------------------------------------------------------------------------

function TestWorld:_loadModules()
    -- Clear cached modules to get fresh load with stubs in place
    -- The archive modules are already stubbed via _installArchiveSpies
    package.loaded["Kdm/Data/ConsequenceApplicator"] = nil
    package.loaded["Kdm/Sequence/Strain"] = nil
    package.loaded["Kdm/Sequence/Campaign"] = nil
    package.loaded["Kdm/Data/Deck"] = nil

    self._strainModule = require("Kdm/Sequence/Strain")
    self._campaignModule = require("Kdm/Sequence/Campaign")
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

function TestWorld:importCampaign(options)
    options = options or {}

    -- Default expansion with all pattern components
    local defaultExpansions = {
        {
            name = "Core",
            components = {
                ["Fighting Arts"] = "Core Fighting Arts",
                ["Disorders"] = "Core Disorders",
                ["Severe Injuries"] = "Core Severe Injuries",
                ["Tactics"] = "Core Tactics",
                ["Abilities"] = "Core Abilities",
                ["Secret Fighting Arts"] = "Core Secret Fighting Arts",
                ["Weapon Proficiencies"] = "Core Weapon Proficiencies",
                ["Armor Sets"] = "Core Armor Sets",
                ["Vermin"] = "Core Vermin",
                ["Strange Resources"] = "Core Strange Resources",
                ["Basic Resources"] = "Core Basic Resources",
                ["Terrain"] = "Core Terrain",
                ["Rare Gear"] = "Core Rare Gear",
                ["Seed Pattern Gear"] = "Core Seed Pattern Gear",
                ["Hunt Events"] = "Core Hunt Events",
                ["Seed Patterns"] = "Core Seed Patterns",
                ["Patterns"] = "Core Patterns",
                ["Pattern Gear"] = "Core Pattern Gear",
                ["Settlement Events"] = "Core Settlement Events",
                ["Innovation Archive"] = "Core Innovations",
                ["Settlement Locations"] = "Core Settlement Locations",
            },
        }
    }

    -- Minimal import data that triggers deck creation
    local importData = {
        version = self._campaignModule._test.EXPORT_VERSION,
        expansions = options.expansions or defaultExpansions,
        unlockedMode = options.unlockedMode or false,
        trash = options.trash or {},
        objectsByLocation = options.objectsByLocation or {},
        timeline = options.timeline or { survivalActions = {} },
        campaign = options.campaign or { references = {}, misc = {} },
        settlementEventsDeck = options.settlementEventsDeck or {},
        characterDeck = options.characterDeck or {},
        survivor = options.survivor or {},
        hunt = options.hunt or {},
        departingSurvivors = options.departingSurvivors or {},
        strainMilestones = options.strainMilestones or {},
    }

    -- Call REAL Campaign.Import (archive calls go to spies)
    self._campaignModule._test.Import(importData)
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

function TestWorld:cardSpawned(cardName)
    -- Check if card was spawned via Archive.Take/TakeFromDeck
    if self._archiveSpy:cardSpawned(cardName) then
        return true
    end
    -- Check if card was added/spawned via specific archive AddCard methods
    -- Fighting arts
    if self._archiveSpy:fightingArtAdded(cardName)
       and not self._archiveSpy:fightingArtRemoved(cardName) then
        return true
    end
    -- Disorders
    if self._archiveSpy:disorderAdded(cardName)
       and not self._archiveSpy:disorderRemoved(cardName) then
        return true
    end
    -- Severe injuries
    if self._archiveSpy:severeInjuryAdded(cardName)
       and not self._archiveSpy:severeInjuryRemoved(cardName) then
        return true
    end
    -- Strange resources
    if self._archiveSpy:strangeResourceAdded(cardName)
       and not self._archiveSpy:strangeResourceRemoved(cardName) then
        return true
    end
    return false
end

---------------------------------------------------------------------------------------------------
-- Deck Operations (for pattern gear tests)
---------------------------------------------------------------------------------------------------

function TestWorld:deckExists(deckName)
    return self._archiveSpy:deckCreated(deckName)
end

function TestWorld:deckWasShuffled(deckName)
    return self._archiveSpy:deckWasShuffled(deckName)
end

---------------------------------------------------------------------------------------------------
-- Object Spawn Verification (for import tests)
---------------------------------------------------------------------------------------------------

function TestWorld:objectWasSpawned(objectName, objectType)
    return self._archiveSpy:objectSpawned(objectName, objectType)
end

return TestWorld

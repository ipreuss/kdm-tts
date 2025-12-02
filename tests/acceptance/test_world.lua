---------------------------------------------------------------------------------------------------
-- TestWorld: Facade for acceptance tests
-- 
-- Manages game state and provides high-level actions for test scenarios.
-- Uses TestTTSAdapter to track TTS operations without actually calling TTS.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = require("tests.acceptance.tts_environment")
local TTSAdapter = require("Kdm/Util/TTSAdapter")
local TestTTSAdapter = require("tests.acceptance.test_tts_adapter")

local TestWorld = {}

function TestWorld.create()
    local world = {
        _adapter = TestTTSAdapter.create(),
        _env = nil,
        _milestones = {},
        _strainModule = nil,
        _decks = {},
    }
    setmetatable(world, { __index = TestWorld })
    
    -- Install test adapter FIRST (before modules load)
    TTSAdapter.Set(world._adapter)
    
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
-- Module Loading
---------------------------------------------------------------------------------------------------

function TestWorld:_loadModules()
    -- Clear cached modules to get fresh load with stubs in place
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
    local found = false
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if milestone.title == title then
            found = true
            break
        end
    end
    
    if not found then
        error("Unknown milestone: " .. title .. " (not in MILESTONE_CARDS)")
    end
    
    self._milestones[title] = true
    return true
end

---------------------------------------------------------------------------------------------------
-- State Inspection
---------------------------------------------------------------------------------------------------

function TestWorld:isReached(title)
    return self._milestones[title] == true
end

function TestWorld:milestoneReward(title)
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if milestone.title == title then
            return milestone.consequences and milestone.consequences.fightingArt
        end
    end
    return nil
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
    local rewards = self._campaignModule._test.CalculateStrainRewards(
        reached,
        self._strainModule.MILESTONE_CARDS
    )
    
    -- Track in deck state
    self._decks = self._decks or {}
    self._decks["Fighting Arts"] = rewards.fightingArts or {}
    self._decks["Vermin"] = rewards.vermin or {}
end

function TestWorld:fightingArtsDeck()
    return self._decks and self._decks["Fighting Arts"] or {}
end

function TestWorld:verminDeck()
    return self._decks and self._decks["Vermin"] or {}
end

function TestWorld:deckContains(deck, cardName)
    for _, card in ipairs(deck) do
        if card == cardName then
            return true
        end
    end
    return false
end

return TestWorld

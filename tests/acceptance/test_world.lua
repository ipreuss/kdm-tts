---------------------------------------------------------------------------------------------------
-- TestWorld: Facade for acceptance tests
-- 
-- Manages game state and provides high-level actions for test scenarios.
-- Loads real game modules with stubbed TTS environment.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = require("tests.acceptance.tts_environment")

local TestWorld = {}

function TestWorld.create()
    local world = {
        _env = TTSEnvironment.create(),
        _milestones = {},
        _strainModule = nil,
    }
    setmetatable(world, { __index = TestWorld })
    world._env:install()
    world:_loadStrainModule()
    return world
end

function TestWorld:destroy()
    self._env:uninstall()
end

---------------------------------------------------------------------------------------------------
-- Module Loading
---------------------------------------------------------------------------------------------------

function TestWorld:_loadStrainModule()
    -- Clear cached module to get fresh load with stubs in place
    package.loaded["Kdm/Strain"] = nil
    self._strainModule = require("Kdm/Strain")
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
    
    -- Get rewards that should be added
    local rewards = self:_calculateRewards(reached)
    
    -- Track in deck state (no TTS spawning)
    self._decks = self._decks or {}
    self._decks["Fighting Arts"] = self._decks["Fighting Arts"] or {}
    for _, reward in ipairs(rewards) do
        if reward.type == "fightingArt" then
            table.insert(self._decks["Fighting Arts"], reward.name)
        end
    end
end

function TestWorld:_calculateRewards(reached)
    local rewards = {}
    for _, milestone in ipairs(self._strainModule.MILESTONE_CARDS) do
        if reached[milestone.title] and milestone.consequences then
            if milestone.consequences.fightingArt then
                table.insert(rewards, {
                    type = "fightingArt",
                    name = milestone.consequences.fightingArt
                })
            end
        end
    end
    return rewards
end

function TestWorld:fightingArtsDeck()
    return self._decks and self._decks["Fighting Arts"] or {}
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

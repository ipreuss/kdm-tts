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
        _currentYear = 1,
        _timeline = {},
        _trashedSettlementEvents = {},
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
    
    -- Use REAL Strain logic to compute consequences
    local changes = self._strainModule.ComputeConsequenceChanges(milestone, self._currentYear)
    
    -- Apply changes to test state
    for _, art in ipairs(changes.fightingArts) do
        self._decks["Fighting Arts"] = self._decks["Fighting Arts"] or {}
        table.insert(self._decks["Fighting Arts"], art)
    end
    
    for _, vermin in ipairs(changes.vermin) do
        self._decks["Vermin"] = self._decks["Vermin"] or {}
        table.insert(self._decks["Vermin"], vermin)
    end
    
    for _, event in ipairs(changes.timelineEvents) do
        self._timeline[event.year] = self._timeline[event.year] or { events = {} }
        table.insert(self._timeline[event.year].events, {
            name = event.name,
            type = event.type,
        })
    end
    
    for _, cardName in ipairs(changes.trashSettlementEvents) do
        self._trashedSettlementEvents[cardName] = true
    end
    
    for _, cardName in ipairs(changes.addBasicResources) do
        self._decks["Basic Resources"] = self._decks["Basic Resources"] or {}
        table.insert(self._decks["Basic Resources"], cardName)
    end
    
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
    
    -- Use REAL Strain logic to compute what to remove
    local changes = self._strainModule.ComputeConsequenceChanges(milestone, self._currentYear)
    
    -- Remove fighting arts
    for _, art in ipairs(changes.fightingArts) do
        local deck = self._decks["Fighting Arts"] or {}
        for i, card in ipairs(deck) do
            if card == art then
                table.remove(deck, i)
                break
            end
        end
    end
    
    -- Remove vermin
    for _, vermin in ipairs(changes.vermin) do
        local deck = self._decks["Vermin"] or {}
        for i, card in ipairs(deck) do
            if card == vermin then
                table.remove(deck, i)
                break
            end
        end
    end
    
    -- Remove timeline events (by name, searching all years)
    for _, event in ipairs(changes.timelineEvents) do
        for year, yearData in pairs(self._timeline or {}) do
            local events = yearData.events or {}
            for i, e in ipairs(events) do
                if e.name == event.name then
                    table.remove(events, i)
                    break
                end
            end
        end
    end
    
    -- Restore trashed settlement events
    for _, cardName in ipairs(changes.trashSettlementEvents) do
        self._trashedSettlementEvents[cardName] = nil
    end
    
    -- Remove basic resources
    for _, cardName in ipairs(changes.addBasicResources) do
        local deck = self._decks["Basic Resources"] or {}
        for i, card in ipairs(deck) do
            if card == cardName then
                table.remove(deck, i)
                break
            end
        end
    end
    
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
    local yearData = self._timeline[year]
    if not yearData then return false end
    for _, event in ipairs(yearData.events or {}) do
        if event.name == eventName then
            return true
        end
    end
    return false
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
    return self._trashedSettlementEvents[cardName] == true
end

function TestWorld:basicResourcesDeck()
    return self._decks and self._decks["Basic Resources"] or {}
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

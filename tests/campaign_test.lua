local Test = require("tests.framework")
local Campaign = require("Kdm/Campaign")
local Timeline = require("Kdm/Timeline")
local Strain = require("Kdm/Strain")
local FightingArtsArchive = require("Kdm/FightingArtsArchive")
local VerminArchive = require("Kdm/VerminArchive")
local Showdown = require("Kdm/Showdown")
local Hunt = require("Kdm/Hunt")
local Archive = require("Kdm/Archive")
local Expansion = require("Kdm/Expansion")
local Rules = require("Kdm/Rules")
local Trash = require("Kdm/Trash")
local Survivor = require("Kdm/Survivor")
local Location = require("Kdm/Location")

local function getInternalCampaign()
    local i = 1
    while true do
        local name, value = debug.getupvalue(Campaign._test.Import, i)
        if not name then
            break
        end
        if name == "Campaign" then
            return value
        end
        i = i + 1
    end
end

local InternalCampaign = getInternalCampaign()

Test.test("Campaign.SetupSettlementEventsDeck refreshes search without card names", function(t)
    local originalRefresh = Timeline.RefreshSettlementEventSearchFromDeck
    local called = false
    Timeline.RefreshSettlementEventSearchFromDeck = function()
        called = true
    end

    Campaign._test.SetupSettlementEventsDeck(nil)

    Timeline.RefreshSettlementEventSearchFromDeck = originalRefresh
    t:assertTrue(called, "Expected refresh to run even when no card names provided")
end)

Test.test("Campaign.Import applies strain milestone state", function(t)
    local restores = {}
    local function stub(target, key, replacement)
        local original = target[key]
        target[key] = replacement
        table.insert(restores, function()
            target[key] = original
        end)
    end

    local calledState
    stub(Strain, "LoadState", function(state)
        calledState = state
    end)
    stub(Showdown, "Clean", function() end)
    stub(Hunt, "Clean", function() end)
    stub(Hunt, "Import", function() end)
    stub(InternalCampaign, "Clean", function() end)
    stub(Archive, "Clean", function() end)
    stub(Archive, "Take", function() end)
    stub(Archive, "CreateAllGearDeck", function() end)
    stub(Expansion, "SetEnabled", function() end)
    stub(Expansion, "SetUnlockedMode", function() end)
    stub(Rules, "createRulebookButtons", function() end)
    stub(InternalCampaign, "SetupArchiveOverrides", function() end)
    stub(Trash, "Import", function() end)

    local settlementDeck = {}
    function settlementDeck:Take() end
    function settlementDeck:Object() return {} end

    stub(InternalCampaign, "SetupDeckFromExpansionComponents", function(name)
        if name == "Settlement Events" then
            return settlementDeck
        end
        return {}
    end)

    stub(InternalCampaign, "SetupObjects", function() end)
    stub(InternalCampaign, "SetupSurvivalTokens", function() end)
    stub(InternalCampaign, "SetupReferences", function() end)
    stub(InternalCampaign, "SetupSettlementEventsDeck", function() end)
    stub(InternalCampaign, "SetupMisc", function() end)
    stub(InternalCampaign, "SetupCharacterDeck", function() end)
    stub(Survivor, "Import", function() end)
    stub(Survivor, "SpawnSurvivorBox", function() end)
    stub(Survivor, "Survivors", function()
        return { {}, {}, {}, {} }
    end)
    stub(Timeline, "Import", function() end)
    stub(Location, "Get", function()
        return {
            Position = function() return { x = 0, y = 0, z = 0 } end,
            Center = function() return { x = 0, y = 0, z = 0 } end,
            AllObjects = function() return {} end,
        }
    end)

    local data = {
        version = Campaign._test.EXPORT_VERSION,
        expansions = {},
        campaign = {
            name = "Integration Test Campaign",
            references = {},
            misc = {},
            timeline = {},
        },
        unlockedMode = false,
        trash = {},
        timeline = { survivalActions = {} },
        survivor = {},
        hunt = {},
        strainMilestones = { reached = { ["Milestone B"] = true } },
        objectsByLocation = {},
        settlementEventsDeck = {},
        characterDeck = {},
        departingSurvivors = { [1] = 1 },
    }

    local ok, err = pcall(function()
        Campaign._test.Import(data)
        t:assertEqual(data.strainMilestones, calledState, "Campaign.Import should forward strain milestone state to Strain.LoadState")
    end)

    for i = #restores, 1, -1 do
        restores[i]()
    end

    if not ok then
        error(err, 0)
    end
end)

Test.test("Strain milestones carry over when checkbox is unchecked", function(t)
    local internal = InternalCampaign
    local originalFlag = internal.clearStrainMilestones
    internal.clearStrainMilestones = false

    local sentinel = { reached = { Foo = true } }
    local originalSave = Strain.Save
    Strain.Save = function()
        return sentinel
    end

    local payload = Campaign._test.BuildStrainMilestoneState()

    internal.clearStrainMilestones = originalFlag
    Strain.Save = originalSave

    t:assertDeepEqual(sentinel, payload, "Expected strain milestones to carry over when checkbox unchecked")
end)

Test.test("Strain milestones reset when checkbox is checked", function(t)
    local internal = InternalCampaign
    local originalFlag = internal.clearStrainMilestones
    internal.clearStrainMilestones = true

    local originalSave = Strain.Save
    Strain.Save = function()
        error("Strain.Save should not be invoked when clearing milestones")
    end

    local payload = Campaign._test.BuildStrainMilestoneState()

    internal.clearStrainMilestones = originalFlag
    Strain.Save = originalSave

    t:assertDeepEqual({}, payload, "Expected empty strain milestones payload when checkbox checked")
end)

Test.test("Campaign.RandomSelect returns unique subset", function(t)
    local originalRandom = math.random
    local picks = { 5, 2, 1 }
    local index = 0
    math.random = function(_, upper)
        index = index + 1
        local value = picks[index] or 1
        if value > upper then
            value = upper
        elseif value < 1 then
            value = 1
        end
        return value
    end

    local pool = { "A", "B", "C", "D", "E" }
    local selected = InternalCampaign.RandomSelect(pool, 2)

    math.random = originalRandom

    t:assertEqual(2, #selected, "Should return requested number of items")
    t:assertTrue(selected[1] ~= selected[2], "RandomSelect should not return duplicates")
end)

Test.test("Campaign.AddStrainRewards skips when no milestones unlocked", function(t)
    local originalSave = Strain.Save
    local originalMilestones = Strain.MILESTONE_CARDS
    local originalAdd = FightingArtsArchive.AddCard

    Strain.Save = function()
        return { reached = {} }
    end
    Strain.MILESTONE_CARDS = {
        { title = "Milestone A", consequences = { fightingArt = "Art A" } },
    }

    local called = false
    FightingArtsArchive.AddCard = function()
        called = true
    end

    InternalCampaign.AddStrainRewards()

    Strain.Save = originalSave
    Strain.MILESTONE_CARDS = originalMilestones
    FightingArtsArchive.AddCard = originalAdd

    t:assertFalse(called, "No cards should be added when no milestones are reached")
end)

Test.test("Campaign.AddStrainRewards adds selected fighting arts via archive", function(t)
    local originalSave = Strain.Save
    local originalMilestones = Strain.MILESTONE_CARDS
    local originalAdd = FightingArtsArchive.AddCard
    local originalSelect = InternalCampaign.RandomSelect

    Strain.Save = function()
        return {
            reached = {
                ["Milestone A"] = true,
                ["Milestone B"] = true,
                ["Milestone C"] = true,
            }
        }
    end
    Strain.MILESTONE_CARDS = {
        { title = "Milestone A", consequences = { fightingArt = "Art A" } },
        { title = "Milestone B", consequences = { fightingArt = "Art B" } },
        { title = "Milestone C", consequences = { fightingArt = "Art C" } },
    }

    local requestedItems
    InternalCampaign.RandomSelect = function(items, count)
        requestedItems = {}
        for i = 1, #items do
            requestedItems[i] = items[i]
        end
        return { items[2], items[3] }
    end

    local added = {}
    FightingArtsArchive.AddCard = function(card)
        table.insert(added, card)
        return true
    end

    InternalCampaign.AddStrainRewards()

    Strain.Save = originalSave
    Strain.MILESTONE_CARDS = originalMilestones
    FightingArtsArchive.AddCard = originalAdd
    InternalCampaign.RandomSelect = originalSelect

    t:assertEqual(3, #requestedItems, "RandomSelect should receive all unlocked rewards")
    t:assertDeepEqual({ "Art B", "Art C" }, added, "Only selected fighting arts should be added")
end)

Test.test("Campaign.AddStrainRewards applies vermin rewards", function(t)
    local originalSave = Strain.Save
    local originalMilestones = Strain.MILESTONE_CARDS
    local originalVermin = VerminArchive.AddCard

    Strain.Save = function()
        return {
            reached = {
                ["Milestone V"] = true,
            }
        }
    end
    Strain.MILESTONE_CARDS = {
        { title = "Milestone V", consequences = { vermin = "Fiddler Crab Spider", timelineEvent = { name = "Acid Storm", type = "SettlementEvent", offset = 1 } } },
    }

    local verminCalls = {}
    VerminArchive.AddCard = function(card)
        table.insert(verminCalls, card)
        return true
    end

    InternalCampaign.AddStrainRewards()

    Strain.Save = originalSave
    Strain.MILESTONE_CARDS = originalMilestones
    VerminArchive.AddCard = originalVermin

    t:assertDeepEqual({ "Fiddler Crab Spider" }, verminCalls, "Vermin reward should be added")
end)

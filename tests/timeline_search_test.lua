local Test = require("tests.framework")
local Timeline = require("Kdm/Timeline")

local function reset()
    Timeline._testResetSearchState()
end

local function withStubbedLocationGet(stub, fn)
    Timeline._test.SetLocationGet(stub)
    local ok, err = pcall(fn)
    Timeline._test.ResetLocationGet()
    if not ok then
        error(err, 0)
    end
end

local function withStubbedDeck(objectsProvider, fn)
    withStubbedLocationGet(function()
        return {
            FirstObject = function()
                return {}
            end,
        }
    end, function()
        Timeline._test.SetContainerFunction(function()
            local container = {}
            function container:Objects()
                return objectsProvider()
            end
            return container
        end)
        local ok, err = pcall(fn)
        Timeline._test.ResetContainerFunction()
        if not ok then
            error(err, 0)
        end
    end)
end

Test.test("SortedKeys returns ordered keys", function(t)
    reset()
    local result = Timeline._test.SortedKeys({ b = true, a = true, c = true })
    t:assertDeepEqual({ "a", "b", "c" }, result)
end)

Test.test("RebuildSearchTrie indexes deck names and base entries", function(t)
    reset()
    Timeline._test.AddBaseSearchEntry({ "Rule" }, { name = "Rule", type = "RulebookEvent" })
    Timeline._test.RebuildSearchTrie({ "Heat Wave" })

    local settlementResults = Timeline._test.GetTrie():Get("Heat")
    t:assertEqual(1, #settlementResults)
    t:assertEqual("Heat Wave", settlementResults[1].name)
    t:assertEqual("SettlementEvent", settlementResults[1].type)

    local ruleResults = Timeline._test.GetTrie():Get("Rule")
    t:assertEqual(1, #ruleResults)
    t:assertEqual("Rule", ruleResults[1].name)
    t:assertEqual("RulebookEvent", ruleResults[1].type)
end)

Test.test("NamesEqual compares ordered arrays", function(t)
    reset()
    local equals = Timeline._test.NamesEqual
    t:assertTrue(equals({ "a", "b" }, { "a", "b" }))
    t:assertFalse(equals({ "a", "b" }, { "b", "a" }))
    t:assertFalse(equals({ "a" }, { "a", "b" }))
end)

Test.test("RefreshSettlementEventSearchFromDeck clears settlement entries when location missing", function(t)
    reset()
    Timeline._test.RebuildSearchTrie({ "Heat Wave" })
    t:assertTrue(Timeline._test.GetCurrentSettlementEventNames() ~= nil)
    withStubbedLocationGet(function()
        return nil
    end, function()
        Timeline.RefreshSettlementEventSearchFromDeck()
    end)
    t:assertEqual(nil, Timeline._test.GetCurrentSettlementEventNames())
end)

Test.test("SettlementEventNamesFromDeck returns nil when container errors", function(t)
    reset()
    withStubbedLocationGet(function()
        return {
            FirstObject = function()
                return {}
            end,
        }
    end, function()
        Timeline._test.SetContainerFunction(function()
            return {
                Objects = function()
                    error("container failure")
                end,
            }
        end)

        local ok, result = pcall(Timeline._test.SettlementEventNamesFromDeck)
        Timeline._test.ResetContainerFunction()
        t:assertTrue(ok)
        t:assertEqual(nil, result)
    end)
end)

Test.test("Settlement event search mirrors deck contents", function(t)
    reset()
    local deckCards = {
        { name = "Heat Wave", gm_notes = "Settlement Events" },
        { name = "Glossolalia", gm_notes = "Settlement Events" },
        { name = "Not Included", gm_notes = "Innovations" },
    }
    withStubbedDeck(function()
        return deckCards
    end, function()
        Timeline.RefreshSettlementEventSearchFromDeck()
    end)
    local names = Timeline._test.GetCurrentSettlementEventNames()
    t:assertDeepEqual({ "Glossolalia", "Heat Wave" }, names)

    local results = Timeline._test.GetTrie():Get("Heat")
    t:assertEqual(1, #results)
    t:assertEqual("Heat Wave", results[1].name)
end)

Test.test("Settlement event search updates as deck changes", function(t)
    reset()
    local deckCards = {
        { name = "Heat Wave", gm_notes = "Settlement Events" },
    }
    withStubbedDeck(function()
        return deckCards
    end, function()
        Timeline.RefreshSettlementEventSearchFromDeck()
        t:assertTrue(Timeline._test.NamesEqual({ "Heat Wave" }, Timeline._test.GetCurrentSettlementEventNames()))

        deckCards = {
            { name = "Rivalry", gm_notes = "Settlement Events" },
        }

        Timeline.RefreshSettlementEventSearchFromDeck()
    end)

    t:assertTrue(Timeline._test.NamesEqual({ "Rivalry" }, Timeline._test.GetCurrentSettlementEventNames()))
end)

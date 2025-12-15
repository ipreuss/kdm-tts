---------------------------------------------------------------------------------------------------
-- Hunt Cleanup Acceptance Tests (kdm-0zu)
--
-- User story: When the hunt ends and cleanup runs, stacked hunt event cards (decks)
-- should be cleaned up just like individual cards.
--
-- SCOPE: What these tests verify (headless)
--   - Location:Clean() properly handles Deck objects when types is specified
--   - Decks containing only matching types are destroyed
--   - Decks containing mixed types are preserved as blocking
--
-- This tests the Location:Clean() behavior that Hunt.CleanInternal() depends on.
-- The unit tests in location_clean_test.lua test implementation details.
-- These acceptance tests verify user-visible behavior.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Minimal stubs for Location module
---------------------------------------------------------------------------------------------------

local function createLocationStubs()
    return {
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Console"] = { AddCommand = function() end },
        ["Kdm/Util/Container"] = {},
        ["Kdm/Util/EventManager"] = { AddHandler = function() end },
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/LocationData"] = {},
        ["Kdm/Log"] = { ForModule = function() return { Debugf = function() end, Errorf = function() end } end },
        ["Kdm/NamedObject"] = { DEFAULT_CAST_HEIGHT = 5 },
        ["Kdm/Util/Util"] = {
            ArrayContains = function(array, value)
                for _, element in ipairs(array) do
                    if element == value then return true end
                end
                return false
            end,
        },
    }
end

local function withStubs(stubs, fn)
    local originals = {}
    for name, mod in pairs(stubs) do
        originals[name] = package.loaded[name]
        package.loaded[name] = mod
    end
    local ok, err = pcall(fn)
    for name, orig in pairs(originals) do
        package.loaded[name] = orig
    end
    if not ok then
        error(err)
    end
end

---------------------------------------------------------------------------------------------------
-- Mock objects for acceptance tests
---------------------------------------------------------------------------------------------------

-- Mock a single hunt event card
local function createHuntCard(name, cardType)
    local destroyed = false
    return {
        tag = "Card",
        interactable = true,
        getName = function() return name end,
        getGUID = function() return "card-" .. name end,
        getGMNotes = function() return cardType end,
        destruct = function() destroyed = true end,
        isDestroyed = function() return destroyed end,
    }
end

-- Mock a deck containing multiple cards (like Herb Gathering + Mineral Gathering stacked)
local function createHuntDeck(name, cards)
    local destroyed = false
    return {
        tag = "Deck",
        interactable = true,
        getName = function() return name end,
        getGUID = function() return "deck-" .. name end,
        getGMNotes = function() return "" end,  -- Decks have empty GMNotes
        getQuantity = function() return #cards end,
        getObjects = function()
            local objects = {}
            for i, card in ipairs(cards) do
                table.insert(objects, {
                    index = i - 1,
                    name = card.name,
                    gm_notes = card.type,
                })
            end
            return objects
        end,
        destruct = function() destroyed = true end,
        isDestroyed = function() return destroyed end,
    }
end

-- Hunt card types (matches Hunt.ttslua HUNT_CARD_TYPES)
local HUNT_CARD_TYPES = { "Hunt Events", "Monster Hunt Events", "Special Hunt Events" }

-- Create fake cast function
local function createFakeCastFunc(objects)
    return function(self, params)
        local hits = {}
        for _, obj in ipairs(objects) do
            table.insert(hits, { hit_object = obj })
        end
        return hits
    end
end

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Deck Cleanup Behavior (kdm-0zu)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup removes deck of stacked Special Hunt Events", function(t)
    -- GIVEN: Two Special Hunt Event cards stacked on the same track space (forming a deck)
    -- This happens when e.g., Herb Gathering and Mineral Gathering land on the same space

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location"] = nil
        local Location = require("Kdm/Location")

        local stackedDeck = createHuntDeck("Stacked Special Hunt Events", {
            { name = "Herb Gathering", type = "Special Hunt Events" },
            { name = "Mineral Gathering", type = "Special Hunt Events" },
        })

        local fakeCast = createFakeCastFunc({ stackedDeck })
        local location = setmetatable({}, Location)

        -- WHEN: Hunt cleanup runs (calling BoxClean with HUNT_CARD_TYPES)
        local blocking = location:Clean({ types = HUNT_CARD_TYPES }, fakeCast)

        -- THEN: The deck should be removed (not blocking)
        t:assertTrue(stackedDeck.isDestroyed(),
            "Deck of Special Hunt Events should be cleaned up during hunt cleanup")
        t:assertEqual(0, #blocking,
            "No blocking objects when deck contains only hunt cards")
    end)
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup removes deck with mixed hunt card types", function(t)
    -- GIVEN: Hunt cards of different types stacked together
    -- (e.g., a Hunt Event and a Special Hunt Event on the same space)

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location"] = nil
        local Location = require("Kdm/Location")

        local mixedHuntDeck = createHuntDeck("Mixed Hunt Cards", {
            { name = "Abandoned Lair", type = "Hunt Events" },
            { name = "Herb Gathering", type = "Special Hunt Events" },
            { name = "White Lion Ambush", type = "Monster Hunt Events" },
        })

        local fakeCast = createFakeCastFunc({ mixedHuntDeck })
        local location = setmetatable({}, Location)

        -- WHEN: Hunt cleanup runs
        local blocking = location:Clean({ types = HUNT_CARD_TYPES }, fakeCast)

        -- THEN: The deck should be removed (all cards are hunt card types)
        t:assertTrue(mixedHuntDeck.isDestroyed(),
            "Deck of mixed hunt card types should be cleaned up")
        t:assertEqual(0, #blocking)
    end)
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup preserves deck containing non-hunt cards", function(t)
    -- GIVEN: A deck that somehow contains a non-hunt card mixed with hunt cards
    -- (This should be preserved as blocking to avoid accidental data loss)

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location"] = nil
        local Location = require("Kdm/Location")

        local mixedDeck = createHuntDeck("Mixed with Non-Hunt", {
            { name = "Herb Gathering", type = "Special Hunt Events" },
            { name = "Random Gear Card", type = "Gear" },  -- Not a hunt card!
        })

        local fakeCast = createFakeCastFunc({ mixedDeck })
        local location = setmetatable({}, Location)

        -- WHEN: Hunt cleanup runs
        local blocking = location:Clean({ types = HUNT_CARD_TYPES }, fakeCast)

        -- THEN: The deck should NOT be removed (contains non-hunt card)
        t:assertFalse(mixedDeck.isDestroyed(),
            "Deck containing non-hunt cards should NOT be cleaned up")
        t:assertEqual(1, #blocking,
            "Mixed deck should be returned as blocking object")
    end)
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup handles individual cards alongside decks", function(t)
    -- GIVEN: A mix of individual cards and a deck at the same location

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location"] = nil
        local Location = require("Kdm/Location")

        local individualCard = createHuntCard("Lonely Hunt Event", "Hunt Events")
        local stackedDeck = createHuntDeck("Stacked Cards", {
            { name = "Herb Gathering", type = "Special Hunt Events" },
            { name = "Mineral Gathering", type = "Special Hunt Events" },
        })

        local fakeCast = createFakeCastFunc({ individualCard, stackedDeck })
        local location = setmetatable({}, Location)

        -- WHEN: Hunt cleanup runs
        local blocking = location:Clean({ types = HUNT_CARD_TYPES }, fakeCast)

        -- THEN: Both should be cleaned up
        t:assertTrue(individualCard.isDestroyed(),
            "Individual hunt card should be cleaned up")
        t:assertTrue(stackedDeck.isDestroyed(),
            "Deck of hunt cards should be cleaned up")
        t:assertEqual(0, #blocking)
    end)
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Original card cleanup behavior unchanged", function(t)
    -- GIVEN: Individual hunt event cards (not in a deck)
    -- This ensures the fix for decks didn't break existing card cleanup

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location"] = nil
        local Location = require("Kdm/Location")

        local huntEvent = createHuntCard("Abandoned Lair", "Hunt Events")
        local specialEvent = createHuntCard("Herb Gathering", "Special Hunt Events")
        local monsterEvent = createHuntCard("White Lion Ambush", "Monster Hunt Events")

        local fakeCast = createFakeCastFunc({ huntEvent, specialEvent, monsterEvent })
        local location = setmetatable({}, Location)

        -- WHEN: Hunt cleanup runs
        local blocking = location:Clean({ types = HUNT_CARD_TYPES }, fakeCast)

        -- THEN: All individual cards should be cleaned up (existing behavior)
        t:assertTrue(huntEvent.isDestroyed(), "Hunt Event card should be cleaned up")
        t:assertTrue(specialEvent.isDestroyed(), "Special Hunt Event card should be cleaned up")
        t:assertTrue(monsterEvent.isDestroyed(), "Monster Hunt Event card should be cleaned up")
        t:assertEqual(0, #blocking)
    end)
end)

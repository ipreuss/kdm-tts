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
local LocationStubs = require("tests.support.location_stubs")

-- Import shared stubs and helpers
local createLocationStubs = LocationStubs.createLocationStubs
local withStubs = LocationStubs.withStubs
local createFakeCastFunc = LocationStubs.createFakeCastFunc

---------------------------------------------------------------------------------------------------
-- Domain-specific mock factories for acceptance tests
---------------------------------------------------------------------------------------------------

-- Create a hunt event card using domain language
local function createHuntCard(name, cardType)
    return LocationStubs.createMockObject({
        tag = "Card",
        name = name,
        guid = "card-" .. name,
        gmNotes = cardType,
    })
end

-- Create a deck of hunt cards (like Herb Gathering + Mineral Gathering stacked)
local function createHuntDeck(name, cards)
    -- Convert domain format { name, type } to stub format { name, gmNotes }
    local containedCards = {}
    for _, card in ipairs(cards) do
        table.insert(containedCards, {
            name = card.name,
            gmNotes = card.type,
        })
    end
    return LocationStubs.createMockDeck({
        name = name,
        guid = "deck-" .. name,
        containedCards = containedCards,
    })
end

-- Hunt card types (matches Hunt.ttslua HUNT_CARD_TYPES)
local HUNT_CARD_TYPES = { "Hunt Events", "Monster Hunt Events", "Special Hunt Events" }

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Deck Cleanup Behavior (kdm-0zu)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup removes deck of stacked Special Hunt Events", function(t)
    -- GIVEN: Two Special Hunt Event cards stacked on the same track space (forming a deck)
    -- This happens when e.g., Herb Gathering and Mineral Gathering land on the same space

    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

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
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

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
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

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
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

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
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

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

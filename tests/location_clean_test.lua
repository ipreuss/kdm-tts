---------------------------------------------------------------------------------------------------
-- Characterization Tests: Location:Clean()
--
-- These tests capture existing behavior before adding Deck handling.
-- Created: 2025-12-15 for bead kdm-0zu
--
-- DISCOVERED BEHAVIOR:
--   - Objects with matching GMNotes type are destroyed
--   - Objects with matching tag are destroyed
--   - Objects with ignored tags (Board, Table) are skipped (not blocking, not destroyed)
--   - Non-interactable objects are skipped
--   - Objects with ignored types are skipped
--   - Non-matching objects are returned as blocking
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local LocationStubs = require("tests.support.location_stubs")

-- Import shared stubs and helpers
local createLocationStubs = LocationStubs.createLocationStubs
local withStubs = LocationStubs.withStubs
local createMockObject = LocationStubs.createMockObject
local createMockDeck = LocationStubs.createMockDeck
local createFakeCastFunc = LocationStubs.createFakeCastFunc

---------------------------------------------------------------------------------------------------
-- Tests for Location.Matches
---------------------------------------------------------------------------------------------------

Test.test("CHARACTERIZATION: Location.Matches returns true for matching tag", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ tag = "Card" })
        local result = Location.Matches(obj, { "Card", "Deck" }, nil)
        t:assertEqual(true, result)
    end)
end)

Test.test("CHARACTERIZATION: Location.Matches returns true for matching type (GMNotes)", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ gmNotes = "Special Hunt Events" })
        local result = Location.Matches(obj, nil, { "Special Hunt Events", "Basic Hunt Events" })
        t:assertEqual(true, result)
    end)
end)

Test.test("CHARACTERIZATION: Location.Matches returns false for non-matching tag and type", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ tag = "Figurine", gmNotes = "Monster" })
        local result = Location.Matches(obj, { "Card" }, { "Special Hunt Events" })
        t:assertEqual(false, result)
    end)
end)

Test.test("CHARACTERIZATION: Location.Matches returns false when tags is nil and type doesn't match", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ tag = "Deck", gmNotes = "" })
        local result = Location.Matches(obj, nil, { "Special Hunt Events" })
        t:assertEqual(false, result)
    end)
end)

---------------------------------------------------------------------------------------------------
-- Tests for Location:Clean
---------------------------------------------------------------------------------------------------

Test.test("CHARACTERIZATION: Clean destroys Card with matching GMNotes type", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local card = createMockObject({ tag = "Card", gmNotes = "Special Hunt Events" })
        local fakeCast = createFakeCastFunc({ card })

        -- Create a minimal location instance
        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(true, card.isDestroyed())
        t:assertEqual(0, #blocking)
    end)
end)

Test.test("CHARACTERIZATION: Clean returns Card with non-matching type as blocking", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local card = createMockObject({ tag = "Card", gmNotes = "Abilities" })
        local fakeCast = createFakeCastFunc({ card })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(false, card.isDestroyed())
        t:assertEqual(1, #blocking)
        t:assertEqual(card, blocking[1])
    end)
end)

Test.test("CHARACTERIZATION: Clean destroys object with matching tag", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local deck = createMockObject({ tag = "Deck", gmNotes = "" })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ tags = { "Deck" } }, fakeCast)

        t:assertEqual(true, deck.isDestroyed())
        t:assertEqual(0, #blocking)
    end)
end)

Test.test("CHARACTERIZATION: Clean ignores Board objects (CLEAN_IGNORE_TAGS)", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local board = createMockObject({ tag = "Board", gmNotes = "" })
        local fakeCast = createFakeCastFunc({ board })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(false, board.isDestroyed())
        t:assertEqual(0, #blocking)  -- Board is ignored, NOT blocking
    end)
end)

Test.test("CHARACTERIZATION: Clean ignores Table objects (CLEAN_IGNORE_TAGS)", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local tableObj = createMockObject({ tag = "Table", gmNotes = "" })
        local fakeCast = createFakeCastFunc({ tableObj })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(false, tableObj.isDestroyed())
        t:assertEqual(0, #blocking)  -- Table is ignored, NOT blocking
    end)
end)

Test.test("CHARACTERIZATION: Clean ignores non-interactable objects", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ tag = "Card", gmNotes = "Special Hunt Events", interactable = false })
        local fakeCast = createFakeCastFunc({ obj })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(false, obj.isDestroyed())  -- Not destroyed even though type matches
        t:assertEqual(0, #blocking)  -- Not blocking either
    end)
end)

Test.test("CHARACTERIZATION: Clean ignores objects with ignored types", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local obj = createMockObject({ tag = "Card", gmNotes = "Monster Resources" })
        local fakeCast = createFakeCastFunc({ obj })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({
            types = { "Special Hunt Events" },
            ignoreTypes = { "Monster Resources" }
        }, fakeCast)

        t:assertEqual(false, obj.isDestroyed())
        t:assertEqual(0, #blocking)  -- Ignored, NOT blocking
    end)
end)

Test.test("CHARACTERIZATION: Clean processes multiple objects correctly", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        local matchingCard = createMockObject({ tag = "Card", gmNotes = "Special Hunt Events", name = "Herb Gathering" })
        local nonMatchingCard = createMockObject({ tag = "Card", gmNotes = "Abilities", name = "Some Ability" })
        local board = createMockObject({ tag = "Board", name = "Hunt Board" })

        local fakeCast = createFakeCastFunc({ matchingCard, nonMatchingCard, board })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(true, matchingCard.isDestroyed())   -- Matching type destroyed
        t:assertEqual(false, nonMatchingCard.isDestroyed())  -- Non-matching returned as blocking
        t:assertEqual(false, board.isDestroyed())  -- Board ignored
        t:assertEqual(1, #blocking)
        t:assertEqual(nonMatchingCard, blocking[1])
    end)
end)

---------------------------------------------------------------------------------------------------
-- Tests documenting Deck behavior
-- NOTE: The bug (Deck returned as blocking) has been fixed.
-- Decks are now inspected for their card contents when types is specified.
---------------------------------------------------------------------------------------------------

Test.test("Clean returns Deck as blocking when deck has no cards matching types", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Deck with no cards matching the requested types should be blocking
        local deck = createMockDeck({
            gmNotes = "",
            containedCards = {
                { name = "Some Card", gmNotes = "Unrelated Type" },
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        -- Deck with non-matching cards should be blocking
        t:assertEqual(false, deck.isDestroyed())
        t:assertEqual(1, #blocking)
        t:assertEqual(deck, blocking[1])
    end)
end)

Test.test("CHARACTERIZATION: Clean destroys Deck when tags includes Deck", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- This works: when tags includes "Deck", the Deck object matches
        local deck = createMockObject({ tag = "Deck", gmNotes = "" })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ tags = { "Card", "Deck" } }, fakeCast)

        t:assertEqual(true, deck.isDestroyed())
        t:assertEqual(0, #blocking)
    end)
end)

---------------------------------------------------------------------------------------------------
-- NEW BEHAVIOR TESTS: Deck handling when only types specified
---------------------------------------------------------------------------------------------------

Test.test("Clean destroys Deck when ALL contained cards match types", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Deck containing only Special Hunt Events cards (should be cleaned up)
        local deck = createMockDeck({
            containedCards = {
                { name = "Herb Gathering", gmNotes = "Special Hunt Events" },
                { name = "Mineral Gathering", gmNotes = "Special Hunt Events" },
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(true, deck.isDestroyed(), "Deck with all matching cards should be destroyed")
        t:assertEqual(0, #blocking)
    end)
end)

Test.test("Clean returns Deck as blocking when ANY contained card doesn't match types", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Deck containing mixed cards (one matches, one doesn't)
        local deck = createMockDeck({
            containedCards = {
                { name = "Herb Gathering", gmNotes = "Special Hunt Events" },
                { name = "Some Ability", gmNotes = "Abilities" },  -- Doesn't match
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(false, deck.isDestroyed(), "Mixed deck should NOT be destroyed")
        t:assertEqual(1, #blocking, "Mixed deck should be returned as blocking")
        t:assertEqual(deck, blocking[1])
    end)
end)

Test.test("Clean destroys Deck when cards match any of multiple types", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Deck with cards matching different hunt card types
        local deck = createMockDeck({
            containedCards = {
                { name = "Herb Gathering", gmNotes = "Special Hunt Events" },
                { name = "Basic Hunt Event", gmNotes = "Basic Hunt Events" },
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        -- HUNT_CARD_TYPES includes both "Special Hunt Events" and "Basic Hunt Events"
        local blocking = location:Clean({
            types = { "Special Hunt Events", "Basic Hunt Events", "Hunt Events" }
        }, fakeCast)

        t:assertEqual(true, deck.isDestroyed(), "Deck should be destroyed when all cards match any of the types")
        t:assertEqual(0, #blocking)
    end)
end)

Test.test("Clean ignores Deck when tags is specified (existing behavior preserved)", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- When tags include "Deck", we use the tag match (existing behavior)
        local deck = createMockDeck({
            containedCards = {
                { name = "Herb Gathering", gmNotes = "Special Hunt Events" },
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        -- When tags is specified and includes Deck, use existing tag-based matching
        local blocking = location:Clean({ tags = { "Deck" } }, fakeCast)

        t:assertEqual(true, deck.isDestroyed(), "Deck should be destroyed via tag match")
        t:assertEqual(0, #blocking)
    end)
end)

Test.test("Clean does not check Deck contents when no types specified", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Only tags specified, no types - should use existing tag-based behavior
        local deck = createMockDeck({
            containedCards = {
                { name = "Something", gmNotes = "SomeType" },
            }
        })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        -- No tags match, no types specified - deck should be blocking (existing behavior)
        local blocking = location:Clean({ tags = { "Card" } }, fakeCast)

        t:assertEqual(false, deck.isDestroyed())
        t:assertEqual(1, #blocking, "Deck should be blocking when tag doesn't match and no types to check")
    end)
end)

Test.test("Clean destroys empty Deck when types is specified", function(t)
    withStubs(createLocationStubs(), function()
        package.loaded["Kdm/Location/Location"] = nil
        local Location = require("Kdm/Location/Location")

        -- Empty deck (no cards) should be destroyed since it doesn't contain
        -- any cards that would be "wrong" to destroy (vacuous truth)
        local deck = createMockDeck({ containedCards = {} })
        local fakeCast = createFakeCastFunc({ deck })

        local location = setmetatable({}, Location)

        local blocking = location:Clean({ types = { "Special Hunt Events" } }, fakeCast)

        t:assertEqual(true, deck.isDestroyed(), "Empty deck should be destroyed when types specified")
        t:assertEqual(0, #blocking)
    end)
end)

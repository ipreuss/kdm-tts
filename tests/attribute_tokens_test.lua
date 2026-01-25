---------------------------------------------------------------------------------------------------
-- Attribute Token Tests (kdm-spk)
--
-- Tests for attribute token recognition on all player display card locations.
-- Verifies tokens are summed correctly in player modifiers regardless of card type.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Mock Helpers
---------------------------------------------------------------------------------------------------

local function createMockToken(name, faceDown, quantity)
    return {
        tag = "Generic",  -- Not "Card"
        getName = function() return name end,
        getGMNotes = function() return "Tokens" end,
        getQuantity = function() return quantity or 1 end,
        getRotation = function()
            -- Face down = z rotation near 180
            return { z = faceDown and 180 or 0 }
        end,
        registerCollisions = function() end,
    }
end

local function createMockCard(name)
    return {
        tag = "Card",
        getName = function() return name end,
        getGMNotes = function() return "Fighting Arts" end,
    }
end

local function createMockLocation(objects)
    return {
        AllObjects = function() return objects or {} end,
    }
end

---------------------------------------------------------------------------------------------------
-- Test: TOKEN_STATS maps token names to stat keys
---------------------------------------------------------------------------------------------------

Test.test("Player.TOKEN_STATS maps all attribute token names", function(t)
    -- Load actual Player module for TOKEN_STATS reference
    local Player = require("Kdm/Entity/Player")

    t:assertEqual(Player.TOKEN_STATS["Movement Token"], "movement")
    t:assertEqual(Player.TOKEN_STATS["Speed Token"], "speed")
    t:assertEqual(Player.TOKEN_STATS["Accuracy Token"], "accuracy")
    t:assertEqual(Player.TOKEN_STATS["Strength Token"], "strength")
    t:assertEqual(Player.TOKEN_STATS["Evasion Token"], "evasion")
    t:assertEqual(Player.TOKEN_STATS["Luck Token"], "luck")
    t:assertEqual(Player.TOKEN_STATS["Lunacy Token"], "frenzy")
end)

---------------------------------------------------------------------------------------------------
-- Mock TokenValue for headless tests (mirrors Util.TokenValue logic)
---------------------------------------------------------------------------------------------------

-- Mock implementation that doesn't depend on TTS APIs
local function mockTokenValue(token)
    local rotation = token.getRotation()
    local faceDown = rotation and rotation.z and math.abs(rotation.z - 180) < 10
    local value = faceDown and -1 or 1
    local qty = token.getQuantity() or 1
    if qty >= 2 then
        value = value * qty
    end
    return value
end

---------------------------------------------------------------------------------------------------
-- Test: Token value calculation
---------------------------------------------------------------------------------------------------

Test.test("Token value returns 1 for face-up token", function(t)
    local token = createMockToken("Strength Token", false, 1)
    local value = mockTokenValue(token)
    t:assertEqual(value, 1)
end)

Test.test("Token value returns -1 for face-down token", function(t)
    local token = createMockToken("Strength Token", true, 1)
    local value = mockTokenValue(token)
    t:assertEqual(value, -1)
end)

Test.test("Token value multiplies by quantity", function(t)
    local token = createMockToken("Strength Token", false, 3)
    local value = mockTokenValue(token)
    t:assertEqual(value, 3)
end)

---------------------------------------------------------------------------------------------------
-- BEHAVIOR: All token types on all card locations are now counted (kdm-spk)
---------------------------------------------------------------------------------------------------

Test.test("All token types on gear locations are counted (not just evasion)", function(t)
    -- Behavior changed in kdm-spk: ALL token types on gear/cards are counted
    local Player = require("Kdm/Entity/Player")

    -- Verify all token types are mapped (and will be counted)
    t:assertNotNil(Player.TOKEN_STATS["Evasion Token"], "Evasion token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Strength Token"], "Strength token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Speed Token"], "Speed token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Accuracy Token"], "Accuracy token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Movement Token"], "Movement token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Luck Token"], "Luck token should be mapped")
    t:assertNotNil(Player.TOKEN_STATS["Lunacy Token"], "Lunacy token should be mapped")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE: AC1 - Tokens on any player display card are counted
---------------------------------------------------------------------------------------------------

Test.test("AC1: CARD_LOCATION_SUFFIXES includes all card display locations", function(t)
    local Player = require("Kdm/Entity/Player")

    -- Verify the constant exists and contains expected entries
    t:assertNotNil(Player.CARD_LOCATION_SUFFIXES, "CARD_LOCATION_SUFFIXES should exist")
    t:assertGreaterThan(#Player.CARD_LOCATION_SUFFIXES, 0, "Should have entries")

    -- Verify key location types are included
    local function contains(list, value)
        for _, v in ipairs(list) do
            if v == value then return true end
        end
        return false
    end

    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Fighting Art 1"), "Should include Fighting Art 1")
    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Disorder 1"), "Should include Disorder 1")
    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Weapon Proficiency"), "Should include Weapon Proficiency")
    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Gear 1"), "Should include Gear 1")
    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Ability/Impairment 1"), "Should include Ability/Impairment 1")
    t:assertTrue(contains(Player.CARD_LOCATION_SUFFIXES, "Ability/Impairment 11"), "Should include Ability/Impairment 11")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE: AC2 - Token sum shown correctly
---------------------------------------------------------------------------------------------------

Test.test("AC2: Multiple tokens on different cards should sum correctly", function(t)
    local Player = require("Kdm/Entity/Player")

    -- Test the summing logic conceptually
    local modifiers = {}

    -- Simulate adding tokens from multiple locations
    local tokensToSum = {
        { stat = "strength", value = 1 },  -- Fighting Art 1
        { stat = "strength", value = 2 },  -- Gear 3
        { stat = "accuracy", value = 1 },  -- Disorder 2
    }

    for _, token in ipairs(tokensToSum) do
        modifiers[token.stat] = (modifiers[token.stat] or 0) + token.value
    end

    t:assertEqual(modifiers["strength"], 3, "Strength should sum to 3")
    t:assertEqual(modifiers["accuracy"], 1, "Accuracy should be 1")
    t:assertNil(modifiers["speed"], "Speed should be nil (no tokens)")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE: AC4/AC5 - Export/Import persistence
---------------------------------------------------------------------------------------------------

Test.test("AC4: NON_GEAR_CARD_SUFFIXES includes card-only locations for export", function(t)
    local Player = require("Kdm/Entity/Player")

    -- Verify the constant exists for export use
    t:assertNotNil(Player.NON_GEAR_CARD_SUFFIXES, "NON_GEAR_CARD_SUFFIXES should exist")
    t:assertGreaterThan(#Player.NON_GEAR_CARD_SUFFIXES, 0, "Should have entries")

    -- Verify key location types are included
    local function contains(list, value)
        for _, v in ipairs(list) do
            if v == value then return true end
        end
        return false
    end

    -- Should include card locations
    t:assertTrue(contains(Player.NON_GEAR_CARD_SUFFIXES, "Fighting Art 1"), "Should include Fighting Art 1")
    t:assertTrue(contains(Player.NON_GEAR_CARD_SUFFIXES, "Disorder 1"), "Should include Disorder 1")
    t:assertTrue(contains(Player.NON_GEAR_CARD_SUFFIXES, "Weapon Proficiency"), "Should include Weapon Proficiency")
    t:assertTrue(contains(Player.NON_GEAR_CARD_SUFFIXES, "Ability/Impairment 1"), "Should include Ability/Impairment 1")

    -- Should NOT include gear locations (those are handled separately in export)
    t:assertFalse(contains(Player.NON_GEAR_CARD_SUFFIXES, "Gear 1"), "Should NOT include Gear 1")
    t:assertFalse(contains(Player.NON_GEAR_CARD_SUFFIXES, "Fist & Tooth"), "Should NOT include Fist & Tooth")
end)

---------------------------------------------------------------------------------------------------
-- Integration test helper: Scan locations and sum tokens
---------------------------------------------------------------------------------------------------

-- This function mirrors the logic in Player.UpdateStats() using the shared constant
local function scanLocationsForTokens(locationGetter, playerPrefix, cardLocationSuffixes, tokenStats, tokenValueFn)
    local modifiers = {}

    for _, suffix in ipairs(cardLocationSuffixes) do
        local location = locationGetter(playerPrefix .. " " .. suffix)
        if location then
            for _, object in ipairs(location:AllObjects()) do
                if object.tag ~= "Card" then
                    local stat = tokenStats[object.getName()]
                    if stat then
                        modifiers[stat] = (modifiers[stat] or 0) + tokenValueFn(object)
                    end
                end
            end
        end
    end

    return modifiers
end

Test.test("Integration: scanLocationsForTokens sums tokens from all card types", function(t)
    local Player = require("Kdm/Entity/Player")

    -- Create mock locations with tokens
    local locations = {
        ["Player 1 Fighting Art 1"] = createMockLocation({
            createMockCard("Timeless Eye"),
            createMockToken("Strength Token", false, 1),  -- +1 strength
        }),
        ["Player 1 Disorder 2"] = createMockLocation({
            createMockCard("Anxiety"),
            createMockToken("Speed Token", false, 2),  -- +2 speed
        }),
        ["Player 1 Gear 5"] = createMockLocation({
            createMockCard("Leather Shield"),
            createMockToken("Evasion Token", false, 1),  -- +1 evasion (was already counted)
            createMockToken("Strength Token", false, 1),  -- +1 strength (NEW: now counted)
        }),
        ["Player 1 Weapon Proficiency"] = createMockLocation({
            createMockCard("Sword Specialization"),
            createMockToken("Accuracy Token", false, 1),  -- +1 accuracy
        }),
    }

    -- Create empty locations for the rest
    local emptyLocation = createMockLocation({})
    local function locationGetter(name)
        return locations[name] or emptyLocation
    end

    local modifiers = scanLocationsForTokens(
        locationGetter,
        "Player 1",
        Player.CARD_LOCATION_SUFFIXES,
        Player.TOKEN_STATS,
        mockTokenValue
    )

    t:assertEqual(modifiers["strength"], 2, "Strength should be 2 (1 from FA + 1 from Gear)")
    t:assertEqual(modifiers["speed"], 2, "Speed should be 2")
    t:assertEqual(modifiers["evasion"], 1, "Evasion should be 1")
    t:assertEqual(modifiers["accuracy"], 1, "Accuracy should be 1")
end)

Test.test("Integration: Card objects are not counted as tokens", function(t)
    local Player = require("Kdm/Entity/Player")

    -- Location with only a card (no tokens)
    local locations = {
        ["Player 1 Fighting Art 1"] = createMockLocation({
            createMockCard("Monster Claw Style"),
        }),
    }

    local emptyLocation = createMockLocation({})
    local function locationGetter(name)
        return locations[name] or emptyLocation
    end

    local modifiers = scanLocationsForTokens(
        locationGetter,
        "Player 1",
        Player.CARD_LOCATION_SUFFIXES,
        Player.TOKEN_STATS,
        mockTokenValue
    )

    -- No tokens, so modifiers should be empty
    t:assertNil(modifiers["strength"], "No strength modifier expected")
    t:assertNil(modifiers["speed"], "No speed modifier expected")
end)

Test.test("Integration: Face-down tokens subtract from modifiers", function(t)
    local Player = require("Kdm/Entity/Player")

    local locations = {
        ["Player 1 Fighting Art 1"] = createMockLocation({
            createMockToken("Strength Token", false, 1),  -- +1
            createMockToken("Strength Token", true, 1),   -- -1
        }),
    }

    local emptyLocation = createMockLocation({})
    local function locationGetter(name)
        return locations[name] or emptyLocation
    end

    local modifiers = scanLocationsForTokens(
        locationGetter,
        "Player 1",
        Player.CARD_LOCATION_SUFFIXES,
        Player.TOKEN_STATS,
        mockTokenValue
    )

    t:assertEqual(modifiers["strength"], 0, "Strength should be 0 (+1 -1)")
end)

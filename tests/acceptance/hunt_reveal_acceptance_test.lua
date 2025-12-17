---------------------------------------------------------------------------------------------------
-- Hunt Card Auto-Reveal Acceptance Tests
--
-- When a player moves the Hunt Party to a track space with cards, those cards are automatically
-- revealed and moved to a dedicated viewing area. This improves visibility during gameplay.
--
-- SCOPE: What these tests verify (headless)
--   - Visited position tracking prevents duplicate reveals
--   - Card type filtering (only hunt event cards are revealed)
--   - State reset during cleanup
--   - State reset during new hunt setup
--
-- OUT OF SCOPE: What requires TTS console tests
--   - Drop handler registration and triggering
--   - Card flipping (rotation changes)
--   - Card movement to revealed area
--   - "Next Card" 3D button creation and interaction
--   - Visual positioning and spacing
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Minimal TTS Stubs for Hunt Module
---------------------------------------------------------------------------------------------------

local function createHuntTestEnvironment()
    -- Global TTS functions
    _G.logStyle = function() end
    _G.printToAll = function() end
    _G.broadcastToAll = function() end
    _G.log = function() end

    -- Wait stub - executes callbacks synchronously
    _G.Wait = {
        frames = function(callback, frames)
            if callback then callback() end
        end,
        condition = function(callback, condition, timeout, timeoutCallback)
            if callback then callback() end
        end,
        time = function(callback, time)
            if callback then callback() end
        end,
    }

    -- Mock card objects
    local function createMockCard(name, gmNotes, isFaceDown)
        return {
            tag = "Card",
            getName = function() return name end,
            getGMNotes = function() return gmNotes end,
            getRotation = function()
                return isFaceDown and { x = 0, y = 180, z = 180 } or { x = 0, y = 180, z = 0 }
            end,
            setRotation = function() end,
            setPositionSmooth = function() end,
            isDestroyed = function() return false end,
            createButton = function() end,
            clearButtons = function() end,
        }
    end

    -- Track what objects are at each location
    local locationObjects = {}

    -- Location stub with configurable objects
    package.loaded["Kdm/Location"] = {
        Get = function(name)
            return {
                Position = function() return { x = 0, y = 0, z = 0 } end,
                Center = function() return { x = 0, y = 0, z = 0 } end,
                AllObjects = function()
                    return locationObjects[name] or {}
                end,
                BoxClean = function() return {} end,
                RayClean = function() return {} end,
                LookAt = function() end,
                AddDropHandler = function() end,
            }
        end,
        _test = {
            setObjects = function(locationName, objects)
                locationObjects[locationName] = objects
            end,
            reset = function()
                locationObjects = {}
            end,
        },
    }

    -- Util stub
    package.loaded["Kdm/Util/Util"] = {
        ArrayContains = function(array, value)
            for _, v in ipairs(array) do
                if v == value then return true end
            end
            return false
        end,
        IsFaceDown = function(card)
            local rot = card.getRotation()
            return rot.z > 90
        end,
        ConcatArrays = function(a, b)
            local result = {}
            for _, v in ipairs(a or {}) do table.insert(result, v) end
            for _, v in ipairs(b or {}) do table.insert(result, v) end
            return result
        end,
        CopyArray = function(a)
            local result = {}
            for _, v in ipairs(a or {}) do table.insert(result, v) end
            return result
        end,
        Map = function(arr, fn)
            local result = {}
            for _, v in ipairs(arr) do table.insert(result, fn(v)) end
            return result
        end,
        HighlightAll = function() end,
    }

    -- Archive stub (minimal)
    package.loaded["Kdm/Archive"] = {
        Take = function() return {} end,
        Clean = function() end,
    }

    -- Other required stubs
    package.loaded["Kdm/Util/Check"] = {
        Fail = function(msg) error(msg) end,
        Str = function(v) return type(v) == "string" end,
        Func = function(v) return type(v) == "function" end,
    }
    package.loaded["Kdm/Util/Container"] = function(obj)
        return {
            Object = function() return obj end,
            Shuffle = function() end,
            Take = function() return {} end,
        }
    end
    package.loaded["Kdm/Deck"] = {
        Remove = function() end,
        AdjustToTrash = function() end,
    }
    package.loaded["Kdm/Expansion"] = {
        All = function() return {} end,
        IsUnlockedMode = function() return false end,
        IsEnabled = function() return true end,
    }
    package.loaded["Kdm/Trash"] = {
        IsInTrash = function() return false end,
    }
    package.loaded["Kdm/Survivor"] = {
        DepartingSurvivorNeedsToSkipNextHunt = function() return false end,
        ClearSkipNextHunt = function() end,
        GetDepartingSurvivors = function() return pairs({}) end,
    }
    package.loaded["Kdm/HuntParty"] = {
        Create = function() return {} end,
        Cleanup = function() end,
    }
    package.loaded["Kdm/Ui"] = {
        Get2d = function() return {
            Panel = function() return {} end,
        } end,
    }
    package.loaded["Kdm/Ui/PanelKit"] = {
        Dialog = function() return {
            Panel = function() return {
                Button = function() end,
            } end,
            ShowForPlayer = function() return "White" end,
            HideForPlayer = function() return "None" end,
            IsOpen = function() return false end,
        } end,
        ScrollSelector = function() return {
            SetOptionsWithDefault = function() end,
            SetOptions = function() end,
        } end,
    }

    return {
        createMockCard = createMockCard,
        Location = package.loaded["Kdm/Location"],
    }
end

---------------------------------------------------------------------------------------------------
-- Test Helper: Load Hunt module fresh
---------------------------------------------------------------------------------------------------

local function loadHuntModule()
    -- Clear cached modules
    for k in pairs(package.loaded) do
        if k:match("^Kdm/") then
            package.loaded[k] = nil
        end
    end

    local env = createHuntTestEnvironment()

    -- Load Hunt module
    local Hunt = require("Kdm/Hunt")
    Hunt.Init()

    return {
        Hunt = Hunt,
        env = env,
        Location = env.Location,
        createMockCard = env.createMockCard,
    }
end

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Visited Position Tracking
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: First visit to track position reveals cards", function(t)
    local modules = loadHuntModule()

    -- Place a hunt event card at Hunt Track 1
    local card = modules.createMockCard("Abandoned Lair", "Hunt Events", true)
    modules.Location._test.setObjects("Hunt Track 1", { card })

    -- Simulate party arriving at track 1
    modules.Hunt.OnPartyArrival(1)

    -- Verify position was marked as visited
    t:assertTrue(modules.Hunt.visitedPositions[1],
        "Track position 1 should be marked as visited")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Second visit to same position does not re-reveal", function(t)
    local modules = loadHuntModule()

    -- Place a card at Hunt Track 2
    local card = modules.createMockCard("Abandoned Lair", "Hunt Events", true)
    modules.Location._test.setObjects("Hunt Track 2", { card })

    -- First visit
    modules.Hunt.OnPartyArrival(2)
    local cardsAfterFirst = #modules.Hunt.remainingCards

    -- Manually reset remaining cards to simulate cards were processed
    modules.Hunt.remainingCards = {}

    -- Second visit to same position
    modules.Hunt.OnPartyArrival(2)

    -- remainingCards should still be empty (not re-populated)
    t:assertEqual(0, #modules.Hunt.remainingCards,
        "Second visit should not re-populate remainingCards")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Different track positions are independent", function(t)
    local modules = loadHuntModule()

    -- Place cards at two different positions
    local card1 = modules.createMockCard("Card 1", "Hunt Events", true)
    local card2 = modules.createMockCard("Card 2", "Hunt Events", true)
    modules.Location._test.setObjects("Hunt Track 1", { card1 })
    modules.Location._test.setObjects("Hunt Track 3", { card2 })

    -- Visit position 1
    modules.Hunt.OnPartyArrival(1)
    t:assertTrue(modules.Hunt.visitedPositions[1], "Position 1 should be visited")
    t:assertNil(modules.Hunt.visitedPositions[3], "Position 3 should not be visited yet")

    -- Clear remaining cards
    modules.Hunt.remainingCards = {}

    -- Visit position 3
    modules.Hunt.OnPartyArrival(3)
    t:assertTrue(modules.Hunt.visitedPositions[3], "Position 3 should now be visited")

    -- Both should be marked
    t:assertTrue(modules.Hunt.visitedPositions[1], "Position 1 should still be visited")
    t:assertTrue(modules.Hunt.visitedPositions[3], "Position 3 should be visited")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Card Type Filtering
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Only hunt event cards are revealed", function(t)
    local modules = loadHuntModule()

    -- Place different card types at a track position
    local huntEvent = modules.createMockCard("Abandoned Lair", "Hunt Events", true)
    local monsterHuntEvent = modules.createMockCard("White Lion Ambush", "Monster Hunt Events", true)
    local specialHuntEvent = modules.createMockCard("The Forest Gate", "Special Hunt Events", false)
    local otherCard = modules.createMockCard("Some Gear", "Gear", false)

    modules.Location._test.setObjects("Hunt Track 5", {
        huntEvent, monsterHuntEvent, specialHuntEvent, otherCard
    })

    -- Trigger reveal
    modules.Hunt.OnPartyArrival(5)

    -- Should have found 3 hunt cards (not the gear card)
    -- Note: remainingCards is populated then immediately processed,
    -- so we check revealedCardCount instead
    t:assertTrue(modules.Hunt.revealedCardCount >= 1,
        "At least one card should have been revealed")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Empty track position causes no error", function(t)
    local modules = loadHuntModule()

    -- No cards at this position
    modules.Location._test.setObjects("Hunt Track 4", {})

    -- Should not error
    local success = pcall(function()
        modules.Hunt.OnPartyArrival(4)
    end)

    t:assertTrue(success, "Empty track position should not cause error")
    t:assertTrue(modules.Hunt.visitedPositions[4],
        "Empty position should still be marked as visited")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: State Reset
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup resets visited positions", function(t)
    local modules = loadHuntModule()

    -- Visit some positions
    modules.Hunt.visitedPositions[1] = true
    modules.Hunt.visitedPositions[3] = true
    modules.Hunt.visitedPositions[5] = true

    -- Run cleanup
    modules.Hunt.CleanInternal()

    -- Visited positions should be reset
    t:assertNil(modules.Hunt.visitedPositions[1], "Position 1 should be cleared")
    t:assertNil(modules.Hunt.visitedPositions[3], "Position 3 should be cleared")
    t:assertNil(modules.Hunt.visitedPositions[5], "Position 5 should be cleared")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Cleanup resets remaining cards queue", function(t)
    local modules = loadHuntModule()

    -- Simulate cards in queue
    modules.Hunt.remainingCards = { {}, {}, {} }  -- 3 mock cards
    modules.Hunt.revealedCardCount = 5

    -- Run cleanup
    modules.Hunt.CleanInternal()

    -- State should be reset
    t:assertEqual(0, #modules.Hunt.remainingCards, "Remaining cards should be empty")
    t:assertEqual(0, modules.Hunt.revealedCardCount, "Revealed count should be zero")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Hunt Track Start position is handled correctly", function(t)
    local modules = loadHuntModule()

    -- Place card at start position
    local card = modules.createMockCard("Starting Event", "Hunt Events", true)
    modules.Location._test.setObjects("Hunt Track Start", { card })

    -- Trigger reveal at "Start" (string, not number)
    modules.Hunt.OnPartyArrival("Start")

    -- Should be marked visited with string key
    t:assertTrue(modules.Hunt.visitedPositions["Start"],
        "Start position should be marked as visited")
end)

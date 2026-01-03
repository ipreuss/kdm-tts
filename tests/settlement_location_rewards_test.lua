local Test = require("tests.framework")

--------------------------------------------------------------------------------
-- Test Setup
--------------------------------------------------------------------------------

-- Mock Location module
local mockLocations = {}
local Location = {
    Get = function(name)
        return {
            FirstObject = function(_, params)
                return mockLocations[name]
            end
        }
    end
}

-- Mock Archive module
local archiveTakeCallCount = 0
local lastArchiveTakeParams = nil
local Archive = {
    Take = function(params)
        archiveTakeCallCount = archiveTakeCallCount + 1
        lastArchiveTakeParams = params
        if params.spawnFunc then
            params.spawnFunc({ getName = function() return params.name end })
        end
        return {}
    end,
    Clean = function() end
}

-- Mock Util module
local highlightedObjects = {}
local Util = {
    HighlightAll = function(objects)
        highlightedObjects = objects
    end
}

-- Mock log module
local broadcastMessages = {}
local log = {
    Debugf = function() end,
    Printf = function() end,
    Broadcastf = function(_, msg, ...)
        table.insert(broadcastMessages, string.format(msg, ...))
    end
}

-- Create module with mocks injected
local function createModule()
    -- Reset state
    mockLocations = {}
    archiveTakeCallCount = 0
    lastArchiveTakeParams = nil
    highlightedObjects = {}
    broadcastMessages = {}

    -- Build the module with mocks
    local M = {}
    local SETTLEMENT_LOCATION_TYPE = "Settlement Locations"
    local NUM_SETTLEMENT_SLOTS = 20

    function M.IsLocationPlaced(locationName)
        for i = 1, NUM_SETTLEMENT_SLOTS do
            local loc = Location.Get("Settlement Location " .. i)
            local obj = loc:FirstObject({ types = { SETTLEMENT_LOCATION_TYPE } })
            if obj and obj.getName() == locationName then
                return true
            end
        end
        return false
    end

    function M.FindEmptySlot()
        for i = 1, NUM_SETTLEMENT_SLOTS do
            local loc = Location.Get("Settlement Location " .. i)
            local obj = loc:FirstObject({ types = { SETTLEMENT_LOCATION_TYPE } })
            if obj == nil then
                return i
            end
        end
        return nil
    end

    function M.SpawnLocation(locationName, slotIndex)
        local location = Location.Get("Settlement Location " .. slotIndex)
        Archive.Take({
            name = locationName,
            type = SETTLEMENT_LOCATION_TYPE,
            location = location,
            rotation = { x = 0, y = 180, z = 180 },
            spawnFunc = function(obj)
                Util.HighlightAll({ obj })
                log:Broadcastf("%s added to settlement location %d", locationName, slotIndex)
            end
        })
        Archive.Clean()
    end

    function M.HandleFullGrid(locationName)
        log:Broadcastf("Cannot add %s - all settlement location slots are full!", locationName)
        local objects = {}
        for i = 1, NUM_SETTLEMENT_SLOTS do
            local loc = Location.Get("Settlement Location " .. i)
            local obj = loc:FirstObject({ types = { SETTLEMENT_LOCATION_TYPE } })
            if obj then
                table.insert(objects, obj)
            end
        end
        if #objects > 0 then
            Util.HighlightAll(objects)
        end
    end

    function M.SpawnForVictory(monster, level)
        local victory = level and level.showdown and level.showdown.aftermath and level.showdown.aftermath.victory
        if not victory then
            return false
        end

        local reward = victory.settlementLocationReward
        if not reward then
            return false
        end

        if M.IsLocationPlaced(reward) then
            return false
        end

        local slotIndex = M.FindEmptySlot()
        if not slotIndex then
            M.HandleFullGrid(reward)
            return false
        end

        M.SpawnLocation(reward, slotIndex)
        return true
    end

    return M
end

--------------------------------------------------------------------------------
-- IsLocationPlaced Tests
--------------------------------------------------------------------------------

Test.test("IsLocationPlaced returns false when location not on board", function(t)
    local M = createModule()

    local result = M.IsLocationPlaced("Catarium")

    t:assertEqual(result, false, "Should return false when location not placed")
end)

Test.test("IsLocationPlaced returns true when location exists in slot 1", function(t)
    local M = createModule()
    mockLocations["Settlement Location 1"] = { getName = function() return "Catarium" end }

    local result = M.IsLocationPlaced("Catarium")

    t:assertEqual(result, true, "Should return true when location is in slot 1")
end)

Test.test("IsLocationPlaced returns true when location exists in slot 15", function(t)
    local M = createModule()
    mockLocations["Settlement Location 15"] = { getName = function() return "Stone Circle" end }

    local result = M.IsLocationPlaced("Stone Circle")

    t:assertEqual(result, true, "Should return true when location is in slot 15")
end)

Test.test("IsLocationPlaced returns false for different location name", function(t)
    local M = createModule()
    mockLocations["Settlement Location 5"] = { getName = function() return "Catarium" end }

    local result = M.IsLocationPlaced("Plumery")

    t:assertEqual(result, false, "Should return false when searching for different location")
end)

--------------------------------------------------------------------------------
-- FindEmptySlot Tests
--------------------------------------------------------------------------------

Test.test("FindEmptySlot returns 1 when all slots empty", function(t)
    local M = createModule()

    local result = M.FindEmptySlot()

    t:assertEqual(result, 1, "Should return 1 (first slot) when all empty")
end)

Test.test("FindEmptySlot returns first empty slot", function(t)
    local M = createModule()
    mockLocations["Settlement Location 1"] = { getName = function() return "Catarium" end }
    mockLocations["Settlement Location 2"] = { getName = function() return "Stone Circle" end }
    mockLocations["Settlement Location 3"] = { getName = function() return "Plumery" end }

    local result = M.FindEmptySlot()

    t:assertEqual(result, 4, "Should return 4 (first empty after 3 filled)")
end)

Test.test("FindEmptySlot returns nil when all slots full", function(t)
    local M = createModule()
    -- Fill all 20 slots
    for i = 1, 20 do
        mockLocations["Settlement Location " .. i] = { getName = function() return "Location " .. i end }
    end

    local result = M.FindEmptySlot()

    t:assertNil(result, "Should return nil when all 20 slots full")
end)

--------------------------------------------------------------------------------
-- SpawnForVictory Tests
--------------------------------------------------------------------------------

Test.test("SpawnForVictory returns false when no victory data", function(t)
    local M = createModule()
    local monster = { name = "White Lion" }
    local level = { showdown = {} }

    local result = M.SpawnForVictory(monster, level)

    t:assertEqual(result, false, "Should return false with no aftermath data")
    t:assertEqual(archiveTakeCallCount, 0, "Should not call Archive.Take")
end)

Test.test("SpawnForVictory returns false when no settlementLocationReward", function(t)
    local M = createModule()
    local monster = { name = "White Lion" }
    local level = {
        showdown = {
            aftermath = {
                victory = {
                    resources = { basic = 4, monster = 4 },
                    checklist = { { text = "Test" } }
                }
            }
        }
    }

    local result = M.SpawnForVictory(monster, level)

    t:assertEqual(result, false, "Should return false with no reward configured")
    t:assertEqual(archiveTakeCallCount, 0, "Should not call Archive.Take")
end)

Test.test("SpawnForVictory returns false when location already placed", function(t)
    local M = createModule()
    mockLocations["Settlement Location 3"] = { getName = function() return "Catarium" end }

    local monster = { name = "White Lion" }
    local level = {
        showdown = {
            aftermath = {
                victory = {
                    settlementLocationReward = "Catarium",
                    checklist = { { text = "Test" } }
                }
            }
        }
    }

    local result = M.SpawnForVictory(monster, level)

    t:assertEqual(result, false, "Should return false when location already placed")
    t:assertEqual(archiveTakeCallCount, 0, "Should not call Archive.Take")
end)

Test.test("SpawnForVictory spawns location and returns true", function(t)
    local M = createModule()
    local monster = { name = "White Lion" }
    local level = {
        showdown = {
            aftermath = {
                victory = {
                    settlementLocationReward = "Catarium",
                    checklist = { { text = "Test" } }
                }
            }
        }
    }

    local result = M.SpawnForVictory(monster, level)

    t:assertEqual(result, true, "Should return true on successful spawn")
    t:assertEqual(archiveTakeCallCount, 1, "Should call Archive.Take once")
    t:assertEqual(lastArchiveTakeParams.name, "Catarium", "Should spawn correct location")
end)

Test.test("SpawnForVictory broadcasts message on spawn", function(t)
    local M = createModule()
    local monster = { name = "White Lion" }
    local level = {
        showdown = {
            aftermath = {
                victory = {
                    settlementLocationReward = "Catarium",
                    checklist = { { text = "Test" } }
                }
            }
        }
    }

    M.SpawnForVictory(monster, level)

    t:assertEqual(#broadcastMessages, 1, "Should broadcast one message")
    t:assertContains(broadcastMessages[1], "Catarium", "Message should mention location name")
end)

Test.test("SpawnForVictory returns false when grid full", function(t)
    local M = createModule()
    -- Fill all 20 slots
    for i = 1, 20 do
        mockLocations["Settlement Location " .. i] = { getName = function() return "Location " .. i end }
    end

    local monster = { name = "White Lion" }
    local level = {
        showdown = {
            aftermath = {
                victory = {
                    settlementLocationReward = "Catarium",
                    checklist = { { text = "Test" } }
                }
            }
        }
    }

    local result = M.SpawnForVictory(monster, level)

    t:assertEqual(result, false, "Should return false when grid full")
    t:assertEqual(archiveTakeCallCount, 0, "Should not call Archive.Take")
    t:assertEqual(#broadcastMessages, 1, "Should broadcast error message")
    t:assertContains(broadcastMessages[1], "full", "Error should mention slots are full")
end)

--------------------------------------------------------------------------------
-- HandleFullGrid Tests
--------------------------------------------------------------------------------

Test.test("HandleFullGrid broadcasts error message", function(t)
    local M = createModule()

    M.HandleFullGrid("Catarium")

    t:assertEqual(#broadcastMessages, 1, "Should broadcast one message")
    t:assertContains(broadcastMessages[1], "Cannot add Catarium", "Should mention location name")
    t:assertContains(broadcastMessages[1], "full", "Should mention slots are full")
end)

Test.test("HandleFullGrid highlights occupied slots", function(t)
    local M = createModule()
    -- Add a few locations
    mockLocations["Settlement Location 1"] = { getName = function() return "Catarium" end }
    mockLocations["Settlement Location 5"] = { getName = function() return "Stone Circle" end }

    M.HandleFullGrid("Plumery")

    t:assertEqual(#highlightedObjects, 2, "Should highlight 2 occupied slots")
end)

return Test

-- Tests for Hunt and Showdown monster filtering by enabled expansions
-- Bead: kdm-0er

local Test = require("tests.framework")
require("tests.support.bootstrap").setup()

local Expansion = require("Kdm/Expansion")

-- Initialize expansions for testing
Expansion.Init({})

-- Import production filter functions via _test interface
local Hunt = require("Kdm/Hunt")
local Showdown = require("Kdm/Showdown")

local HuntFilterEnabledMonsters = Hunt._test.FilterEnabledMonsters
local ShowdownFilterEnabledMonsters = Showdown._test.FilterEnabledMonsters

--------------------------------------------------------------------------------
-- Test: Hunt filters monsters by enabled expansion
--------------------------------------------------------------------------------

Test.test("Hunt filters monsters by enabled expansion", function(t)
    -- Setup: Only Core enabled
    Expansion.SetEnabled({ Core = true, Gorm = false })
    Expansion.SetUnlockedMode(false)

    local testMonsters = {
        { name = "White Lion", nemesis = false },
        { name = "Gorm", nemesis = false },
    }
    local testExpansionMap = {
        ["White Lion"] = { name = "Core" },
        ["Gorm"] = { name = "Gorm" },
    }

    local filtered = HuntFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(1, #filtered, "Expected 1 monster after filtering")
    t:assertEqual("White Lion", filtered[1].name, "Core monster should be present")
end)

--------------------------------------------------------------------------------
-- Test: Showdown filters monsters by enabled expansion
--------------------------------------------------------------------------------

Test.test("Showdown filters monsters by enabled expansion", function(t)
    -- Setup: Only Core enabled
    Expansion.SetEnabled({ Core = true, Sunstalker = false })
    Expansion.SetUnlockedMode(false)

    local testMonsters = {
        { name = "White Lion", nemesis = false },
        { name = "Screaming Antelope", nemesis = false },
        { name = "Sunstalker", nemesis = false },
    }
    local testExpansionMap = {
        ["White Lion"] = { name = "Core" },
        ["Screaming Antelope"] = { name = "Core" },
        ["Sunstalker"] = { name = "Sunstalker" },
    }

    local filtered = ShowdownFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(2, #filtered, "Expected 2 Core monsters after filtering")
    t:assertEqual("White Lion", filtered[1].name)
    t:assertEqual("Screaming Antelope", filtered[2].name)
end)

--------------------------------------------------------------------------------
-- Test: Unlocked mode shows all monsters
--------------------------------------------------------------------------------

Test.test("Filter shows all monsters in unlocked mode", function(t)
    -- Setup: Some expansions disabled but unlocked mode ON
    Expansion.SetEnabled({ Core = true, Gorm = false, Sunstalker = false })
    Expansion.SetUnlockedMode(true)

    local testMonsters = {
        { name = "White Lion" },
        { name = "Gorm" },
        { name = "Sunstalker" },
    }
    local testExpansionMap = {
        ["White Lion"] = { name = "Core" },
        ["Gorm"] = { name = "Gorm" },
        ["Sunstalker"] = { name = "Sunstalker" },
    }

    local filtered = HuntFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(3, #filtered, "Unlocked mode should show all monsters")

    -- Cleanup
    Expansion.SetUnlockedMode(false)
end)

--------------------------------------------------------------------------------
-- Test: Core monsters always present (Core always enabled)
--------------------------------------------------------------------------------

Test.test("Core monsters always present", function(t)
    -- Setup: Core is always enabled (hardcoded in Expansion.SetEnabled)
    Expansion.SetEnabled({ Gorm = false, Sunstalker = false })
    Expansion.SetUnlockedMode(false)

    local coreMonsters = { "White Lion", "Screaming Antelope", "Phoenix" }
    local testMonsters = {}
    local testExpansionMap = {}

    for _, name in ipairs(coreMonsters) do
        table.insert(testMonsters, { name = name })
        testExpansionMap[name] = { name = "Core" }
    end

    local filtered = HuntFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(3, #filtered, "All Core monsters should be present")
    for i, monster in ipairs(filtered) do
        t:assertEqual(coreMonsters[i], monster.name)
    end
end)

--------------------------------------------------------------------------------
-- Test: Multiple expansions enabled
--------------------------------------------------------------------------------

Test.test("Filter respects multiple enabled expansions", function(t)
    -- Setup: Core and Gorm enabled, Sunstalker disabled
    Expansion.SetEnabled({ Core = true, Gorm = true, Sunstalker = false })
    Expansion.SetUnlockedMode(false)

    local testMonsters = {
        { name = "White Lion" },
        { name = "Gorm" },
        { name = "Sunstalker" },
    }
    local testExpansionMap = {
        ["White Lion"] = { name = "Core" },
        ["Gorm"] = { name = "Gorm" },
        ["Sunstalker"] = { name = "Sunstalker" },
    }

    local filtered = HuntFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(2, #filtered, "Expected Core + Gorm monsters")
    t:assertEqual("White Lion", filtered[1].name)
    t:assertEqual("Gorm", filtered[2].name)
end)

--------------------------------------------------------------------------------
-- Test: Nemesis monsters follow same filtering rules
--------------------------------------------------------------------------------

Test.test("Nemesis monsters filtered by expansion", function(t)
    -- Setup: Core enabled, Manhunter disabled
    Expansion.SetEnabled({ Core = true, Manhunter = false })
    Expansion.SetUnlockedMode(false)

    local testMonsters = {
        { name = "White Lion", nemesis = false },
        { name = "Manhunter", nemesis = true },
    }
    local testExpansionMap = {
        ["White Lion"] = { name = "Core" },
        ["Manhunter"] = { name = "Manhunter" },
    }

    local filtered = HuntFilterEnabledMonsters(testMonsters, testExpansionMap)

    t:assertEqual(1, #filtered, "Disabled nemesis monster should be filtered out")
    t:assertEqual("White Lion", filtered[1].name)
end)

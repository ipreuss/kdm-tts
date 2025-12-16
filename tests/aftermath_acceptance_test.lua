-- Acceptance tests for Showdown Aftermath Checklist (kdm-4ro)
-- These tests verify the aftermath data structure and UI behavior

local Test = require("tests.framework")
require("tests.support.bootstrap").setup()

local Expansion = require("Kdm/Expansion")

-- Initialize expansions for testing
Expansion.Init({})

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function getAllExpansions()
    return Expansion.All()
end

-- Collect all monsters with their aftermath data
local function collectMonsterAftermath()
    local monsters = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for _, monster in ipairs(expansion.monsters or {}) do
            if monster.levels then
                for _, level in ipairs(monster.levels) do
                    if level.showdown and level.showdown.aftermath then
                        table.insert(monsters, {
                            expansion = expansion.name,
                            monster = monster.name,
                            level = level.name,
                            aftermath = level.showdown.aftermath,
                        })
                    end
                end
            end
        end
    end
    return monsters
end

--------------------------------------------------------------------------------
-- Data Structure Tests
--------------------------------------------------------------------------------

Test.test("Aftermath data has valid structure", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    for _, entry in ipairs(monstersWithAftermath) do
        local aftermath = entry.aftermath
        local desc = string.format("%s %s (%s)", entry.monster, entry.level, entry.expansion)

        -- victory must be a table if present
        if aftermath.victory then
            t:assertEqual(type(aftermath.victory), "table",
                string.format("%s: victory must be a table", desc))
            for i, item in ipairs(aftermath.victory) do
                t:assertEqual(type(item.text), "string",
                    string.format("%s: victory[%d].text must be a string", desc, i))
                t:assertTrue(#item.text > 0,
                    string.format("%s: victory[%d].text must be non-empty", desc, i))
            end
        end

        -- defeat must be a table if present
        if aftermath.defeat then
            t:assertEqual(type(aftermath.defeat), "table",
                string.format("%s: defeat must be a table", desc))
            for i, item in ipairs(aftermath.defeat) do
                t:assertEqual(type(item.text), "string",
                    string.format("%s: defeat[%d].text must be a string", desc, i))
                t:assertTrue(#item.text > 0,
                    string.format("%s: defeat[%d].text must be non-empty", desc, i))
            end
        end
    end
end)

Test.test("White Lion Level 1 has aftermath data", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local whiteLionL1 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "White Lion" and entry.level == "Level 1" then
            whiteLionL1 = entry.aftermath
            break
        end
    end

    t:assertNotNil(whiteLionL1, "White Lion L1 should have aftermath data")
    t:assertNotNil(whiteLionL1.victory, "White Lion L1 should have victory aftermath")
    t:assertNotNil(whiteLionL1.defeat, "White Lion L1 should have defeat aftermath")

    -- Victory should have standard items
    t:assertTrue(#whiteLionL1.victory >= 3, "White Lion L1 victory should have at least 3 items")

    -- Defeat should have jewelry loss
    t:assertTrue(#whiteLionL1.defeat >= 1, "White Lion L1 defeat should have at least 1 item")
end)

--------------------------------------------------------------------------------

Test.test("Screaming Antelope Level 1 has aftermath data", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local antelopeL1 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Screaming Antelope" and entry.level == "Level 1" then
            antelopeL1 = entry.aftermath
            break
        end
    end

    t:assertNotNil(antelopeL1, "Screaming Antelope L1 should have aftermath data")
    t:assertNotNil(antelopeL1.victory, "Screaming Antelope L1 should have victory aftermath")
    t:assertNotNil(antelopeL1.defeat, "Screaming Antelope L1 should have defeat aftermath")

    -- Victory should include warning about insanity vanishing
    t:assertTrue(#antelopeL1.victory >= 4, "Screaming Antelope L1 victory should have at least 4 items")
end)

--------------------------------------------------------------------------------

Test.test("Butcher (nemesis) has aftermath data", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local butcherL1 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Butcher" and entry.level == "Level 1" then
            butcherL1 = entry.aftermath
            break
        end
    end

    t:assertNotNil(butcherL1, "Butcher L1 should have aftermath data")
    t:assertNotNil(butcherL1.victory, "Butcher L1 should have victory aftermath")
    t:assertNotNil(butcherL1.defeat, "Butcher L1 should have defeat aftermath")

    -- Victory should include courage gain and cleaver
    t:assertTrue(#butcherL1.victory >= 2, "Butcher L1 victory should have at least 2 items")
end)

--------------------------------------------------------------------------------

Test.test("Monsters with aftermath count", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    -- We should have at least some monsters with aftermath data
    t:assertTrue(#monstersWithAftermath >= 8,
        string.format("Should have at least 8 monster levels with aftermath, found %d", #monstersWithAftermath))
end)

--------------------------------------------------------------------------------

Test.test("All Core monsters have both victory and defeat aftermath", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    -- Core quarries and nemesis that should have both victory AND defeat
    local coreMonsters = {
        ["White Lion"] = { "Level 1", "Level 2", "Level 3" },
        ["Screaming Antelope"] = { "Level 1", "Level 2", "Level 3" },
        ["Phoenix"] = { "Level 1", "Level 2", "Level 3" },
        ["Butcher"] = { "Level 1", "Level 2", "Level 3" },
    }

    for monsterName, levels in pairs(coreMonsters) do
        for _, levelName in ipairs(levels) do
            local found = nil
            for _, entry in ipairs(monstersWithAftermath) do
                if entry.monster == monsterName and entry.level == levelName then
                    found = entry.aftermath
                    break
                end
            end

            local desc = string.format("%s %s", monsterName, levelName)
            t:assertNotNil(found, desc .. " should have aftermath data")
            if found then
                t:assertNotNil(found.victory, desc .. " should have victory aftermath")
                t:assertNotNil(found.defeat, desc .. " should have defeat aftermath")
                t:assertTrue(#found.victory >= 1, desc .. " victory should have at least 1 item")
                t:assertTrue(#found.defeat >= 1, desc .. " defeat should have at least 1 item")
            end
        end
    end
end)

--------------------------------------------------------------------------------

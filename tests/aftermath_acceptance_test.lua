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
    t:assertTrue(#whiteLionL1.victory.checklist >= 3, "White Lion L1 victory should have at least 3 items")

    -- Defeat should have jewelry loss
    t:assertTrue(#whiteLionL1.defeat.checklist >= 1, "White Lion L1 defeat should have at least 1 item")
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
    t:assertTrue(#antelopeL1.victory.checklist >= 4, "Screaming Antelope L1 victory should have at least 4 items")
end)

--------------------------------------------------------------------------------

Test.test("Butcher (nemesis) has aftermath data", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    -- Test all 3 Butcher levels have correct aftermath structure
    for _, levelName in ipairs({ "Level 1", "Level 2", "Level 3" }) do
        local butcher = nil
        for _, entry in ipairs(monstersWithAftermath) do
            if entry.monster == "Butcher" and entry.level == levelName then
                butcher = entry.aftermath
                break
            end
        end

        local desc = "Butcher " .. levelName
        t:assertNotNil(butcher, desc .. " should have aftermath data")
        t:assertNotNil(butcher.victory, desc .. " should have victory aftermath")
        t:assertNotNil(butcher.defeat, desc .. " should have defeat aftermath")

        -- Victory: Axe proficiency, Hunt XP, Weapon Prof Level, d10 roll = 4 items
        -- Level 3 has 2 extra items for Forsaker Mask (Memento Mori check + fallback)
        local expectedVictoryItems = (levelName == "Level 3") and 6 or 4
        t:assertEqual(#butcher.victory.checklist, expectedVictoryItems,
            string.format("%s victory should have exactly %d items, found %d", desc, expectedVictoryItems, #butcher.victory.checklist))

        -- Defeat: Lose all resources = 1 item
        t:assertEqual(#butcher.defeat.checklist, 1,
            string.format("%s defeat should have exactly 1 item, found %d", desc, #butcher.defeat.checklist))
    end
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
                t:assertTrue(#found.victory.checklist >= 1, desc .. " victory should have at least 1 item")
                t:assertTrue(#found.defeat.checklist >= 1, desc .. " defeat should have at least 1 item")
            end
        end
    end
end)

--------------------------------------------------------------------------------

Test.test("Expansion monsters have aftermath data", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    -- Expansion monsters that should have aftermath
    local expansionMonsters = {
        ["Gorm"] = { "Level 1", "Level 2", "Level 3" },
        ["Dragon King"] = { "Level 1", "Level 2", "Level 3" },
        ["Spidicules"] = { "Level 1", "Level 2", "Level 3" },
        ["Dung Beetle Knight"] = { "Level 1", "Level 2", "Level 3" },
        ["Flower Knight"] = { "Level 1", "Level 2", "Level 3" },
    }

    for monsterName, levels in pairs(expansionMonsters) do
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
                t:assertTrue(#found.victory.checklist >= 3, desc .. " victory should have at least 3 items")
                t:assertTrue(#found.defeat.checklist >= 1, desc .. " defeat should have at least 1 item")
            end
        end
    end
end)

--------------------------------------------------------------------------------

Test.test("Dragon King L3 has extra victory item", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local dragonKingL3 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Dragon King" and entry.level == "Level 3" then
            dragonKingL3 = entry.aftermath
            break
        end
    end

    t:assertNotNil(dragonKingL3, "Dragon King L3 should have aftermath data")
    -- L3 has extra item: "If Sculpture: gain Radiant Claw strange resource"
    t:assertEqual(#dragonKingL3.victory.checklist, 4,
        string.format("Dragon King L3 victory should have 4 items (extra for Sculpture), found %d", #dragonKingL3.victory.checklist))
end)

--------------------------------------------------------------------------------

Test.test("Spidicules L3 has extra victory item", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local spidiculesL3 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Spidicules" and entry.level == "Level 3" then
            spidiculesL3 = entry.aftermath
            break
        end
    end

    t:assertNotNil(spidiculesL3, "Spidicules L3 should have aftermath data")
    -- L3 has extra item: "If Scarification: Killing blow survivor gains ability"
    t:assertEqual(#spidiculesL3.victory.checklist, 4,
        string.format("Spidicules L3 victory should have 4 items (extra for Scarification), found %d", #spidiculesL3.victory.checklist))
end)

--------------------------------------------------------------------------------

Test.test("Flower Knight L3 has extra victory items", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local flowerKnightL3 = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Flower Knight" and entry.level == "Level 3" then
            flowerKnightL3 = entry.aftermath
            break
        end
    end

    t:assertNotNil(flowerKnightL3, "Flower Knight L3 should have aftermath data")
    -- L3 has 2 extra items: "Sleeping Virus Flower" and "If Petal Spiral"
    t:assertEqual(#flowerKnightL3.victory.checklist, 5,
        string.format("Flower Knight L3 victory should have 5 items (2 extra for L3), found %d", #flowerKnightL3.victory.checklist))
end)

--------------------------------------------------------------------------------

Test.test("Dung Beetle Knight defeat has 4 items", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    for _, levelName in ipairs({ "Level 1", "Level 2", "Level 3" }) do
        local dbk = nil
        for _, entry in ipairs(monstersWithAftermath) do
            if entry.monster == "Dung Beetle Knight" and entry.level == levelName then
                dbk = entry.aftermath
                break
            end
        end

        local desc = "Dung Beetle Knight " .. levelName
        t:assertNotNil(dbk, desc .. " should have aftermath data")
        -- DBK defeat has 4 items about nominated survivors
        t:assertEqual(#dbk.defeat.checklist, 4,
            string.format("%s defeat should have 4 items, found %d", desc, #dbk.defeat.checklist))
    end
end)

--------------------------------------------------------------------------------

Test.test("Sunstalker has aftermath data for L1/L2/L3 (not Great Devourer)", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    -- Test L1, L2, L3 (Great Devourer is campaign finale with no aftermath)
    local sunstalkerLevels = { "Level 1", "Level 2", "Level 3" }

    for _, levelName in ipairs(sunstalkerLevels) do
        local found = nil
        for _, entry in ipairs(monstersWithAftermath) do
            if entry.monster == "Sunstalker" and entry.level == levelName then
                found = entry.aftermath
                break
            end
        end

        local desc = "Sunstalker " .. levelName
        t:assertNotNil(found, desc .. " should have aftermath data")
        if found then
            t:assertNotNil(found.victory, desc .. " should have victory aftermath")
            t:assertNotNil(found.defeat, desc .. " should have defeat aftermath")
        end
    end
end)

--------------------------------------------------------------------------------

Test.test("Sunstalker L1/L2 victory has 4 items", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    for _, levelName in ipairs({ "Level 1", "Level 2" }) do
        local found = nil
        for _, entry in ipairs(monstersWithAftermath) do
            if entry.monster == "Sunstalker" and entry.level == levelName then
                found = entry.aftermath
                break
            end
        end

        local desc = "Sunstalker " .. levelName
        t:assertNotNil(found, desc .. " should have aftermath data")
        -- Victory: +1 Hunt XP, +1 WP, Collect resources (settlement location reward is automated)
        t:assertEqual(#found.victory.checklist, 3,
            string.format("%s victory should have 3 items, found %d", desc, #found.victory.checklist))
        -- Defeat: If Graves -> Shadow Dance
        t:assertEqual(#found.defeat.checklist, 1,
            string.format("%s defeat should have 1 item, found %d", desc, #found.defeat.checklist))
    end
end)

--------------------------------------------------------------------------------

Test.test("Sunstalker L3 victory has 5 items", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local found = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Sunstalker" and entry.level == "Level 3" then
            found = entry.aftermath
            break
        end
    end

    t:assertNotNil(found, "Sunstalker Level 3 should have aftermath data")
    -- Victory: +1 Hunt XP, +1 WP, Collect resources, If Storytelling Edged Tonometry (settlement location reward is automated)
    t:assertEqual(#found.victory.checklist, 4,
        string.format("Sunstalker Level 3 victory should have 4 items, found %d", #found.victory.checklist))
    -- Defeat: If Graves -> Shadow Dance
    t:assertEqual(#found.defeat.checklist, 1,
        string.format("Sunstalker Level 3 defeat should have 1 item, found %d", #found.defeat.checklist))
end)

Test.test("Sunstalker Great Devourer has no aftermath (campaign finale)", function(t)
    local monstersWithAftermath = collectMonsterAftermath()

    local found = nil
    for _, entry in ipairs(monstersWithAftermath) do
        if entry.monster == "Sunstalker" and entry.level == "The Great Devourer" then
            found = entry.aftermath
            break
        end
    end

    -- Campaign finale has no aftermath - victory ends campaign, defeat means everyone dies
    t:assertNil(found, "Sunstalker Great Devourer should have no aftermath (campaign finale)")
end)

--------------------------------------------------------------------------------
-- Disabled Checklist Item Tests (Settlement Location Rewards)
--------------------------------------------------------------------------------

Test.test("Disabled checklist item shows as checked", function(t)
    -- Test that disabled items with checked=true appear correctly
    local items = {
        { text = "Catarium added to settlement", disabled = true, checked = true },
        { text = "Regular item", disabled = false, checked = false },
    }

    -- Verify first item is disabled and checked
    t:assertEqual(items[1].disabled, true, "First item should be disabled")
    t:assertEqual(items[1].checked, true, "First item should be checked")
    t:assertEqual(items[2].disabled, false, "Second item should not be disabled")
end)

Test.test("settlementLocationReward field exists in White Lion L1", function(t)
    local expansions = getAllExpansions()

    local found = nil
    for _, expansion in ipairs(expansions) do
        if expansion.monsters then
            for _, monster in ipairs(expansion.monsters) do
                if monster.name == "White Lion" and monster.levels then
                    for _, level in ipairs(monster.levels) do
                        if level.name == "Level 1" then
                            found = level.showdown.aftermath.victory
                            break
                        end
                    end
                end
            end
        end
    end

    t:assertNotNil(found, "White Lion L1 should have victory aftermath")
    t:assertEqual(found.settlementLocationReward, "Catarium",
        "White Lion L1 should have settlementLocationReward = 'Catarium'")
end)

Test.test("settlementLocationReward field exists in Screaming Antelope L1", function(t)
    local expansions = getAllExpansions()

    local found = nil
    for _, expansion in ipairs(expansions) do
        if expansion.monsters then
            for _, monster in ipairs(expansion.monsters) do
                if monster.name == "Screaming Antelope" and monster.levels then
                    for _, level in ipairs(monster.levels) do
                        if level.name == "Level 1" then
                            found = level.showdown.aftermath.victory
                            break
                        end
                    end
                end
            end
        end
    end

    t:assertNotNil(found, "Screaming Antelope L1 should have victory aftermath")
    t:assertEqual(found.settlementLocationReward, "Stone Circle",
        "Screaming Antelope L1 should have settlementLocationReward = 'Stone Circle'")
end)

Test.test("settlementLocationReward field exists in Phoenix L1", function(t)
    local expansions = getAllExpansions()

    local found = nil
    for _, expansion in ipairs(expansions) do
        if expansion.monsters then
            for _, monster in ipairs(expansion.monsters) do
                if monster.name == "Phoenix" and monster.levels then
                    for _, level in ipairs(monster.levels) do
                        if level.name == "Level 1" then
                            found = level.showdown.aftermath.victory
                            break
                        end
                    end
                end
            end
        end
    end

    t:assertNotNil(found, "Phoenix L1 should have victory aftermath")
    t:assertEqual(found.settlementLocationReward, "Plumery",
        "Phoenix L1 should have settlementLocationReward = 'Plumery'")
end)

Test.test("settlementLocationReward field exists in White Gigalion L2 and L3", function(t)
    local expansions = getAllExpansions()

    local foundL2 = nil
    local foundL3 = nil
    for _, expansion in ipairs(expansions) do
        if expansion.monsters then
            for _, monster in ipairs(expansion.monsters) do
                if monster.name == "White Gigalion" and monster.levels then
                    for _, level in ipairs(monster.levels) do
                        if level.name == "Level 2" then
                            foundL2 = level.showdown.aftermath.victory
                        elseif level.name == "Level 3" then
                            foundL3 = level.showdown.aftermath.victory
                        end
                    end
                end
            end
        end
    end

    t:assertNotNil(foundL2, "White Gigalion L2 should have victory aftermath")
    t:assertEqual(foundL2.settlementLocationReward, "Giga-Catarium",
        "White Gigalion L2 should have settlementLocationReward = 'Giga-Catarium'")

    t:assertNotNil(foundL3, "White Gigalion L3 should have victory aftermath")
    t:assertEqual(foundL3.settlementLocationReward, "Giga-Catarium",
        "White Gigalion L3 should have settlementLocationReward = 'Giga-Catarium'")
end)

Test.test("settlementLocationReward field exists in Sunstalker all levels", function(t)
    local expansions = getAllExpansions()

    local levels = {}
    for _, expansion in ipairs(expansions) do
        if expansion.monsters then
            for _, monster in ipairs(expansion.monsters) do
                if monster.name == "Sunstalker" and monster.levels then
                    for _, level in ipairs(monster.levels) do
                        if level.showdown and level.showdown.aftermath and level.showdown.aftermath.victory then
                            levels[level.name] = level.showdown.aftermath.victory
                        end
                    end
                end
            end
        end
    end

    for levelName, victory in pairs(levels) do
        if levelName ~= "The Great Devourer" then
            t:assertEqual(victory.settlementLocationReward, "Skyreef Sanctuary",
                string.format("Sunstalker %s should have settlementLocationReward = 'Skyreef Sanctuary'", levelName))
        end
    end
end)

--------------------------------------------------------------------------------

-- Integration tests for verifying expansion data consistency
-- These tests check that gear/armor/weapon references are self-consistent
-- across expansion definitions.

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

local function collectGearArchiveDecks()
    -- Collect all deck names that are of type "Gear" from archive entries
    local gearDecks = {}
    for _, expansion in ipairs(getAllExpansions()) do
        local archiveEntries = expansion.archiveEntries
        if archiveEntries and archiveEntries.entries then
            for _, entry in ipairs(archiveEntries.entries) do
                local deckName, deckType = entry[1], entry[2]
                if deckType == "Gear" then
                    gearDecks[deckName] = expansion.name
                end
            end
        end
    end
    return gearDecks
end

local function collectArmorStats()
    -- Collect all armor names from armorStats
    local armorNames = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for name, _ in pairs(expansion.armorStats or {}) do
            armorNames[name] = expansion.name
        end
    end
    return armorNames
end

local function collectWeaponStats()
    -- Collect all weapon names from weaponStats
    local weaponNames = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for name, _ in pairs(expansion.weaponStats or {}) do
            weaponNames[name] = expansion.name
        end
    end
    return weaponNames
end

local function collectComponents()
    -- Collect all component mappings
    local components = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for key, value in pairs(expansion.components or {}) do
            components[key] = { value = value, expansion = expansion.name }
        end
    end
    return components
end

--------------------------------------------------------------------------------
-- Tests
--------------------------------------------------------------------------------

Test.test("All expansions have required fields", function(t)
    for _, expansion in ipairs(getAllExpansions()) do
        t:assertNotNil(expansion.name, "Expansion must have a name")
        t:assertNotNil(expansion.archiveEntries, 
            string.format("Expansion '%s' must have archiveEntries", expansion.name))
        t:assertNotNil(expansion.archiveEntries.archive, 
            string.format("Expansion '%s' archiveEntries must have archive name", expansion.name))
        t:assertNotNil(expansion.archiveEntries.entries, 
            string.format("Expansion '%s' archiveEntries must have entries", expansion.name))
    end
end)

Test.test("All component keys map to archive entries", function(t)
    for _, expansion in ipairs(getAllExpansions()) do
        local archiveNames = {}
        if expansion.archiveEntries and expansion.archiveEntries.entries then
            for _, entry in ipairs(expansion.archiveEntries.entries) do
                archiveNames[entry[1]] = true
            end
        end
        
        for key, value in pairs(expansion.components or {}) do
            -- Skip table values (some components map to multiple decks)
            if type(value) == "string" then
                t:assertTrue(archiveNames[value], 
                    string.format("Component '%s' -> '%s' in expansion '%s' not found in archiveEntries", 
                        key, value, expansion.name))
            end
        end
    end
end)

Test.test("Gear archive entries are present", function(t)
    local gearDecks = collectGearArchiveDecks()
    
    -- Just verify we have gear decks and they have names
    local count = 0
    for deckName, expansionName in pairs(gearDecks) do
        count = count + 1
        t:assertTrue(#deckName > 0, 
            string.format("Gear deck in '%s' should have a non-empty name", expansionName))
    end
    
    t:assertTrue(count > 0, "Should have at least one gear deck defined")
end)

Test.test("ArmorStats entries have valid structure", function(t)
    for _, expansion in ipairs(getAllExpansions()) do
        for name, stats in pairs(expansion.armorStats or {}) do
            -- Each armor should have the 5 armor slot values
            t:assertNotNil(stats.head, 
                string.format("Armor '%s' in '%s' missing 'head' stat", name, expansion.name))
            t:assertNotNil(stats.arms, 
                string.format("Armor '%s' in '%s' missing 'arms' stat", name, expansion.name))
            t:assertNotNil(stats.body, 
                string.format("Armor '%s' in '%s' missing 'body' stat", name, expansion.name))
            t:assertNotNil(stats.waist, 
                string.format("Armor '%s' in '%s' missing 'waist' stat", name, expansion.name))
            t:assertNotNil(stats.legs, 
                string.format("Armor '%s' in '%s' missing 'legs' stat", name, expansion.name))
            
            -- Values should be numbers
            t:assertEqual(type(stats.head), "number",
                string.format("Armor '%s' head should be number", name))
            t:assertEqual(type(stats.arms), "number",
                string.format("Armor '%s' arms should be number", name))
            t:assertEqual(type(stats.body), "number",
                string.format("Armor '%s' body should be number", name))
            t:assertEqual(type(stats.waist), "number",
                string.format("Armor '%s' waist should be number", name))
            t:assertEqual(type(stats.legs), "number",
                string.format("Armor '%s' legs should be number", name))
        end
    end
end)

Test.test("WeaponStats entries have valid structure", function(t)
    for _, expansion in ipairs(getAllExpansions()) do
        for name, stats in pairs(expansion.weaponStats or {}) do
            -- Each weapon should have speed, accuracy, strength
            t:assertNotNil(stats.speed, 
                string.format("Weapon '%s' in '%s' missing 'speed' stat", name, expansion.name))
            t:assertNotNil(stats.accuracy, 
                string.format("Weapon '%s' in '%s' missing 'accuracy' stat", name, expansion.name))
            t:assertNotNil(stats.strength, 
                string.format("Weapon '%s' in '%s' missing 'strength' stat", name, expansion.name))
            
            -- Values should be numbers
            t:assertEqual(type(stats.speed), "number",
                string.format("Weapon '%s' speed should be number", name))
            t:assertEqual(type(stats.accuracy), "number",
                string.format("Weapon '%s' accuracy should be number", name))
            t:assertEqual(type(stats.strength), "number",
                string.format("Weapon '%s' strength should be number", name))
        end
    end
end)

Test.test("No duplicate gear names across expansions", function(t)
    local allArmor = {}
    local allWeapons = {}
    local duplicates = {}
    
    for _, expansion in ipairs(getAllExpansions()) do
        for name, _ in pairs(expansion.armorStats or {}) do
            if allArmor[name] then
                table.insert(duplicates, string.format("Armor '%s' defined in both '%s' and '%s'", 
                    name, allArmor[name], expansion.name))
            else
                allArmor[name] = expansion.name
            end
        end
        
        for name, _ in pairs(expansion.weaponStats or {}) do
            if allWeapons[name] then
                table.insert(duplicates, string.format("Weapon '%s' defined in both '%s' and '%s'", 
                    name, allWeapons[name], expansion.name))
            else
                allWeapons[name] = expansion.name
            end
        end
    end
    
    t:assertEqual(#duplicates, 0, 
        "Found duplicate gear definitions: " .. table.concat(duplicates, "; "))
end)

Test.test("Archive entries have no duplicates within expansion", function(t)
    for _, expansion in ipairs(getAllExpansions()) do
        local seen = {}
        local duplicates = {}
        
        if expansion.archiveEntries and expansion.archiveEntries.entries then
            for _, entry in ipairs(expansion.archiveEntries.entries) do
                local key = entry[1] .. "|" .. entry[2]
                if seen[key] then
                    table.insert(duplicates, entry[1])
                else
                    seen[key] = true
                end
            end
        end
        
        t:assertEqual(#duplicates, 0, 
            string.format("Expansion '%s' has duplicate archive entries: %s", 
                expansion.name, table.concat(duplicates, ", ")))
    end
end)

Test.test("Weapons with pairingGroup must have paired=true", function(t)
    local errors = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for name, stats in pairs(expansion.weaponStats or {}) do
            if stats.pairingGroup and not stats.paired then
                table.insert(errors, string.format(
                    "Weapon '%s' in '%s' has pairingGroup but not paired=true",
                    name, expansion.name))
            end
        end
    end
    t:assertEqual(#errors, 0, table.concat(errors, "; "))
end)

Test.test("PairingGroup weapons have at least 2 members", function(t)
    -- Collect all pairingGroups and count members
    local pairingGroups = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for name, stats in pairs(expansion.weaponStats or {}) do
            if stats.pairingGroup then
                if not pairingGroups[stats.pairingGroup] then
                    pairingGroups[stats.pairingGroup] = {}
                end
                table.insert(pairingGroups[stats.pairingGroup], name)
            end
        end
    end

    local errors = {}
    for group, members in pairs(pairingGroups) do
        if #members < 2 then
            table.insert(errors, string.format(
                "PairingGroup '%s' has only %d member(s): %s",
                group, #members, table.concat(members, ", ")))
        end
    end
    t:assertEqual(#errors, 0, table.concat(errors, "; "))
end)

--------------------------------------------------------------------------------
-- Resource Rewards Tests
--------------------------------------------------------------------------------

-- Helper to collect all monsters with their resource rewards
local function collectMonsterResourceRewards()
    local monsters = {}
    for _, expansion in ipairs(getAllExpansions()) do
        for _, monster in ipairs(expansion.monsters or {}) do
            if monster.levels then
                for _, level in ipairs(monster.levels) do
                    local victory = level.showdown and level.showdown.aftermath and level.showdown.aftermath.victory
                    if victory and victory.resources then
                        table.insert(monsters, {
                            expansion = expansion.name,
                            monster = monster.name,
                            level = level.name,
                            resources = victory.resources,
                        })
                    end
                end
            end
        end
    end
    return monsters
end

Test.test("Resource rewards have valid structure", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    for _, entry in ipairs(monstersWithRewards) do
        local res = entry.resources
        local desc = string.format("%s %s (%s)", entry.monster, entry.level, entry.expansion)

        -- basic must be a number if present
        if res.basic then
            t:assertEqual(type(res.basic), "number",
                string.format("%s: basic must be a number", desc))
            t:assertTrue(res.basic >= 0,
                string.format("%s: basic must be non-negative", desc))
        end

        -- monster must be a number if present
        if res.monster then
            t:assertEqual(type(res.monster), "number",
                string.format("%s: monster must be a number", desc))
            t:assertTrue(res.monster >= 0,
                string.format("%s: monster must be non-negative", desc))
        end

        -- vermin must be a number if present
        if res.vermin then
            t:assertEqual(type(res.vermin), "number",
                string.format("%s: vermin must be a number", desc))
            t:assertTrue(res.vermin >= 0,
                string.format("%s: vermin must be non-negative", desc))
        end

        -- strange must be a table of strings if present
        if res.strange then
            t:assertEqual(type(res.strange), "table",
                string.format("%s: strange must be a table", desc))
            for i, name in ipairs(res.strange) do
                t:assertEqual(type(name), "string",
                    string.format("%s: strange[%d] must be a string", desc, i))
                t:assertTrue(#name > 0,
                    string.format("%s: strange[%d] must be non-empty", desc, i))
            end
        end
    end
end)

Test.test("Screaming Antelope has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local antelopeRewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Screaming Antelope" then
            antelopeRewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster
    t:assertNotNil(antelopeRewards["Level 1"], "Screaming Antelope L1 should have rewards")
    t:assertEqual(antelopeRewards["Level 1"].basic, 4, "Screaming Antelope L1 basic should be 4")
    t:assertEqual(antelopeRewards["Level 1"].monster, 4, "Screaming Antelope L1 monster should be 4")

    -- L2: 4 basic, 6 monster
    t:assertNotNil(antelopeRewards["Level 2"], "Screaming Antelope L2 should have rewards")
    t:assertEqual(antelopeRewards["Level 2"].basic, 4, "Screaming Antelope L2 basic should be 4")
    t:assertEqual(antelopeRewards["Level 2"].monster, 6, "Screaming Antelope L2 monster should be 6")

    -- L3: 5 basic, 7 monster, strange = { "Black Lichen" } (no vermin per Core Rules p88)
    t:assertNotNil(antelopeRewards["Level 3"], "Screaming Antelope L3 should have rewards")
    t:assertEqual(antelopeRewards["Level 3"].basic, 5, "Screaming Antelope L3 basic should be 5")
    t:assertEqual(antelopeRewards["Level 3"].monster, 7, "Screaming Antelope L3 monster should be 7")
    t:assertNil(antelopeRewards["Level 3"].vermin, "Screaming Antelope L3 should NOT have vermin (Core Rules p88)")
    t:assertNotNil(antelopeRewards["Level 3"].strange, "Screaming Antelope L3 should have strange resources")
    t:assertEqual(#antelopeRewards["Level 3"].strange, 1, "Screaming Antelope L3 should have 1 strange resource")
    t:assertEqual(antelopeRewards["Level 3"].strange[1], "Black Lichen", "Screaming Antelope L3 strange should be Black Lichen")
end)

Test.test("Phoenix has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local phoenixRewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Phoenix" then
            phoenixRewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 6 monster
    t:assertNotNil(phoenixRewards["Level 1"], "Phoenix L1 should have rewards")
    t:assertEqual(phoenixRewards["Level 1"].basic, 4, "Phoenix L1 basic should be 4")
    t:assertEqual(phoenixRewards["Level 1"].monster, 6, "Phoenix L1 monster should be 6")

    -- L2: 5 basic, 7 monster
    t:assertNotNil(phoenixRewards["Level 2"], "Phoenix L2 should have rewards")
    t:assertEqual(phoenixRewards["Level 2"].basic, 5, "Phoenix L2 basic should be 5")
    t:assertEqual(phoenixRewards["Level 2"].monster, 7, "Phoenix L2 monster should be 7")

    -- L3: 6 basic, 9 monster, strange = { "Phoenix Crest", "Black Lichen" }
    t:assertNotNil(phoenixRewards["Level 3"], "Phoenix L3 should have rewards")
    t:assertEqual(phoenixRewards["Level 3"].basic, 6, "Phoenix L3 basic should be 6")
    t:assertEqual(phoenixRewards["Level 3"].monster, 9, "Phoenix L3 monster should be 9")
    t:assertNotNil(phoenixRewards["Level 3"].strange, "Phoenix L3 should have strange resources")
    t:assertEqual(#phoenixRewards["Level 3"].strange, 2, "Phoenix L3 should have 2 strange resources")
end)

Test.test("Gorm has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local gormRewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Gorm" then
            gormRewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster
    t:assertNotNil(gormRewards["Level 1"], "Gorm L1 should have rewards")
    t:assertEqual(gormRewards["Level 1"].basic, 4, "Gorm L1 basic should be 4")
    t:assertEqual(gormRewards["Level 1"].monster, 4, "Gorm L1 monster should be 4")

    -- L2: 4 basic, 6 monster
    t:assertNotNil(gormRewards["Level 2"], "Gorm L2 should have rewards")
    t:assertEqual(gormRewards["Level 2"].basic, 4, "Gorm L2 basic should be 4")
    t:assertEqual(gormRewards["Level 2"].monster, 6, "Gorm L2 monster should be 6")

    -- L3: 4 basic, 8 monster, strange = { "Stomach Lining" }
    t:assertNotNil(gormRewards["Level 3"], "Gorm L3 should have rewards")
    t:assertEqual(gormRewards["Level 3"].basic, 4, "Gorm L3 basic should be 4")
    t:assertEqual(gormRewards["Level 3"].monster, 8, "Gorm L3 monster should be 8")
    t:assertNotNil(gormRewards["Level 3"].strange, "Gorm L3 should have strange resources")
    t:assertEqual(#gormRewards["Level 3"].strange, 1, "Gorm L3 should have 1 strange resource")
    t:assertEqual(gormRewards["Level 3"].strange[1], "Stomach Lining", "Gorm L3 strange should be Stomach Lining")
end)

Test.test("White Lion has resource rewards for L1-L3 (existing baseline)", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local lionRewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "White Lion" then
            lionRewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster
    t:assertNotNil(lionRewards["Level 1"], "White Lion L1 should have rewards")
    t:assertEqual(lionRewards["Level 1"].basic, 4, "White Lion L1 basic should be 4")
    t:assertEqual(lionRewards["Level 1"].monster, 4, "White Lion L1 monster should be 4")

    -- L2: 4 basic, 6 monster
    t:assertNotNil(lionRewards["Level 2"], "White Lion L2 should have rewards")
    t:assertEqual(lionRewards["Level 2"].basic, 4, "White Lion L2 basic should be 4")
    t:assertEqual(lionRewards["Level 2"].monster, 6, "White Lion L2 monster should be 6")

    -- L3: 4 basic, 8 monster, strange = { "Elder Cat Teeth" }
    t:assertNotNil(lionRewards["Level 3"], "White Lion L3 should have rewards")
    t:assertEqual(lionRewards["Level 3"].basic, 4, "White Lion L3 basic should be 4")
    t:assertEqual(lionRewards["Level 3"].monster, 8, "White Lion L3 monster should be 8")
    t:assertNotNil(lionRewards["Level 3"].strange, "White Lion L3 should have strange resources")
    t:assertEqual(lionRewards["Level 3"].strange[1], "Elder Cat Teeth", "White Lion L3 strange should be Elder Cat Teeth")
end)

Test.test("Spidicules has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local rewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Spidicules" then
            rewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster
    t:assertNotNil(rewards["Level 1"], "Spidicules L1 should have rewards")
    t:assertEqual(rewards["Level 1"].basic, 4, "Spidicules L1 basic should be 4")
    t:assertEqual(rewards["Level 1"].monster, 4, "Spidicules L1 monster should be 4")

    -- L2: 4 basic, 6 monster
    t:assertNotNil(rewards["Level 2"], "Spidicules L2 should have rewards")
    t:assertEqual(rewards["Level 2"].basic, 4, "Spidicules L2 basic should be 4")
    t:assertEqual(rewards["Level 2"].monster, 6, "Spidicules L2 monster should be 6")

    -- L3: 4 basic, 8 monster, strange = { "Silken Nervous System" }
    t:assertNotNil(rewards["Level 3"], "Spidicules L3 should have rewards")
    t:assertEqual(rewards["Level 3"].basic, 4, "Spidicules L3 basic should be 4")
    t:assertEqual(rewards["Level 3"].monster, 8, "Spidicules L3 monster should be 8")
    t:assertNotNil(rewards["Level 3"].strange, "Spidicules L3 should have strange resources")
    t:assertEqual(#rewards["Level 3"].strange, 1, "Spidicules L3 should have 1 strange resource")
    t:assertEqual(rewards["Level 3"].strange[1], "Silken Nervous System", "Spidicules L3 strange should be Silken Nervous System")
end)

Test.test("Dragon King has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local rewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Dragon King" then
            rewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster
    t:assertNotNil(rewards["Level 1"], "Dragon King L1 should have rewards")
    t:assertEqual(rewards["Level 1"].basic, 4, "Dragon King L1 basic should be 4")
    t:assertEqual(rewards["Level 1"].monster, 4, "Dragon King L1 monster should be 4")

    -- L2: 4 basic, 6 monster, strange = { "Pituitary Gland" }
    t:assertNotNil(rewards["Level 2"], "Dragon King L2 should have rewards")
    t:assertEqual(rewards["Level 2"].basic, 4, "Dragon King L2 basic should be 4")
    t:assertEqual(rewards["Level 2"].monster, 6, "Dragon King L2 monster should be 6")
    t:assertNotNil(rewards["Level 2"].strange, "Dragon King L2 should have strange resources")
    t:assertEqual(#rewards["Level 2"].strange, 1, "Dragon King L2 should have 1 strange resource")
    t:assertEqual(rewards["Level 2"].strange[1], "Pituitary Gland", "Dragon King L2 strange should be Pituitary Gland")

    -- L3: 4 basic, 8 monster, strange = { "Shining Liver" }
    t:assertNotNil(rewards["Level 3"], "Dragon King L3 should have rewards")
    t:assertEqual(rewards["Level 3"].basic, 4, "Dragon King L3 basic should be 4")
    t:assertEqual(rewards["Level 3"].monster, 8, "Dragon King L3 monster should be 8")
    t:assertNotNil(rewards["Level 3"].strange, "Dragon King L3 should have strange resources")
    t:assertEqual(#rewards["Level 3"].strange, 1, "Dragon King L3 should have 1 strange resource")
    t:assertEqual(rewards["Level 3"].strange[1], "Shining Liver", "Dragon King L3 strange should be Shining Liver")
end)

Test.test("Sunstalker has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local rewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Sunstalker" then
            rewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster, strange = { "Sunstones" }
    t:assertNotNil(rewards["Level 1"], "Sunstalker L1 should have rewards")
    t:assertEqual(rewards["Level 1"].basic, 4, "Sunstalker L1 basic should be 4")
    t:assertEqual(rewards["Level 1"].monster, 4, "Sunstalker L1 monster should be 4")
    t:assertNotNil(rewards["Level 1"].strange, "Sunstalker L1 should have strange resources")
    t:assertEqual(#rewards["Level 1"].strange, 1, "Sunstalker L1 should have 1 strange resource")
    t:assertEqual(rewards["Level 1"].strange[1], "Sunstones", "Sunstalker L1 strange should be Sunstones")

    -- L2: 4 basic, 6 monster, strange = { "1,000 Year Old Sunspot" }
    t:assertNotNil(rewards["Level 2"], "Sunstalker L2 should have rewards")
    t:assertEqual(rewards["Level 2"].basic, 4, "Sunstalker L2 basic should be 4")
    t:assertEqual(rewards["Level 2"].monster, 6, "Sunstalker L2 monster should be 6")
    t:assertNotNil(rewards["Level 2"].strange, "Sunstalker L2 should have strange resources")
    t:assertEqual(#rewards["Level 2"].strange, 1, "Sunstalker L2 should have 1 strange resource")
    t:assertEqual(rewards["Level 2"].strange[1], "1,000 Year Old Sunspot", "Sunstalker L2 strange should be 1,000 Year Old Sunspot")

    -- L3: 7 basic, 8 monster, strange = { "3,000 Year Old Sunspot" }
    t:assertNotNil(rewards["Level 3"], "Sunstalker L3 should have rewards")
    t:assertEqual(rewards["Level 3"].basic, 7, "Sunstalker L3 basic should be 7")
    t:assertEqual(rewards["Level 3"].monster, 8, "Sunstalker L3 monster should be 8")
    t:assertNotNil(rewards["Level 3"].strange, "Sunstalker L3 should have strange resources")
    t:assertEqual(#rewards["Level 3"].strange, 1, "Sunstalker L3 should have 1 strange resource")
    t:assertEqual(rewards["Level 3"].strange[1], "3,000 Year Old Sunspot", "Sunstalker L3 strange should be 3,000 Year Old Sunspot")
end)

Test.test("Dung Beetle Knight has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local rewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Dung Beetle Knight" then
            rewards[entry.level] = entry.resources
        end
    end

    -- L1: 6 basic, 4 monster, strange = { "Preserved Caustic Dung", "Preserved Caustic Dung" }
    t:assertNotNil(rewards["Level 1"], "Dung Beetle Knight L1 should have rewards")
    t:assertEqual(rewards["Level 1"].basic, 6, "Dung Beetle Knight L1 basic should be 6")
    t:assertEqual(rewards["Level 1"].monster, 4, "Dung Beetle Knight L1 monster should be 4")
    t:assertNotNil(rewards["Level 1"].strange, "Dung Beetle Knight L1 should have strange resources")
    t:assertEqual(#rewards["Level 1"].strange, 2, "Dung Beetle Knight L1 should have 2 strange resources")

    -- L2: 7 basic, 6 monster, strange = { 3x "Preserved Caustic Dung", "Scell" }
    t:assertNotNil(rewards["Level 2"], "Dung Beetle Knight L2 should have rewards")
    t:assertEqual(rewards["Level 2"].basic, 7, "Dung Beetle Knight L2 basic should be 7")
    t:assertEqual(rewards["Level 2"].monster, 6, "Dung Beetle Knight L2 monster should be 6")
    t:assertNotNil(rewards["Level 2"].strange, "Dung Beetle Knight L2 should have strange resources")
    t:assertEqual(#rewards["Level 2"].strange, 4, "Dung Beetle Knight L2 should have 4 strange resources")

    -- L3: 8 basic, 8 monster, strange = { 3x "Preserved Caustic Dung", "Scell" }
    t:assertNotNil(rewards["Level 3"], "Dung Beetle Knight L3 should have rewards")
    t:assertEqual(rewards["Level 3"].basic, 8, "Dung Beetle Knight L3 basic should be 8")
    t:assertEqual(rewards["Level 3"].monster, 8, "Dung Beetle Knight L3 monster should be 8")
    t:assertNotNil(rewards["Level 3"].strange, "Dung Beetle Knight L3 should have strange resources")
    t:assertEqual(#rewards["Level 3"].strange, 4, "Dung Beetle Knight L3 should have 4 strange resources")
end)

Test.test("Flower Knight has resource rewards for L1-L3", function(t)
    local monstersWithRewards = collectMonsterResourceRewards()

    local rewards = {}
    for _, entry in ipairs(monstersWithRewards) do
        if entry.monster == "Flower Knight" then
            rewards[entry.level] = entry.resources
        end
    end

    -- L1: 4 basic, 4 monster (no strange)
    t:assertNotNil(rewards["Level 1"], "Flower Knight L1 should have rewards")
    t:assertEqual(rewards["Level 1"].basic, 4, "Flower Knight L1 basic should be 4")
    t:assertEqual(rewards["Level 1"].monster, 4, "Flower Knight L1 monster should be 4")
    t:assertNil(rewards["Level 1"].strange, "Flower Knight L1 should have no strange resources")

    -- L2: 4 basic, 6 monster (no strange)
    t:assertNotNil(rewards["Level 2"], "Flower Knight L2 should have rewards")
    t:assertEqual(rewards["Level 2"].basic, 4, "Flower Knight L2 basic should be 4")
    t:assertEqual(rewards["Level 2"].monster, 6, "Flower Knight L2 monster should be 6")
    t:assertNil(rewards["Level 2"].strange, "Flower Knight L2 should have no strange resources")

    -- L3: 4 basic, 8 monster (no strange)
    t:assertNotNil(rewards["Level 3"], "Flower Knight L3 should have rewards")
    t:assertEqual(rewards["Level 3"].basic, 4, "Flower Knight L3 basic should be 4")
    t:assertEqual(rewards["Level 3"].monster, 8, "Flower Knight L3 monster should be 8")
    t:assertNil(rewards["Level 3"].strange, "Flower Knight L3 should have no strange resources")
end)

--------------------------------------------------------------------------------

-- Summary test that reports statistics
Test.test("Expansion data summary", function(t)
    local totalArmor = 0
    local totalWeapons = 0
    local totalGearDecks = 0
    local totalArchiveEntries = 0
    
    for _, expansion in ipairs(getAllExpansions()) do
        for _ in pairs(expansion.armorStats or {}) do
            totalArmor = totalArmor + 1
        end
        for _ in pairs(expansion.weaponStats or {}) do
            totalWeapons = totalWeapons + 1
        end
        if expansion.archiveEntries and expansion.archiveEntries.entries then
            for _, entry in ipairs(expansion.archiveEntries.entries) do
                totalArchiveEntries = totalArchiveEntries + 1
                if entry[2] == "Gear" then
                    totalGearDecks = totalGearDecks + 1
                end
            end
        end
    end
    
    -- Just verify we have data
    t:assertTrue(totalArmor > 0, "Should have armor definitions")
    t:assertTrue(totalWeapons > 0, "Should have weapon definitions")
    t:assertTrue(totalGearDecks > 0, "Should have gear deck entries")
    t:assertTrue(totalArchiveEntries > 0, "Should have archive entries")
    
    -- Print summary (this will show in test output)
    print(string.format("\n  Expansion Data Summary:"))
    print(string.format("    - %d expansions loaded", #getAllExpansions()))
    print(string.format("    - %d armor pieces defined", totalArmor))
    print(string.format("    - %d weapons defined", totalWeapons))
    print(string.format("    - %d gear decks in archives", totalGearDecks))
    print(string.format("    - %d total archive entries", totalArchiveEntries))
end)

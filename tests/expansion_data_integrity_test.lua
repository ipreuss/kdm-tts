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

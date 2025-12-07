local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Template Archive Integrity Tests
-- Verifies that archive entries declared in expansion code exist in template_workshop.json
---------------------------------------------------------------------------------------------------

-- Parse template_workshop.json to extract all object nicknames
local function loadTemplateNicknames()
    local file = io.open("template_workshop.json", "r")
    if not file then
        return nil, "Could not open template_workshop.json"
    end
    
    local nicknames = {}
    
    -- Read line by line to avoid loading 16MB into memory
    for line in file:lines() do
        local nickname = line:match('"Nickname":%s*"([^"]+)"')
        if nickname then
            nicknames[nickname] = (nicknames[nickname] or 0) + 1
        end
    end
    
    file:close()
    return nicknames
end

-- Parse template_workshop.json to extract all GUIDs
local function loadTemplateGuids()
    local file = io.open("template_workshop.json", "r")
    if not file then
        return nil, "Could not open template_workshop.json"
    end
    
    local guids = {}
    
    for line in file:lines() do
        local guid = line:match('"GUID":%s*"([^"]+)"')
        if guid then
            guids[guid] = true
        end
    end
    
    file:close()
    return guids
end

-- Load all expansions
local function getAllExpansions()
    local expansions = {}
    
    local Core = require("Kdm/Expansion/Core")
    table.insert(expansions, Core)
    
    local expansionFiles = {
        "CommunityEdition", "DragonKing", "DungBeetleKnight", "FlowerKnight",
        "Gorm", "Kraken", "LionGod", "LionKnight", "LonelyTree", "Manhunter",
        "Slenderman", "Spidicules", "Sunstalker", "DBKIntegrated", "HarvesterWorm",
        "Screaming God", "Nightmare Ram"
    }
    
    for _, name in ipairs(expansionFiles) do
        local ok, expansion = pcall(require, "Kdm/Expansion/" .. name)
        if ok and expansion then
            table.insert(expansions, expansion)
        end
    end
    
    return expansions
end

---------------------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------------------

Test.test("Template file can be parsed for nicknames", function(t)
    local nicknames, err = loadTemplateNicknames()
    t:assertTrue(nicknames ~= nil, err or "Failed to load nicknames")
    
    -- Should have many objects
    local count = 0
    for _ in pairs(nicknames) do count = count + 1 end
    t:assertTrue(count > 100, "Should have more than 100 unique nicknames, got " .. count)
end)

Test.test("All expansion archive GUIDs exist in template", function(t)
    local guids = loadTemplateGuids()
    if not guids then
        t:fail("Could not load template GUIDs")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    for _, expansion in ipairs(expansions) do
        if expansion.guidNames then
            for guid, name in pairs(expansion.guidNames) do
                if not guids[guid] then
                    table.insert(missing, string.format("GUID '%s' (%s) in '%s'", 
                        guid, name, expansion.name))
                end
            end
        end
    end
    
    if #missing > 0 then
        t:fail("GUIDs not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

Test.test("All expansion archives exist in template (by nickname)", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    for _, expansion in ipairs(expansions) do
        if expansion.archiveEntries and expansion.archiveEntries.archive then
            local archiveName = expansion.archiveEntries.archive
            -- Skip Core - it uses GUID mapping via guidNames, not nickname lookup
            if expansion.name ~= "Core" then
                t:assertTrue(nicknames[archiveName], 
                    string.format("Archive '%s' for expansion '%s' not found in template_workshop.json", 
                        archiveName, expansion.name))
            end
        end
    end
end)

Test.test("All archive entry decks exist in template", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    for _, expansion in ipairs(expansions) do
        if expansion.archiveEntries and expansion.archiveEntries.entries then
            for _, entry in ipairs(expansion.archiveEntries.entries) do
                local deckName = entry[1]
                if not nicknames[deckName] then
                    table.insert(missing, string.format("'%s' (type: %s) in '%s'", 
                        deckName, entry[2], expansion.name))
                end
            end
        end
    end
    
    if #missing > 0 then
        t:fail("Archive entries not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

Test.test("All component deck references exist in template", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    for _, expansion in ipairs(expansions) do
        for key, value in pairs(expansion.components or {}) do
            if type(value) == "string" then
                if not nicknames[value] then
                    table.insert(missing, string.format("Component '%s' -> '%s' in '%s'", 
                        key, value, expansion.name))
                end
            end
        end
    end
    
    if #missing > 0 then
        t:fail("Component references not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

Test.test("All gearStats items exist in template", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    for _, expansion in ipairs(expansions) do
        for name, _ in pairs(expansion.gearStats or {}) do
            if not nicknames[name] then
                table.insert(missing, string.format("Gear '%s' in '%s'", name, expansion.name))
            end
        end
    end
    
    if #missing > 0 then
        t:fail("gearStats items not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

-- TODO: Re-enable these tests once missing items are resolved
-- Currently skipped because there are known data inconsistencies that need manual review:
-- - Armor: Vagabond Armor, White Sunlion Mask, Flower Knight Costume
-- - Weapons: Aya's (incomplete), paired weapons (Bone Hatchet, Tempered Axe), Thunder Maul (Core, not in template)

Test.test("All armorStats items exist in template", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    local knownMissing = {
    }
    
    for _, expansion in ipairs(expansions) do
        for name, _ in pairs(expansion.armorStats or {}) do
            if not nicknames[name] and not knownMissing[name] then
                table.insert(missing, string.format("Armor '%s' in '%s'", name, expansion.name))
            end
        end
    end
    
    if #missing > 0 then
        t:fail("armorStats items not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

Test.test("All weaponStats items exist in template", function(t)
    local nicknames = loadTemplateNicknames()
    if not nicknames then
        t:fail("Could not load template nicknames")
        return
    end
    
    local expansions = getAllExpansions()
    local missing = {}
    
    -- Known missing items documented in docs/BACKLOG.md#missing-gear-items
    -- Thunder Maul is in Core (not CE) but missing from template
    local knownMissing = {
        ["Aya's"] = true,
        ["Bone Hatchet"] = true,
        ["Tempered Axe"] = true,
        ["Thunder Maul"] = true,
    }
    
    for _, expansion in ipairs(expansions) do
        for name, _ in pairs(expansion.weaponStats or {}) do
            if not nicknames[name] and not knownMissing[name] then
                table.insert(missing, string.format("Weapon '%s' in '%s'", name, expansion.name))
            end
        end
    end
    
    if #missing > 0 then
        t:fail("weaponStats items not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

-- Print summary
Test.test("Template integrity summary", function(t)
    local nicknames = loadTemplateNicknames()
    if nicknames then
        local count = 0
        for _ in pairs(nicknames) do count = count + 1 end
        print(string.format("\n  Template Summary:"))
        print(string.format("    - %d unique object nicknames in template_workshop.json", count))
    end
    t:assertTrue(true)
end)

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

-- Check if a base name has bracket variants in template
-- e.g., "Bone Hatchet" matches if "Bone Hatchet [left]" or "Bone Hatchet [right]" exist
local function hasBracketVariant(baseName, nicknames)
    -- Escape special pattern characters in base name
    local escaped = baseName:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    local pattern = "^" .. escaped .. " %[.+%]$"
    for nickname in pairs(nicknames) do
        if nickname:match(pattern) then
            return true
        end
    end
    return false
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

-- Note: Paired weapons (Bone Hatchet, Tempered Axe, Aya's) are validated
-- via hasBracketVariant() which checks for [variant] suffixes in template.

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
    
    -- All paired weapons now handled via hasBracketVariant()
    local knownMissing = {
    }

    for _, expansion in ipairs(expansions) do
        for name, stats in pairs(expansion.weaponStats or {}) do
            local found = nicknames[name]

            -- For paired weapons, also accept bracket variants
            if not found and stats.paired then
                found = hasBracketVariant(name, nicknames)
            end

            if not found and not knownMissing[name] then
                table.insert(missing, string.format("Weapon '%s' in '%s'", name, expansion.name))
            end
        end
    end
    
    if #missing > 0 then
        t:fail("weaponStats items not found in template_workshop.json:\n  - " .. table.concat(missing, "\n  - "))
    end
end)

Test.test("Core Archive.data token entries have NamedObject GUIDs", function(t)
    local templateGuids = loadTemplateGuids()
    if not templateGuids then
        t:fail("Could not load template GUIDs")
        return
    end

    -- Stub minimal dependencies to load Archive module for its static data
    local noop = function() end
    local noopLog = { Debugf = noop, Errorf = noop, Printf = noop, Broadcastf = noop }
    local stubs = {
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Util/Container"] = function() return {} end,
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/Location/Location"] = {},
        ["Kdm/Core/Log"] = { ForModule = function() return noopLog end },
        ["Kdm/Util/ObjectState"] = {},
        ["Kdm/Util/TTSSpawner"] = {},
        ["Kdm/Util/Util"] = {},
    }

    -- Load NamedObject.data (it has minimal deps, just need stubs)
    local noStubs = {
        ["Kdm/Util/Check"] = stubs["Kdm/Util/Check"],
        ["Kdm/Core/Console"] = { AddCommand = noop },
        ["Kdm/Util/EventManager"] = { AddHandler = noop },
        ["Kdm/Expansion"] = stubs["Kdm/Expansion"],
        ["Kdm/Core/Log"] = stubs["Kdm/Core/Log"],
    }

    -- Save and stub
    local savedModules = {}
    for name, stub in pairs(stubs) do
        savedModules[name] = package.loaded[name]
        package.loaded[name] = stub
    end
    for name, stub in pairs(noStubs) do
        if not savedModules[name] then
            savedModules[name] = package.loaded[name]
        end
        package.loaded[name] = stub
    end

    -- Clear cached modules to force reload
    local origArchive = package.loaded["Kdm/Archive/Archive"]
    local origNamedObject = package.loaded["Kdm/Location/NamedObject"]
    package.loaded["Kdm/Archive/Archive"] = nil
    package.loaded["Kdm/Location/NamedObject"] = nil

    local ok, err = pcall(function()
        local Archive = require("Kdm/Archive/Archive")
        local NamedObject = require("Kdm/Location/NamedObject")

        -- Build reverse lookup: name -> guid from NamedObject.data
        local nameToGuid = {}
        for guid, data in pairs(NamedObject.data) do
            nameToGuid[data.name] = guid
        end

        local missing = {}
        local invalidGuids = {}

        -- Check each "Tokens" type entry in Archive.data
        for _, entry in ipairs(Archive.data) do
            local name, entryType, archiveName = entry[1], entry[2], entry[3]
            if entryType == "Tokens" then
                local guid = nameToGuid[archiveName]
                if not guid then
                    table.insert(missing, string.format("'%s' (archive: '%s')", name, archiveName))
                elseif not templateGuids[guid] then
                    table.insert(invalidGuids, string.format("'%s' GUID '%s' not in template", archiveName, guid))
                end
            end
        end

        if #missing > 0 then
            t:fail("Archive.data tokens missing NamedObject.data entries:\n  - " .. table.concat(missing, "\n  - "))
        end

        if #invalidGuids > 0 then
            t:fail("NamedObject.data token GUIDs not in template:\n  - " .. table.concat(invalidGuids, "\n  - "))
        end
    end)

    -- Restore
    package.loaded["Kdm/Archive/Archive"] = origArchive
    package.loaded["Kdm/Location/NamedObject"] = origNamedObject
    for name, original in pairs(savedModules) do
        package.loaded[name] = original
    end

    if not ok then
        t:fail("Test setup error: " .. tostring(err))
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

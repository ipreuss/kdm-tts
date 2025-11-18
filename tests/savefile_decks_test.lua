-- Validates that the three character decks in the savefile stay in sync with
-- the archetype names defined in Util/Names.ttslua. This intentionally reads
-- savefile_backup.json (the live asset source) to catch drifts between code and
-- bundled TTS data.
local Test = require("tests.framework")
local Bootstrap = require("tests.support.bootstrap")
local json = require("tests.support.json")

Bootstrap.setup()

local Names = require("Kdm/Util/Names")

local TARGET_DECKS = {
    ["Character - Abilities"] = true,
    ["Character - Impairments"] = true,
    ["Character - Legendary Abilities"] = true,
}

local SAVE_PATH = "savefile_backup.json"

local function readSave()
    local file, err = io.open(SAVE_PATH, "r")
    if not file then
        error((
            "Could not open %s: %s\n"
            .. "This test needs the real savefile to validate deck/name consistency."
        ):format(SAVE_PATH, err))
    end
    local content = file:read("*a")
    file:close()
    return json.decode(content)
end

local function collectDecks()
    local save = readSave()
    local decks = {}

    local function walk(obj)
        if type(obj) ~= "table" then
            return
        end

        if TARGET_DECKS[obj.Nickname] and (obj.Name == "Deck" or obj.Name == "DeckCustom") then
            decks[obj.Nickname] = obj
        end

        if obj.ContainedObjects then
            for _, child in ipairs(obj.ContainedObjects) do
                walk(child)
            end
        end
        if obj.ObjectStates then
            for _, child in ipairs(obj.ObjectStates) do
                walk(child)
            end
        end
    end

    walk(save)
    return decks
end

local function nameKeys()
    local result = {}
    for characterName in pairs(Names.names[Names.Gender.male]) do
        if characterName ~= "none" then
            result[characterName] = true
        end
    end
    for characterName in pairs(Names.names[Names.Gender.female]) do
        if characterName ~= "none" then
            result[characterName] = true
        end
    end
    return result
end

Test.test("Character decks match name definitions", function(t)
    local decks = collectDecks()
    for target in pairs(TARGET_DECKS) do
        t:assertTrue(decks[target], ("Missing deck '%s' in savefile"):format(target))
    end

    local cardNames = {}
    local function addCards(deck)
        for _, card in ipairs(deck.ContainedObjects or {}) do
            cardNames[card.Nickname] = true
        end
    end

    for _, deck in pairs(decks) do
        addCards(deck)
    end

    local definedNames = nameKeys()

    for name in pairs(definedNames) do
        t:assertTrue(cardNames[name], ("Name '%s' present in Names but missing from character decks"):format(name))
    end
    for name in pairs(cardNames) do
        t:assertTrue(definedNames[name], ("Name '%s' present in character decks but missing from Names"):format(name))
    end
end)

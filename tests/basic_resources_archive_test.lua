local Test = require("tests.framework")

local function withStubs(stubs, fn)
    local originals = {}
    for name, mod in pairs(stubs) do
        originals[name] = package.loaded[name]
        package.loaded[name] = mod
    end
    local ok, err = pcall(fn)
    for name, orig in pairs(originals) do
        package.loaded[name] = orig
    end
    if not ok then
        error(err)
    end
end

local function buildBasicResourcesStubs(options)
    options = options or {}

    local deckResets = {}
    local deckObject = {
        inserted = {},
        removed = {},
        objects = {},
    }
    function deckObject.getPosition()
        return { x = 0, y = 0, z = 0 }
    end
    function deckObject.putObject(card)
        table.insert(deckObject.inserted, card)
    end
    function deckObject.getObjects()
        return deckObject.objects
    end
    function deckObject.takeObject(params)
        table.insert(deckObject.removed, params)
        local card = { 
            resting = true,  -- For Wait.condition check
            destruct = function() end,
        }
        -- Invoke callback_function if provided (simulates async TTS behavior)
        if params.callback_function then
            params.callback_function(card)
        end
        return card
    end

    if options.includeCard ~= false then
        table.insert(deckObject.objects, { name = options.cardName or "Lump of Atnas", gm_notes = "Basic Resources", index = 1 })
    end

    local archiveObject = {
        takeCalls = {},
        putCalls = {},
        resetCount = 0,
    }
    function archiveObject.takeObject(params)
        table.insert(archiveObject.takeCalls, params)
        return deckObject
    end
    function archiveObject.putObject(obj)
        table.insert(archiveObject.putCalls, obj)
    end
    function archiveObject.reset()
        archiveObject.resetCount = archiveObject.resetCount + 1
    end

    local namedObjectStub = {
        Get = function()
            return archiveObject
        end,
    }

    local strainDeck = {
        destroyed = false,
        objects = {
            { name = options.cardName or "Lump of Atnas", gm_notes = "Basic Resources", index = 1 },
        },
    }
    function strainDeck.getObjects()
        return strainDeck.objects
    end
    function strainDeck.takeObject(params)
        strainDeck.lastTakeParams = params
        local card = {
            name = options.cardName or "Lump of Atnas",
            resting = true,  -- For Wait.condition check
            destruct = function() end,
        }
        -- Invoke callback_function if provided (simulates async TTS behavior)
        if params.callback_function then
            params.callback_function(card)
        end
        return card
    end
    function strainDeck.destruct()
        strainDeck.destroyed = true
    end

    local archiveStub = {}
    function archiveStub.Take()
        return strainDeck
    end
    function archiveStub.Clean()
        archiveStub.cleans = (archiveStub.cleans or 0) + 1
    end

    local deckStub = {
        ResetDeck = function(location)
            table.insert(deckResets, location)
        end,
    }

    -- Set up archive helpers after deckStub exists
    function archiveStub.TransferCard(params)
        local card = params.source.takeObject({
            index = params.cardIndex,
            position = params.target.getPosition(),
            smooth = false,
        })
        if card then
            params.target.putObject(card)
            card.destruct()
        end
        if params.archive then
            if params.archive.reset then params.archive.reset() end
            params.archive.putObject(params.target)
        end
        archiveStub.cleans = (archiveStub.cleans or 0) + 1
        if params.deckLocation then
            deckStub.ResetDeck(params.deckLocation)
        end
        if params.onComplete then params.onComplete() end
    end
    function archiveStub.RemoveAndDestroyCard(params)
        local card = params.deck.takeObject({
            index = params.cardIndex,
            smooth = false,
        })
        if card then card.destruct() end
        if params.archive then
            if params.archive.reset then params.archive.reset() end
            params.archive.putObject(params.deck)
        end
        archiveStub.cleans = (archiveStub.cleans or 0) + 1
        if params.deckLocation then
            deckStub.ResetDeck(params.deckLocation)
        end
        if params.onComplete then params.onComplete() end
    end

    local logStub = { Errorf = function() end, Printf = function() end, Debugf = function() end }

    local stubs = {
        ["Kdm/Archive/Archive"] = archiveStub,
        ["Kdm/Location/NamedObject"] = namedObjectStub,
        ["Kdm/Data/Deck"] = deckStub,
        ["Kdm/Core/Log"] = { ForModule = function() return logStub end },
    }

    return stubs, {
        archiveObject = archiveObject,
        strainDeck = strainDeck,
        deckResets = deckResets,
        deckObject = deckObject,
        archiveStub = archiveStub,
    }
end

Test.test("BasicResourcesArchive.AddCard inserts reward card", function(t)
    local stubs, env = buildBasicResourcesStubs({})
    withStubs(stubs, function()
        package.loaded["Kdm/Archive/BasicResourcesArchive"] = nil
        local BasicResourcesArchive = require("Kdm/Archive/BasicResourcesArchive")

        local ok = BasicResourcesArchive.AddCard("Lump of Atnas")
        t:assertTrue(ok, "AddCard should succeed when card present")
        t:assertEqual(1, #env.deckObject.inserted, "Card should be inserted into Basic Resources deck")
        t:assertEqual("Lump of Atnas", env.deckObject.inserted[1].name)
        t:assertEqual("Basic Resources", env.deckResets[1])
        t:assertEqual(1, env.archiveStub.cleans, "Archive.Clean should be called after use")
    end)
end)

Test.test("BasicResourcesArchive.AddCard fails when card missing", function(t)
    local stubs = buildBasicResourcesStubs({ includeCard = false })
    withStubs(stubs, function()
        package.loaded["Kdm/Archive/BasicResourcesArchive"] = nil
        local BasicResourcesArchive = require("Kdm/Archive/BasicResourcesArchive")

        local ok = BasicResourcesArchive.AddCard("Missing")
        t:assertFalse(ok, "Expected failure when card absent")
    end)
end)

Test.test("BasicResourcesArchive.RemoveCard removes present card", function(t)
    local stubs, env = buildBasicResourcesStubs({})
    withStubs(stubs, function()
        package.loaded["Kdm/Archive/BasicResourcesArchive"] = nil
        local BasicResourcesArchive = require("Kdm/Archive/BasicResourcesArchive")

        local ok = BasicResourcesArchive.RemoveCard("Lump of Atnas")
        t:assertTrue(ok, "Removal should succeed")
        t:assertEqual(1, #env.deckObject.removed)
        t:assertEqual("Basic Resources", env.deckResets[1])
    end)
end)

Test.test("BasicResourcesArchive.RemoveCard logs when absent", function(t)
    local stubs = buildBasicResourcesStubs({ includeCard = false })
    withStubs(stubs, function()
        package.loaded["Kdm/Archive/BasicResourcesArchive"] = nil
        local BasicResourcesArchive = require("Kdm/Archive/BasicResourcesArchive")

        local ok = BasicResourcesArchive.RemoveCard("Missing")
        t:assertFalse(ok, "Removal should fail when card missing")
    end)
end)

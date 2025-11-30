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

local function buildVerminStubs(options)
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
        return { destruct = function() end }
    end

    if options.includeCard ~= false then
        table.insert(deckObject.objects, { name = options.cardName or "Fiddler Crab Spider", gm_notes = "Vermin", index = 1 })
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
            { name = options.cardName or "Fiddler Crab Spider", gm_notes = "Vermin", index = 1 },
        },
    }
    function strainDeck.getObjects()
        return strainDeck.objects
    end
    function strainDeck.takeObject(params)
        strainDeck.lastTakeParams = params
        return {
            name = options.cardName or "Fiddler Crab Spider",
            destruct = function() end,
        }
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

    local logStub = { Errorf = function() end, Printf = function() end, Debugf = function() end }

    local stubs = {
        ["Kdm/Archive"] = archiveStub,
        ["Kdm/NamedObject"] = namedObjectStub,
        ["Kdm/Deck"] = deckStub,
        ["Kdm/Log"] = { ForModule = function() return logStub end },
    }

    return stubs, {
        archiveObject = archiveObject,
        strainDeck = strainDeck,
        deckResets = deckResets,
        deckObject = deckObject,
        archiveStub = archiveStub,
    }
end

Test.test("VerminArchive.AddCard inserts reward card", function(t)
    local stubs, env = buildVerminStubs({})
    withStubs(stubs, function()
        package.loaded["Kdm/VerminArchive"] = nil
        local VerminArchive = require("Kdm/VerminArchive")

        local ok = VerminArchive.AddCard("Fiddler Crab Spider")
        t:assertTrue(ok, "AddCard should succeed when card present")
        t:assertEqual(1, #env.deckObject.inserted, "Card should be inserted into Vermin deck")
        t:assertEqual("Fiddler Crab Spider", env.deckObject.inserted[1].name)
        t:assertEqual("Vermin", env.deckResets[1])
        t:assertTrue(env.strainDeck.destroyed, "Strain deck instance should be destroyed after use")
    end)
end)

Test.test("VerminArchive.AddCard fails when card missing", function(t)
    local stubs = buildVerminStubs({ includeCard = false })
    withStubs(stubs, function()
        package.loaded["Kdm/VerminArchive"] = nil
        local VerminArchive = require("Kdm/VerminArchive")

        local ok = VerminArchive.AddCard("Missing")
        t:assertFalse(ok, "Expected failure when card absent")
    end)
end)

Test.test("VerminArchive.RemoveCard removes present card", function(t)
    local stubs, env = buildVerminStubs({})
    withStubs(stubs, function()
        package.loaded["Kdm/VerminArchive"] = nil
        local VerminArchive = require("Kdm/VerminArchive")

        local ok = VerminArchive.RemoveCard("Fiddler Crab Spider")
        t:assertTrue(ok, "Removal should succeed")
        t:assertEqual(1, #env.deckObject.removed)
        t:assertEqual("Vermin", env.deckResets[1])
    end)
end)

Test.test("VerminArchive.RemoveCard logs when absent", function(t)
    local stubs = buildVerminStubs({ includeCard = false })
    withStubs(stubs, function()
        package.loaded["Kdm/VerminArchive"] = nil
        local VerminArchive = require("Kdm/VerminArchive")

        local ok = VerminArchive.RemoveCard("Missing")
        t:assertFalse(ok, "Removal should fail when card missing")
    end)
end)

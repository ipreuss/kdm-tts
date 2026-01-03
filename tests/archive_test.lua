local Test = require("tests.framework")

local function archiveKey(name, type)
    return string.format("%s.%s", type, name)
end

local function withArchive(fn)
    local env = {}
    local function createContainer()
        local container = {
            takes = {},
            takeHandler = nil,
        }
        function container:IsEmpty()
            return false
        end
        function container:Guid()
            return "container-guid"
        end
        function container:Take(params)
            table.insert(self.takes, params)
            if self.takeHandler then
                return self.takeHandler(params)
            end
            if params.spawnFunc then
                params.spawnFunc(env.card)
            end
            return env.card
        end
        return container
    end

    env.NewContainer = createContainer

    local stubModules = {
        ["Kdm/Expansion"] = {
            All = function()
                return {}
            end,
        },
        ["Kdm/Location/Location"] = {
            Get = function()
                return {
                    Center = function()
                        return { x = 0, y = 0, z = 0 }
                    end,
                }
            end,
        },
        ["Kdm/Location/NamedObject"] = {},
        ["Kdm/Core/Log"] = {
            ForModule = function()
                local noop = function() end
                return {
                    Debugf = noop,
                    Errorf = noop,
                    Printf = noop,
                    Broadcastf = noop,
                }
            end,
        },
        ["Kdm/Util/Container"] = function(object)
            local container = createContainer()
            container.takeHandler = env.containerTakeHandler
            container.sourceObject = object
            env.lastCreatedContainer = container
            return container
        end,
    }

    stubModules["Kdm/Location/NamedObject"].Get = function(name)
        env.lastArchiveRequested = name
        local archiveObject = {
            getGUID = function()
                return "archive-guid"
            end,
            getName = function()
                return name
            end,
            takeObject = function(_, params)
                env.archiveTakeObjectParams = params
                return {}
            end,
        }
        return archiveObject
    end

    local savedModules = {}
    for name, stub in pairs(stubModules) do
        savedModules[name] = package.loaded[name]
        package.loaded[name] = stub
    end

    local originalArchive = package.loaded["Kdm/Archive/Archive"]
    package.loaded["Kdm/Archive/Archive"] = nil

    local ok, result = pcall(function()
        local Archive = require("Kdm/Archive/Archive")
        fn(Archive, env)
    end)

    package.loaded["Kdm/Archive/Archive"] = originalArchive
    for name, original in pairs(savedModules) do
        package.loaded[name] = original
    end

    if not ok then
        error(result, 0)
    end
end

Test.test("Archive.Take falls back to stripped names and re-applies requested state", function(t)
    withArchive(function(Archive, env)
        Archive.Init()
        Archive.containers = Archive.containers or {}
        Archive.RegisterEntries({
            archive = "Story of Blood Archive",
            entries = {
                { "Story of Blood", "Fighting Arts" },
            },
            allowOverrides = true,
        })

        local states = {
            { id = 1, name = "Story of Blood" },
            { id = 2, name = "Story of Blood [1, 2x]" },
        }
        local namesById = {
            [1] = "Story of Blood",
            [2] = "Story of Blood [1, 2x]",
        }
        local card = {
            stateId = 1,
            currentName = namesById[1],
            stateChanges = 0,
        }
        function card.getStates()
            return states
        end
        function card.setState(id)
            card.stateChanges = card.stateChanges + 1
            card.stateId = id
            card.currentName = namesById[id] or card.currentName
            return card
        end
        function card.getName()
            return card.currentName
        end
        env.card = card

        env.containerTakeHandler = function(params)
            if params.name == "Story of Blood" then
                if params.spawnFunc then
                    params.spawnFunc(card)
                end
                return card
            end
            return nil
        end

        local spawnNames = {}
        local result = Archive.Take({
            name = "Story of Blood [1, 2x]",
            type = "Fighting Arts",
            position = { x = 0, y = 0, z = 0 },
            spawnFunc = function(obj)
                table.insert(spawnNames, obj.getName())
            end,
        })

        t:assertTrue(result ~= nil, "Archive.Take should return the requested card")
        t:assertEqual("Story of Blood [1, 2x]", result.getName(), "Returned card should be on the requested state")
        t:assertEqual(1, #spawnNames, "Spawn callback should be invoked once")
        t:assertEqual("Story of Blood [1, 2x]", spawnNames[1], "Spawn callback should receive the fully-qualified state name")
        t:assertEqual(2, card.stateId, "Card should be switched to the requested state ID exactly once")
        t:assertEqual(1, card.stateChanges, "Card state should be applied only once")
    end)
end)

Test.test("Archive.Take handles fallback names even when an archive is provided", function(t)
    withArchive(function(Archive, env)
        Archive.Init()
        Archive.containers = Archive.containers or {}
        Archive.RegisterEntries({
            archive = "Story of Blood Archive",
            entries = {
                { "Story of Blood", "Fighting Arts" },
            },
            allowOverrides = true,
        })

        local states = {
            { id = 1, name = "Story of Blood" },
            { id = 2, name = "Story of Blood [1, 2x]" },
        }
        local namesById = {
            [1] = "Story of Blood",
            [2] = "Story of Blood [1, 2x]",
        }
        local card = {
            stateId = 1,
            currentName = namesById[1],
            stateChanges = 0,
        }
        function card.getStates()
            return states
        end
        function card.setState(id)
            card.stateChanges = card.stateChanges + 1
            card.stateId = id
            card.currentName = namesById[id] or card.currentName
            return card
        end
        function card.getName()
            return card.currentName
        end
        env.card = card

        env.containerTakeHandler = function(params)
            if params.name == "Story of Blood" then
                if params.spawnFunc then
                    params.spawnFunc(card)
                end
                return card
            end
            return nil
        end

        local spawnNames = {}
        local result = Archive.Take({
            archive = "Story of Blood Archive",
            name = "Story of Blood [1, 2x]",
            type = "Fighting Arts",
            position = { x = 1, y = 2, z = 3 },
            spawnFunc = function(obj)
                table.insert(spawnNames, obj.getName())
            end,
        })

        t:assertTrue(result ~= nil, "Archive.Take should return the requested card")
        local container = env.lastCreatedContainer
        local takeNames = {}
        for _, take in ipairs(container.takes) do
            table.insert(takeNames, take.name)
        end
        t:assertTrue(#container.takes >= 2, "Container should be attempted with the fallback name (attempts: "..table.concat(takeNames, ", ")..")")
        t:assertEqual("Story of Blood [1, 2x]", container.takes[1].name, "First attempt should use the requested name")
        local lastTake = container.takes[#container.takes]
        t:assertEqual("Story of Blood", lastTake.name, "Final successful attempt should use the stripped name")
        t:assertEqual("Story of Blood [1, 2x]", result.getName(), "Returned card should be on the requested state")
        t:assertEqual(1, #spawnNames, "Spawn callback should be invoked once")
        t:assertEqual("Story of Blood [1, 2x]", spawnNames[1], "Spawn callback should receive the fully-qualified state name")
        t:assertEqual(2, card.stateId, "Card should be switched to the requested state ID exactly once")
        t:assertEqual(1, card.stateChanges, "Card state should be applied only once")
    end)
end)

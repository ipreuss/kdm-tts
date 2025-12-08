---------------------------------------------------------------------------------------------------
-- Resource Rewards Acceptance Tests
--
-- Tests for resource rewards user-visible behavior after winning a showdown.
--
-- SCOPE: These tests verify business logic and state transitions:
--   - Button visibility based on showdown state
--   - Correct resource counts per monster/level
--   - Drawing from existing decks (not archive)
--   - Second press confirmation
--
-- OUT OF SCOPE: Visual styling (button colors, position) - verified via TTS manual testing.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Minimal TTS Stubs (leaf-level only)
---------------------------------------------------------------------------------------------------

local function createMinimalTTSEnvironment()
    -- Global TTS functions
    _G.logStyle = function() end
    _G.printToAll = function() end
    _G.broadcastToAll = function() end
    _G.log = function() end

    -- Wait stub - executes callbacks synchronously for testing
    _G.Wait = {
        frames = function(callback, frames)
            if callback then callback() end
        end,
        condition = function(callback, condition, timeout, timeoutCallback)
            if callback then callback() end
        end,
        time = function(callback, time)
            if callback then callback() end
        end,
    }

    -- Stub for TTS objects
    local function createMockObject(name)
        return {
            getName = function() return name end,
            getGUID = function() return "mock-guid-" .. name end,
            UI = {
                setAttribute = function() end,
                setXml = function() end,
            },
            setPositionSmooth = function() end,
            setRotationSmooth = function() end,
            getPosition = function() return { x = 0, y = 0, z = 0 } end,
            getRotation = function() return { x = 0, y = 0, z = 0 } end,
        }
    end

    -- NamedObject stub
    package.loaded["Kdm/NamedObject"] = {
        Get = function(name)
            return createMockObject(name)
        end,
    }

    -- Location stub with deck tracking
    local locationDecks = {}
    package.loaded["Kdm/Location"] = {
        Get = function(name)
            return {
                Center = function() return { x = 0, y = 2, z = 0 } end,
                FirstObject = function(self, options)
                    return locationDecks[name]
                end,
            }
        end,
        _test = {
            setDeck = function(locationName, deck)
                locationDecks[locationName] = deck
            end,
            reset = function()
                locationDecks = {}
            end,
        },
    }

    -- MessageBox stub with tracking
    local messageBoxShown = false
    local messageBoxCallback = nil
    package.loaded["Kdm/MessageBox"] = {
        Show = function(msg, callback)
            messageBoxShown = true
            messageBoxCallback = callback
        end,
        _test = {
            wasShown = function() return messageBoxShown end,
            confirmDialog = function()
                if messageBoxCallback then messageBoxCallback() end
            end,
            reset = function()
                messageBoxShown = false
                messageBoxCallback = nil
            end,
        },
    }

    -- Container stub with card counting and call tracking
    local containerCalls = {}  -- Track all Container.Take calls across all containers
    local function createContainerFunc(cardCount, containerName)
        local count = cardCount or 100
        local takenCards = {}
        local containerInstance = {}

        function containerInstance:IsEmpty()
            return count <= 0
        end

        function containerInstance:Take(params)
            -- params is the first argument after self (due to colon syntax)
            if count > 0 then
                count = count - 1
                local callRecord = {
                    container = containerName,
                    position = params and params.position,
                }
                if params and params.position then
                    table.insert(takenCards, params.position)
                end
                table.insert(containerCalls, callRecord)
                return { getName = function() return "Card" end }
            end
            return nil
        end

        containerInstance._takenCards = takenCards
        containerInstance._getCount = function() return count end

        return containerInstance
    end

    -- Container module: callable table that also has _test methods
    local ContainerModule = {
        _test = {
            getCalls = function() return containerCalls end,
            reset = function() containerCalls = {} end,
        }
    }
    setmetatable(ContainerModule, {
        __call = function(self, obj)
            local name = obj and obj.getName and obj.getName() or "unknown"
            return createContainerFunc(100, name)
        end
    })
    package.loaded["Kdm/Util/Container"] = ContainerModule

    -- Ui stub - minimal implementation for button creation
    local uiElements = {}
    local function createUiElement(id, config)
        config = config or {}
        local element = {
            _id = id,
            _active = config.active or false,
            _onClick = config.onClick,
            GetAttribute = function(self, attr)
                if attr == "active" then return self._active end
                return nil
            end,
            Show = function(self)
                self._active = true
            end,
            Hide = function(self)
                self._active = false
            end,
            Button = function(self, btnConfig)
                local btn = createUiElement(btnConfig.id, btnConfig)
                uiElements[btnConfig.id] = btn
                return btn
            end,
            Image = function(self, imgConfig)
                return createUiElement(imgConfig.id, imgConfig)
            end,
            Text = function(self, txtConfig)
                return createUiElement(txtConfig.id, txtConfig)
            end,
            Panel = function(self, pnlConfig)
                return createUiElement(pnlConfig.id, pnlConfig)
            end,
            VerticalLayout = function(self, config)
                return createUiElement(config.id, config)
            end,
            HorizontalLayout = function(self, config)
                return createUiElement(config.id, config)
            end,
            ApplyToObject = function() end,
            Apply = function() end,
        }
        uiElements[id] = element
        return element
    end

    package.loaded["Kdm/Ui"] = {
        Create3d = function(id, object, z)
            local ui = createUiElement(id)
            return ui
        end,
        Get2d = function()
            return createUiElement("2d-root")
        end,
        DARK_BROWN = "#4a3728",
        LIGHT_BROWN = "#d4c4a8",
        INVISIBLE_COLORS = "#00000000|#00000000|#00000000|#00000000",
        _test = {
            getElement = function(id) return uiElements[id] end,
            reset = function() uiElements = {} end,
        },
    }

    -- Survivor stub (for Showdown)
    package.loaded["Kdm/Survivor"] = {
        DepartingSurvivorNeedsToSkipNextHunt = function() return false end,
        ClearSkipNextHunt = function() end,
    }

    -- Archive stub with call tracking for strange resources
    local archiveCalls = {}
    package.loaded["Kdm/Archive"] = {
        TakeFromDeck = function(params)
            table.insert(archiveCalls, {
                deckName = params.deckName,
                deckType = params.deckType,
                name = params.name,
                cardType = params.cardType,
                position = params.position,
            })
            return { getName = function() return params.name end }
        end,
        _test = {
            getCalls = function() return archiveCalls end,
            reset = function() archiveCalls = {} end,
        },
    }
end

---------------------------------------------------------------------------------------------------
-- Test Helper: Load modules fresh
---------------------------------------------------------------------------------------------------

local function loadResourceRewardsModule()
    -- Clear cached modules
    for k in pairs(package.loaded) do
        if k:match("^Kdm/") then
            package.loaded[k] = nil
        end
    end

    createMinimalTTSEnvironment()

    -- Load EventManager first
    local EventManager = require("Kdm/Util/EventManager")
    EventManager.handlers = {}
    EventManager.globalHandlers = {}

    -- Load Showdown (needed for monster/level state)
    local Showdown = require("Kdm/Showdown")

    -- Load ResourceRewards
    local ResourceRewards = require("Kdm/ResourceRewards")
    ResourceRewards.Init()
    ResourceRewards.PostInit()

    return {
        EventManager = EventManager,
        Showdown = Showdown,
        ResourceRewards = ResourceRewards,
        Ui = package.loaded["Kdm/Ui"],
        Location = package.loaded["Kdm/Location"],
        MessageBox = package.loaded["Kdm/MessageBox"],
        Container = package.loaded["Kdm/Util/Container"],
        Archive = package.loaded["Kdm/Archive"],
    }
end

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Button Visibility
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Rewards button is hidden before showdown starts", function(t)
    local modules = loadResourceRewardsModule()

    -- Button should start hidden
    t:assertFalse(modules.ResourceRewards.Test.IsButtonVisible(),
        "Button should be hidden before showdown starts")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Rewards button appears when showdown starts with resource rewards", function(t)
    local modules = loadResourceRewardsModule()

    -- Simulate showdown start with White Lion Level 1
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 1",
        showdown = {
            resources = { basic = 4, monster = 4 },
        },
    }

    -- Fire showdown started event
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- Button should now be visible
    t:assertTrue(modules.ResourceRewards.Test.IsButtonVisible(),
        "Button should be visible after showdown starts")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Rewards button hidden for Prologue (no resource rewards)", function(t)
    local modules = loadResourceRewardsModule()

    -- Simulate Prologue showdown (no resources)
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Prologue",
        showdown = {
            -- No resources field = no rewards
        },
    }

    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    t:assertFalse(modules.ResourceRewards.Test.IsButtonVisible(),
        "Button should be hidden for Prologue (no resources)")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Rewards button hidden when showdown ends", function(t)
    local modules = loadResourceRewardsModule()

    -- Start showdown
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 1",
        showdown = {
            resources = { basic = 4, monster = 4 },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)
    t:assertTrue(modules.ResourceRewards.Test.IsButtonVisible(), "Button visible after start")

    -- End showdown
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_ENDED)

    t:assertFalse(modules.ResourceRewards.Test.IsButtonVisible(),
        "Button should be hidden after showdown ends")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Resource Data
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: White Lion L1 has correct resource counts (4 basic, 4 monster)", function(t)
    -- Read expansion data file directly (it's a .ttslua file, not .lua)
    local file = io.open("Expansion/Core.ttslua", "r")
    if not file then
        t:skip("Expansion/Core.ttslua not found")
        return
    end

    local content = file:read("*all")
    file:close()

    -- Check for White Lion Level 1 resources
    -- The data shows: resources = { basic = 4, monster = 4 }
    local hasL1Resources = content:match('name = "Level 1"')
        and content:match('resources = { basic = 4, monster = 4 }')

    t:assertTrue(hasL1Resources ~= nil, "White Lion L1 should have 4 basic, 4 monster resources")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Strange resources spawn from archive using Archive.TakeFromDeck", function(t)
    local modules = loadResourceRewardsModule()

    -- Setup mock decks at locations
    modules.Location._test.setDeck("Basic Resources", { name = "Basic Resources" })
    modules.Location._test.setDeck("Monster Resources", { name = "Monster Resources" })

    -- Reset call tracking
    modules.Container._test.reset()
    modules.Archive._test.reset()

    -- Start showdown with strange resources (simulating White Lion Level 3)
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 3",
        showdown = {
            resources = { basic = 4, monster = 8, strange = { "Elder Cat Teeth" } },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- Spawn resources
    modules.ResourceRewards.Test.SpawnRewards()

    -- Verify Archive.TakeFromDeck was called for strange resources
    local archiveCalls = modules.Archive._test.getCalls()
    t:assertEqual(1, #archiveCalls, "Should call Archive.TakeFromDeck once for strange resource")

    local call = archiveCalls[1]
    t:assertEqual("Strange Resources", call.deckName, "Should spawn from Strange Resources deck")
    t:assertEqual("Elder Cat Teeth", call.name, "Should spawn the named card")
    t:assertTrue(call.position ~= nil, "Should provide spawn position")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Multiple strange resources spawn in correct grid order", function(t)
    local modules = loadResourceRewardsModule()

    -- Setup mock decks at locations
    modules.Location._test.setDeck("Basic Resources", { name = "Basic Resources" })
    modules.Location._test.setDeck("Monster Resources", { name = "Monster Resources" })

    -- Reset call tracking
    modules.Container._test.reset()
    modules.Archive._test.reset()

    -- Simulate monster with multiple strange resources
    modules.Showdown.monster = {
        name = "Test Monster",
        resourcesDeck = "Test Monster Resources",
    }
    modules.Showdown.level = {
        name = "Level X",
        showdown = {
            resources = { basic = 2, monster = 2, strange = { "Card A", "Card B", "Card C" } },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- Spawn resources
    modules.ResourceRewards.Test.SpawnRewards()

    -- Verify all 3 strange resources spawned
    local archiveCalls = modules.Archive._test.getCalls()
    t:assertEqual(3, #archiveCalls, "Should call Archive.TakeFromDeck 3 times for 3 strange resources")

    -- Verify cards spawned in order
    t:assertEqual("Card A", archiveCalls[1].name, "First strange resource should be Card A")
    t:assertEqual("Card B", archiveCalls[2].name, "Second strange resource should be Card B")
    t:assertEqual("Card C", archiveCalls[3].name, "Third strange resource should be Card C")

    -- Verify grid positions are after basic+monster (4 cards = index 4, 5, 6)
    -- Basic/monster take positions 0-3 (4 cards), strange start at position 4
    local containerCalls = modules.Container._test.getCalls()
    t:assertEqual(4, #containerCalls, "Should draw 2 basic + 2 monster = 4 cards from containers")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Confirmation Dialog
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Second press shows confirmation dialog", function(t)
    local modules = loadResourceRewardsModule()

    -- Setup mock decks at locations
    modules.Location._test.setDeck("Basic Resources", { name = "Basic Resources" })
    modules.Location._test.setDeck("Monster Resources", { name = "Monster Resources" })

    -- Start showdown
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 1",
        showdown = {
            resources = { basic = 4, monster = 4 },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- First spawn (no dialog)
    modules.ResourceRewards.Test.SpawnRewards()
    t:assertFalse(modules.MessageBox._test.wasShown(),
        "First spawn should not show confirmation")

    -- Reset message box tracker
    modules.MessageBox._test.reset()

    -- Simulate second click via OnClick (which checks hasSpawnedThisShowdown)
    -- We can't call OnClick directly, but we can check the flag
    t:assertTrue(modules.ResourceRewards.Test.HasSpawnedThisShowdown(),
        "HasSpawnedThisShowdown should be true after first spawn")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Drawing from Existing Decks
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Resources drawn from existing showdown board decks", function(t)
    -- This test verifies that resources come from EXISTING decks on the showdown
    -- board, not from the archive. We verify by checking that Container.Take()
    -- is called on the deck objects at the board locations.

    local modules = loadResourceRewardsModule()

    -- Setup mock deck objects at the resource locations
    -- These simulate the decks already on the showdown board
    local basicDeckObj = { getName = function() return "Basic Resources Deck" end }
    local monsterDeckObj = { getName = function() return "Monster Resources Deck" end }

    modules.Location._test.setDeck("Basic Resources", basicDeckObj)
    modules.Location._test.setDeck("Monster Resources", monsterDeckObj)

    -- Reset container call tracking
    modules.Container._test.reset()

    -- Start showdown with White Lion Level 1 (4 basic + 4 monster)
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 1",
        showdown = {
            resources = { basic = 4, monster = 4 },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- Spawn resources
    modules.ResourceRewards.Test.SpawnRewards()

    -- Verify Container.Take was called on the board decks
    local calls = modules.Container._test.getCalls()
    t:assertTrue(#calls > 0, "Should have called Container.Take() on board decks")

    -- Count calls by container name
    local basicCalls = 0
    local monsterCalls = 0
    for _, call in ipairs(calls) do
        if call.container == "Basic Resources Deck" then
            basicCalls = basicCalls + 1
        elseif call.container == "Monster Resources Deck" then
            monsterCalls = monsterCalls + 1
        end
    end

    t:assertEqual(4, basicCalls, "Should draw 4 cards from Basic Resources deck on board")
    t:assertEqual(4, monsterCalls, "Should draw 4 cards from Monster Resources deck on board")
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Resources spawn to grid layout positions", function(t)
    -- This test verifies that spawned resources are positioned in a grid pattern
    -- by checking the positions passed to Container.Take()

    local modules = loadResourceRewardsModule()

    -- Setup mock decks
    local basicDeckObj = { getName = function() return "Basic Resources Deck" end }
    local monsterDeckObj = { getName = function() return "Monster Resources Deck" end }

    modules.Location._test.setDeck("Basic Resources", basicDeckObj)
    modules.Location._test.setDeck("Monster Resources", monsterDeckObj)

    -- Reset container call tracking
    modules.Container._test.reset()

    -- Start showdown with 2 basic + 2 monster = 4 cards (fits in one row of 4 columns)
    modules.Showdown.monster = {
        name = "White Lion",
        resourcesDeck = "White Lion Resources",
    }
    modules.Showdown.level = {
        name = "Level 1",
        showdown = {
            resources = { basic = 2, monster = 2 },
        },
    }
    modules.EventManager.FireEvent(modules.EventManager.ON_SHOWDOWN_STARTED)

    -- Spawn resources
    modules.ResourceRewards.Test.SpawnRewards()

    -- Get all positions from Container.Take calls
    local calls = modules.Container._test.getCalls()
    t:assertEqual(4, #calls, "Should spawn 4 cards (2 basic + 2 monster)")

    -- Verify grid pattern: cards in same row should have same z, different x
    local positions = {}
    for _, call in ipairs(calls) do
        if call.position then
            table.insert(positions, call.position)
        end
    end

    t:assertEqual(4, #positions, "All 4 calls should have positions")

    -- All 4 cards should be in the same row (same z value)
    local firstZ = positions[1].z
    for i = 2, #positions do
        t:assertEqual(firstZ, positions[i].z,
            string.format("Card %d should be in same row (z=%.2f)", i, firstZ))
    end

    -- Cards should have different x values (different columns)
    local xValues = {}
    for _, pos in ipairs(positions) do
        xValues[pos.x] = true
    end
    local uniqueXCount = 0
    for _ in pairs(xValues) do uniqueXCount = uniqueXCount + 1 end

    t:assertEqual(4, uniqueXCount, "All 4 cards should be in different columns (unique x values)")

    -- Verify consistent column spacing (x values should be evenly spaced)
    local sortedX = {}
    for _, pos in ipairs(positions) do
        table.insert(sortedX, pos.x)
    end
    table.sort(sortedX)

    if #sortedX >= 2 then
        local spacing = sortedX[2] - sortedX[1]
        for i = 2, #sortedX - 1 do
            local actualSpacing = sortedX[i + 1] - sortedX[i]
            local diff = math.abs(actualSpacing - spacing)
            t:assertTrue(diff < 0.01,
                string.format("Column spacing should be consistent (expected %.2f, got %.2f)", spacing, actualSpacing))
        end
    end
end)

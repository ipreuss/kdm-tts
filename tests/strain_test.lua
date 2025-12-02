local Test = require("tests.framework")
local ui_stubs = require("tests.stubs.ui_stubs")
local tts_objects = require("tests.stubs.tts_objects")

-- NOTE: True integration test for Strain→Archive moved to strain_archive_integration_test.lua
-- That test exercises real Archive code; this file now only tests Strain-specific logic.

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

local function buildStrainStubs()
    local recorder = {
        rows = {},
        rootChildren = {},
    }

    local rootPanel = { children = recorder.rootChildren }
    function rootPanel:Panel(params)
        local child = { attributes = params }
        table.insert(self.children, child)
        return child
    end
    function rootPanel:Button(_) end
    function rootPanel:Text(_) end
    function rootPanel:SetHeight(height) self.height = height end

    local listPanel = ui_stubs.listPanel(recorder)
    local scrollArea = {
        Panel = function() return listPanel end,
        SetContentHeight = function(_, height)
            recorder.scrollContentHeight = height
        end,
    }

    local dialog = ui_stubs.dialog()
    dialog.Panel = function() return rootPanel end  -- Override to use custom rootPanel
    local dialogStats = dialog.stats

    local confirmDialog = ui_stubs.dialog()
    local uncheckDialog = ui_stubs.dialog()

    local panelKitStub = {}

    function panelKitStub.Dialog(params)
        if params.id == "StrainMilestoneConfirmation" then
            return confirmDialog
        end
        if params.id == "StrainMilestoneUncheck" then
            return uncheckDialog
        end
        return dialog
    end

    function panelKitStub.ClassicDialog(args)
        recorder.legacyArgs = args
        return {
            contentX = 10,
            contentY = -30,
            contentWidth = 300,
            contentHeight = 210,
            elements = {
                titleText = { SetText = function() end },
                subtitleText = { SetText = function() end },
            },
        }
    end

    function panelKitStub.ScrollArea(args)
        recorder.scrollArgs = args
        return scrollArea
    end

    function panelKitStub.VerticalLayout(params)
        return {
            AddTitle = function() return { SetText = function() end } end,
            AddSection = function()
                local content = { text = nil }
                function content:SetText(value) content.text = value end
                local label = { text = nil }
                function label:SetText(value) label.text = value end
                return { content = content, label = label }
            end,
            AddSpacer = function() end,
            AddButtonRow = function() return {} end,
            AddCustom = function()
                return { SetText = function() end }
            end,
            GetUsedHeight = function() return 300 end,
            AutoSize = function() return 400 end,
        }
    end

    function panelKitStub.CalculateVerticalLayoutHeight()
        return 450
    end

    function panelKitStub.AutoSizedDialog(params)
        local mockLayout = {
            AddTitle = function() return { SetText = function() end } end,
            AddSection = function()
                local content = { text = nil }
                function content:SetText(value) content.text = value end
                local label = { text = nil }
                function label:SetText(value) label.text = value end
                return { content = content, label = label }
            end,
            AddSpacer = function() end,
            AddButtonRow = function() return {} end,
        }
        local contentRefs = params.buildContent(mockLayout)
        return {
            dialog = confirmDialog,
            panel = { Text = function() return { SetText = function() end } end, Button = function() end },
            contentRefs = contentRefs,
        }
    end

    function panelKitStub.DialogFromSpec(params)
        local dialog = panelKitStub.Dialog({
            id = params.id,
            width = params.width,
            height = (params.layout and params.layout.minHeight) or 300,
            closeButton = params.dialog and params.dialog.closeButton,
            modal = params.dialog and params.dialog.modal,
        })
        local panel = dialog:Panel()
        local chrome = panelKitStub.ClassicDialog({
            panel = panel,
            id = params.chrome and params.chrome.id or params.id,
            width = params.width,
            height = (params.layout and params.layout.minHeight) or 300,
        })
        local layout = panelKitStub.VerticalLayout({
            parent = panel,
            contentArea = chrome,
            padding = (params.layout and params.layout.padding) or 12,
            spacing = (params.layout and params.layout.spacing) or 10,
        })
        if params.spec and params.spec.Render then
            params.spec:Render(layout)
        end
        return {
            dialog = dialog,
            panel = panel,
            chrome = chrome,
            layout = layout,
            height = (params.layout and params.layout.minHeight) or 300,
            contentHeight = 200,
        }
    end

    local logStub = { Debugf = function() end, Errorf = function() end, Printf = function() end }
    local archiveStub = {
        calls = {},
        cleanCount = 0,
    }
    
    -- Default Strain Rewards deck stub (essential resource, must exist)
    -- Will be populated with milestone fighting arts when stubs are created
    local defaultDeckObjects = {}
    local defaultStrainDeck = {
        __objects = defaultDeckObjects,  -- For Container stub's Objects() method
        getName = function() return "Strain Rewards" end,
        getGUID = function() return "default-strain-deck" end,
        getObjects = function() return defaultDeckObjects end,
        destruct = function() end,
    }
    
    -- Set __takeHandler for Container stub compatibility
    defaultStrainDeck.__takeHandler = function(_, params)
        -- Find card by name/type
        if params and params.name then
            for _, obj in ipairs(defaultDeckObjects) do
                if obj.name == params.name and (not params.type or obj.gm_notes == params.type) then
                    local card = {
                        name = obj.name,
                        gm_notes = obj.gm_notes,
                        getName = function() return obj.name end,
                    }
                    if params.spawnFunc then
                        params.spawnFunc(card)
                    end
                    return card
                end
            end
        end
        return nil
    end
    
    function archiveStub.Take(params)
        table.insert(archiveStub.calls, params)
        if archiveStub.takeHandler then
            return archiveStub.takeHandler(params)
        end
        -- Return default Strain Rewards deck for essential resources
        if params.name == "Strain Rewards" then
            return defaultStrainDeck
        end
        return nil
    end
    function archiveStub.Clean()
        archiveStub.cleanCount = archiveStub.cleanCount + 1
    end
    function archiveStub.TakeFromDeck(params)
        -- Simplified implementation that delegates to Take and Container stubs
        local ObjectState = require("Kdm/Util/ObjectState")
        
        -- Take deck from archive
        local deck = archiveStub.Take({
            name = params.deckName,
            type = params.deckType,
            position = params.deckStagingPosition or { x = 0, y = 10, z = 0 },
            rotation = { x = 0, y = 180, z = 180 },
            lenient = true,
        })
        assert(deck, string.format("Deck '%s' not found in archive - check mod setup", params.deckName))
        
        -- Create container
        local containerStub = require("Kdm/Util/Container")
        local deckContainer = containerStub(deck)
        
        -- Try to take card
        local function takeCardCandidate(targetName, desiredStateName)
            local object = deckContainer:Take({
                name = targetName,
                type = params.cardType,
                position = params.position,
                rotation = params.rotation,
            })
            if not object then
                return nil
            end
            if desiredStateName then
                object = ObjectState.ApplyStateByName(object, desiredStateName)
            end
            if params.spawnFunc then
                params.spawnFunc(object)
            end
            return object
        end
        
        -- First attempt
        local card = takeCardCandidate(params.name)
        
        -- Fallback
        if not card then
            local strippedName = ObjectState.StripTrailingBracketSuffix(params.name)
            if strippedName ~= params.name then
                card = takeCardCandidate(strippedName, params.name)
            end
        end
        
        -- Cleanup
        deck.destruct()
        archiveStub.Clean()
        
        assert(card, "Card not found: " .. params.name)
    end
    local locationStub = {
        Get = function()
            return {
                FirstObject = function() return nil end,
                Center = function() return { x = 0, y = 0, z = 0 } end,
            }
        end,
    }
    local containers = {}
    local function containerStub(object)
        local stub = {
            object = object,
            takes = {},
            destroyed = false,
        }
        function stub:Objects()
            if self.object and self.object.__objects then
                return self.object.__objects
            end
            return {}
        end
        function stub:Delete() end
        function stub:Take(params)
            table.insert(self.takes, params)
            if self.object then
                if self.object.__card then
                    if params.spawnFunc then
                        params.spawnFunc(self.object.__card)
                    end
                    return self.object.__card
                end
                if self.object.__takeHandler then
                    return self.object.__takeHandler(params)
                end
            end
            return nil
        end
        function stub:Destruct()
            self.destroyed = true
            if self.object then
                self.object.__destroyed = true
            end
        end
        table.insert(containers, stub)
        return stub
    end

    local namedObjectStub = {
        Get = function()
            return {
                takeObject = function()
                    local deck = {}
                    function deck:getName() return "Stub Deck" end
                    function deck:getGUID() return "stub-guid" end
                    function deck:getPosition() return { x = 0, y = 0, z = 0 } end
                    function deck:putObject() end
                    function deck:getObjects() return deck.__objects or {} end
                    function deck:takeObject(params)
                        if deck.__objects and params and params.index then
                            deck.__objects[params.index] = nil
                        end
                        return {
                            destruct = function() end,
                        }
                    end
                    deck.__objects = {
                        { name = "Test Art", gm_notes = "Fighting Arts", index = 1 },
                    }
                    return deck
                end,
                putObject = function() end,
                reset = function() end,
                getName = function() return "Stub Archive" end,
                getGUID = function() return "archive-guid" end,
            }
        end,
    }

    local deckStub = {
        ResetDeck = function() end,
    }

    local consoleStub = {}
    consoleStub.commands = {}
    function consoleStub.AddCommand(name, func, desc)
        consoleStub.commands[name] = { func = func, desc = desc }
    end

    local stubs = {
        ["Kdm/Ui/PanelKit"] = panelKitStub,
        ["Kdm/Ui"] = {
            Get2d = function() return {} end,
            DARK_BROWN = "#111111",
            MID_BROWN = "#999999",
        },
        ["Kdm/Log"] = { ForModule = function() return logStub end },
        ["Kdm/GameData/StrainMilestones"] = {
            {
                title = "Milestone A",
                condition = "Condition A",
                flavorText = "Flavor A",
                rulesText = "Rules A",
                consequences = { fightingArt = "Test Art" },
            },
            {
                title = "Milestone B",
                condition = "Condition B",
                flavorText = "Flavor B",
                rulesText = "Rules B",
            },
        },
        ["Kdm/Archive"] = archiveStub,
        ["Kdm/Location"] = locationStub,
        ["Kdm/Util/Container"] = containerStub,
        ["Kdm/NamedObject"] = namedObjectStub,
        ["Kdm/Deck"] = deckStub,
        ["Kdm/Console"] = consoleStub,
        ["Kdm/VerminArchive"] = {},
        ["Kdm/Timeline"] = {},
    }
    
    -- Populate default Strain Rewards deck with milestone fighting arts
    for i, milestone in ipairs(stubs["Kdm/GameData/StrainMilestones"]) do
        if milestone.consequences and milestone.consequences.fightingArt then
            table.insert(defaultDeckObjects, {
                name = milestone.consequences.fightingArt,
                gm_notes = "Fighting Arts",
                index = i,
            })
        end
    end

    local verminStub = {
        added = {},
        removed = {},
    }
    function verminStub.AddCard(name)
        table.insert(verminStub.added, name)
        return true
    end
    function verminStub.RemoveCard(name)
        table.insert(verminStub.removed, name)
        return true
    end
    stubs["Kdm/VerminArchive"] = verminStub

    local timelineStub = {
        scheduled = {},
        removed = {},
    }
    function timelineStub.ScheduleEvent(spec)
        table.insert(timelineStub.scheduled, spec)
        return true
    end
    function timelineStub.RemoveEventByName(name, eventType)
        table.insert(timelineStub.removed, { name = name, type = eventType })
        return true
    end
    stubs["Kdm/Timeline"] = timelineStub

    return stubs, {
        recorder = recorder,
        dialogStats = dialogStats,
        listPanel = listPanel,
        archiveStub = archiveStub,
        containers = containers,
        namedObjectStub = namedObjectStub,
        deckStub = deckStub,
        verminStub = verminStub,
        timelineStub = timelineStub,
    }
end

local function getInternalStrain(StrainModule)
    local i = 1
    while true do
        local name, value = debug.getupvalue(StrainModule.Init, i)
        if not name then break end
        if name == "Strain" then
            return value
        end
        i = i + 1
    end
end

local function withStrain(t, callback, options)
    local stubs, env = buildStrainStubs()
    if options and options.customizeStubs then
        options.customizeStubs(stubs, env)
    end
    withStubs(stubs, function()
        package.loaded["Kdm/FightingArtsArchive"] = nil
        local FightingArtsArchiveModule = require("Kdm/FightingArtsArchive")
        package.loaded["Kdm/Strain"] = nil
        local StrainModule = require("Kdm/Strain")
        local strainTable = getInternalStrain(StrainModule)
        t:assertTrue(strainTable ~= nil, "found internal Strain table")
        env.fightingArtsArchive = FightingArtsArchiveModule
        callback(StrainModule, strainTable, env)
    end)
end

local function createArchiveForDeck(stubs, faDeck)
    local archiveObject = {
        takeCalls = {},
        putCalls = {},
        resetCount = 0,
    }
    archiveObject.takeObject = function(params)
        table.insert(archiveObject.takeCalls, params)
        return faDeck
    end
    archiveObject.putObject = function(obj)
        table.insert(archiveObject.putCalls, obj)
    end
    archiveObject.reset = function()
        archiveObject.resetCount = archiveObject.resetCount + 1
    end
    archiveObject.getName = function()
        return "Stub Fighting Arts Archive"
    end
    archiveObject.getGUID = function()
        return "stub-archive-guid"
    end
    stubs["Kdm/NamedObject"] = {
        Get = function()
            return archiveObject
        end,
    }
    return archiveObject
end

local function setupAddToArchiveScenario(stubs, env, options)
    options = options or {}
    local includeRewardCard = options.includeRewardCard ~= false
    local cardName = options.cardName or "Test Art"

    local faDeck = tts_objects.deck({ name = "Fighting Arts Deck" })
    local archiveObject = createArchiveForDeck(stubs, faDeck)

    local cardNames = includeRewardCard and { cardName, "Other Card" } or { "Other Card" }
    local strainDeck = tts_objects.deckWithCards(cardNames, {
        deckName = "Strain Rewards",
        gm_notes = "Fighting Arts",
        takeHandler = includeRewardCard and function(params)
            return { name = cardName, gm_notes = "Fighting Arts" }
        end or function() return nil end,
    })

    env.archiveStub.takeHandler = function(params)
        if params.name == "Strain Rewards" then
            return strainDeck
        end
        return nil
    end

    local deckResets = {}
    env.deckStub.ResetDeck = function(location)
        table.insert(deckResets, location)
    end

    env.acceptance = {
        archiveStub = env.archiveStub,
        faDeck = faDeck,
        archive = archiveObject,
        strainDeck = strainDeck,
        deckResets = deckResets,
        cardName = cardName,
    }
end

local function setupRemovalScenario(stubs, env, options)
    options = options or {}
    local includeRewardCard = options.includeRewardCard ~= false
    local cardName = options.cardName or "Test Art"

    local removedCard = { destroyed = false }
    local cardNames = includeRewardCard and { cardName, "Other Card" } or { "Other Card" }
    local faDeck = tts_objects.deckWithCards(cardNames, {
        deckName = "Stub Fighting Arts Deck",
        gm_notes = "Fighting Arts",
        takeHandler = includeRewardCard and function(params)
            return {
                destruct = function()
                    removedCard.destroyed = true
                end,
            }
        end or function() return nil end,
    })
    faDeck.takeCalls = {}

    local deckResets = {}
    env.deckStub.ResetDeck = function(location)
        table.insert(deckResets, location)
    end

    local archiveObject = createArchiveForDeck(stubs, faDeck)
    env.acceptance = {
        archiveStub = env.archiveStub,
        archive = archiveObject,
        faDeck = faDeck,
        deckResets = deckResets,
        removedCard = removedCard,
        cardName = cardName,
    }
end

local function setupRewardDeckFallback(stubs, env)
    local takes = {}
    local strainDeck = tts_objects.deckWithCards({ "Story of Blood" }, {
        deckName = "Strain Rewards",
        gm_notes = "Fighting Arts",
        takeHandler = function(params)
            table.insert(takes, params)
            if params.name ~= "Story of Blood" then
                return nil
            end
            return tts_objects.card({
                name = "Story of Blood",
                gm_notes = "Fighting Arts",
                currentState = 1,
                states = {
                    { id = 1, name = "Story of Blood" },
                    { id = 2, name = "Story of Blood [1, 2x]" },
                },
                onStateChange = function(stateId)
                    -- Card name changes with state
                end,
            })
        end,
    })
    strainDeck.getGUID = function() return "strain-rewards" end
    strainDeck.takes = takes

    env.archiveStub.takeHandler = function(params)
        if params.name == "Strain Rewards" then
            return strainDeck
        end
        return nil
    end
end

Test.test("Strain.Init clones milestones and builds UI rows", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        t:assertEqual(#strain.MILESTONE_CARDS, #strain.milestones)
        for i, milestone in ipairs(strain.milestones) do
            t:assertTrue(milestone ~= strain.MILESTONE_CARDS[i])
            t:assertEqual(strain.MILESTONE_CARDS[i].title, milestone.title)
            t:assertFalse(milestone.reached)
        end

        t:assertEqual(#strain.milestones, #env.recorder.rows)
        local expectedHeight = (#strain.milestones * strain.ROW_HEIGHT)
            + math.max(#strain.milestones - 1, 0) * strain.ROW_GAP
        t:assertEqual(expectedHeight, env.listPanel.height)
        t:assertEqual(expectedHeight, env.recorder.scrollContentHeight)
    end)
end)

Test.test("ToggleMilestone unchecks already reached milestones", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        -- Mark milestone as already reached
        strain.milestones[1].reached = true
        strain.milestoneRows[1].checkBox:Check(true)

        -- Toggle should prompt first
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        t:assertEqual(1, strain.pendingMilestoneIndex)
        t:assertTrue(strain.milestones[1].reached, "Milestone should stay reached until confirmed")

        -- Confirm removal
        strain:ConfirmUncheckMilestone(player)

        t:assertFalse(strain.milestones[1].reached)
        t:assertFalse(env.recorder.rows[1].checkBox.checked)
    end)
end)

Test.test("ShowUi/HideUi delegate to dialog for players", function(t)
    withStrain(t, function(StrainModule, _, env)
        StrainModule.Init()

        local player = { color = "White", steam_name = "Tester" }
        StrainModule.ShowUi(player)
        StrainModule.HideUi(player)

        t:assertEqual(1, env.dialogStats.show)
        t:assertEqual(1, env.dialogStats.hide)
    end)
end)

Test.test("Milestones have flavor and rules text", function(t)
    withStrain(t, function(StrainModule, strain)
        StrainModule.Init()

        for _, milestone in ipairs(strain.milestones) do
            t:assertNotNil(milestone.flavorText, "Milestone should have flavor text")
            t:assertNotNil(milestone.rulesText, "Milestone should have rules text")
            t:assertType(milestone.flavorText, "string", "Flavor text should be string")
            t:assertType(milestone.rulesText, "string", "Rules text should be string")
        end
    end)
end)

Test.test("Strain milestone data includes fighting art consequences", function(t)
    local milestones = require("Kdm/GameData/StrainMilestones")
    local expected = {
        ["Ethereal Culture Strain"] = "Ethereal Pact",
        ["Giant's Strain"] = "Giant's Blood",
        ["Opportunist Strain"] = "Backstabber",
        ["Trepanning Strain"] = "Infinite Lives",
        ["Hyper Cerebellum"] = "Shielderang",
        ["Marrow Transformation"] = "Rolling Gait",
        ["Memetic Symphony"] = "Infernal Rhythm",
        ["Surgical Sight"] = "Convalescer",
        ["Ashen Claw Strain"] = "Armored Fist",
        ["Carnage Worms"] = "Dark Manifestation",
        ["Material Feedback Strain"] = "Stockist",
        ["Sweat Stained Oath"] = "Sword Oath",
        ["Plot Twist"] = "Story of Blood",
    }

    local byTitle = {}
    for _, milestone in ipairs(milestones) do
        byTitle[milestone.title] = milestone
    end

    for title, fightingArt in pairs(expected) do
        local entry = byTitle[title]
        t:assertNotNil(entry, string.format("Missing milestone data for %s", title))
        local actual = entry.consequences and entry.consequences.fightingArt
        t:assertEqual(fightingArt, actual, string.format("Expected %s to unlock %s", title, fightingArt))
    end
end)

Test.test("_TakeRewardCard prefers the Strain Rewards deck when available", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        local deckObject = {
            __card = { name = "Test Reward", gm_notes = StrainModule.Strain and StrainModule.Strain.FIGHTING_ART_TYPE or "Fighting Arts" },
            getName = function() return "Strain Rewards" end,
            getGUID = function() return "strain-deck" end,
            getObjects = function()
                return {
                    { name = "Test Reward", gm_notes = "Fighting Arts", index = 1 },
                }
            end,
            takeObject = function(_, params)
                local card = {
                    name = "Test Reward",
                    gm_notes = "Fighting Arts",
                }
                if params and params.spawnFunc then
                    params.spawnFunc(card)
                end
                return card
            end,
            destruct = function() end,
        }
        env.archiveStub.takeHandler = function(params)
            if params.name == strain.REWARD_DECK_NAME then
                return deckObject
            end
            t:fail("Fallback archive should not be used when Strain deck succeeds")
        end

        strain:_TakeRewardCard({
            name = "Test Reward",
            type = strain.FIGHTING_ART_TYPE,
            position = { x = 1, y = 2, z = 3 },
        })

        -- If we get here, it succeeded (would have asserted otherwise)
        t:assertEqual(1, #env.archiveStub.calls, "Archive should be queried once for the deck")
        t:assertEqual(strain.REWARD_DECK_NAME, env.archiveStub.calls[1].name)
        t:assertEqual(1, #env.containers, "Deck container should be created")
        t:assertEqual(1, #env.containers[1].takes, "Card should be taken from the deck container")
        local takeParams = env.containers[1].takes[1]
        t:assertEqual(1, takeParams.position.x)
        t:assertEqual(2, takeParams.position.y)
        t:assertEqual(3, takeParams.position.z)
    end)
end)

Test.test("_TakeRewardCard fails fast when the Strain Rewards deck is unavailable", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        local callCount = 0
        env.archiveStub.takeHandler = function(params)
            callCount = callCount + 1
            t:assertEqual(1, callCount, "Archive.Take should be invoked exactly once (for the rewards deck)")
            t:assertEqual(strain.REWARD_DECK_NAME, params.name)
            return nil
        end

        local ok, err = pcall(function()
            strain:_TakeRewardCard({
                name = "Fallback Reward",
                type = strain.FIGHTING_ART_TYPE,
                position = { x = 0, y = 0, z = 0 },
            })
        end)

        t:assertFalse(ok, "Missing Strain rewards deck should trigger assertion")
        t:assertMatch(err, "mod setup", "Error should indicate mod setup problem")
        t:assertEqual(1, #env.archiveStub.calls, "Archive.Take should only be invoked for the Strain rewards deck")
    end)
end)

Test.test("AddFightingArtToArchive transfers reward card into the fighting arts deck", function(t)
    withStrain(t, function(_, strain, env)
        local archiveModule = env.fightingArtsArchive
        local ok = archiveModule.AddCard(env.acceptance.cardName)

        t:assertTrue(ok, "Expected AddFightingArtToArchive to succeed when card exists")
        t:assertEqual(1, #env.acceptance.faDeck.insertedCards, "Reward card should be inserted into the fighting arts deck")
        t:assertEqual(env.acceptance.cardName, env.acceptance.faDeck.insertedCards[1].name)
        t:assertEqual(1, env.acceptance.archive.resetCount, "Archive reset should run after successful transfer")
        t:assertTrue(env.acceptance.strainDeck.destroyed, "Strain rewards deck should be destroyed after transfer")
        t:assertEqual(1, #env.acceptance.deckResets, "Deck.ResetDeck should run once for fighting arts location")
        t:assertEqual(strain.FIGHTING_ART_LOCATION, env.acceptance.deckResets[1])
        t:assertEqual(1, env.acceptance.archiveStub.cleanCount, "Archive.Clean should run after successful transfer")
    end, {
        customizeStubs = function(stubs, env)
            setupAddToArchiveScenario(stubs, env, {})
        end
    })
end)

Test.test("AddFightingArtToArchive returns false when the reward card is missing", function(t)
    withStrain(t, function(_, _, env)
        local archiveModule = env.fightingArtsArchive
        local ok = archiveModule.AddCard("Missing Reward")

        t:assertFalse(ok, "Expected AddFightingArtToArchive to fail when card is absent")
        t:assertEqual(0, #env.acceptance.faDeck.insertedCards, "No cards should be inserted when transfer fails")
        t:assertEqual(0, env.acceptance.archive.resetCount, "Archive reset should not run on failure")
        t:assertTrue(env.acceptance.strainDeck.destroyed, "Strain rewards deck should be destroyed after attempting transfer")
        t:assertEqual(0, #env.acceptance.deckResets, "Deck.ResetDeck should not run on failure")
        t:assertEqual(0, env.acceptance.archiveStub.cleanCount, "Archive.Clean should not run on failure")
    end, {
        customizeStubs = function(stubs, env)
            setupAddToArchiveScenario(stubs, env, { includeRewardCard = false })
        end
    })
end)

Test.test("RemoveFightingArtFromArchive deletes the card from the fighting arts deck", function(t)
    withStrain(t, function(_, strain, env)
        local archiveModule = env.fightingArtsArchive
        local ok = archiveModule.RemoveCard(env.acceptance.cardName)

        t:assertTrue(ok, "Expected removal to succeed when card exists")
        t:assertNotNil(env.acceptance.faDeck.lastTakeParams, "Deck should be asked to remove the matching card index")
        t:assertTrue(env.acceptance.removedCard.destroyed, "Removed card should be destroyed after extraction")
        t:assertEqual(1, env.acceptance.archive.resetCount, "Archive reset should run after successful removal")
        t:assertEqual(1, #env.acceptance.deckResets, "Deck.ResetDeck should run once")
        t:assertEqual(strain.FIGHTING_ART_LOCATION, env.acceptance.deckResets[1])
        t:assertEqual(1, env.acceptance.archiveStub.cleanCount, "Archive.Clean should run after removal")
    end, {
        customizeStubs = function(stubs, env)
            setupRemovalScenario(stubs, env, {})
        end
    })
end)

Test.test("_TakeRewardCard strips bracketed state names", function(t)
    withStrain(t, function(StrainModule, strain)
        local spawnedNames = {}
        strain:_TakeRewardCard({
            name = "Story of Blood [1, 2x]",
            type = StrainModule.FIGHTING_ART_TYPE,
            position = { x = 1, y = 2, z = 3 },
            rotation = { x = 0, y = 180, z = 0 },
            spawnFunc = function(card)
                table.insert(spawnedNames, card:getName())
            end,
        })

        -- If we get here, it succeeded (would have asserted otherwise)
        t:assertEqual(1, #spawnedNames, "Spawn callback should run once")
        t:assertEqual("Story of Blood [1, 2x]", spawnedNames[1], "Card should retain requested state name")
    end, {
        customizeStubs = function(stubs, env)
            setupRewardDeckFallback(stubs, env)
        end
    })
end)

Test.test("RemoveFightingArtFromArchive returns false when the card is absent", function(t)
    withStrain(t, function(_, strain, env)
        local archiveModule = env.fightingArtsArchive
        local ok = archiveModule.RemoveCard("Missing Reward")

        t:assertFalse(ok, "Expected removal to fail when card is not present")
        t:assertNil(env.acceptance.faDeck.lastTakeParams, "Deck should not be asked to remove anything when card missing")
        t:assertFalse(env.acceptance.removedCard.destroyed, "No card should be destroyed when nothing was removed")
        t:assertEqual(0, env.acceptance.archive.resetCount, "Archive reset should not run on failure")
        t:assertEqual(0, #env.acceptance.deckResets, "Deck.ResetDeck should not run on failure")
        t:assertEqual(0, env.acceptance.archiveStub.cleanCount, "Archive.Clean should not run on failure")
    end, {
        customizeStubs = function(stubs, env)
            setupRemovalScenario(stubs, env, { includeRewardCard = false })
        end
    })
end)

Test.test("ToggleMilestone shows confirmation dialog before checking", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        -- Try to check an unchecked milestone - this should show confirmation dialog
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        
        -- The milestone should NOT be checked yet (waiting for confirmation)
        t:assertFalse(strain.milestones[1].reached, "Milestone should not be reached until confirmed")
        
        -- Should have stored the pending milestone info
        t:assertEqual(1, strain.pendingMilestoneIndex)
    end)
end)

Test.test("ExecuteConsequences applies fighting art rewards", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        local added, spawned
        local archiveModule = env.fightingArtsArchive
        local originalAdd = archiveModule.AddCard
        local originalSpawn = strain.SpawnFightingArtForSurvivor
        archiveModule.AddCard = function(name)
            added = name
            return true
        end
        strain.SpawnFightingArtForSurvivor = function(_, name)
            spawned = name
        end

        strain:ExecuteConsequences({ consequences = { fightingArt = "Test Art" } })

        archiveModule.AddCard = originalAdd
        strain.SpawnFightingArtForSurvivor = originalSpawn

        t:assertEqual("Test Art", added, "ExecuteConsequences should add fighting art to deck")
        t:assertEqual("Test Art", spawned, "ExecuteConsequences should spawn card for survivor")
    end)
end)

Test.test("ReverseConsequences removes fighting art rewards", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        local removed
        local archiveModule = env.fightingArtsArchive
        local originalRemove = archiveModule.RemoveCard
        archiveModule.RemoveCard = function(name)
            removed = name
            return true
        end

        strain:ReverseConsequences({ consequences = { fightingArt = "Test Art" } })

        archiveModule.RemoveCard = originalRemove

        t:assertEqual("Test Art", removed, "ReverseConsequences should remove fighting art from deck")
    end)
end)

Test.test("ExecuteConsequences applies vermin rewards", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        strain:ExecuteConsequences({ consequences = { vermin = "Fiddler Crab Spider" } })

        t:assertEqual(1, #env.verminStub.added)
        t:assertEqual("Fiddler Crab Spider", env.verminStub.added[1])
    end)
end)

Test.test("ReverseConsequences removes vermin rewards", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        strain:ReverseConsequences({ consequences = { vermin = "Fiddler Crab Spider" } })

        t:assertEqual(1, #env.verminStub.removed)
        t:assertEqual("Fiddler Crab Spider", env.verminStub.removed[1])
    end)
end)

Test.test("ExecuteConsequences schedules timeline events", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        local spec = { name = "Acid Storm", type = "SettlementEvent", offset = 1 }
        strain:ExecuteConsequences({ consequences = { timelineEvent = spec } })

        t:assertEqual(1, #env.timelineStub.scheduled)
        t:assertEqual("Acid Storm", env.timelineStub.scheduled[1].name)
        t:assertEqual("SettlementEvent", env.timelineStub.scheduled[1].type)
        t:assertEqual(1, env.timelineStub.scheduled[1].offset)
    end)
end)

Test.test("ReverseConsequences removes scheduled timeline events", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        local spec = { name = "Acid Storm", type = "SettlementEvent" }
        strain:ReverseConsequences({ consequences = { timelineEvent = spec } })

        t:assertEqual(1, #env.timelineStub.removed)
        t:assertEqual("Acid Storm", env.timelineStub.removed[1].name)
        t:assertEqual("SettlementEvent", env.timelineStub.removed[1].type)
    end)
end)

Test.test("ConfirmMilestone checks the pending milestone", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        -- Stub out consequence execution so we don't need full archive setup
        local originalExecute = strain.ExecuteConsequences
        strain.ExecuteConsequences = function() end
        
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        
        -- Confirm the milestone
        strain:ConfirmMilestone(player)
        
        -- Restore
        strain.ExecuteConsequences = originalExecute
        
        -- Now it should be checked
        t:assertTrue(strain.milestones[1].reached, "Milestone should be reached after confirmation")
        t:assertTrue(env.recorder.rows[1].checkBox.checked, "Checkbox should be checked after confirmation")
        
        -- Pending info should be cleared
        t:assertNil(strain.pendingMilestoneIndex)
    end)
end)

Test.test("CancelMilestone keeps milestone unchecked", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        
        -- Cancel the milestone
        strain:CancelMilestone(player)
        
        -- Should remain unchecked
        t:assertFalse(strain.milestones[1].reached, "Milestone should remain unchecked after cancel")
        t:assertFalse(env.recorder.rows[1].checkBox.checked, "Checkbox should remain unchecked after cancel")
        
        -- Pending info should be cleared
        t:assertEqual(nil, strain.pendingMilestoneIndex)
    end)
end)

Test.test("Strain.Init restores reached milestones from saved state", function(t)
    withStrain(t, function(StrainModule, strain, env)
        local saveState = {
            reached = {
                ["Milestone B"] = true,
            }
        }
        StrainModule.Init(saveState)

        t:assertFalse(strain.milestones[1].reached, "first milestone should start unchecked")
        t:assertTrue(strain.milestones[2].reached, "saved milestone should be checked")
        t:assertTrue(env.recorder.rows[2].checkBox.checked, "checkbox should reflect saved state")
    end)
end)

Test.test("Strain.LoadState updates rows after initialization", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()

        StrainModule.LoadState({
            reached = {
                ["Milestone B"] = true,
            }
        })

        t:assertFalse(strain.milestones[1].reached)
        t:assertTrue(strain.milestones[2].reached)
        t:assertTrue(env.recorder.rows[2].checkBox.checked, "checkbox should update when load state changes")
    end)
end)

Test.test("Strain.Save serializes reached milestones for export/import", function(t)
    withStrain(t, function(StrainModule, strain)
        StrainModule.Init()

        strain.milestones[1].reached = true
        local saveState = StrainModule.Save()

        t:assertTrue(saveState.reached["Milestone A"], "reached milestone should be recorded")
        t:assertNil(saveState.reached["Milestone B"], "unreached milestones should not be persisted")
    end)
end)

Test.test("ShowConfirmationDialog displays manual steps", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        local milestone = {
            title = "Test Milestone",
            flavorText = "Test flavor",
            rulesText = "Test rules",
            consequences = {
                manual = {
                    "Do this thing manually",
                    "Do this other thing"
                }
            }
        }
        
        strain:ShowConfirmationDialog(milestone)
        
        t:assertNotNil(strain.confirmationManualText, "Manual text element should exist")
        t:assertNotNil(strain.confirmationManualText.text, "Manual text should have been set")
        local manualText = strain.confirmationManualText.text
        t:assertMatch(manualText, "Do this thing manually", "Should display first manual step")
        t:assertMatch(manualText, "Do this other thing", "Should display second manual step")
        t:assertMatch(manualText, "•", "Should have bullet points")
    end)
end)

Test.test("ShowConfirmationDialog displays (None) when no manual steps", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        local milestone = {
            title = "Test Milestone",
            flavorText = "Test flavor",
            rulesText = "Test rules",
            consequences = {
                fightingArt = "Test Art"
            }
        }
        
        strain:ShowConfirmationDialog(milestone)
        
        t:assertNotNil(strain.confirmationManualText, "Manual text element should exist")
        t:assertNotNil(strain.confirmationManualText.text, "Manual text should have been set")
        local manualText = strain.confirmationManualText.text
        t:assertEqual("(None)", manualText, "Should display (None) when no manual steps")
    end)
end)

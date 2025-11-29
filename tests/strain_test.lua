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

    local listPanel = {
        panels = recorder.rows,
        height = 0,
    }
    function listPanel:SetHeight(height)
        self.height = height
    end
    function listPanel:Panel(params)
        local row = { attributes = params }
        function row:SetHeight(h) self.height = h end
        function row:SetOffsetXY(offset) self.offset = offset end
        function row:SetWidth(w) self.width = w end
        function row:SetColor(color) self.color = color end
        function row:CheckBox(cbParams)
            local checkbox = { params = cbParams, checked = nil }
            function checkbox:Check(value) checkbox.checked = value end
            row.checkBox = checkbox
            return checkbox
        end
        function row:Text(textParams)
            local text = { params = textParams, text = nil }
            function text:SetText(value) text.text = value end
            function text:SetWidth(w) text.width = w end
            function text:SetHeight(h) text.height = h end
            return text
        end
        table.insert(self.panels, row)
        return row
    end

    local scrollArea = {
        Panel = function() return listPanel end,
        SetContentHeight = function(_, height)
            recorder.scrollContentHeight = height
        end,
    }

    local dialogStats = { show = 0, hide = 0 }
    local dialog = {
        Panel = function() return rootPanel end,
        ShowForPlayer = function(_, player)
            dialogStats.show = dialogStats.show + 1
            return player.color
        end,
        HideForPlayer = function(_, player)
            dialogStats.hide = dialogStats.hide + 1
            return player.color
        end,
        ShowForAll = function()
            dialogStats.show = dialogStats.show + 1
        end,
        HideForAll = function()
            dialogStats.hide = dialogStats.hide + 1
        end,
        IsOpen = function() return dialogStats.show > dialogStats.hide end,
    }

    local confirmDialog = {
        Panel = function() return {
            Text = function(_, params) 
                local text = { params = params, text = nil }
                function text:SetText(value) text.text = value end
                return text
            end,
            Button = function() end,
        } end,
        ShowForPlayer = function() end,
        HideForPlayer = function() end,
        Show = function() end,
        Hide = function() end,
        ShowForAll = function() end,
        HideForAll = function() end,
        SetHeight = function() end,
    }

    local function simplePanel()
        local panel = {}
        function panel:Panel()
            return simplePanel()
        end
        function panel:Text(params)
            local text = { params = params, text = nil }
            function text:SetText(value) text.text = value end
            return text
        end
        function panel:Button()
            return {}
        end
        return panel
    end

    local uncheckDialog = {
        Panel = simplePanel,
        ShowForAll = function() end,
        HideForAll = function() end,
    }

    local panelKitStub = {
        Dialog = function(params)
            if params.id == "StrainMilestoneConfirmation" then
                return confirmDialog
            end
            if params.id == "StrainMilestoneUncheck" then
                return uncheckDialog
            end
            return dialog
        end,
        ClassicDialog = function(args)
            recorder.legacyArgs = args
            return {
                contentX = 10,
                contentY = -30,
                contentWidth = 300,
                contentHeight = 210,
            }
        end,
        ScrollArea = function(args)
            recorder.scrollArgs = args
            return scrollArea
        end,
        VerticalLayout = function(params)
            return {
                AddTitle = function() return { SetText = function() end } end,
                AddSection = function() return {
                    content = { SetText = function() end },
                    label = { SetText = function() end }
                } end,
                AddSpacer = function() end,
                AddButtonRow = function() return {} end,
                GetUsedHeight = function() return 300 end,
                AutoSize = function() return 400 end,
            }
        end,
        CalculateVerticalLayoutHeight = function(params) return 450 end,
        AutoSizedDialog = function(params)
            local mockLayout = {
                AddTitle = function() return { SetText = function() end } end,
                AddSection = function() return {
                    content = { SetText = function() end },
                    label = { SetText = function() end }
                } end,
                AddSpacer = function() end,
                AddButtonRow = function() return {} end,
            }
            local contentRefs = params.buildContent(mockLayout)
            return {
                dialog = confirmDialog,
                panel = { Text = function() return { SetText = function() end } end, Button = function() end },
                contentRefs = contentRefs,
            }
        end,
    }

    local logStub = { Debugf = function() end, Errorf = function() end, Printf = function() end }
    local archiveStub = {
        calls = {},
        cleanCount = 0,
    }
    function archiveStub.Take(params)
        table.insert(archiveStub.calls, params)
        if archiveStub.takeHandler then
            return archiveStub.takeHandler(params)
        end
        return nil
    end
    function archiveStub.Clean()
        archiveStub.cleanCount = archiveStub.cleanCount + 1
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
    }

    return stubs, {
        recorder = recorder,
        dialogStats = dialogStats,
        listPanel = listPanel,
        archiveStub = archiveStub,
        containers = containers,
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

local function withStrain(t, callback)
    local stubs, env = buildStrainStubs()
    withStubs(stubs, function()
        package.loaded["Kdm/Strain"] = nil
        local StrainModule = require("Kdm/Strain")
        local strainTable = getInternalStrain(StrainModule)
        t:assertTrue(strainTable ~= nil, "found internal Strain table")
        callback(StrainModule, strainTable, env)
    end)
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
            t:assertTrue(milestone.flavorText ~= nil, "Milestone should have flavor text")
            t:assertTrue(milestone.rulesText ~= nil, "Milestone should have rules text")
            t:assertTrue(type(milestone.flavorText) == "string", "Flavor text should be string")
            t:assertTrue(type(milestone.rulesText) == "string", "Rules text should be string")
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
        t:assertTrue(entry ~= nil, string.format("Missing milestone data for %s", title))
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

        local success = strain:_TakeRewardCard({
            name = "Test Reward",
            type = strain.FIGHTING_ART_TYPE,
            position = { x = 1, y = 2, z = 3 },
        })

        t:assertTrue(success, "_TakeRewardCard should succeed via Strain deck")
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

Test.test("_TakeRewardCard returns false when the Strain Rewards deck is unavailable", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        local callCount = 0
        env.archiveStub.takeHandler = function(params)
            callCount = callCount + 1
            t:assertEqual(1, callCount, "Archive.Take should be invoked exactly once (for the rewards deck)")
            t:assertEqual(strain.REWARD_DECK_NAME, params.name)
            return nil
        end

        local success = strain:_TakeRewardCard({
            name = "Fallback Reward",
            type = strain.FIGHTING_ART_TYPE,
            position = { x = 0, y = 0, z = 0 },
        })

        t:assertFalse(success, "Missing Strain rewards deck should be treated as a failure")
        t:assertEqual(1, #env.archiveStub.calls, "Archive.Take should only be invoked for the Strain rewards deck")
    end)
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
    withStrain(t, function(StrainModule, strain)
        StrainModule.Init()
        local added, spawned
        local originalAdd = strain.AddFightingArtToArchive
        local originalSpawn = strain.SpawnFightingArtForSurvivor
        strain.AddFightingArtToArchive = function(name)
            added = name
            return true
        end
        strain.SpawnFightingArtForSurvivor = function(_, name)
            spawned = name
        end

        strain:ExecuteConsequences({ consequences = { fightingArt = "Test Art" } })

        strain.AddFightingArtToArchive = originalAdd
        strain.SpawnFightingArtForSurvivor = originalSpawn

        t:assertEqual("Test Art", added, "ExecuteConsequences should add fighting art to deck")
        t:assertEqual("Test Art", spawned, "ExecuteConsequences should spawn card for survivor")
    end)
end)

Test.test("ReverseConsequences removes fighting art rewards", function(t)
    withStrain(t, function(StrainModule, strain)
        StrainModule.Init()
        local removed
        local originalRemove = strain.RemoveFightingArtFromArchive
        strain.RemoveFightingArtFromArchive = function(name)
            removed = name
            return true
        end

        strain:ReverseConsequences({ consequences = { fightingArt = "Test Art" } })

        strain.RemoveFightingArtFromArchive = originalRemove

        t:assertEqual("Test Art", removed, "ReverseConsequences should remove fighting art from deck")
    end)
end)

Test.test("ConfirmMilestone checks the pending milestone", function(t)
    withStrain(t, function(StrainModule, strain, env)
        StrainModule.Init()
        
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        
        -- Confirm the milestone
        strain:ConfirmMilestone(player)
        
        -- Now it should be checked
        t:assertTrue(strain.milestones[1].reached, "Milestone should be reached after confirmation")
        t:assertTrue(env.recorder.rows[1].checkBox.checked, "Checkbox should be checked after confirmation")
        
        -- Pending info should be cleared
        t:assertEqual(nil, strain.pendingMilestoneIndex)
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
        t:assertTrue(saveState.reached["Milestone B"] == nil, "unreached milestones should not be persisted")
    end)
end)

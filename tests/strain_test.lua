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
        function row:CheckBox(cbParams)
            local checkbox = { params = cbParams, checked = nil }
            function checkbox:Check(value) checkbox.checked = value end
            row.checkBox = checkbox
            return checkbox
        end
        function row:Text(textParams)
            local text = { params = textParams, text = nil }
            function text:SetText(value) text.text = value end
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
    }

    local panelKitStub = {
        Dialog = function(params)
            if params.id == "StrainMilestoneConfirmation" then
                return confirmDialog
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
    }

    local logStub = { Debugf = function() end, Errorf = function() end }

    local stubs = {
        ["Kdm/Ui/PanelKit"] = panelKitStub,
        ["Kdm/Ui"] = {
            Get2d = function() return {} end,
            DARK_BROWN = "#111111",
            MID_BROWN = "#999999",
        },
        ["Kdm/Log"] = { ForModule = function() return logStub end },
    }

    return stubs, {
        recorder = recorder,
        dialogStats = dialogStats,
        listPanel = listPanel,
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

        t:assertEqual(#strain.DUMMY_MILESTONES, #strain.milestones)
        for i, milestone in ipairs(strain.milestones) do
            t:assertTrue(milestone ~= strain.DUMMY_MILESTONES[i])
            t:assertEqual(strain.DUMMY_MILESTONES[i].title, milestone.title)
            t:assertFalse(milestone.reached)
        end

        t:assertEqual(#strain.milestones, #env.recorder.rows)
        local expectedHeight = #strain.milestones * strain.ROW_HEIGHT
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

        -- Toggle should uncheck it
        local player = { color = "White" }
        strain:ToggleMilestone(1, player)
        
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
        t:assertEqual(player, strain.pendingPlayer)
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
        t:assertEqual(nil, strain.pendingPlayer)
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
        t:assertEqual(nil, strain.pendingPlayer)
    end)
end)

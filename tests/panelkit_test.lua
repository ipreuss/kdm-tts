local Test = require("tests.framework")
local PanelKit = require("Kdm/Ui/PanelKit")

local function stubPanel(params)
    local panel = {
        attributes = {
            id = params.id,
            active = params.active,
            visibility = nil,
        }
    }

    function panel:Show()
        self.attributes.active = true
    end

    function panel:Hide()
        self.attributes.active = false
    end

    function panel:ShowForPlayer(color)
        self.attributes.active = true
        self.attributes.visibility = color
        return color
    end

    function panel:HideForPlayer(color)
        if self.attributes.visibility == color then
            self.attributes.active = false
        end
        return self.attributes.visibility or "None"
    end

    function panel:Button(_) end
    function panel:Image(_) end

    return panel
end

local function stubUi()
    return {
        Panel = function(_, params)
            return stubPanel(params)
        end
    }
end

local function nestedPanel(params)
    local panel = stubPanel(params)
    panel.height = params.height or 0

    function panel:SetHeight(height)
        self.height = height
    end

    function panel:Panel(childParams)
        return nestedPanel(childParams)
    end

    function panel:VerticalScroll(childParams)
        local scroll = nestedPanel(childParams)
        scroll.isScrollView = true
        return scroll
    end

    return panel
end

Test.test("dialog per-player tracks open state based on player visibility", function(t)
    local dialog = PanelKit.Dialog({
        id = "Dialog",
        width = 10,
        height = 10,
        ui = stubUi(),
        perPlayer = true,
    })

    local result = dialog:ShowForPlayer({ color = "White" })
    t:assertEqual("White", result)
    t:assertTrue(dialog:IsOpen())

    dialog:HideForPlayer({ color = "White" })
    t:assertFalse(dialog:IsOpen())
end)

Test.test("dialog global visibility toggles open state", function(t)
    local dialog = PanelKit.Dialog({
        id = "GlobalDialog",
        width = 10,
        height = 10,
        ui = stubUi(),
        perPlayer = false,
    })

    dialog:ShowForAll()
    t:assertTrue(dialog:IsOpen())

    dialog:HideForAll()
    t:assertFalse(dialog:IsOpen())
end)

Test.test("global dialog returns 'All' when ShowForPlayer is used", function(t)
    local dialog = PanelKit.Dialog({
        id = "GlobalDialog",
        width = 10,
        height = 10,
        ui = stubUi(),
        perPlayer = false,
    })

    local result = dialog:ShowForPlayer({ color = "White" })
    t:assertEqual("All", result)
    t:assertTrue(dialog:IsOpen())

    local hideResult = dialog:HideForPlayer({ color = "White" })
    t:assertEqual("All", hideResult)
    t:assertFalse(dialog:IsOpen())
end)

Test.test("per-player dialog returns caller color and toggles open", function(t)
    local dialog = PanelKit.Dialog({
        id = "PlayerDialog",
        width = 10,
        height = 10,
        ui = stubUi(),
        perPlayer = true,
    })

    local result = dialog:ShowForPlayer({ color = "Blue" })
    t:assertEqual("Blue", result)
    t:assertTrue(dialog:IsOpen())

    local hideResult = dialog:HideForPlayer({ color = "Blue" })
    t:assertEqual("Blue", hideResult)
    t:assertFalse(dialog:IsOpen())
end)

Test.test("scroll area builds a scroll view with helper accessors", function(t)
    local area = PanelKit.ScrollArea({
        parent = nestedPanel({ id = "Root" }),
        id = "Area",
        width = 100,
        height = 50,
        contentHeight = 25,
    })

    local scrollView = area:ScrollView()
    t:assertEqual("AreaScroll", scrollView.attributes.id)
    t:assertTrue(scrollView.isScrollView)

    local contentPanel = area:Panel()
    t:assertEqual("AreaPanel", contentPanel.attributes.id)
    t:assertEqual(25, contentPanel.height)

    area:SetContentHeight(40)
    t:assertEqual(40, contentPanel.height)
end)

Test.test("scroll area supports disabling scroll and custom ids", function(t)
    local area = PanelKit.ScrollArea({
        parent = nestedPanel({ id = "Root" }),
        id = "Plain",
        containerId = "CustomContainer",
        panelId = "InnerPanel",
        width = 80,
        height = 30,
        scroll = false,
        contentHeight = 10,
    })

    local container = area:ScrollView()
    t:assertEqual("CustomContainer", container.attributes.id)
    t:assertTrue(container.isScrollView == nil)

    local panel = area:Panel()
    t:assertEqual("InnerPanel", panel.attributes.id)
end)

Test.test("scroll selector defaults, selection, and GetSelected", function(t)
    local labelCalled = false
    local function makePanel(params)
        local panel = stubPanel(params)
        function panel:Text(_)
            labelCalled = true
        end
        function panel:VerticalScroll(p) return makePanel(p) end
        function panel:Panel(p) return makePanel(p) end
        function panel:SetHeight(_) end
        function panel:OptionButtonGroup(opts)
            local group = {
                options = {},
                parent = panel,
                fontSize = opts.fontSize,
                textAlignment = opts.textAlignment,
                textColor = opts.textColor,
                selectedColors = opts.selectedColors,
                unselectedColors = opts.unselectedColors,
                onClick = opts.onClick,
            }
            function group:OptionButton(p)
                local button = stubPanel(p)
                button.selectCalled = false
                function button:Select() self.selectCalled = true end
                function button:SetText(_) end
                function button:SetOptionValue(v) button.optionValue = v end
                function button:OptionValue() return button.optionValue end
                button.optionValue = p.optionValue
                table.insert(self.options, button)
                return button
            end
            return group
        end
        return panel
    end

    local ui = { Panel = function(_, params) return makePanel(params) end }

    local selected = {}
    local selector = PanelKit.ScrollSelector({
        parent = ui:Panel({ id = "Root", x = 0, y = 0, width = 100, height = 100 }),
        id = "Sel",
        x = 0,
        y = 0,
        width = 50,
        height = 50,
        label = { text = "Label" },
        onSelect = function(value, _) table.insert(selected, value) end,
    })

    selector:SetOptionsWithDefault({
        { text = "A", value = "a", selected = false },
        { text = "B", value = "b", selected = false },
    }, true)

    t:assertTrue(labelCalled)
    t:assertEqual(2, #selector.buttons)
    t:assertEqual("a", selector:GetSelected())
    t:assertEqual("a", selected[1])
    t:assertTrue(selector.buttons[1].selectCalled)

    -- simulate clicking second option
    selector.group.onClick(selector.buttons[2])
    t:assertEqual("b", selector:GetSelected())
    t:assertTrue(selector.buttons[2].selectCalled)
end)

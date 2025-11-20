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

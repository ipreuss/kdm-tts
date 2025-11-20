local Test = require("tests.framework")
local PanelKit = require("Kdm/Ui/PanelKit")

local function stubUi()
    local ui = {}
    function ui:Panel(params)
        local active = params.active
        local panel = {
            attributes = { id = params.id },
            children = {},
            Show = function() active = true end,
            Hide = function() active = false end,
            Button = function(_, _) end,
            Image = function(_, _) end,
            Panel = function(self, p)
                return ui:Panel(p)
            end,
        }
        return panel
    end
    return ui
end

Test.test("Timeline dialog uses global show/hide", function(t)
    local dialog = PanelKit.Dialog({
        id = "Timeline",
        width = 10,
        height = 10,
        ui = stubUi(),
        perPlayer = false,
    })

    dialog:ShowForAll()
    t:assertTrue(dialog:IsOpen())

    local result = dialog:ShowForPlayer({ color = "White" })
    t:assertEqual("All", result)
    t:assertTrue(dialog:IsOpen())

    dialog:HideForAll()
    t:assertFalse(dialog:IsOpen())
end)

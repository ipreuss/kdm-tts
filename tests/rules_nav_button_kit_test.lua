---------------------------------------------------------------------------------------------------
-- RulesNavButtonKit Unit Tests
--
-- Tests for the Rules Navigation Board button utility module.
--
-- Test scope: Unit tests with mock ui parameter.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Minimal TTS Stubs
---------------------------------------------------------------------------------------------------

local function createMinimalTTSEnvironment()
    _G.logStyle = function() end
    _G.printToAll = function() end
    _G.broadcastToAll = function() end
    _G.log = function() end

    -- Ui stub
    package.loaded["Kdm/Ui"] = {
        DARK_BROWN = "#4a3728",
        LIGHT_BROWN = "#d4c4a8",
        INVISIBLE_COLORS = "#00000000|#00000000|#00000000|#00000000",
    }
end

---------------------------------------------------------------------------------------------------
-- Test Helper: Load module fresh
---------------------------------------------------------------------------------------------------

local function loadRulesNavButtonKit()
    for k in pairs(package.loaded) do
        if k:match("^Kdm/") then
            package.loaded[k] = nil
        end
    end

    createMinimalTTSEnvironment()

    return require("Kdm/Util/RulesNavButtonKit")
end

---------------------------------------------------------------------------------------------------
-- UNIT TESTS: GetPosition
---------------------------------------------------------------------------------------------------

Test.test("UNIT: GetPosition(1, 1) returns correct top-left corner coordinates", function(t)
    local kit = loadRulesNavButtonKit()
    local pos = kit.GetPosition(1, 1)

    t:assertNotNil(pos.topLeft, "Should return topLeft coordinates")
    t:assertNotNil(pos.bottomRight, "Should return bottomRight coordinates")

    -- Column 1 should be at x1 = 7.762758
    t:assertTrue(math.abs(pos.topLeft.x - 7.762758) < 0.001,
        string.format("Column 1 x should be ~7.76, got %.6f", pos.topLeft.x))

    -- Row 1 should be at y1 = -0.401185
    t:assertTrue(math.abs(pos.topLeft.y - (-0.401185)) < 0.001,
        string.format("Row 1 y should be ~-0.40, got %.6f", pos.topLeft.y))
end)

---------------------------------------------------------------------------------------------------

Test.test("UNIT: GetPosition(13, 2) returns correct far-right row-2 coordinates", function(t)
    local kit = loadRulesNavButtonKit()
    local pos = kit.GetPosition(13, 2)

    t:assertNotNil(pos.topLeft, "Should return topLeft coordinates")

    -- Column 13 should be at x13 = -6.702875
    t:assertTrue(math.abs(pos.topLeft.x - (-6.702875)) < 0.001,
        string.format("Column 13 x should be ~-6.70, got %.6f", pos.topLeft.x))

    -- Row 2 should be at y2 = 0.392804
    t:assertTrue(math.abs(pos.topLeft.y - 0.392804) < 0.001,
        string.format("Row 2 y should be ~0.39, got %.6f", pos.topLeft.y))
end)

---------------------------------------------------------------------------------------------------

Test.test("UNIT: Column spacing is consistent across all columns", function(t)
    local kit = loadRulesNavButtonKit()

    local positions = {}
    for col = 1, 13 do
        positions[col] = kit.GetPosition(col, 1)
    end

    -- Calculate expected spacing
    local expectedDx = (positions[13].topLeft.x - positions[1].topLeft.x) / 12

    -- Verify each column is consistently spaced
    for col = 1, 12 do
        local actualSpacing = positions[col + 1].topLeft.x - positions[col].topLeft.x
        local diff = math.abs(actualSpacing - expectedDx)
        t:assertTrue(diff < 0.0001,
            string.format("Column %d->%d spacing should be %.6f, got %.6f",
                col, col + 1, expectedDx, actualSpacing))
    end
end)

---------------------------------------------------------------------------------------------------

Test.test("UNIT: bottomRight is offset from topLeft by consistent width/height", function(t)
    local kit = loadRulesNavButtonKit()

    local pos1 = kit.GetPosition(1, 1)
    local pos2 = kit.GetPosition(7, 2)

    local width1 = pos1.bottomRight.x - pos1.topLeft.x
    local height1 = pos1.bottomRight.y - pos1.topLeft.y

    local width2 = pos2.bottomRight.x - pos2.topLeft.x
    local height2 = pos2.bottomRight.y - pos2.topLeft.y

    t:assertTrue(math.abs(width1 - width2) < 0.0001,
        "Width should be consistent across positions")
    t:assertTrue(math.abs(height1 - height2) < 0.0001,
        "Height should be consistent across positions")
end)

---------------------------------------------------------------------------------------------------

Test.test("UNIT: Width is calculated from X coordinates, not Y (regression test)", function(t)
    local kit = loadRulesNavButtonKit()
    local pos = kit.GetPosition(1, 1)

    local width = pos.bottomRight.x - pos.topLeft.x
    local height = pos.bottomRight.y - pos.topLeft.y

    -- Width should NOT equal height (the original bug used Y for both)
    t:assertTrue(math.abs(width - height) > 0.1,
        "Width should differ from height (regression test for Y-coordinate bug)")

    -- Expected width: x1End - x1 = 6.705129 - 7.762758 = -1.057629
    t:assertTrue(math.abs(width - (-1.057629)) < 0.001,
        string.format("Width should be ~-1.06, got %.6f", width))

    -- Expected height: y1End - y1 = 0.047924 - (-0.401185) = 0.449109
    t:assertTrue(math.abs(height - 0.449109) < 0.001,
        string.format("Height should be ~0.45, got %.6f", height))
end)

---------------------------------------------------------------------------------------------------
-- UNIT TESTS: CreateButton
---------------------------------------------------------------------------------------------------

Test.test("UNIT: CreateButton calls ui:Button with correct parameters", function(t)
    local kit = loadRulesNavButtonKit()

    local capturedParams = nil
    local mockUi = {
        Button = function(self, params)
            capturedParams = params
            return { id = params.id }
        end,
    }

    local onClick = function() end
    kit.CreateButton({
        ui = mockUi,
        id = "TestButton",
        col = 5,
        row = 1,
        onClick = onClick,
    })

    t:assertNotNil(capturedParams, "Should call ui:Button")
    t:assertEqual("TestButton", capturedParams.id, "Should pass id")
    t:assertEqual(onClick, capturedParams.onClick, "Should pass onClick")
    t:assertNotNil(capturedParams.topLeft, "Should pass topLeft")
    t:assertNotNil(capturedParams.bottomRight, "Should pass bottomRight")
end)

---------------------------------------------------------------------------------------------------
-- UNIT TESTS: CreateStyledButton
---------------------------------------------------------------------------------------------------

Test.test("UNIT: CreateStyledButton creates panel, text, and button", function(t)
    local kit = loadRulesNavButtonKit()

    local createdElements = {}
    local mockUi = {
        Panel = function(self, params)
            createdElements.panel = params
            return { id = params.id, type = "panel" }
        end,
        Text = function(self, params)
            createdElements.text = params
            return { id = params.id, type = "text" }
        end,
        Button = function(self, params)
            createdElements.button = params
            return { id = params.id, type = "button" }
        end,
    }

    local result = kit.CreateStyledButton({
        ui = mockUi,
        id = "MyButton",
        col = 13,
        row = 2,
        label = "Click Me",
        onClick = function() end,
        active = false,
    })

    -- Verify all three elements created
    t:assertNotNil(createdElements.panel, "Should create panel")
    t:assertNotNil(createdElements.text, "Should create text")
    t:assertNotNil(createdElements.button, "Should create button")

    -- Verify IDs follow pattern
    t:assertEqual("MyButtonPanel", createdElements.panel.id, "Panel id should be <id>Panel")
    t:assertEqual("MyButtonLabel", createdElements.text.id, "Text id should be <id>Label")
    t:assertEqual("MyButton", createdElements.button.id, "Button id should be <id>")

    -- Verify label passed to text
    t:assertEqual("Click Me", createdElements.text.text, "Text should have label")

    -- Verify active state propagated
    t:assertEqual(false, createdElements.panel.active, "Panel should respect active param")
    t:assertEqual(false, createdElements.text.active, "Text should respect active param")
    t:assertEqual(false, createdElements.button.active, "Button should respect active param")

    -- Verify return structure
    t:assertNotNil(result.panel, "Should return panel element")
    t:assertNotNil(result.text, "Should return text element")
    t:assertNotNil(result.button, "Should return button element")
end)

---------------------------------------------------------------------------------------------------

Test.test("UNIT: CreateStyledButton defaults active to true", function(t)
    local kit = loadRulesNavButtonKit()

    local createdElements = {}
    local mockUi = {
        Panel = function(self, params)
            createdElements.panel = params
            return {}
        end,
        Text = function(self, params)
            createdElements.text = params
            return {}
        end,
        Button = function(self, params)
            createdElements.button = params
            return {}
        end,
    }

    kit.CreateStyledButton({
        ui = mockUi,
        id = "Test",
        col = 1,
        row = 1,
        -- active not specified
    })

    t:assertEqual(true, createdElements.panel.active, "Panel should default to active=true")
    t:assertEqual(true, createdElements.text.active, "Text should default to active=true")
    t:assertEqual(true, createdElements.button.active, "Button should default to active=true")
end)

local Test = require("tests.framework")

local function buildLayoutStubs()
    local recorder = {
        elements = {},
        calls = {},
    }

    local mockPanel = {}
    function mockPanel:Text(params)
        table.insert(recorder.calls, { type = "Text", params = params })
        local element = { type = "Text", params = params }
        table.insert(recorder.elements, element)
        return element
    end
    
    function mockPanel:Button(params)
        table.insert(recorder.calls, { type = "Button", params = params })
        local element = { type = "Button", params = params }
        table.insert(recorder.elements, element)
        return element
    end

    local stubs = {
        ["Kdm/Util/Check"] = {
            Table = function(val) return type(val) == "table" end,
        },
        ["Kdm/Ui"] = {
            DARK_BROWN = "#453824",
            MID_BROWN = "#7f7059",
            MID_BROWN_COLORS = "#7f7059|#655741|#655741|#ffffff",
        },
    }

    return stubs, {
        recorder = recorder,
        mockPanel = mockPanel,
    }
end

local function withLayout(t, callback)
    local stubs, env = buildLayoutStubs()
    
    local originals = {}
    for name, mod in pairs(stubs) do
        originals[name] = package.loaded[name]
        package.loaded[name] = mod
    end
    
    local ok, err = pcall(function()
        package.loaded["Kdm/Ui/LayoutManager"] = nil
        local LayoutManager = require("Kdm/Ui/LayoutManager")
        callback(LayoutManager, env)
    end)
    
    for name, orig in pairs(originals) do
        package.loaded[name] = orig
    end
    
    if not ok then
        error(err)
    end
end

Test.test("VerticalLayout creates layout with content area", function(t)
    withLayout(t, function(LayoutManager, env)
        local contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 }
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = contentArea,
            padding = 20,
            spacing = 15,
        })
        
        t:assertEqual(env.mockPanel, layout.parent)
        t:assertEqual(contentArea, layout.contentArea)
        t:assertEqual(20, layout.padding)
        t:assertEqual(15, layout.spacing)
        t:assertEqual(nil, layout.currentY) -- Should be nil until first element
    end)
end)

Test.test("AddTitle creates centered title text", function(t)
    withLayout(t, function(LayoutManager, env)
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 20,
        })
        
        layout:AddTitle({ text = "Test Title" })
        
        t:assertEqual(1, #env.recorder.calls)
        local call = env.recorder.calls[1]
        t:assertEqual("Text", call.type)
        t:assertEqual("Test Title", call.params.text)
        t:assertEqual(24, call.params.fontSize)
        t:assertEqual("Bold", call.params.fontStyle)
        t:assertEqual("UpperCenter", call.params.alignment)
        t:assertEqual(30, call.params.x) -- contentX + padding
        t:assertEqual(-50, call.params.y) -- contentY - padding
    end)
end)

Test.test("AddSection creates label and content with spacing", function(t)
    withLayout(t, function(LayoutManager, env)
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 20,
            spacing = 15,
        })
        
        layout:AddSection({
            label = "Story:",
            content = "This is the flavor text content.",
        })
        
        t:assertEqual(2, #env.recorder.calls)
        
        -- Check label
        local labelCall = env.recorder.calls[1]
        t:assertEqual("Text", labelCall.type)
        t:assertEqual("Story:", labelCall.params.text)
        t:assertEqual(18, labelCall.params.fontSize)
        t:assertEqual("Bold", labelCall.params.fontStyle)
        
        -- Check content (should be indented and below label)
        local contentCall = env.recorder.calls[2]
        t:assertEqual("Text", contentCall.type)
        t:assertEqual("This is the flavor text content.", contentCall.params.text)
        t:assertEqual(16, contentCall.params.fontSize)
        t:assertEqual(40, contentCall.params.x) -- contentX + padding + indent
        t:assertEqual(250, contentCall.params.width) -- contentWidth - padding*2 - indent
    end)
end)

Test.test("AddButtonRow centers multiple buttons", function(t)
    withLayout(t, function(LayoutManager, env)
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 20,
        })
        
        local clicked = {}
        layout:AddButtonRow({
            buttons = {
                { text = "OK", onClick = function() clicked[1] = true end },
                { text = "Cancel", onClick = function() clicked[2] = true end },
            }
        })
        
        t:assertEqual(2, #env.recorder.calls)
        
        -- Check first button positioning
        local button1 = env.recorder.calls[1]
        t:assertEqual("Button", button1.type)
        t:assertEqual("OK", button1.params.text)
        
        -- Check second button positioning  
        local button2 = env.recorder.calls[2]
        t:assertEqual("Button", button2.type)
        t:assertEqual("Cancel", button2.params.text)
        
        -- Buttons should be side by side
        t:assertEqual(button1.params.y, button2.params.y)
        t:assertTrue(button2.params.x > button1.params.x)
    end)
end)

Test.test("GetUsedHeight calculates layout height correctly", function(t)
    withLayout(t, function(LayoutManager, env)
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 20,
            spacing = 15,
        })
        
        -- Initially no height used
        t:assertEqual(0, layout:GetUsedHeight())
        
        -- Add a title
        layout:AddTitle({ text = "Title", height = 35 })
        
        -- Should be padding + title height + padding
        -- contentY(-30) - currentY(-65) + padding(20) = 75
        -- After title: currentY = contentY - padding - titleHeight = -30 - 20 - 35 = -85
        -- Used height = contentY - currentY + padding = -30 - (-85) + 20 = 75
        local expectedHeight = 75
        t:assertEqual(expectedHeight, layout:GetUsedHeight())
    end)
end)

Test.test("AutoSize calculates appropriate dialog height", function(t)
    withLayout(t, function(LayoutManager, env)
        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 10, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 20,
        })
        
        -- Add some content
        layout:AddTitle({ text = "Title", height = 35 })
        layout:AddSection({ label = "Test:", content = "Content", contentHeight = 80 })
        
        -- Auto-size should return content height + padding
        local autoHeight = layout:AutoSize({ padding = 50, minHeight = 200, maxHeight = 600 })
        local usedHeight = layout:GetUsedHeight()
        local expectedHeight = usedHeight + 50
        
        t:assertEqual(expectedHeight, autoHeight)
        t:assertTrue(autoHeight >= 200) -- Should respect minHeight
        t:assertTrue(autoHeight <= 600) -- Should respect maxHeight
    end)
end)

Test.test("CalculateLayoutHeight honors polymorphic elements", function(t)
    withLayout(t, function(LayoutManager)
        local Elements = LayoutManager.Elements
        local elements = {
            Elements.Title({ fontSize = 20 }),
            Elements.Spacer({ height = 5 }),
            Elements.Section({}),
            Elements.ButtonRow({ height = 40 }),
        }

        local result = LayoutManager.CalculateLayoutHeight({
            elements = elements,
            padding = 10,
            spacing = 5,
            chromeOverhead = 0,
        })

        -- Elements expand to title, spacer, label, content, buttonRow
        local expectedElements = 5
        local spacingTotal = (expectedElements - 1) * 5
        local titleHeight = 20 * LayoutManager.TITLE_HEIGHT_MULTIPLIER
        local labelHeight = 18 * LayoutManager.LABEL_HEIGHT_MULTIPLIER
        local contentHeight = LayoutManager.CONTENT_FONT_SIZE * LayoutManager.CONTENT_HEIGHT_MULTIPLIER
        local heights = titleHeight + 5 + labelHeight + contentHeight + 40
        local expected = (10 * 2) + heights + spacingTotal
        t:assertEqual(expected, result)
    end)
end)

Test.test("Specification calculates height and renders layout", function(t)
    withLayout(t, function(LayoutManager, env)
        local spec = LayoutManager.Specification()
        local capturedTitle
        spec:AddTitle({ text = "Spec Title", id = "SpecTitle" }, function(element)
            capturedTitle = element
        end)
        spec:AddSpacer(5)
        spec:AddButtonRow({
            height = 40,
            buttons = {
                { text = "One" },
                { text = "Two" },
            },
        })

        local height = spec:CalculateHeight({ padding = 10, spacing = 5, chromeOverhead = 0 })
        t:assertTrue(height > 0)

        local dialogHeight = spec:CalculateDialogHeight({ padding = 10, spacing = 5 })
        t:assertTrue(dialogHeight > height)

        local layout = LayoutManager.VerticalLayout({
            parent = env.mockPanel,
            contentArea = { contentX = 0, contentY = -30, contentWidth = 300, contentHeight = 200 },
            padding = 10,
            spacing = 5,
        })

        spec:Render(layout)

        t:assertTrue(#env.recorder.calls >= 3)
        t:assertEqual("Text", env.recorder.calls[1].type)
        t:assertTrue(capturedTitle ~= nil)
    end)
end)

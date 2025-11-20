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

Test.test("Timeline ShowUi/HideUi use global dialog", function(t)
    local logStub = { Debugf = function() end, Errorf = function() end, Broadcastf = function() end }
    withStubs({
        ["Kdm/Archive"] = {},
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Util/Container"] = {},
        ["Kdm/Expansion"] = {},
        ["Kdm/Hunt"] = {},
        ["Kdm/Location"] = {},
        ["Kdm/Log"] = { ForModule = function() return logStub end },
        ["Kdm/MessageBox"] = {},
        ["Kdm/Rules"] = {},
        ["Kdm/Showdown"] = {},
        ["Kdm/Ui"] = {},
        ["Kdm/Util/Util"] = {},
        ["Kdm/Ui/PanelKit"] = {},
        ["Kdm/Util/Trie"] = function() return {} end,
    }, function()
        package.loaded["Kdm/Timeline"] = nil
        local Timeline = require("Kdm/Timeline")

        -- Reach into the local Timeline table captured by ShowUi to set dialog
        local timelineTable
        local i = 1
        while true do
            local name, value = debug.getupvalue(Timeline.ShowUi, i)
            if not name then break end
            if name == "Timeline" then
                timelineTable = value
                break
            end
            i = i + 1
        end
        t:assertTrue(timelineTable ~= nil, "found internal Timeline table")

        local calls = { show = 0, hide = 0 }
        timelineTable.dialog = {
            ShowForAll = function()
                calls.show = calls.show + 1
            end,
            HideForAll = function()
                calls.hide = calls.hide + 1
            end,
            IsOpen = function() return calls.show > calls.hide end,
        }

        local player = { color = "White", steam_name = "Tester" }
        Timeline.ShowUi(player)
        Timeline.HideUi(player)

        t:assertEqual(1, calls.show)
        t:assertEqual(1, calls.hide)
        t:assertFalse(timelineTable.dialog:IsOpen())
    end)
end)

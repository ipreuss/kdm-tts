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

Test.test("Showdown ShowUi/HideUi delegate to dialog per-player", function(t)
    local logStub = { Debugf = function() end, Errorf = function() end }
    withStubs({
        ["Kdm/Archive"] = {},
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Util/Container"] = {},
        ["Kdm/Util/EventManager"] = { AddHandler = function() end },
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/Util/Grid"] = { Create = function() return {} end },
        ["Kdm/Log"] = { ForModule = function() return logStub end },
        ["Kdm/Location"] = { Get = function() return { Position = function() end } end },
        ["Kdm/Monster"] = {},
        ["Kdm/NamedObject"] = { Get = function() return {} end },
        ["Kdm/Util/Overlay"] = { Create = function() return {} end },
        ["Kdm/Player"] = {},
        ["Kdm/Rules"] = {},
        ["Kdm/Terrain"] = {},
        ["Kdm/Ui"] = { Get2d = function() return {} end },
        ["Kdm/Util/Util"] = {
            TabStr = function() return "" end,
            Map = function(list, fn) local out = {} for i,v in ipairs(list or {}) do out[i]=fn(v) end return out end,
        },
        ["Kdm/Survivor"] = {},
        ["Kdm/Ui/PanelKit"] = false,
    }, function()
        package.loaded["Kdm/Showdown"] = nil
        local dialogCalls = { show = 0, hide = 0 }
        local dialogStub = {
            Panel = function()
                return { Button = function() end }
            end,
            ShowForPlayer = function(_, player)
                dialogCalls.show = dialogCalls.show + 1
                return player.color
            end,
            HideForPlayer = function(_, player)
                dialogCalls.hide = dialogCalls.hide + 1
                return player.color
            end,
            IsOpen = function() return false end,
        }
        package.loaded["Kdm/Ui/PanelKit"] = {
            Dialog = function() return dialogStub end,
            OptionList = function() return { SetOptions = function() end } end,
            ScrollSelector = function()
                return {
                    SetOptionsWithDefault = function() end,
                }
            end,
        }

        local Showdown = require("Kdm/Showdown")
        Showdown.Init()
        local player = { color = "Green", steam_name = "Test" }
        Showdown.ShowUi(player)
        Showdown.HideUi(player)
        t:assertEqual(1, dialogCalls.show)
        t:assertEqual(1, dialogCalls.hide)
    end)
end)

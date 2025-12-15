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

Test.test("Hunt ShowUi/HideUi delegate to dialog per-player", function(t)
    local logStub = { Debugf = function() end, Errorf = function() end, Broadcastf = function() end }
    withStubs({
        ["Kdm/Archive"] = {},
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Util/Container"] = {},
        ["Kdm/Deck"] = {},
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/Location"] = {
            Get = function(name)
                return {
                    AddDropHandler = function() end,
                    BoxClean = function() return {} end,
                    AllObjects = function() return {} end,
                }
            end
        },
        ["Kdm/Log"] = { ForModule = function() return logStub end },
        ["Kdm/Trash"] = {},
        ["Kdm/Ui"] = { Get2d = function() return {} end },
        ["Kdm/Util/Util"] = { Map = function(list, fn) local out = {} for i,v in ipairs(list or {}) do out[i]=fn(v) end return out end },
        ["Kdm/Survivor"] = {},
        ["Kdm/Ui/PanelKit"] = false, -- placeholder, replaced below
    }, function()
        package.loaded["Kdm/Hunt"] = nil

        local dialogCalls = { show = 0, hide = 0 }
        local dialogStub = {
            Panel = function(self)
                return {
                    Button = function() end,
                }
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

        local Hunt = require("Kdm/Hunt")
        Hunt.Init() -- sets Hunt.dialog internally
        local player = { color = "Blue", steam_name = "Test" }
        Hunt.ShowUi(player)
        Hunt.HideUi(player)
        t:assertEqual(1, dialogCalls.show)
        t:assertEqual(1, dialogCalls.hide)
    end)
end)

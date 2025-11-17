local Test = require("tests.framework")

local function withStubbedModules(fn)
    local originals = {}

    local captured = {
        getNameArgs = {},
    }

    local function stub(name, value)
        originals[name] = package.loaded[name]
        package.loaded[name] = value
    end

    stub("Kdm/Archive", {})
    stub("Kdm/Location", {})
    stub("Kdm/MessageBox", {})
    stub("Kdm/NamedObject", {})
    stub("Kdm/Ui", {})
    stub("Kdm/Util/EventManager", {
        FireEvent = function()
        end,
    })
    stub("Kdm/Util/Util", { Max = math.max, Min = math.min })

    stub("Kdm/Util/Check", {
        Num = function() return true end,
        Boolean = function() return true end,
        BooleanOrNil = function() return true end,
        StrOrNil = function() return true end,
        Str = function() return true end,
    })

    stub("Kdm/Log", {
        ForModule = function()
            return {
                Debugf = function() end,
                Printf = function() end,
                Errorf = function() end,
            }
        end,
    })

    local realNames = require("Kdm/Util/Names")
    local namesModule = {
        Gender = realNames.Gender,
        getName = function(gender, character)
            table.insert(captured.getNameArgs, { gender = gender, character = character })
            return "Stub Name"
        end,
    }
    stub("Kdm/Util/Names", namesModule)

    package.loaded["Kdm/Survivor"] = nil
    local Survivor = require("Kdm/Survivor")

    Survivor.InitSaveState({})
    Survivor.SetInnovationsChecker(function()
        return false
    end)
    Survivor.SetCharacterProvider(function()
    end)

    Survivor.Test.stubUi({
        livingSurvivorsText = { SetText = function() end },
        deadSurvivorsText = { SetText = function() end },
        maleSurvivorsText = { SetText = function() end },
        femaleSurvivorsText = { SetText = function() end },
        UpdateLivingDeadCounts = function() end,
        UpdateSexCounts = function() end,
        SetPageAndRefresh = function() end,
    })

    local ok, err = pcall(fn, Survivor, captured)

    package.loaded["Kdm/Survivor"] = originals["Kdm/Survivor"]
    for name, value in pairs(originals) do
        package.loaded[name] = value
    end

    if not ok then
        error(err, 0)
    end
end

Test.test("newSurvivor passes gender constants to Names.getName", function(t)
    withStubbedModules(function(Survivor, captured)
        Survivor.NewSurvivor(true)
        Survivor.NewSurvivor(false)

        t:assertEqual(2, #captured.getNameArgs)
        t:assertEqual("male", captured.getNameArgs[1].gender)
        t:assertEqual("female", captured.getNameArgs[2].gender)
    end)
end)

Test.test("CreateSurvivor registers survivor and sets gender/name", function(t)
    withStubbedModules(function(Survivor, captured)
        local characterCard = { name = "Hero" }
        local survivor = Survivor.CreateSurvivor("male", { characterCard = characterCard })

        t:assertEqual(1, #Survivor.Survivors())
        t:assertEqual(survivor, Survivor.Survivors()[1])
        t:assertTrue(survivor:Male())
        t:assertFalse(survivor:Female())
        t:assertEqual("Stub Name", survivor:Name())

        t:assertEqual(1, #captured.getNameArgs)
        t:assertEqual("male", captured.getNameArgs[1].gender)
        t:assertEqual("Hero", captured.getNameArgs[1].character)
        t:assertEqual(1, survivor:Survival())
    end)
end)

Test.test("NewSurvivor handles character card path", function(t)
    withStubbedModules(function(Survivor, captured)
        local characterCard = { name = "Hero" }
        Survivor.SetInnovationsChecker(function() return true end)
        Survivor.SetCharacterProvider(function() return characterCard end)

        Survivor.NewSurvivor(true)

        t:assertEqual(1, #Survivor.Survivors())
        t:assertEqual("Hero", captured.getNameArgs[1].character)
        t:assertEqual(characterCard, Survivor.Survivors()[1]:Cards()[1])
    end)
end)

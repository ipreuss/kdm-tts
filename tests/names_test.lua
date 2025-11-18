local Test = require("tests.framework")
local Names = require("Kdm/Util/Names")

local function withFixedRandom(fn, replacement)
    local originalRandom = math.random
    math.random = replacement or function()
        return 1
    end

    local ok, err = pcall(fn)
    math.random = originalRandom
    if not ok then
        error(err, 0)
    end
end

Test.test("Gender constants are strings", function(t)
    t:assertEqual("male", Names.Gender.male)
    t:assertEqual("female", Names.Gender.female)
end)

Test.test("getName falls back to generic male names when character missing", function(t)
    withFixedRandom(function()
        local name = Names.getName(Names.Gender.male, "Unknown Character")
        t:assertEqual("Arkt", name)
    end)
end)

Test.test("getName falls back to generic female names when character missing", function(t)
    withFixedRandom(function()
        local name = Names.getName(Names.Gender.female, nil)
        t:assertEqual("Arla", name)
    end)
end)

Test.test("getName uses character-specific pool when available", function(t)
    withFixedRandom(function()
        local name = Names.getName(Names.Gender.male, "The Adventurer")
        t:assertEqual("Rakk", name)
    end)
end)

Test.test("getName calls math.random with the pool size", function(t)
    local receivedN
    local poolSize = #Names.names[Names.Gender.male]["The Adventurer"]
    withFixedRandom(function()
        local name = Names.getName(Names.Gender.male, "The Adventurer")
        t:assertEqual("Rakk", name)
        t:assertEqual(poolSize, receivedN)
    end, function(n)
        receivedN = n
        return 1
    end)
end)

Test.test("getName requires gender string", function(t)
    t:assertTrue(pcall(function()
        Names.getName("male")
    end))

    t:assertFalse(pcall(function()
        Names.getName(nil)
    end))
end)

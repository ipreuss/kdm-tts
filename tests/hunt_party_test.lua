---------------------------------------------------------------------------------------------------
-- HuntParty Unit Tests (kdm-gmk)
--
-- Tests for the dynamic hunt party module that replaces the static Hunt Party token
-- with scaled-down survivor figurine copies.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local HuntParty = require("Kdm/HuntParty")

---------------------------------------------------------------------------------------------------
-- Module Structure Tests
---------------------------------------------------------------------------------------------------

Test.test("HuntParty module exports expected functions", function(t)
    t:assertNotNil(HuntParty.Create, "Create function exists")
    t:assertNotNil(HuntParty.Remove, "Remove function exists")
    t:assertNotNil(HuntParty.Cleanup, "Cleanup function exists")
    t:assertNotNil(HuntParty.GetBaseObject, "GetBaseObject function exists")
end)

---------------------------------------------------------------------------------------------------
-- Formation Calculation Tests
---------------------------------------------------------------------------------------------------

Test.test("GetFormation returns centered position for 1 survivor", function(t)
    local positions = HuntParty.GetFormation(1)

    t:assertEqual(#positions, 1)
    t:assertEqual(positions[1].x, 0)
    t:assertEqual(positions[1].z, 0)
end)

Test.test("GetFormation returns side-by-side for 2 survivors", function(t)
    local positions = HuntParty.GetFormation(2)

    t:assertEqual(#positions, 2)
    t:assertEqual(positions[1].z, -0.5)
    t:assertEqual(positions[2].z, 0.5)
end)

Test.test("GetFormation returns triangle for 3 survivors", function(t)
    local positions = HuntParty.GetFormation(3)

    t:assertEqual(#positions, 3)
    -- Front position (toward monster = negative z)
    t:assertEqual(positions[1].z, -0.5)
    -- Back positions
    t:assertEqual(positions[2].z, 0.5)
    t:assertEqual(positions[3].z, 0.5)
end)

Test.test("GetFormation returns 2x2 grid for 4 survivors", function(t)
    local positions = HuntParty.GetFormation(4)

    t:assertEqual(#positions, 4)
    -- Front row
    t:assertEqual(positions[1].x, -0.5)
    t:assertEqual(positions[1].z, -0.5)
    t:assertEqual(positions[2].x, 0.5)
    t:assertEqual(positions[2].z, -0.5)
    -- Back row
    t:assertEqual(positions[3].x, -0.5)
    t:assertEqual(positions[3].z, 0.5)
    t:assertEqual(positions[4].x, 0.5)
    t:assertEqual(positions[4].z, 0.5)
end)

Test.test("GetFormation falls back to single position for invalid count", function(t)
    local positions = HuntParty.GetFormation(0)

    t:assertEqual(#positions, 1)
    t:assertEqual(positions[1].x, 0)
    t:assertEqual(positions[1].z, 0)
end)

---------------------------------------------------------------------------------------------------
-- Figurine Collection Tests
---------------------------------------------------------------------------------------------------

Test.test("CollectFigurines filters survivors with FigurineJSON", function(t)
    -- Mock survivors
    local survivorWithFigurine = {
        id = 1,
        FigurineJSON = function() return '{"Name":"Test"}' end
    }
    local survivorWithoutFigurine = {
        id = 2,
        FigurineJSON = function() return nil end
    }
    local survivors = { survivorWithFigurine, survivorWithoutFigurine }

    local collected = HuntParty.CollectFigurines(survivors)

    t:assertEqual(#collected, 1)
    t:assertEqual(collected[1].id, 1)
end)

Test.test("CollectFigurines returns empty table when no figurines", function(t)
    local survivors = {
        { id = 1, FigurineJSON = function() return nil end },
        { id = 2, FigurineJSON = function() return nil end }
    }

    local collected = HuntParty.CollectFigurines(survivors)

    t:assertEqual(#collected, 0)
end)

Test.test("CollectFigurines preserves all survivors with figurines", function(t)
    local survivors = {
        { id = 1, FigurineJSON = function() return '{"Name":"A"}' end },
        { id = 2, FigurineJSON = function() return '{"Name":"B"}' end },
        { id = 3, FigurineJSON = function() return '{"Name":"C"}' end },
        { id = 4, FigurineJSON = function() return '{"Name":"D"}' end },
    }

    local collected = HuntParty.CollectFigurines(survivors)

    t:assertEqual(#collected, 4)
end)

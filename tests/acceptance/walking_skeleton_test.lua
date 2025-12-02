---------------------------------------------------------------------------------------------------
-- Walking Skeleton: Proves acceptance test architecture is viable
--
-- This is intentionally minimal. It validates:
-- 1. TestWorld.create()/destroy() lifecycle works
-- 2. Game actions can be called
-- 3. State inspection works
-- 4. Test framework integration works
--
-- Once this passes, we can incrementally add real module integration.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")
local TestWorld = require("tests.acceptance.test_world")

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE SKELETON: TestWorld lifecycle works", function(t)
    -- Create world
    local world = TestWorld.create()
    t:assertNotNil(world, "TestWorld.create() should return world")
    
    -- Destroy should not error
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE SKELETON: milestone state is tracked", function(t)
    local world = TestWorld.create()
    
    -- Initially not reached
    t:assertFalse(world:isReached("Ethereal Culture Strain"))
    
    -- Action: reach milestone
    local ok = world:reachMilestone("Ethereal Culture Strain")
    t:assertTrue(ok, "reachMilestone should succeed")
    
    -- Inspection: state changed
    t:assertTrue(world:isReached("Ethereal Culture Strain"))
    
    -- Other milestones still not reached
    t:assertFalse(world:isReached("Giant's Strain"))
    
    world:destroy()
end)

---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE SKELETON: multiple milestones tracked independently", function(t)
    local world = TestWorld.create()
    
    world:reachMilestone("Ethereal Culture Strain")
    world:reachMilestone("Giant's Strain")
    
    t:assertTrue(world:isReached("Ethereal Culture Strain"))
    t:assertTrue(world:isReached("Giant's Strain"))
    t:assertFalse(world:isReached("Opportunist Strain"))
    
    world:destroy()
end)



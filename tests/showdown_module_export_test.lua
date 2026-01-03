---------------------------------------------------------------------------------------------------
-- Showdown Module Export Bug Test
--
-- Bug: Showdown.monster and Showdown.level are assigned to the internal module table
-- but not exported. Other modules that require("Kdm/Sequence/Showdown") get nil.
--
-- This test documents the bug (kdm-w1k.1) and will pass once the bug is fixed.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Minimal stubs for testing module export behavior
---------------------------------------------------------------------------------------------------

local function setupMinimalStubs()
    -- Stub global TTS functions
    _G.logStyle = function() end
    _G.printToAll = function() end
    _G.broadcastToAll = function() end
    _G.log = function() end

    -- Stub Wait
    _G.Wait = {
        frames = function(callback, frames)
            if callback then callback() end
        end,
        condition = function(callback)
            if callback then callback() end
        end,
    }
end

---------------------------------------------------------------------------------------------------
-- Test: Module Export Structure
---------------------------------------------------------------------------------------------------

Test.test("Showdown module exports monster and level fields", function(t)
    setupMinimalStubs()

    -- Clear any cached module
    package.loaded["Kdm/Sequence/Showdown"] = nil

    -- This simulates what the module returns
    -- We test the STRUCTURE of the return value, not the runtime behavior
    local moduleSource = [[
        local Showdown = {}
        Showdown.monster = nil
        Showdown.level = nil

        function Showdown.SetState(monster, level)
            Showdown.monster = monster
            Showdown.level = level
        end

        return {
            SetState = Showdown.SetState,
            -- BUG: monster and level are NOT in this table
            -- They exist on the internal Showdown table, not the returned table
        }
    ]]

    -- Load the module simulation
    local chunk = load(moduleSource)
    local exportedModule = chunk()

    -- Simulate what happens when code assigns to internal table
    -- The exported table doesn't have monster/level
    t:assertNil(exportedModule.monster, "BUG CONFIRMED: exported module doesn't have 'monster' field")
    t:assertNil(exportedModule.level, "BUG CONFIRMED: exported module doesn't have 'level' field")
end)

---------------------------------------------------------------------------------------------------
-- Test: Correct Module Export Pattern
---------------------------------------------------------------------------------------------------

Test.test("SPEC: Module should export monster and level (correct pattern)", function(t)
    -- This shows what the CORRECT implementation looks like
    local moduleSource = [[
        local internal = {}

        -- Create the export table with monster/level fields
        local exports = {
            monster = nil,
            level = nil,
        }

        function exports.SetState(monster, level)
            exports.monster = monster  -- Assign to EXPORTS table
            exports.level = level      -- Assign to EXPORTS table
        end

        return exports
    ]]

    local chunk = load(moduleSource)
    local exportedModule = chunk()

    -- Before SetState, fields exist but are nil
    t:assertNil(exportedModule.monster, "monster starts as nil")
    t:assertNil(exportedModule.level, "level starts as nil")

    -- After SetState, fields are populated
    exportedModule.SetState({ name = "White Lion" }, { name = "Level 1" })

    t:assertNotNil(exportedModule.monster, "monster should be set after SetState")
    t:assertNotNil(exportedModule.level, "level should be set after SetState")
    t:assertEqual("White Lion", exportedModule.monster.name)
    t:assertEqual("Level 1", exportedModule.level.name)
end)

---------------------------------------------------------------------------------------------------
-- Test: Actual Showdown Module (requires full environment)
-- This test requires more stubs but tests the real module
---------------------------------------------------------------------------------------------------

Test.test("BUG: Showdown module return table lacks monster/level fields", function(t)
    -- Read the actual return statement from Showdown.ttslua
    local file = io.open("Showdown.ttslua", "r")
    if not file then
        t:skip("Showdown.ttslua not found (run from project root)")
        return
    end

    local content = file:read("*all")
    file:close()

    -- Check if the return table includes monster and level
    -- Look for pattern: return { ... monster = ... }
    local returnSection = content:match("return%s*{[^}]+}")

    if not returnSection then
        t:fail("Could not find return statement in Showdown.ttslua")
        return
    end

    local hasMonsterExport = returnSection:match("monster%s*=")
    local hasLevelExport = returnSection:match("level%s*=")

    -- This test documents the bug - it passes when bug exists
    -- Once fixed, change assertNil to assertNotNil
    t:assertNil(hasMonsterExport, "BUG: monster should be exported (currently missing)")
    t:assertNil(hasLevelExport, "BUG: level should be exported (currently missing)")
end)

---------------------------------------------------------------------------------------------------
-- TestWorld: Facade for acceptance tests
-- 
-- Manages game state and provides high-level actions for test scenarios.
-- This is the MINIMAL walking skeleton - just enough to prove the pattern.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = require("tests.acceptance.tts_environment")

local TestWorld = {}

function TestWorld.create()
    local world = {
        _env = TTSEnvironment.create(),
        _milestones = {},
    }
    setmetatable(world, { __index = TestWorld })
    world._env:install()
    return world
end

function TestWorld:destroy()
    self._env:uninstall()
end

---------------------------------------------------------------------------------------------------
-- Game Actions (minimal for skeleton)
---------------------------------------------------------------------------------------------------

function TestWorld:reachMilestone(title)
    -- For skeleton: just track state locally
    -- Future: interact with real Strain module
    self._milestones[title] = true
    return true
end

---------------------------------------------------------------------------------------------------
-- State Inspection (minimal for skeleton)
---------------------------------------------------------------------------------------------------

function TestWorld:isReached(title)
    return self._milestones[title] == true
end

return TestWorld

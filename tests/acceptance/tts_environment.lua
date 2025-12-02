---------------------------------------------------------------------------------------------------
-- TTSEnvironment: Manages TTS stub installation for acceptance tests
--
-- This is the MINIMAL walking skeleton - only enables Check test mode.
-- Future versions will stub Wait, Physics, UI, etc.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = {}

function TTSEnvironment.create()
    local env = {
        _installed = false,
    }
    setmetatable(env, { __index = TTSEnvironment })
    return env
end

function TTSEnvironment:install()
    if self._installed then
        error("TTSEnvironment already installed - did you forget to call destroy()?")
    end
    
    -- Enable Check test mode (allows tables to pass Object checks)
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(true)
    
    self._installed = true
end

function TTSEnvironment:uninstall()
    if not self._installed then
        return -- Allow multiple uninstall calls (for safety in cleanup)
    end
    
    -- Disable Check test mode
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(false)
    
    self._installed = false
end

return TTSEnvironment

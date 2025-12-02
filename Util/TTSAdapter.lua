---------------------------------------------------------------------------------------------------
-- TTSAdapter: Interface for TTS operations
--
-- All mod code should use this adapter instead of calling TTS API directly.
-- This enables testing with a fake adapter that simulates TTS behavior.
--
-- Usage:
--   local TTSAdapter = require("Kdm/Util/TTSAdapter")
--   local adapter = TTSAdapter.Get()
--   adapter:waitFrames(10, function() ... end)
---------------------------------------------------------------------------------------------------

local TTSAdapter = {}

-- Singleton instance (swappable for tests)
local _instance = nil

---------------------------------------------------------------------------------------------------
-- Singleton management
---------------------------------------------------------------------------------------------------

function TTSAdapter.Get()
    if not _instance then
        _instance = TTSAdapter._createRealAdapter()
    end
    return _instance
end

function TTSAdapter.Set(adapter)
    _instance = adapter
end

function TTSAdapter.Reset()
    _instance = nil
end

---------------------------------------------------------------------------------------------------
-- Real adapter (production) - wraps actual TTS API
---------------------------------------------------------------------------------------------------

function TTSAdapter._createRealAdapter()
    local adapter = {}
    
    function adapter:takeFromArchive(archiveObject, params)
        return archiveObject.takeObject(params)
    end
    
    function adapter:destroyObject(object)
        if object and object.destruct then
            object.destruct()
        end
    end
    
    function adapter:putInContainer(container, object)
        if container and object then
            container.putObject(object)
        end
    end
    
    function adapter:waitFrames(count, callback)
        Wait.frames(callback, count)
    end
    
    function adapter:waitTime(seconds, callback)
        Wait.time(callback, seconds)
    end
    
    function adapter:getObjectContents(object)
        if object and object.getObjects then
            return object.getObjects()
        end
        return {}
    end
    
    function adapter:getObjectPosition(object)
        if object and object.getPosition then
            return object.getPosition()
        end
        return { x = 0, y = 0, z = 0 }
    end
    
    return adapter
end

---------------------------------------------------------------------------------------------------

return TTSAdapter

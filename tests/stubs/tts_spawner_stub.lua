---------------------------------------------------------------------------------------------------
-- Fake TTSSpawner for unit/integration tests
--
-- Provides a test double for TTSSpawner that records calls and returns configurable fake objects.
-- Used to test Archive behavior without requiring Tabletop Simulator.
---------------------------------------------------------------------------------------------------

local tts_spawner_stub = {}

---------------------------------------------------------------------------------------------------

function tts_spawner_stub.create(config)
    config = config or {}
    
    local spawner = {
        takeCalls = {},
        destroyCalls = {},
        physicsCalls = {},
    }
    
    function spawner.TakeFromArchive(archiveObject, params)
        table.insert(spawner.takeCalls, {
            archive = archiveObject,
            params = params,
        })
        
        -- Return fake object or use config handler
        if config.takeHandler then
            return config.takeHandler(archiveObject, params)
        end
        
        -- Default: return minimal fake object
        local fakeObject = {
            name = params.name or "FakeObject",
            guid = "fake-guid-" .. #spawner.takeCalls,
        }
        
        function fakeObject.getName()
            return fakeObject.name
        end
        
        function fakeObject.getGUID()
            return fakeObject.guid
        end
        
        function fakeObject.getPosition()
            return params.position or { x = 0, y = 0, z = 0 }
        end
        
        function fakeObject.destruct()
            -- no-op
        end
        
        return fakeObject
    end
    
    function spawner.PhysicsCast(params)
        table.insert(spawner.physicsCalls, params)
        return config.physicsResults or {}
    end
    
    function spawner.DestroyObject(object)
        table.insert(spawner.destroyCalls, object)
    end
    
    return spawner
end

---------------------------------------------------------------------------------------------------

return tts_spawner_stub

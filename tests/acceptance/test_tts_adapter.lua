---------------------------------------------------------------------------------------------------
-- TestTTSAdapter: Fake TTS adapter for headless acceptance testing
--
-- Simulates TTS behavior and tracks operations for test assertions.
-- Callbacks are executed immediately (synchronous) for predictable tests.
---------------------------------------------------------------------------------------------------

local TestTTSAdapter = {}
TestTTSAdapter.__index = TestTTSAdapter

function TestTTSAdapter.create()
    local adapter = {
        _spawnedCards = {},     -- Track by deck type: { ["Fighting Arts"] = { "Card1", "Card2" } }
        _takenObjects = {},     -- All takeFromArchive calls
        _destroyedObjects = {}, -- All destroyed objects
        _containerOps = {},     -- putInContainer calls
        _nextGuid = 1,
    }
    setmetatable(adapter, TestTTSAdapter)
    return adapter
end

---------------------------------------------------------------------------------------------------
-- Adapter interface implementation
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:takeFromArchive(archiveObject, params)
    local cardName = params.name or "Unknown"
    
    -- Track the operation
    table.insert(self._takenObjects, {
        archive = archiveObject,
        params = params,
        name = cardName,
    })
    
    -- Track by deck type if provided
    if params.deckType then
        self._spawnedCards[params.deckType] = self._spawnedCards[params.deckType] or {}
        table.insert(self._spawnedCards[params.deckType], cardName)
    end
    
    -- Create fake object
    local fakeObject = self:_createFakeObject(params)
    
    -- Execute callback immediately (synchronous for tests)
    if params.callback_function then
        params.callback_function(fakeObject)
    end
    
    return fakeObject
end

function TestTTSAdapter:destroyObject(object)
    table.insert(self._destroyedObjects, object)
end

function TestTTSAdapter:putInContainer(container, object)
    table.insert(self._containerOps, {
        container = container,
        object = object,
    })
end

function TestTTSAdapter:waitFrames(count, callback)
    -- Execute immediately in tests
    if callback then callback() end
end

function TestTTSAdapter:waitTime(seconds, callback)
    -- Execute immediately in tests
    if callback then callback() end
end

function TestTTSAdapter:getObjectContents(object)
    -- Return empty or mock contents
    if object and object._mockContents then
        return object._mockContents
    end
    return {}
end

function TestTTSAdapter:getObjectPosition(object)
    if object and object._position then
        return object._position
    end
    return { x = 0, y = 0, z = 0 }
end

---------------------------------------------------------------------------------------------------
-- Query methods for test assertions
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:getSpawnedCards(deckType)
    return self._spawnedCards[deckType] or {}
end

function TestTTSAdapter:getTakenObjects()
    return self._takenObjects
end

function TestTTSAdapter:getDestroyedObjects()
    return self._destroyedObjects
end

function TestTTSAdapter:wasCardSpawned(deckType, cardName)
    local cards = self._spawnedCards[deckType] or {}
    for _, name in ipairs(cards) do
        if name == cardName then
            return true
        end
    end
    return false
end

function TestTTSAdapter:spawnedCardCount(deckType)
    local cards = self._spawnedCards[deckType] or {}
    return #cards
end

---------------------------------------------------------------------------------------------------
-- Test setup helpers
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:reset()
    self._spawnedCards = {}
    self._takenObjects = {}
    self._destroyedObjects = {}
    self._containerOps = {}
    self._nextGuid = 1
end

function TestTTSAdapter:trackCardSpawn(deckType, cardName)
    self._spawnedCards[deckType] = self._spawnedCards[deckType] or {}
    table.insert(self._spawnedCards[deckType], cardName)
end

---------------------------------------------------------------------------------------------------
-- Internal helpers
---------------------------------------------------------------------------------------------------

function TestTTSAdapter:_createFakeObject(params)
    local guid = "fake-" .. self._nextGuid
    self._nextGuid = self._nextGuid + 1
    
    local name = params.name or "FakeObject"
    
    return {
        _name = name,
        _guid = guid,
        _position = params.position or { x = 0, y = 0, z = 0 },
        getName = function() return name end,
        getGUID = function() return guid end,
        getPosition = function() return params.position or { x = 0, y = 0, z = 0 } end,
        destruct = function() end,
        setLock = function() end,
        getObjects = function() return {} end,
        takeObject = function(p)
            if p and p.callback_function then
                local obj = { getName = function() return p.name or "taken" end }
                p.callback_function(obj)
                return obj
            end
            return { getName = function() return "taken" end }
        end,
        putObject = function() end,
    }
end

---------------------------------------------------------------------------------------------------

return TestTTSAdapter

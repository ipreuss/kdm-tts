---------------------------------------------------------------------------------------------------
-- Shared Test Stubs for Location Module
--
-- Provides common stubs, mocks, and helpers for testing Location-dependent code.
-- Focused on Location:Clean() raycast/boxcast testing patterns.
--
-- Uses TtsMockBase for common TTS object shape, extends with:
--   - isDestroyed() method for cleanup verification
--   - tag property for object type matching
--   - interactable property for ignore checks
---------------------------------------------------------------------------------------------------

local TtsMockBase = require("tests.support.tts_mock_base")

local LocationStubs = {}

---------------------------------------------------------------------------------------------------
-- Module Stubs
---------------------------------------------------------------------------------------------------

-- Create minimal stubs for Location module dependencies
function LocationStubs.createLocationStubs()
    return {
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Core/Console"] = { AddCommand = function() end },
        ["Kdm/Util/Container"] = {},
        ["Kdm/Util/EventManager"] = { AddHandler = function() end },
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/Location/LocationData"] = {},
        ["Kdm/Core/Log"] = { ForModule = function() return { Debugf = function() end, Errorf = function() end } end },
        ["Kdm/Location/NamedObject"] = { DEFAULT_CAST_HEIGHT = 5 },
        ["Kdm/Util/Util"] = {
            ArrayContains = function(array, value)
                for _, element in ipairs(array) do
                    if element == value then return true end
                end
                return false
            end,
            TabStr = function(t)
                if type(t) ~= "table" then return tostring(t) end
                local parts = {}
                for k, v in pairs(t) do
                    table.insert(parts, tostring(k) .. "=" .. tostring(v))
                end
                return "{" .. table.concat(parts, ", ") .. "}"
            end,
        },
    }
end

-- Execute a function with stubs in place, restoring originals after
function LocationStubs.withStubs(stubs, fn)
    local originals = {}
    for name, mod in pairs(stubs) do
        originals[name] = package.loaded[name]
        package.loaded[name] = mod
    end
    local ok, err = pcall(fn)
    for name, orig in pairs(originals) do
        package.loaded[name] = orig
    end
    if not ok then
        error(err)
    end
end

---------------------------------------------------------------------------------------------------
-- Mock Object Factories (extend TtsMockBase with Location-specific behavior)
---------------------------------------------------------------------------------------------------

-- Create a mock TTS object (Card, Figurine, etc.)
-- Extends base with: tag, interactable, isDestroyed()
function LocationStubs.createMockObject(params)
    params = params or {}
    local base = TtsMockBase.createBaseCard(params)

    -- Location-specific extensions
    base.tag = params.tag or "Card"
    base.interactable = params.interactable ~= false  -- default true
    base.isDestroyed = base._isDestroyed

    -- Override destruct to work without self parameter
    local setDestroyed = base._setDestroyed
    base.destruct = function() setDestroyed(true) end

    return base
end

-- Create a mock TTS Deck object with getObjects() for contained cards
-- Extends base with: tag, interactable, isDestroyed()
function LocationStubs.createMockDeck(params)
    params = params or {}
    local base = TtsMockBase.createBaseDeck(params)

    -- Location-specific extensions
    base.tag = "Deck"
    base.interactable = params.interactable ~= false
    base.isDestroyed = base._isDestroyed

    -- Override destruct to work without self parameter
    local setDestroyed = base._setDestroyed
    base.destruct = function() setDestroyed(true) end

    return base
end

---------------------------------------------------------------------------------------------------
-- Test Helpers
---------------------------------------------------------------------------------------------------

-- Create a fake cast function that returns specified objects as hits
function LocationStubs.createFakeCastFunc(objects)
    return function(self, params)
        local hits = {}
        for _, obj in ipairs(objects) do
            table.insert(hits, { hit_object = obj })
        end
        return hits
    end
end

---------------------------------------------------------------------------------------------------

return LocationStubs

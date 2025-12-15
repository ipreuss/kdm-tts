---------------------------------------------------------------------------------------------------
-- Shared Test Stubs for Location Module
--
-- Provides common stubs, mocks, and helpers for testing Location-dependent code.
-- Used by: location_clean_test.lua, hunt_cleanup_acceptance_test.lua
---------------------------------------------------------------------------------------------------

local LocationStubs = {}

---------------------------------------------------------------------------------------------------
-- Module Stubs
---------------------------------------------------------------------------------------------------

-- Create minimal stubs for Location module dependencies
function LocationStubs.createLocationStubs()
    return {
        ["Kdm/Util/Check"] = setmetatable({}, { __call = function() return true end }),
        ["Kdm/Console"] = { AddCommand = function() end },
        ["Kdm/Util/Container"] = {},
        ["Kdm/Util/EventManager"] = { AddHandler = function() end },
        ["Kdm/Expansion"] = { All = function() return {} end },
        ["Kdm/LocationData"] = {},
        ["Kdm/Log"] = { ForModule = function() return { Debugf = function() end, Errorf = function() end } end },
        ["Kdm/NamedObject"] = { DEFAULT_CAST_HEIGHT = 5 },
        ["Kdm/Util/Util"] = {
            ArrayContains = function(array, value)
                for _, element in ipairs(array) do
                    if element == value then return true end
                end
                return false
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
-- Mock Object Factories
---------------------------------------------------------------------------------------------------

-- Create a mock TTS object (Card, Figurine, etc.)
function LocationStubs.createMockObject(params)
    params = params or {}
    local destroyed = false
    return {
        tag = params.tag or "Card",
        interactable = params.interactable ~= false,  -- default true
        getName = function() return params.name or "Test Object" end,
        getGUID = function() return params.guid or "abc123" end,
        getGMNotes = function() return params.gmNotes or "" end,
        destruct = function() destroyed = true end,
        isDestroyed = function() return destroyed end,
    }
end

-- Create a mock TTS Deck object with getObjects() for contained cards
function LocationStubs.createMockDeck(params)
    params = params or {}
    local destroyed = false
    local containedCards = params.containedCards or {}

    return {
        tag = "Deck",
        interactable = params.interactable ~= false,
        getName = function() return params.name or "Test Deck" end,
        getGUID = function() return params.guid or "deck123" end,
        getGMNotes = function() return params.gmNotes or "" end,
        getQuantity = function() return #containedCards end,
        getObjects = function()
            local objects = {}
            for i, card in ipairs(containedCards) do
                table.insert(objects, {
                    index = i - 1,
                    name = card.name or "Card " .. i,
                    gm_notes = card.gmNotes or "",
                })
            end
            return objects
        end,
        destruct = function() destroyed = true end,
        isDestroyed = function() return destroyed end,
    }
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

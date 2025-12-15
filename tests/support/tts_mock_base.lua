---------------------------------------------------------------------------------------------------
-- Base TTS Mock Factory
--
-- Provides the common shape for TTS object mocks. Other test stub modules can use
-- these base factories and extend them with test-specific behavior.
--
-- Used by:
--   - tests/support/location_stubs.lua (adds isDestroyed(), tag, interactable)
--   - tests/stubs/tts_objects.lua (adds takeObject, putObject, states)
---------------------------------------------------------------------------------------------------

local TtsMockBase = {}

---------------------------------------------------------------------------------------------------
-- Base Object Factory
---------------------------------------------------------------------------------------------------

-- Create base TTS object with common properties and methods
-- Returns a table that can be extended with additional fields/methods
function TtsMockBase.createBaseObject(params)
    params = params or {}
    local destroyed = false

    return {
        -- Common state
        _destroyed = destroyed,
        _params = params,

        -- Common methods (TTS API shape)
        getName = function() return params.name or "Test Object" end,
        getGUID = function() return params.guid or "test-guid" end,
        getGMNotes = function() return params.gmNotes or params.gm_notes or "" end,
        getPosition = function() return params.position or { x = 0, y = 0, z = 0 } end,

        destruct = function(self)
            if type(self) == "table" and self._destroyed ~= nil then
                self._destroyed = true
            else
                destroyed = true
            end
        end,

        -- Accessor for destroyed state (modules can wrap this differently)
        _isDestroyed = function() return destroyed end,
        _setDestroyed = function(val) destroyed = val end,
    }
end

---------------------------------------------------------------------------------------------------
-- Base Deck Factory
---------------------------------------------------------------------------------------------------

-- Create base TTS Deck with getObjects() support
function TtsMockBase.createBaseDeck(params)
    params = params or {}
    local base = TtsMockBase.createBaseObject({
        name = params.name or "Test Deck",
        guid = params.guid or "deck-guid",
        gmNotes = params.gmNotes or "",
        position = params.position,
    })

    local containedCards = params.containedCards or params.objects or {}

    -- Deck-specific methods
    base.getQuantity = function() return #containedCards end

    base.getObjects = function()
        local objects = {}
        for i, card in ipairs(containedCards) do
            table.insert(objects, {
                index = card.index or (i - 1),
                name = card.name or "Card " .. i,
                gm_notes = card.gmNotes or card.gm_notes or "",
            })
        end
        return objects
    end

    -- Store for extension
    base._containedCards = containedCards

    return base
end

---------------------------------------------------------------------------------------------------
-- Base Card Factory
---------------------------------------------------------------------------------------------------

-- Create base TTS Card
function TtsMockBase.createBaseCard(params)
    params = params or {}
    local base = TtsMockBase.createBaseObject({
        name = params.name or "Test Card",
        guid = params.guid or "card-guid",
        gmNotes = params.gmNotes or params.gm_notes or "",
        position = params.position,
    })

    return base
end

---------------------------------------------------------------------------------------------------

return TtsMockBase

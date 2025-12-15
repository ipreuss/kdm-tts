-- Shared TTS object stubs for testing
-- Provides mock implementations of TTS game objects (Deck, Card, Container, etc.)
--
-- Uses TtsMockBase for common TTS object shape, extends with:
--   - takeObject/putObject for deck operations
--   - state support for cards
--   - Container and Archive patterns

local TtsMockBase = require("tests.support.tts_mock_base")

local tts_objects = {}

---------------------------------------------------------------------------------------------------
-- Deck Stub
---------------------------------------------------------------------------------------------------

function tts_objects.deck(options)
    options = options or {}
    local deckObjects = options.objects or {}
    local insertedCards = {}

    -- Use base deck and extend with archive/container operations
    local base = TtsMockBase.createBaseDeck({
        name = options.name,
        guid = options.guid,
        position = options.position,
        containedCards = deckObjects,
    })

    local deck = {
        destroyed = false,
        insertedCards = insertedCards,
        lastTakeParams = nil,
        __objects = deckObjects,  -- For Container compatibility
    }

    -- Copy base methods
    deck.getName = base.getName
    deck.getPosition = base.getPosition
    deck.getObjects = function() return deckObjects end  -- Keep original format

    -- Set __takeHandler for Container compatibility
    if options.takeHandler then
        deck.__takeHandler = options.takeHandler
    end

    deck.takeObject = function(params)
        deck.lastTakeParams = params
        local result
        if options.takeHandler then
            result = options.takeHandler(params)
        else
            -- Default: return first matching object
            for _, obj in ipairs(deckObjects) do
                if not params.index or obj.index == params.index then
                    result = { name = obj.name, gm_notes = obj.gm_notes }
                    break
                end
            end
        end
        -- If callback_function is provided, invoke it with the result (TTS async pattern)
        if params.callback_function and result then
            params.callback_function(result)
        end
        return result
    end

    deck.putObject = function(card)
        table.insert(insertedCards, card)
    end

    deck.destruct = function()
        deck.destroyed = true
    end

    deck.reset = function()
        if options.resetHandler then
            options.resetHandler()
        end
    end

    return deck
end

---------------------------------------------------------------------------------------------------
-- Card Stub (with state support)
---------------------------------------------------------------------------------------------------

function tts_objects.card(options)
    options = options or {}

    -- Use base card and extend with state support
    local base = TtsMockBase.createBaseCard({
        name = options.name,
        guid = options.guid,
        gmNotes = options.gm_notes,
        position = options.position,
    })

    local card = {
        name = options.name or "Test Card",
        gm_notes = options.gm_notes or "",
        currentState = options.currentState or 1,
        destroyed = false,
    }

    -- Use base methods where applicable
    card.getGUID = base.getGUID
    card.getPosition = base.getPosition
    card.getGMNotes = function() return card.gm_notes end

    card.getName = function()
        -- If states are defined, return name based on current state
        if options.states then
            for _, state in ipairs(options.states) do
                if state.id == card.currentState then
                    return state.name
                end
            end
        end
        return card.name
    end

    card.getStates = function()
        return options.states or {}
    end

    card.setState = function(stateId)
        card.currentState = stateId
        if options.onStateChange then
            options.onStateChange(stateId)
        end
        return card
    end

    card.setRotation = function(rotation)
        card.rotation = rotation
    end

    card.destruct = function()
        card.destroyed = true
    end

    return card
end

---------------------------------------------------------------------------------------------------
-- Container Stub
---------------------------------------------------------------------------------------------------

function tts_objects.container(deckObject)
    local container = {
        deckObject = deckObject,
        deletedCards = {},
    }
    
    container.Objects = function()
        if deckObject.getObjects then
            return deckObject.getObjects()
        end
        return {}
    end
    
    container.Delete = function(params)
        local cardNames = params
        if type(params) == "table" and not params[1] then
            -- Named parameter format
            cardNames = params.cardNames or params
        end
        for _, name in ipairs(cardNames) do
            table.insert(container.deletedCards, name)
        end
    end
    
    return container
end

---------------------------------------------------------------------------------------------------
-- Archive Object Stub
---------------------------------------------------------------------------------------------------

function tts_objects.archiveObject(options)
    options = options or {}
    
    local archive = {
        resetCalled = false,
        takeParams = {},
    }
    
    archive.takeObject = function(params)
        table.insert(archive.takeParams, params)
        if options.takeHandler then
            return options.takeHandler(params)
        end
        return tts_objects.deck(options.deckOptions or {})
    end
    
    archive.reset = function()
        archive.resetCalled = true
        if options.onReset then
            options.onReset()
        end
    end
    
    return archive
end

---------------------------------------------------------------------------------------------------
-- Staging Position Helper
---------------------------------------------------------------------------------------------------

function tts_objects.stagingPosition(base)
    base = base or { x = -150, y = 60, z = 120 }
    return {
        x = base.x + 5,
        y = base.y,
        z = base.z,
    }
end

---------------------------------------------------------------------------------------------------
-- Create deck with objects helper
---------------------------------------------------------------------------------------------------

function tts_objects.deckWithCards(cardNames, options)
    options = options or {}
    local deckObjects = {}
    
    for i, name in ipairs(cardNames) do
        table.insert(deckObjects, {
            name = name,
            gm_notes = options.gm_notes or "Fighting Arts",
            index = i,
        })
    end
    
    return tts_objects.deck({
        name = options.deckName or "Test Deck",
        position = options.position,
        objects = deckObjects,
        takeHandler = options.takeHandler,
        resetHandler = options.resetHandler,
    })
end

return tts_objects

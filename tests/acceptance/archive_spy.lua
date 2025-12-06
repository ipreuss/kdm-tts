---------------------------------------------------------------------------------------------------
-- ArchiveSpy: Intercepts archive module calls for acceptance testing
--
-- Records all archive operations so tests can verify real execution code
-- calls the correct archive methods with correct arguments.
---------------------------------------------------------------------------------------------------

local ArchiveSpy = {}

function ArchiveSpy.create()
    local spy = {
        _calls = {
            fightingArtsAdd = {},
            fightingArtsRemove = {},
            verminAdd = {},
            verminRemove = {},
            trashAdd = {},
            trashRemove = {},
            basicResourcesAdd = {},
            basicResourcesRemove = {},
            disordersAdd = {},
            disordersRemove = {},
            severeInjuriesAdd = {},
            severeInjuriesRemove = {},
            strangeResourcesAdd = {},
            strangeResourcesRemove = {},
            timelineSchedule = {},
            timelineRemove = {},
            archiveTake = {},
            deckCreated = {},    -- NEW: tracks deck creation via CreateDeckFromSources
            deckShuffle = {},    -- NEW: tracks shuffle calls on decks
        },
    }
    setmetatable(spy, { __index = ArchiveSpy })
    return spy
end

function ArchiveSpy:createArchiveStub()
    local spy = self

    -- Create a deck stub that tracks shuffle calls
    local function createDeckStub(deckName)
        return {
            name = deckName,
            type = "Deck",
            getObjects = function() return {} end,
            getName = function() return deckName end,
            setName = function() end,
            setGMNotes = function() end,
            getGMNotes = function() return deckName end,
            getPosition = function() return { x = 0, y = 0, z = 0 } end,
            setPosition = function() end,
            setPositionSmooth = function() end,
            getRotation = function() return { x = 0, y = 0, z = 0 } end,
            setRotation = function() end,
            destruct = function() end,
            destroy = function() end,
            setLock = function() end,
            clone = function() return createDeckStub(deckName) end,
            shuffle = function()
                table.insert(spy._calls.deckShuffle, { name = deckName })
            end,
            putObject = function(obj) end,
            takeObject = function(params)
                return createDeckStub(params and params.name or "card")
            end,
            getQuantity = function() return 10 end,
        }
    end

    -- Create a container stub that wraps deck operations
    local function createContainerStub(deckName)
        local deckStub = createDeckStub(deckName)
        return {
            Object = function() return deckStub end,
            Shuffle = function()
                table.insert(spy._calls.deckShuffle, { name = deckName })
            end,
            Delete = function() end,
            Take = function() return {} end,
        }
    end

    return {
        Take = function(params)
            table.insert(spy._calls.archiveTake, { name = params.name, type = params.type })
            return createDeckStub(params.name or params.type)
        end,
        Clean = function() end,
        TakeFromDeck = function(params)
            -- For fighting arts spawned from Strain Rewards deck
            table.insert(spy._calls.archiveTake, { name = params.name, type = params.cardType, source = "deck" })
            return {}
        end,
        CreateDeckFromSources = function(params)
            table.insert(spy._calls.deckCreated, {
                name = params.name,
                type = params.type,
                sources = params.sources,
            })
            return createContainerStub(params.name)
        end,
        ArchiveSource = function(name, type)
            return { name = name, type = type, source = "Archive" }
        end,
        CreateAllGearDeck = function() end,
    }
end

function ArchiveSpy:createFightingArtsArchiveStub()
    local spy = self
    return {
        REWARD_DECK_NAME = "Strain Rewards",
        REWARD_DECK_TYPE = "Rewards",
        REWARD_DECK_STAGING_POSITION = { x = -150, y = 60, z = 120 },
        FIGHTING_ART_TYPE = "Fighting Arts",
        FIGHTING_ART_LOCATION = "Fighting Arts",
        FIGHTING_ART_ARCHIVE = "Fighting Arts Archive",
        AddCard = function(cardName, onComplete)
            table.insert(spy._calls.fightingArtsAdd, { card = cardName })
            -- Call onComplete to chain spawn consequences (disorder/injury/resource)
            if onComplete then onComplete() end
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.fightingArtsRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createVerminArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName)
            table.insert(spy._calls.verminAdd, { card = cardName })
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.verminRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createBasicResourcesArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName)
            table.insert(spy._calls.basicResourcesAdd, { card = cardName })
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.basicResourcesRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createDisordersArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName)
            table.insert(spy._calls.disordersAdd, { card = cardName })
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.disordersRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createSevereInjuriesArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName)
            table.insert(spy._calls.severeInjuriesAdd, { card = cardName })
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.severeInjuriesRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createStrangeResourcesArchiveStub()
    local spy = self
    return {
        AddCard = function(cardName)
            table.insert(spy._calls.strangeResourcesAdd, { card = cardName })
            return true
        end,
        RemoveCard = function(cardName)
            table.insert(spy._calls.strangeResourcesRemove, { card = cardName })
            return true
        end,
    }
end

function ArchiveSpy:createTrashStub()
    local spy = self
    return {
        AddCard = function(cardName, cardType, deckLocation)
            table.insert(spy._calls.trashAdd, { card = cardName, type = cardType })
            return true
        end,
        RemoveCard = function(cardName, cardType, deckLocation)
            table.insert(spy._calls.trashRemove, { card = cardName, type = cardType })
            return true
        end,
    }
end

function ArchiveSpy:createTimelineStub(getCurrentYear)
    local spy = self
    return {
        ScheduleEvent = function(event)
            local currentYear = getCurrentYear and getCurrentYear() or 1
            local targetYear = currentYear + (event.offset or 1)
            table.insert(spy._calls.timelineSchedule, {
                event = event,
                year = targetYear,
            })
            return true
        end,
        RemoveEventByName = function(name, eventType)
            table.insert(spy._calls.timelineRemove, { name = name, type = eventType })
            return true
        end,
        Import = function(data) end,
        RefreshSettlementEventSearchFromDeck = function() end,
    }
end

---------------------------------------------------------------------------------------------------
-- Additional module stubs for Campaign.Import
---------------------------------------------------------------------------------------------------

function ArchiveSpy:createShowdownStub()
    return {
        Clean = function() end,
    }
end

function ArchiveSpy:createHuntStub()
    return {
        Clean = function() end,
        Import = function(data) end,
    }
end

function ArchiveSpy:createExpansionStub()
    return {
        SetEnabled = function(enabledByName) end,
        SetUnlockedMode = function(mode) end,
        All = function() return {} end,
    }
end

function ArchiveSpy:createRulesStub()
    return {
        createRulebookButtons = function() end,
    }
end

function ArchiveSpy:createLocationStub()
    local locationStub = {
        Position = function() return { x = 0, y = 0, z = 0 } end,
        Center = function() return { x = 0, y = 0, z = 0 } end,
        BoxClean = function(options) return {} end,
    }
    return {
        Get = function(name)
            return locationStub
        end,
    }
end

function ArchiveSpy:createNamedObjectStub()
    local spy = self
    -- Create a full deck stub with all needed methods
    local function createFullDeckStub(deckName)
        local stub
        stub = {
            name = deckName,
            type = "Deck",
            getObjects = function() return {} end,
            getName = function() return deckName end,
            setName = function() end,
            setGMNotes = function() end,
            getGMNotes = function() return deckName end,
            getPosition = function() return { x = 0, y = 0, z = 0 } end,
            setPosition = function() end,
            setPositionSmooth = function() end,
            getRotation = function() return { x = 0, y = 0, z = 0 } end,
            setRotation = function() end,
            destruct = function() end,
            destroy = function() end,
            setLock = function() end,
            clone = function() return createFullDeckStub(deckName) end,
            shuffle = function()
                table.insert(spy._calls.deckShuffle, { name = deckName })
            end,
            putObject = function(obj) end,
            takeObject = function(params)
                return createFullDeckStub(params and params.name or "card")
            end,
            getQuantity = function() return 10 end,
        }
        return stub
    end

    return {
        Get = function(name)
            return {
                reset = function() end,
                putObject = function(obj) end,
                takeObject = function(params)
                    -- Return full deck stub so Container can wrap it
                    local deckName = name:gsub(" Archive$", "")
                    return createFullDeckStub(deckName)
                end,
            }
        end,
    }
end

function ArchiveSpy:createContainerModuleStub()
    local spy = self
    return function(object)
        local containerName = object and object.getName and object.getName() or "unknown"
        return {
            Object = function() return object end,
            Shuffle = function()
                table.insert(spy._calls.deckShuffle, { name = containerName })
            end,
            Delete = function(items) end,
            Take = function(params)
                return {
                    getName = function() return params.name end,
                    getPosition = function() return params.position or { x = 0, y = 0, z = 0 } end,
                }
            end,
        }
    end
end

function ArchiveSpy:createSurvivorStub()
    return {
        Import = function(data) end,
        Survivors = function() return {} end,
        SpawnSurvivorBox = function(survivor, location) end,
    }
end

function ArchiveSpy:createCampaignMigrationsStub()
    return {
        Apply = function(data, targetVersion)
            data.version = targetVersion
        end,
    }
end

function ArchiveSpy:createWaitStub()
    return {
        frames = function(callback, frames)
            -- Execute callback immediately in tests
            callback()
        end,
        time = function(callback, seconds)
            callback()
        end,
    }
end

function ArchiveSpy:createPlayerStub()
    return {
        Players = function()
            return { {}, {}, {}, {} }  -- 4 dummy players
        end,
    }
end

function ArchiveSpy:createTrashStubWithImport()
    local spy = self
    return {
        AddCard = function(cardName, cardType, deckLocation)
            table.insert(spy._calls.trashAdd, { card = cardName, type = cardType })
            return true
        end,
        RemoveCard = function(cardName, cardType, deckLocation)
            table.insert(spy._calls.trashRemove, { card = cardName, type = cardType })
            return true
        end,
        IsInTrash = function(name, type)
            return false
        end,
        Import = function(data) end,
    }
end

---------------------------------------------------------------------------------------------------
-- Query methods for assertions
---------------------------------------------------------------------------------------------------

function ArchiveSpy:fightingArtAdded(cardName)
    for _, call in ipairs(self._calls.fightingArtsAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:fightingArtsAddedCount()
    return #self._calls.fightingArtsAdd
end

function ArchiveSpy:fightingArtRemoved(cardName)
    for _, call in ipairs(self._calls.fightingArtsRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:verminAdded(cardName)
    for _, call in ipairs(self._calls.verminAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:verminRemoved(cardName)
    for _, call in ipairs(self._calls.verminRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:trashAdded(cardName)
    for _, call in ipairs(self._calls.trashAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:trashRemoved(cardName)
    for _, call in ipairs(self._calls.trashRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:basicResourceAdded(cardName)
    for _, call in ipairs(self._calls.basicResourcesAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:basicResourceRemoved(cardName)
    for _, call in ipairs(self._calls.basicResourcesRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:disorderAdded(cardName)
    for _, call in ipairs(self._calls.disordersAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:disorderRemoved(cardName)
    for _, call in ipairs(self._calls.disordersRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:severeInjuryAdded(cardName)
    for _, call in ipairs(self._calls.severeInjuriesAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:severeInjuryRemoved(cardName)
    for _, call in ipairs(self._calls.severeInjuriesRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:strangeResourceAdded(cardName)
    for _, call in ipairs(self._calls.strangeResourcesAdd) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:strangeResourceRemoved(cardName)
    for _, call in ipairs(self._calls.strangeResourcesRemove) do
        if call.card == cardName then return true end
    end
    return false
end

function ArchiveSpy:timelineEventScheduled(eventName, year)
    for _, call in ipairs(self._calls.timelineSchedule) do
        if call.event and call.event.name == eventName then
            if year == nil or call.year == year then
                return true
            end
        end
    end
    return false
end

function ArchiveSpy:timelineEventRemoved(eventName)
    for _, call in ipairs(self._calls.timelineRemove) do
        if call.name == eventName then return true end
    end
    return false
end

function ArchiveSpy:cardSpawned(cardName, cardType)
    for _, call in ipairs(self._calls.archiveTake) do
        if call.name == cardName and (cardType == nil or call.type == cardType) then
            return true
        end
    end
    return false
end

function ArchiveSpy:deckCreated(deckName)
    for _, call in ipairs(self._calls.deckCreated) do
        if call.name == deckName then
            return true
        end
    end
    return false
end

function ArchiveSpy:deckWasShuffled(deckName)
    for _, call in ipairs(self._calls.deckShuffle) do
        if call.name == deckName then
            return true
        end
    end
    return false
end

function ArchiveSpy:reset()
    for key, _ in pairs(self._calls) do
        self._calls[key] = {}
    end
end

return ArchiveSpy

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
            timelineSchedule = {},
            timelineRemove = {},
        },
    }
    setmetatable(spy, { __index = ArchiveSpy })
    return spy
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
            -- Don't call onComplete - it triggers SpawnFightingArtForSurvivor which needs TTS
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

function ArchiveSpy:reset()
    for key, _ in pairs(self._calls) do
        self._calls[key] = {}
    end
end

return ArchiveSpy

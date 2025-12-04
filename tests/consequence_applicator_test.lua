---------------------------------------------------------------------------------------------------
-- ConsequenceApplicator Unit Tests
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

local function createFakeDeps()
    return {
        FightingArtsArchive = {
            AddCard = function(name, cb) return true end,
            RemoveCard = function(name) return true end,
        },
        VerminArchive = {
            AddCard = function(name) return true end,
            RemoveCard = function(name) return true end,
        },
        BasicResourcesArchive = {
            AddCard = function(name) return true end,
            RemoveCard = function(name) return true end,
        },
        Trash = {
            AddCard = function(name, t, l) return true end,
            RemoveCard = function(name, t, l) return true end,
        },
        Timeline = {
            ScheduleEvent = function(e) return true end,
            RemoveEventByName = function(n, t) return true end,
        },
    }
end

---------------------------------------------------------------------------------------------------
-- Apply Operations
---------------------------------------------------------------------------------------------------

Test.test("ApplyFightingArt: calls FightingArtsArchive.AddCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.FightingArtsArchive.AddCard = function(name, cb)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.ApplyFightingArt("Ethereal Pact")
    
    t:assertEqual("Ethereal Pact", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("ApplyFightingArt: invokes callback", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local callbackInvoked = false
    local capturedCallback = nil
    local deps = createFakeDeps()
    deps.FightingArtsArchive.AddCard = function(name, cb)
        capturedCallback = cb
        return true
    end
    CA.SetDeps(deps)
    
    CA.ApplyFightingArt("Ethereal Pact", function() callbackInvoked = true end)
    
    t:assertNotNil(capturedCallback, "Callback should be passed to AddCard")
    capturedCallback()
    t:assertTrue(callbackInvoked, "Callback should be invoked when called")
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("ApplyVermin: calls VerminArchive.AddCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.VerminArchive.AddCard = function(name)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.ApplyVermin("Fiddler Crab Spider")
    
    t:assertEqual("Fiddler Crab Spider", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("ApplyTimelineEvent: calls Timeline.ScheduleEvent", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.Timeline.ScheduleEvent = function(event)
        calledWith = event
        return true
    end
    CA.SetDeps(deps)
    
    local event = { name = "Acid Storm", year = 5, type = "SettlementEvent" }
    local result = CA.ApplyTimelineEvent(event)
    
    t:assertEqual(event, calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("TrashSettlementEvent: calls Trash.AddCard with correct params", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledName, calledType, calledLocation = nil, nil, nil
    local deps = createFakeDeps()
    deps.Trash.AddCard = function(name, cardType, location)
        calledName = name
        calledType = cardType
        calledLocation = location
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.TrashSettlementEvent("Heat Wave")
    
    t:assertEqual("Heat Wave", calledName)
    t:assertEqual("Settlement Events", calledType)
    t:assertEqual("Settlement Events", calledLocation)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("AddBasicResource: calls BasicResourcesArchive.AddCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.BasicResourcesArchive.AddCard = function(name)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.AddBasicResource("Lump of Atnas")
    
    t:assertEqual("Lump of Atnas", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------
-- Remove Operations
---------------------------------------------------------------------------------------------------

Test.test("RemoveFightingArt: calls FightingArtsArchive.RemoveCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.FightingArtsArchive.RemoveCard = function(name)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.RemoveFightingArt("Ethereal Pact")
    
    t:assertEqual("Ethereal Pact", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("RemoveVermin: calls VerminArchive.RemoveCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.VerminArchive.RemoveCard = function(name)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.RemoveVermin("Fiddler Crab Spider")
    
    t:assertEqual("Fiddler Crab Spider", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("RemoveTimelineEvent: calls Timeline.RemoveEventByName", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledName, calledType = nil, nil
    local deps = createFakeDeps()
    deps.Timeline.RemoveEventByName = function(name, eventType)
        calledName = name
        calledType = eventType
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.RemoveTimelineEvent("Acid Storm", "SettlementEvent")
    
    t:assertEqual("Acid Storm", calledName)
    t:assertEqual("SettlementEvent", calledType)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("RestoreSettlementEvent: calls Trash.RemoveCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledName, calledType, calledLocation = nil, nil, nil
    local deps = createFakeDeps()
    deps.Trash.RemoveCard = function(name, cardType, location)
        calledName = name
        calledType = cardType
        calledLocation = location
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.RestoreSettlementEvent("Heat Wave")
    
    t:assertEqual("Heat Wave", calledName)
    t:assertEqual("Settlement Events", calledType)
    t:assertEqual("Settlement Events", calledLocation)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("RemoveBasicResource: calls BasicResourcesArchive.RemoveCard", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local calledWith = nil
    local deps = createFakeDeps()
    deps.BasicResourcesArchive.RemoveCard = function(name)
        calledWith = name
        return true
    end
    CA.SetDeps(deps)
    
    local result = CA.RemoveBasicResource("Lump of Atnas")
    
    t:assertEqual("Lump of Atnas", calledWith)
    t:assertTrue(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------
-- Error Handling
---------------------------------------------------------------------------------------------------

Test.test("ApplyVermin: returns false on failure", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local deps = createFakeDeps()
    deps.VerminArchive.AddCard = function(name)
        return false
    end
    CA.SetDeps(deps)
    
    local result = CA.ApplyVermin("Fiddler Crab Spider")
    
    t:assertFalse(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

---------------------------------------------------------------------------------------------------

Test.test("ApplyTimelineEvent: returns false on failure", function(t)
    package.loaded["Kdm/ConsequenceApplicator"] = nil
    local CA = require("Kdm/ConsequenceApplicator")
    
    local deps = createFakeDeps()
    deps.Timeline.ScheduleEvent = function(event)
        return false
    end
    CA.SetDeps(deps)
    
    local event = { name = "Acid Storm", year = 5, type = "SettlementEvent" }
    local result = CA.ApplyTimelineEvent(event)
    
    t:assertFalse(result)
    
    CA.ResetDeps()
    package.loaded["Kdm/ConsequenceApplicator"] = nil
end)

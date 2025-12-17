---------------------------------------------------------------------------------------------------
-- EventManager Characterization Tests
--
-- These tests document the actual behavior of EventManager before modifying it.
-- They ensure any refactoring preserves the existing contract.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

-- Fresh EventManager for each test (avoid cross-test pollution)
local function freshEventManager()
    package.loaded["Kdm/Util/EventManager"] = nil
    package.loaded["Kdm/Util/Check"] = nil

    -- Minimal Check stub
    package.loaded["Kdm/Util/Check"] = {
        Str = function(v) return type(v) == "string" end,
        Func = function(v) return type(v) == "function" end,
    }

    return require("Kdm/Util/EventManager")
end

---------------------------------------------------------------------------------------------------
-- AddHandler: Basic Registration
---------------------------------------------------------------------------------------------------

Test.test("AddHandler registers handler for custom event", function(t)
    local EventManager = freshEventManager()
    local called = false

    EventManager.AddHandler("testEvent", function()
        called = true
    end)

    -- Trigger via FireEvent (internal events)
    EventManager.FireEvent("testEvent")

    t:assertTrue(called, "Handler should be called via FireEvent")
end)

Test.test("AddHandler allows multiple handlers for same event", function(t)
    local EventManager = freshEventManager()
    local calls = {}

    EventManager.AddHandler("testEvent", function()
        table.insert(calls, "first")
    end)
    EventManager.AddHandler("testEvent", function()
        table.insert(calls, "second")
    end)

    EventManager.FireEvent("testEvent")

    t:assertEqual(2, #calls, "Both handlers should be called")
    t:assertEqual("first", calls[1])
    t:assertEqual("second", calls[2])
end)

---------------------------------------------------------------------------------------------------
-- AddHandler: Argument Passing
---------------------------------------------------------------------------------------------------

Test.test("Handler receives all arguments passed to event", function(t)
    local EventManager = freshEventManager()
    local receivedArgs = nil

    EventManager.AddHandler("testEvent", function(a, b, c)
        receivedArgs = {a, b, c}
    end)

    EventManager.FireEvent("testEvent", "arg1", "arg2", "arg3")

    t:assertNotNil(receivedArgs)
    t:assertEqual("arg1", receivedArgs[1])
    t:assertEqual("arg2", receivedArgs[2])
    t:assertEqual("arg3", receivedArgs[3])
end)

Test.test("Handler receives nil arguments correctly", function(t)
    local EventManager = freshEventManager()
    local receivedArgs = nil
    local argCount = 0

    EventManager.AddHandler("testEvent", function(a, b, c)
        receivedArgs = {a, b, c}
        -- Count actual args including nils
        if a ~= nil then argCount = argCount + 1 end
        if b ~= nil then argCount = argCount + 1 end
        if c ~= nil then argCount = argCount + 1 end
    end)

    EventManager.FireEvent("testEvent", "first", nil, "third")

    t:assertEqual("first", receivedArgs[1])
    t:assertNil(receivedArgs[2], "nil should be preserved")
    t:assertEqual("third", receivedArgs[3])
end)

---------------------------------------------------------------------------------------------------
-- AddHandler: Global Handler Wrapping (TTS events)
---------------------------------------------------------------------------------------------------

Test.test("AddHandler wraps existing global function", function(t)
    local EventManager = freshEventManager()
    local globalCalled = false
    local handlerCalled = false

    -- Simulate existing TTS global handler
    _G["onTestGlobal"] = function()
        globalCalled = true
    end

    EventManager.AddHandler("onTestGlobal", function()
        handlerCalled = true
    end)

    -- Call the wrapped global (simulates TTS calling the event)
    _G["onTestGlobal"]()

    t:assertTrue(globalCalled, "Original global should still be called")
    t:assertTrue(handlerCalled, "Added handler should be called")

    -- Cleanup
    _G["onTestGlobal"] = nil
end)

Test.test("Global handler receives arguments", function(t)
    local EventManager = freshEventManager()
    local globalArgs = nil
    local handlerArgs = nil

    _G["onTestGlobal2"] = function(a, b)
        globalArgs = {a, b}
    end

    EventManager.AddHandler("onTestGlobal2", function(a, b)
        handlerArgs = {a, b}
    end)

    _G["onTestGlobal2"]("player", "object")

    t:assertEqual("player", globalArgs[1])
    t:assertEqual("object", globalArgs[2])
    t:assertEqual("player", handlerArgs[1])
    t:assertEqual("object", handlerArgs[2])

    _G["onTestGlobal2"] = nil
end)

---------------------------------------------------------------------------------------------------
-- AddHandler: Return Value Chaining
---------------------------------------------------------------------------------------------------

Test.test("Handler receives previous return value as last argument", function(t)
    local EventManager = freshEventManager()
    local firstReturnSeen = nil

    _G["onTestReturn"] = function()
        return "globalResult"
    end

    EventManager.AddHandler("onTestReturn", function(prevReturn)
        firstReturnSeen = prevReturn
        return "handler1Result"
    end)

    local finalResult = _G["onTestReturn"]()

    t:assertEqual("globalResult", firstReturnSeen, "Handler should see global's return value")
    t:assertEqual("handler1Result", finalResult, "Final return should be last handler's return")

    _G["onTestReturn"] = nil
end)

Test.test("Multiple handlers chain return values", function(t)
    local EventManager = freshEventManager()
    local handler1Saw = nil
    local handler2Saw = nil

    _G["onTestChain"] = function()
        return "global"
    end

    EventManager.AddHandler("onTestChain", function(prevReturn)
        handler1Saw = prevReturn
        return "handler1"
    end)

    EventManager.AddHandler("onTestChain", function(prevReturn)
        handler2Saw = prevReturn
        return "handler2"
    end)

    local finalResult = _G["onTestChain"]()

    t:assertEqual("global", handler1Saw, "First handler sees global result")
    t:assertEqual("handler1", handler2Saw, "Second handler sees first handler's result")
    t:assertEqual("handler2", finalResult, "Final result is last handler's return")

    _G["onTestChain"] = nil
end)

---------------------------------------------------------------------------------------------------
-- AddHandler: Combined args + return value
---------------------------------------------------------------------------------------------------

Test.test("Handler receives both original args and return value", function(t)
    local EventManager = freshEventManager()
    local receivedArgs = nil

    _G["onTestCombined"] = function(arg1, arg2)
        return "globalReturn"
    end

    EventManager.AddHandler("onTestCombined", function(arg1, arg2, prevReturn)
        receivedArgs = {arg1, arg2, prevReturn}
    end)

    _G["onTestCombined"]("first", "second")

    t:assertEqual("first", receivedArgs[1], "Should receive first arg")
    t:assertEqual("second", receivedArgs[2], "Should receive second arg")
    t:assertEqual("globalReturn", receivedArgs[3], "Should receive return value as last arg")

    _G["onTestCombined"] = nil
end)

---------------------------------------------------------------------------------------------------
-- FireEvent: Internal Events
---------------------------------------------------------------------------------------------------

Test.test("FireEvent calls handlers without global wrapper", function(t)
    local EventManager = freshEventManager()
    local called = false

    EventManager.AddHandler("internalEvent", function()
        called = true
    end)

    -- FireEvent doesn't go through _G
    EventManager.FireEvent("internalEvent")

    t:assertTrue(called)
end)

Test.test("FireEvent passes arguments to handlers", function(t)
    local EventManager = freshEventManager()
    local receivedArgs = nil

    EventManager.AddHandler("internalEvent", function(a, b, c)
        receivedArgs = {a, b, c}
    end)

    EventManager.FireEvent("internalEvent", 1, 2, 3)

    t:assertEqual(1, receivedArgs[1])
    t:assertEqual(2, receivedArgs[2])
    t:assertEqual(3, receivedArgs[3])
end)

---------------------------------------------------------------------------------------------------
-- Edge Cases
---------------------------------------------------------------------------------------------------

Test.test("Handler with no arguments works", function(t)
    local EventManager = freshEventManager()
    local called = false

    EventManager.AddHandler("noArgsEvent", function()
        called = true
    end)

    EventManager.FireEvent("noArgsEvent")

    t:assertTrue(called)
end)

Test.test("Event with no global handler works", function(t)
    local EventManager = freshEventManager()
    local called = false

    -- No _G["customEvent"] exists
    EventManager.AddHandler("customEvent", function()
        called = true
    end)

    -- Call through the created global
    _G["customEvent"]()

    t:assertTrue(called)

    _G["customEvent"] = nil
end)

local Test = require("tests.framework")
local CircularArray = require("Kdm/Util/CircularArray")

-- Direct test of the addToHistory logic pattern
-- The actual function lives in Rules.ttslua but we test the core behavior here

-- Reimplementation of addToHistory with the bug (for demonstration)
local function addToHistory_buggy(history, skipNextHistory, rules, state)
    if skipNextHistory then
        return false, false  -- skipped, skipReset
    end
    local top = history:Top()  -- BUG: crashes when empty
    if top and top[1] == rules and top[2] == state then
        return false, false  -- duplicate, not skipped
    end
    history:Push({ rules, state })
    return true, false  -- added, not skipped
end

-- Fixed implementation (what we'll implement in Rules.ttslua)
local function addToHistory_fixed(history, skipNextHistory, rules, state)
    if skipNextHistory then
        return false, true  -- skipped, skipReset
    end
    if history:Size() > 0 then
        local top = history:Top()
        if top[1] == rules and top[2] == state then
            return false, false  -- duplicate, not skipped
        end
    end
    history:Push({ rules, state })
    return true, false  -- added, not skipped
end

Test.test("CircularArray.Top asserts on empty array (documents bug precondition)", function(t)
    local history = CircularArray(10)
    t:assertEqual(0, history:Size(), "history should start empty")

    -- This demonstrates the bug: calling Top() on empty array throws
    local success, err = pcall(function()
        history:Top()
    end)
    t:assertFalse(success, "Top() on empty array should throw")
    t:assertMatch(err, "Circular array is empty")
end)

Test.test("addToHistory_buggy crashes on empty history", function(t)
    local history = CircularArray(10)

    local success, err = pcall(function()
        addToHistory_buggy(history, false, "Core Rulebook", 1)
    end)

    t:assertFalse(success, "buggy version should crash on empty history")
    t:assertMatch(err, "Circular array is empty")
end)

Test.test("addToHistory_fixed handles empty history without error", function(t)
    local history = CircularArray(10)
    t:assertEqual(0, history:Size(), "history should start empty")

    -- Act: call fixed version with empty history - should not throw
    local added, skipped = addToHistory_fixed(history, false, "Core Rulebook", 1)

    -- Assert: entry was added
    t:assertTrue(added, "should add entry")
    t:assertFalse(skipped, "should not be skip-reset")
    t:assertEqual(1, history:Size(), "history should have one entry")
    local top = history:Top()
    t:assertEqual("Core Rulebook", top[1])
    t:assertEqual(1, top[2])
end)

Test.test("addToHistory_fixed deduplicates consecutive identical entries", function(t)
    local history = CircularArray(10)

    -- Add first entry
    local added1, _ = addToHistory_fixed(history, false, "Core Rulebook", 5)
    t:assertTrue(added1)
    t:assertEqual(1, history:Size())

    -- Add duplicate - should be ignored
    local added2, _ = addToHistory_fixed(history, false, "Core Rulebook", 5)
    t:assertFalse(added2, "duplicate should not be added")
    t:assertEqual(1, history:Size(), "size should stay 1")

    -- Add different entry - should be added
    local added3, _ = addToHistory_fixed(history, false, "Core Rulebook", 6)
    t:assertTrue(added3)
    t:assertEqual(2, history:Size(), "different entry should be added")
end)

Test.test("addToHistory_fixed respects skipNextHistory flag", function(t)
    local history = CircularArray(10)

    -- Call with skip flag set
    local added, skipReset = addToHistory_fixed(history, true, "Core Rulebook", 1)
    t:assertFalse(added, "entry should be skipped")
    t:assertTrue(skipReset, "skip reset should be signaled")
    t:assertEqual(0, history:Size(), "history should remain empty")
end)

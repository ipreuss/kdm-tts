local Framework = {}

local tests = {}

local function deepEqual(a, b, seen)
    if a == b then
        return true
    end

    local typeA = type(a)
    if typeA ~= type(b) then
        return false
    end

    if typeA ~= "table" then
        return false
    end

    seen = seen or {}
    seen[a] = seen[a] or {}
    if seen[a][b] then
        return true
    end
    seen[a][b] = true

    for key, value in pairs(a) do
        if not deepEqual(value, b[key], seen) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function newContext(name)
    local context = {}

    function context:fail(message)
        error(message or ("Test '%s' failed"):format(name), 2)
    end

    function context:assertTrue(value, message)
        if not value then
            self:fail(message or "Expected expression to be truthy")
        end
    end

    function context:assertFalse(value, message)
        if value then
            self:fail(message or "Expected expression to be falsy")
        end
    end

    function context:assertEqual(expected, actual, message)
        if expected ~= actual then
            self:fail(message or ("Expected %s but got %s"):format(tostring(expected), tostring(actual)))
        end
    end

    function context:assertNotEqual(expected, actual, message)
        if expected == actual then
            self:fail(message or ("Did not expect %s"):format(tostring(actual)))
        end
    end

    function context:assertDeepEqual(expected, actual, message)
        if not deepEqual(expected, actual) then
            self:fail(message or "Tables are not equal")
        end
    end

    function context:assertNil(value, message)
        if value ~= nil then
            self:fail(message or ("Expected nil but got %s"):format(tostring(value)))
        end
    end

    function context:assertNotNil(value, message)
        if value == nil then
            self:fail(message or "Expected non-nil value")
        end
    end

    function context:assertMatch(str, pattern, message)
        if type(str) ~= "string" then
            self:fail(message or ("Expected string to match pattern, but got %s"):format(type(str)))
        end
        if not str:find(pattern) then
            self:fail(message or ("Expected '%s' to match pattern '%s'"):format(str, pattern))
        end
    end

    function context:assertNotMatch(str, pattern, message)
        if type(str) ~= "string" then
            return
        end
        if str:find(pattern) then
            self:fail(message or ("Expected '%s' not to match pattern '%s'"):format(str, pattern))
        end
    end

    function context:assertType(value, expectedType, message)
        local actualType = type(value)
        if actualType ~= expectedType then
            self:fail(message or ("Expected type %s but got %s"):format(expectedType, actualType))
        end
    end

    function context:assertError(fn, message)
        local ok, err = pcall(fn)
        if ok then
            self:fail(message or "Expected function to throw an error")
        end
        return err
    end

    function context:assertNoError(fn, message)
        local ok, err = pcall(fn)
        if not ok then
            self:fail(message or ("Expected no error but got: %s"):format(tostring(err)))
        end
    end

    function context:assertGreaterThan(actual, expected, message)
        if not (actual > expected) then
            self:fail(message or ("%s is not greater than %s"):format(tostring(actual), tostring(expected)))
        end
    end

    function context:assertLessThan(actual, expected, message)
        if not (actual < expected) then
            self:fail(message or ("%s is not less than %s"):format(tostring(actual), tostring(expected)))
        end
    end

    function context:assertContains(haystack, needle, message)
        if type(haystack) == "table" then
            for _, value in ipairs(haystack) do
                if value == needle then
                    return
                end
            end
            self:fail(message or ("Table does not contain %s"):format(tostring(needle)))
        elseif type(haystack) == "string" then
            if not haystack:find(needle, 1, true) then
                self:fail(message or ("String '%s' does not contain '%s'"):format(haystack, needle))
            end
        else
            self:fail(message or ("Cannot check if %s contains %s"):format(type(haystack), tostring(needle)))
        end
    end

    function context:assertNotContains(haystack, needle, message)
        if type(haystack) == "table" then
            for _, value in ipairs(haystack) do
                if value == needle then
                    self:fail(message or ("Table should not contain %s"):format(tostring(needle)))
                end
            end
        elseif type(haystack) == "string" then
            if haystack:find(needle, 1, true) then
                self:fail(message or ("String '%s' should not contain '%s'"):format(haystack, needle))
            end
        else
            self:fail(message or ("Cannot check if %s contains %s"):format(type(haystack), tostring(needle)))
        end
    end

    return context
end

function Framework.test(name, fn)
    table.insert(tests, {
        name = name,
        fn = fn,
    })
end

function Framework.run()
    local passed = 0
    local failed = 0

    for _, test in ipairs(tests) do
        local context = newContext(test.name)
        local ok, err = xpcall(function()
            test.fn(context)
        end, debug.traceback)

        if ok then
            passed = passed + 1
        else
            failed = failed + 1
            io.stderr:write(("✗ %s\n%s\n"):format(test.name, err))
        end
    end

    local summary = ("Ran %d test%s: %d passed, %d failed"):format(
        passed + failed,
        (passed + failed) == 1 and "" or "s",
        passed,
        failed
    )
    print(summary)

    return failed == 0
end

return Framework

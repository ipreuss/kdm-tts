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

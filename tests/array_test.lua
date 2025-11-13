local Test = require("tests.framework")
local array = require("Kdm/Util/array")

Test.test("filter returns a new array with matching values", function(t)
    local data = { "lion", "antelope", "lioness", "antelope" }

    local result = array.filter(data, function(value)
        return value:find("lion")
    end)

    t:assertNotEqual(data, result, "filter must return a new array")
    t:assertEqual(2, #result)
    t:assertDeepEqual({ "lion", "lioness" }, result)
end)

Test.test("filter returns an empty table when nothing matches", function(t)
    local result = array.filter({ 1, 3, 5 }, function(value)
        return value % 2 == 0
    end)

    t:assertEqual(0, #result)
end)

Test.test("All helper always returns true", function(t)
    t:assertTrue(array.All())
    t:assertTrue(array.All("ignored"))
end)

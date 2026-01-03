local Test = require("tests.framework")

local function withStubs(stubs, fn)
    local originals = {}
    for name, mod in pairs(stubs) do
        originals[name] = package.loaded[name]
        package.loaded[name] = mod
    end
    local ok, err = pcall(fn)
    for name, orig in pairs(originals) do
        package.loaded[name] = orig
    end
    if not ok then
        error(err)
    end
end

local function buildTimelineStubs()
    local checkStub = {}
    function checkStub.Num()
        return true
    end
    function checkStub.Str()
        return true
    end
    setmetatable(checkStub, {
        __call = function()
            return true
        end,
    })

    local logStub = { Debugf = function() end, Errorf = function() end, Printf = function() end, Broadcastf = function() end }

    return {
        ["Kdm/Archive/Archive"] = {},
        ["Kdm/Util/Check"] = checkStub,
        ["Kdm/Util/Container"] = {},
        ["Kdm/Expansion"] = {},
        ["Kdm/Sequence/Hunt"] = {},
        ["Kdm/Location/Location"] = {},
        ["Kdm/Core/Log"] = { ForModule = function() return logStub end },
        ["Kdm/Ui/MessageBox"] = {},
        ["Kdm/Ui/Rules"] = {},
        ["Kdm/Sequence/Showdown"] = {},
        ["Kdm/Ui"] = {
            LIGHT_BROWN = "#aaa",
            IMAGE_COLORS = {},
            INVISIBLE_COLORS = {},
        },
        ["Kdm/Util/Util"] = {
            Min = math.min,
            Max = math.max,
            Clamp = function(x, lo, hi) return math.max(lo, math.min(hi, x)) end,
            Intersect = function() return {} end,
            Index = function() return {} end,
            Map = function(tbl, mapper)
                local result = {}
                for i, v in ipairs(tbl or {}) do
                    result[i] = mapper(v)
                end
                return result
            end,
        },
        ["Kdm/Ui/PanelKit"] = {},
        ["Kdm/Util/Trie"] = function() return {} end,
    }
end

local function getInternalTimeline(TimelineModule)
    local i = 1
    while true do
        local name, value = debug.getupvalue(TimelineModule.ShowUi, i)
        if not name then
            break
        end
        if name == "Timeline" then
            return value
        end
        i = i + 1
    end
end

local function buildEventSlot()
    return {
        button = {
            SetImage = function() end,
            SetColors = function() end,
            SetOnClick = function() end,
        },
        text = {
            Show = function() end,
            Hide = function() end,
            SetText = function() end,
        },
    }
end

local function prepareYears(timelineTable, TimelineModule, opts)
    opts = opts or {}
    timelineTable.years = {}
    local maxEvents = (TimelineModule and TimelineModule.MAX_YEAR_EVENTS) or 6
    for i = 1, 3 do
        local events = {}
        for _ = 1, maxEvents do
            table.insert(events, buildEventSlot())
        end
        timelineTable.years[i] = {
            checked = (i == 1),
            events = events,
        }
    end

    if opts.prefilled then
        for _, year in ipairs(timelineTable.years) do
            for _, event in ipairs(year.events) do
                event.event = { name = "Filled", type = "SettlementEvent" }
            end
        end
    end
end

Test.test("Timeline.ScheduleEvent inserts into next unchecked year", function(t)
    withStubs(buildTimelineStubs(), function()
        package.loaded["Kdm/Sequence/Timeline"] = nil
        local Timeline = require("Kdm/Sequence/Timeline")
        local timelineTable = getInternalTimeline(Timeline)
        t:assertTrue(timelineTable ~= nil, "expected timeline table")
        prepareYears(timelineTable, Timeline, {})

        local ok = Timeline.ScheduleEvent({ name = "Acid Storm", type = "SettlementEvent", offset = 1 })
        t:assertTrue(ok, "Expected scheduling to succeed")

        local inserted = timelineTable.years[2].events[1].event
        t:assertTrue(inserted ~= nil, "Event should populate first slot of year 2")
        t:assertEqual("Acid Storm", inserted.name)
        t:assertEqual("SettlementEvent", inserted.type)
    end)
end)

Test.test("Timeline.ScheduleEvent respects offset", function(t)
    withStubs(buildTimelineStubs(), function()
        package.loaded["Kdm/Sequence/Timeline"] = nil
        local Timeline = require("Kdm/Sequence/Timeline")
        local timelineTable = getInternalTimeline(Timeline)
        prepareYears(timelineTable, Timeline, {})

        local ok = Timeline.ScheduleEvent({ name = "Later Event", type = "SettlementEvent", offset = 2 })
        t:assertTrue(ok, "Should schedule when offset skips checked years")

        local inserted = timelineTable.years[3].events[1].event
        t:assertEqual("Later Event", inserted.name)
    end)
end)

Test.test("Timeline.ScheduleEvent fails when target year full", function(t)
    withStubs(buildTimelineStubs(), function()
        package.loaded["Kdm/Sequence/Timeline"] = nil
        local Timeline = require("Kdm/Sequence/Timeline")
        local timelineTable = getInternalTimeline(Timeline)
        prepareYears(timelineTable, Timeline, { prefilled = true })

        local ok = Timeline.ScheduleEvent({ name = "Overflow", type = "SettlementEvent" })
        t:assertFalse(ok, "Scheduling should fail when year is full")
    end)
end)

Test.test("Timeline.RemoveEventByName clears existing event", function(t)
    withStubs(buildTimelineStubs(), function()
        package.loaded["Kdm/Sequence/Timeline"] = nil
        local Timeline = require("Kdm/Sequence/Timeline")
        local timelineTable = getInternalTimeline(Timeline)
        prepareYears(timelineTable, Timeline, {})
        timelineTable.years[2].events[1].event = { name = "Acid Storm", type = "SettlementEvent" }

        local ok = Timeline.RemoveEventByName("Acid Storm", "SettlementEvent")
        t:assertTrue(ok, "Removal should succeed for existing event")
        t:assertTrue(timelineTable.years[2].events[1].event == nil, "Event slot should be cleared")
    end)
end)

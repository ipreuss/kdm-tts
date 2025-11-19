local Test = require("tests.framework")
local Campaign = require("Kdm/Campaign")
local Timeline = require("Kdm/Timeline")

Test.test("Campaign.SetupSettlementEventsDeck refreshes search without card names", function(t)
    local originalRefresh = Timeline.RefreshSettlementEventSearchFromDeck
    local called = false
    Timeline.RefreshSettlementEventSearchFromDeck = function()
        called = true
    end

    Campaign._test.SetupSettlementEventsDeck(nil)

    Timeline.RefreshSettlementEventSearchFromDeck = originalRefresh
    t:assertTrue(called, "Expected refresh to run even when no card names provided")
end)

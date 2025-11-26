local Test = require("tests.framework")
local CampaignMigrations = require("Kdm/GameData/CampaignMigrations")

local function baseV1Data()
    return {
        version = 1,
        innovationDeck = { "Language", "Paint" },
        innovations = {
            { location = "Innovation 1", name = "Lantern Oven", type = "Innovations" },
        },
        principles = {},
        settlementLocations = {},
        settlementGear = {},
        settlementResources = {},
        weaponMasteries = {},
        playerGear = {
            {
                armorSet = { location = "Player 1 Armor Set", name = "Rawhide", type = "Armor Sets" },
                gear = {
                    { location = "Player 1 Gear 1", name = "Cloth", type = "Gear" },
                },
            },
        },
        objectsByLocation = {},
        population = {
            survivors = {
                {
                    cards = {
                        Gear = { "Founding Stone" },
                        Disorder = { "Fear of the Dark" },
                    },
                },
            },
        },
        timeline = {
            timeline = {
                { year = 1, name = "Endless Screams" },
            },
        },
    }
end

Test.test("CampaignMigrations upgrades v1 data through v5", function(t)
    local data = baseV1Data()

    CampaignMigrations.Apply(data, 5)

    t:assertEqual(5, data.version)

    local principles = data.objectsByLocation["Principle: Death"]
    t:assertTrue(type(principles) == "table" and principles[1], "Principle decks should exist after migration")

    local bonding = data.objectsByLocation["Principle: Bonding"]
    t:assertTrue(bonding and bonding[1].name == "Principle: Bonding", "Bonding deck should be added")

    t:assertTrue(type(data.departingSurvivors) == "table", "Departing survivors should be initialized")

    local innovationDeck = data.objectsByLocation["Innovation Deck"]
    t:assertEqual("Language", innovationDeck[1].cards and innovationDeck[1].cards[1].name, "Innovation deck should be reconstructed")

    local survivorCards = data.survivor.survivors[1].cards
    t:assertEqual("Founding Stone", survivorCards[1].name)
    t:assertEqual("Gear", survivorCards[1].type)

    t:assertTrue(data.timeline.years ~= nil, "Timeline years should mirror original timeline entries")
end)

Test.test("CampaignMigrations Apply is no-op for current version", function(t)
    local data = { version = 5, objectsByLocation = { Foo = { tag = "Card" } } }
    CampaignMigrations.Apply(data, 5)
    t:assertEqual(5, data.version)
    t:assertTrue(data.objectsByLocation.Foo.tag == "Card")
end)

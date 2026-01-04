---------------------------------------------------------------------------------------------------
-- Showdown.Setup Integration Test
--
-- Tests the REAL Showdown.Setup() → ResourceRewards integration by stubbing
-- all TTS dependencies at the link seam (package.loaded).
--
-- This test will FAIL if Showdown.monster/level aren't visible to ResourceRewards
-- because it exercises the actual code path.
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Comprehensive TTS Stubs
-- Stub everything Showdown.Setup uses, but let the real logic run
---------------------------------------------------------------------------------------------------

local function createComprehensiveStubs()
    -- Global TTS functions
    _G.logStyle = function() end
    _G.printToAll = function() end
    _G.broadcastToAll = function() end
    _G.log = function() end

    -- Wait - execute callbacks synchronously
    _G.Wait = {
        frames = function(callback) if callback then callback() end end,
        condition = function(callback) if callback then callback() end end,
        time = function(callback) if callback then callback() end end,
    }

    -- Mock TTS object
    local function createMockObject(name, gmNotes)
        return {
            getName = function() return name end,
            getGUID = function() return "guid-" .. name end,
            getGMNotes = function() return gmNotes or "" end,
            getPosition = function() return { x = 0, y = 0, z = 0 } end,
            getRotation = function() return { x = 0, y = 0, z = 0 } end,
            getBounds = function() return { size = { x = 1, y = 1, z = 1 } } end,
            setPositionSmooth = function() end,
            setRotationSmooth = function() end,
            setPosition = function() end,
            setRotation = function() end,
            setScale = function() end,
            shuffle = function() end,
            destruct = function() end,
            destroy = function() end,
            takeObject = function() return createMockObject("taken") end,
            getQuantity = function() return 1 end,
            type = "Card",
            UI = {
                setAttribute = function() end,
                setXml = function() end,
            },
        }
    end

    -- Archive stub
    package.loaded["Kdm/Archive/Archive"] = {
        Take = function(params)
            return createMockObject(params.name or "ArchiveObject", params.type)
        end,
        Clean = function() end,
    }

    -- Location stub
    package.loaded["Kdm/Location/Location"] = {
        Get = function(name)
            return {
                Center = function() return { x = 0, y = 2, z = 0 } end,
                BoxClean = function() end,
                RayCast = function() return {} end,
            }
        end,
    }

    -- Container stub
    package.loaded["Kdm/Util/Container"] = function(obj)
        return {
            Take = function() return createMockObject("container-item") end,
            Shuffle = function() end,
        }
    end

    -- Rules stub
    package.loaded["Kdm/Ui/Rules"] = {
        SpawnRules = function() end,
    }

    -- Monster stub
    package.loaded["Kdm/Entity/Monster"] = {
        Spawn = function() return createMockObject("monster-figurine") end,
    }

    -- Terrain stub
    package.loaded["Kdm/Data/Terrain"] = {
        Spawn = function() end,
        SpawnRandom = function() end,
        SnapToGrid = function() end,
    }

    -- Survivor stub
    package.loaded["Kdm/Entity/Survivor"] = {
        DepartingSurvivorNeedsToSkipNextHunt = function() return false end,
        ClearSkipNextHunt = function() end,
    }

    -- Player stub
    package.loaded["Kdm/Entity/Player"] = {
        All = function() return {} end,
    }

    -- Grid stub
    package.loaded["Kdm/Util/Grid"] = {
        Create = function()
            return {
                Snap = function(self, obj, size) return { x = 0, y = 0, z = 0 } end,
            }
        end,
    }

    -- Overlay stub
    package.loaded["Kdm/Util/Overlay"] = {
        Create = function()
            return {
                Set = function() end,
            }
        end,
    }

    -- NamedObject stub
    package.loaded["Kdm/Location/NamedObject"] = {
        Get = function(name)
            return createMockObject(name)
        end,
    }

    -- Util stub
    package.loaded["Kdm/Util/Util"] = {
        HighlightAll = function() end,
        Find = function() return nil end,
    }

    -- MessageBox stub
    package.loaded["Kdm/Ui/MessageBox"] = {
        Show = function(msg, callback) if callback then callback() end end,
    }

    -- UI stubs
    local function createUiElement(id, config)
        config = config or {}
        local elem = {
            attributes = { id = id, active = config.active or false },
        }
        function elem:GetAttribute(attr) return self.attributes[attr] end
        function elem:Show() self.attributes.active = true end
        function elem:Hide() self.attributes.active = false end
        function elem:Button(cfg) return createUiElement(cfg.id, cfg) end
        function elem:Image(cfg) return createUiElement(cfg.id, cfg) end
        function elem:Text(cfg) return createUiElement(cfg.id, cfg) end
        function elem:Panel(cfg) return createUiElement(cfg.id, cfg) end
        function elem:VerticalLayout(cfg) return createUiElement(cfg.id, cfg) end
        function elem:HorizontalLayout(cfg) return createUiElement(cfg.id, cfg) end
        function elem:VerticalScroll(cfg) return createUiElement(cfg.id, cfg) end
        function elem:ApplyToObject() end
        function elem:Apply() end
        return elem
    end

    package.loaded["Kdm/Ui"] = {
        Create3d = function(id, obj, z) return createUiElement(id) end,
        Get2d = function() return createUiElement("2d-root") end,
    }

    package.loaded["Kdm/Ui/PanelKit"] = {
        ScrollSelector = function() return { Show = function() end, Hide = function() end } end,
        ClassicDialog = function() return createUiElement("dialog") end,
        Dialog = function(config)
            local dialog = createUiElement(config.id)
            dialog.Panel = function() return createUiElement(config.id .. "-panel") end
            return dialog
        end,
    }

    -- Expansion stub - provides monster data
    package.loaded["Kdm/Expansion"] = {
        All = function()
            return {
                {
                    name = "Core",
                    monsters = {
                        {
                            name = "White Lion",
                            size = { x = 2, y = 2 },
                            rules = { "Core Rules", 89 },
                            resourcesDeck = "White Lion Resources",
                            basicAiDeck = "White Lion Basic AI",
                            advancedAiDeck = "White Lion Advanced AI",
                            specialAiDeck = "White Lion Special AI",
                            legendaryAiDeck = "White Lion Legendary AI",
                            info = "White Lion Info",
                            basicAction = "White Lion Basic Action",
                            hitLocationsDeck = "White Lion Hit Locations",
                            huntTrack = { "M", "M", "H", "H", "M", "O", "H", "M", "M", "H", "H" },
                            position = "(11.5, 8.5)",
                            playerPositions = { "(10, 14)", "(11, 15)", "(12, 15)", "(13, 14)" },
                            fixedTerrain = {},
                            randomTerrain = 2,
                            levels = {
                                {
                                    name = "Level 1",
                                    level = 1,
                                    monsterHuntPosition = 4,
                                    showdown = {
                                        basic = 7,
                                        advanced = 3,
                                        movement = 6,
                                        toughness = 8,
                                        resources = { basic = 4, monster = 4 },
                                    },
                                },
                            },
                        },
                    },
                },
            }
        end,
        GetEnabled = function() return { Core = true } end,
    }
end

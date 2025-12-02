---------------------------------------------------------------------------------------------------
-- TTSEnvironment: Manages TTS stub installation for acceptance tests
--
-- Stubs TTS and UI dependencies so acceptance tests can load real game modules.
---------------------------------------------------------------------------------------------------

local TTSEnvironment = {}

function TTSEnvironment.create()
    local env = {
        _installed = false,
        _savedPackages = {},
    }
    setmetatable(env, { __index = TTSEnvironment })
    return env
end

function TTSEnvironment:install()
    if self._installed then
        error("TTSEnvironment already installed - did you forget to call destroy()?")
    end
    
    -- Enable Check test mode (allows tables to pass Object checks)
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(true)
    
    -- Save and stub Strain's UI dependencies
    self:_stubModule("Kdm/Ui/PanelKit", self:_createPanelKitStub())
    self:_stubModule("Kdm/Ui", self:_createUiStub())
    
    self._installed = true
end

function TTSEnvironment:uninstall()
    if not self._installed then
        return -- Allow multiple uninstall calls (for safety in cleanup)
    end
    
    -- Restore saved packages
    for name, orig in pairs(self._savedPackages) do
        package.loaded[name] = orig
    end
    self._savedPackages = {}
    
    -- Disable Check test mode
    local Check = require("Kdm/Util/Check")
    Check.Test_SetTestMode(false)
    
    self._installed = false
end

---------------------------------------------------------------------------------------------------
-- Stub helpers
---------------------------------------------------------------------------------------------------

function TTSEnvironment:_stubModule(name, stub)
    self._savedPackages[name] = package.loaded[name]
    package.loaded[name] = stub
end

function TTSEnvironment:_createPanelKitStub()
    local panelStub = {}
    function panelStub:Panel() return panelStub end
    function panelStub:Text() return panelStub end
    function panelStub:Button() return panelStub end
    function panelStub:CheckButton() return panelStub end
    function panelStub:Show() end
    function panelStub:Hide() end
    
    return {
        Dialog = function() return panelStub end,
        VerticalLayout = function() return panelStub end,
    }
end

function TTSEnvironment:_createUiStub()
    local uiStub = {}
    function uiStub:Panel() return uiStub end
    function uiStub:ApplyToObject() end
    
    return {
        Get2d = function() return uiStub end,
        DARK_BROWN = "#111111",
        MID_BROWN = "#999999",
        LIGHT_BROWN = "#CCCCCC",
        CLASSIC_BACKGROUND = "#222222",
        CLASSIC_HEADER = "#333333",
        CLASSIC_SHADOW = "#111111",
        CLASSIC_BORDER = "#444444",
    }
end

return TTSEnvironment

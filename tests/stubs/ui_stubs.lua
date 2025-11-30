-- Shared UI stubs for testing TTS UI components
-- Provides mock implementations of Panel, Dialog, Text, Button, etc.

local ui_stubs = {}

---------------------------------------------------------------------------------------------------
-- Simple Panel Stub
---------------------------------------------------------------------------------------------------

function ui_stubs.simplePanel()
    local panel = {}
    function panel:Panel()
        return ui_stubs.simplePanel()
    end
    function panel:Text(params)
        local text = { params = params, text = nil }
        function text:SetText(value) text.text = value end
        return text
    end
    function panel:Button()
        return {}
    end
    return panel
end

---------------------------------------------------------------------------------------------------
-- Dialog Stub (with show/hide tracking)
---------------------------------------------------------------------------------------------------

function ui_stubs.dialog()
    local dialogStats = { show = 0, hide = 0 }
    
    local rootPanel = { children = {} }
    function rootPanel:Panel(params)
        local child = { attributes = params }
        table.insert(self.children, child)
        return child
    end
    function rootPanel:Button(_) end
    function rootPanel:Text(_) end
    function rootPanel:SetHeight(height) self.height = height end
    
    return {
        Panel = function() return rootPanel end,
        ShowForPlayer = function(_, player)
            dialogStats.show = dialogStats.show + 1
            return player.color
        end,
        HideForPlayer = function(_, player)
            dialogStats.hide = dialogStats.hide + 1
            return player.color
        end,
        ShowForAll = function()
            dialogStats.show = dialogStats.show + 1
        end,
        HideForAll = function()
            dialogStats.hide = dialogStats.hide + 1
        end,
        Show = function()
            dialogStats.show = dialogStats.show + 1
        end,
        Hide = function()
            dialogStats.hide = dialogStats.hide + 1
        end,
        IsOpen = function() return dialogStats.show > dialogStats.hide end,
        SetHeight = function() end,
        stats = dialogStats,  -- Expose for testing
    }
end

---------------------------------------------------------------------------------------------------
-- List Panel Stub (for recording row creation)
---------------------------------------------------------------------------------------------------

function ui_stubs.listPanel(recorder)
    recorder = recorder or { rows = {} }
    
    local listPanel = {
        panels = recorder.rows,
        height = 0,
    }
    
    function listPanel:SetHeight(height)
        self.height = height
    end
    
    function listPanel:Panel(params)
        local row = { attributes = params }
        function row:SetHeight(h) self.height = h end
        function row:SetOffsetXY(offset) self.offset = offset end
        function row:SetWidth(w) self.width = w end
        function row:SetColor(color) self.color = color end
        function row:CheckBox(cbParams)
            local checkbox = { params = cbParams, checked = nil }
            function checkbox:Check(value) checkbox.checked = value end
            row.checkBox = checkbox
            return checkbox
        end
        function row:Text(textParams)
            local text = { params = textParams, text = nil }
            function text:SetText(value) text.text = value end
            function text:SetWidth(w) text.width = w end
            function text:SetHeight(h) text.height = h end
            return text
        end
        table.insert(self.panels, row)
        return row
    end
    
    return listPanel
end

---------------------------------------------------------------------------------------------------
-- Scroll Area Stub
---------------------------------------------------------------------------------------------------

function ui_stubs.scrollArea(recorder)
    recorder = recorder or { scrollContentHeight = 0 }
    local panel = ui_stubs.listPanel(recorder)  -- Create once and reuse
    
    return {
        Panel = function() return panel end,
        SetContentHeight = function(_, height)
            recorder.scrollContentHeight = height
        end,
    }
end

---------------------------------------------------------------------------------------------------
-- Text Element Stub
---------------------------------------------------------------------------------------------------

function ui_stubs.text(params)
    local text = { params = params, text = nil }
    function text:SetText(value) text.text = value end
    function text:SetWidth(w) text.width = w end
    function text:SetHeight(h) text.height = h end
    return text
end

---------------------------------------------------------------------------------------------------
-- Button Element Stub
---------------------------------------------------------------------------------------------------

function ui_stubs.button(params)
    return { params = params }
end

---------------------------------------------------------------------------------------------------
-- CheckBox Element Stub
---------------------------------------------------------------------------------------------------

function ui_stubs.checkBox(params)
    local checkbox = { params = params, checked = nil }
    function checkbox:Check(value) checkbox.checked = value end
    return checkbox
end

return ui_stubs

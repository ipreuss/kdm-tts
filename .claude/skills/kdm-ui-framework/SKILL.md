---
name: kdm-ui-framework
description: UI framework for creating dialogs, panels, and layouts in the KDM TTS mod. Covers PanelKit patterns (Dialog, ClassicDialog, ScrollArea, OptionList), LayoutManager two-stage layout system, color palette constants (CLASSIC colors, BROWN, RED, GREEN), pre-calculation patterns, and common UI creation workflows. Use when working with UI, panels, dialogs, buttons, layouts, colors, or when mentioning PanelKit, LayoutManager, ClassicDialog, or CLASSIC color constants.
---

# KDM UI Framework

Comprehensive guide to the custom UI framework built on TTS's XML UI system.

## Core Components

### PanelKit (`Ui/PanelKit.ttslua`)

**High-level dialog and panel creation utilities:**

- `PanelKit.Dialog()` — Base dialog container
- `PanelKit.ClassicDialog()` — Standardized KDM-styled chrome (shadows, frames, headers)
- `PanelKit.DialogFromSpec()` — Auto-sized dialog from specification
- `PanelKit.ScrollArea()` — Scrollable content area
- `PanelKit.OptionList()` — Pre-allocated button list for dynamic options
- `PanelKit.ScrollSelector()` — OptionList with selection helpers
- `PanelKit.VerticalLayout()` — Wrapper for LayoutManager

### LayoutManager (`Ui/LayoutManager.ttslua`)

**Two-stage layout system for precise sizing:**

**Stage 1: Pre-calculation**
```lua
local spec = LayoutManager.Specification()
spec:AddTitle({ height = 35 })
spec:AddSection({ labelHeight = 30, contentHeight = 60 })
spec:AddButtonRow({ height = 45 })

local dialogHeight = spec:CalculateDialogHeight({
    padding = 15,
    spacing = 12,
})
```

**Stage 2: Dialog Creation**
```lua
local dialog = PanelKit.Dialog({ width = 650, height = dialogHeight })
local chrome = PanelKit.ClassicDialog({ panel = dialog:Panel(), width = 650, height = dialogHeight })
local layout = LayoutManager.VerticalLayout({ parent = dialog:Panel(), contentArea = chrome })
spec:Render(layout)
```

**Why two stages?** TTS dialog dimensions are immutable after creation. Pre-calculation ensures proper sizing.

## Color Palette

**Defined in `Ui.ttslua` — Use these constants for consistency:**

| Constant | Value | Usage |
|----------|-------|-------|
| `Ui.LIGHT_BROWN` | `#bbb4a1` | Text on dark backgrounds, button labels |
| `Ui.MID_BROWN` | `#7f7059` | Secondary backgrounds |
| `Ui.DARK_BROWN` | `#453824` | Primary button/panel backgrounds |
| `Ui.LIGHT_RED` | `#E96C6C` | Warning/error highlights |
| `Ui.DARK_RED` | `#831010` | Critical warnings |
| `Ui.LIGHT_GREEN` | `#90ee90` | Success/positive highlights |

**Color sets for buttons:**
- `Ui.MID_BROWN_COLORS` — `"#7f7059|#655741|#655741|#ffffff"`
- `Ui.DARK_BROWN_COLORS` — `"#453824|#2f2410|#2f2410|#ffffff"`
- `Ui.INVISIBLE_COLORS` — `"#00000000|#00000088|#00000088|#00000000"`

**ClassicDialog chrome colors (hardcoded in PanelKit):**
- Background: `#d8cab1f0` (light beige)
- Header: `#b1916cff` (tan/gold)
- Frame/Divider: `Ui.DARK_BROWN`
- Shadow: `#00000055`

## Common Patterns

### Pattern 1: Simple Dialog with ClassicDialog Chrome

```lua
local PanelKit = require("Kdm/Ui/PanelKit")
local Ui = require("Kdm/Ui")

local width = 540
local height = 540

local dialog = PanelKit.Dialog({
    id = "MyDialog",
    ui = Ui.Get2d(),
    rectAlignment = "MiddleCenter",
    width = width,
    height = height,
    color = "#00000000",  -- Transparent
    closeButton = false,
})

local panel = dialog:Panel()

local chrome = PanelKit.ClassicDialog({
    panel = panel,
    id = "MyDialog",
    width = width,
    height = height,
    title = "Dialog Title",
    subtitle = "Optional subtitle text",
    closeButton = {
        onClick = function(_, player)
            dialog:HideForPlayer(player)
        end,
    },
})

-- Use chrome.contentX, contentY, contentWidth, contentHeight for content placement
```

### Pattern 2: Auto-Sized Dialog with LayoutManager

```lua
local PanelKit = require("Kdm/Ui/PanelKit")
local LayoutManager = require("Kdm/Ui/LayoutManager")
local Ui = require("Kdm/Ui")

local width = 650

-- Stage 1: Build specification and calculate height
local spec = LayoutManager.Specification()
spec:AddTitle({ text = "Confirmation" })
spec:AddSpacer(6)
spec:AddSection({
    label = "Story:",
    content = "Flavor text goes here...",
    contentStyle = "Italic",
    indent = 15,
})
spec:AddSpacer(10)
spec:AddButtonRow({
    buttons = {
        { id = "Confirm", text = "Confirm", onClick = function() end },
        { id = "Cancel", text = "Cancel", onClick = function() end },
    }
})

local dialogHeight = spec:CalculateDialogHeight({
    padding = 15,
    spacing = 12,
})

-- Stage 2: Create dialog and render
local result = PanelKit.DialogFromSpec({
    id = "MyDialog",
    width = width,
    spec = spec,
    title = "Confirmation",
    padding = 15,
    spacing = 12,
})

-- Access: result.dialog, result.panel, result.chrome, result.layout
```

### Pattern 3: ScrollArea with Dynamic Content

```lua
local chrome = PanelKit.ClassicDialog({ ... })

local scrollArea = PanelKit.ScrollArea({
    parent = panel,
    id = "MyScroll",
    x = chrome.contentX,
    y = chrome.contentY,
    width = chrome.contentWidth,
    height = chrome.contentHeight,
    contentWidth = chrome.contentWidth,
})

local listPanel = scrollArea:Panel()

-- Add content to listPanel, then:
scrollArea:SetContentHeight(calculatedHeight)
```

### Pattern 4: OptionList with Pre-Allocated Buttons

```lua
local optionList = PanelKit.OptionList({
    parent = panel,
    id = "MyOptions",
    x = chrome.contentX,
    y = chrome.contentY,
    width = chrome.contentWidth,
    height = chrome.contentHeight,
    itemHeight = 30,
    maxItems = 20,  -- Pre-allocate to avoid TTS dynamic creation issues
    onClick = function(option)
        local value = option:OptionValue()
        -- Handle selection
    end,
    selectedColors = Ui.DARK_BROWN_COLORS,
    unselectedColors = Ui.INVISIBLE_COLORS,
    textColor = Ui.LIGHT_BROWN,
})

-- Later, update options:
optionList:SetOptions({
    { text = "Option 1", value = "opt1", selected = false },
    { text = "Option 2", value = "opt2", selected = true },
})
```

### Pattern 5: ResetButton (3D UI on boards)

```lua
-- Used for deck/gear reset buttons on physical boards
ui:ResetButton({
    id = "MyButton",
    topLeft = { x = 1.0, y = 2.0 },
    bottomRight = { x = 1.5, y = 3.0 },
    onClick = function()
        -- Reset logic
    end,
    text = "Reset",      -- optional
    fontSize = 120,      -- optional
    rotation = "0 0 270" -- optional, for vertical text
})
```

**Rotation values for 3D UI:**
- `"0 0 180"` — Default (text reads normally)
- `"0 0 270"` — Rotated 90° counterclockwise (vertical, reads bottom-to-top)

## Layout Elements

### Element Types

**LayoutManager.Specification supports:**

- `AddTitle()` — Large centered title (24px, Bold)
- `AddLabel()` — Bold section label (18px)
- `AddContent()` — Body text (16px, wrapped)
- `AddText()` — Generic text with custom styling
- `AddSection()` — Label + Content combo
- `AddSpacer()` — Vertical spacing
- `AddButtonRow()` — Centered row of buttons
- `AddCheckboxWithLabel()` — Checkbox + label combo
- `AddCustom()` — Custom render function
- `AddGrid()` — Grid layout for items

**Capture rendered elements with callbacks:**

```lua
spec:AddTitle({ text = "Title" }, function(element)
    myDialog.titleElement = element
    -- Can call element:SetText() later
end)
```

### Height Calculation Constants

From `LayoutManager.ttslua`:

- `FONT_HEIGHT_MULTIPLIER = 1.5` — Text element height
- `TITLE_HEIGHT_MULTIPLIER = 1.35` — Title height
- `LABEL_HEIGHT_MULTIPLIER = 1.35` — Label height
- `CONTENT_HEIGHT_MULTIPLIER = 5.2` — Content (wrapped text) height
- `DEFAULT_CHROME_OVERHEAD = 195` — Dialog chrome overhead (frame, header, padding)

### Critical Measurements

**TTS Dialog Overhead:** 195px additional space beyond content
- Includes dialog chrome, internal margins, safe positioning
- Measured empirically

**Element Heights:**
- Title: 35px
- Section label: 25-30px
- Section content: varies (use multiplier)
- Button row: 45px
- Spacing: configurable (default 12px)

## Dialog Show/Hide API

**Per-player dialogs:**
```lua
dialog:ShowForPlayer(playerColor)  -- or player object
dialog:HideForPlayer(playerColor)
```

**Global dialogs:**
```lua
dialog:ShowForAll()
dialog:HideForAll()
```

**Check state:**
```lua
if dialog:IsOpen() then ... end
```

## Modal Dialogs

```lua
local dialog = PanelKit.Dialog({
    id = "MyModal",
    width = 400,
    height = 300,
    modal = true,  -- Creates blocker panel
    modalZ = -9,   -- Z-order of blocker (default)
    modalColor = "#00000088",  -- Semi-transparent black
})
```

Modal blocker automatically shows/hides with dialog.

## Implementation Lessons from ARCHITECTURE.md

**Fail Fast:** Errors should surface immediately at their source. Don't mask logic errors with defensive checks like `tonumber()` conversions.

**Type Safety:** Layout calculations must use proper numeric types. If "attempt to perform arithmetic on table value" occurs, debug and fix the root cause.

**Sequential Dependencies:** Pre-calculation MUST happen before UI creation. TTS dialog dimensions are immutable after creation.

## Best Practices

1. **Always use color constants** — Never hardcode color values in UI code
2. **Pre-allocate OptionList buttons** — Set `maxItems` to avoid TTS dynamic creation issues
3. **Two-stage layout** — Calculate height with Specification, then render
4. **Keep SKILL.md lean** — This skill is under 500 lines; detailed examples stay here
5. **Use ClassicDialog chrome** — Provides consistent KDM styling (shadows, frames, headers)
6. **Modal for confirmations** — Use `modal = true` for blocking confirmations
7. **Capture elements in callbacks** — Store references for later updates via `onRender` callbacks

## Common Gotchas

**TTS doesn't render dynamically created UI after initial ApplyToObject** → Pre-allocate buttons with `maxItems`

**Dialog size is immutable** → Must calculate final height before creation

**Coordinate confusion** → `contentX`/`contentY` are absolute positions; use chrome values for placement

**Z-order matters** → Later panels render on top; MessageBox should be last in init sequence

**Per-player vs global** → Check `perPlayer` flag when calling Show/Hide methods

**DialogFromSpec callbacks run synchronously** → Custom `render` callbacks in LayoutManager specs execute *during* `DialogFromSpec()`, not after it returns. Any variable you plan to initialize after the call will be `nil` inside callbacks:
```lua
-- BUG: lateVar is nil inside render callback
local lateVar = nil
PanelKit.DialogFromSpec({
    spec = spec:AddCustom({
        render = function(ctx)
            lateVar:DoSomething()  -- ERROR: attempt to index nil
        end,
    }),
})
lateVar = SomeValue()  -- Too late!

-- FIX: Initialize before DialogFromSpec, or capture in closure beforehand
local earlyVar = SomeValue()
PanelKit.DialogFromSpec({ ... })
```

## Files Reference

- `Ui.ttslua` — Color constants, base UI DSL
- `Ui/PanelKit.ttslua` — High-level dialog/panel utilities
- `Ui/LayoutManager.ttslua` — Two-stage layout system
- `MessageBox.ttslua` — Example of ClassicDialog + custom layout
- `Strain.ttslua` — Example of DialogFromSpec with LayoutManager
- `ARCHITECTURE.md` lines 81-165 — UI Framework section

## Quick Reference Card

```lua
-- Colors
Ui.LIGHT_BROWN, Ui.MID_BROWN, Ui.DARK_BROWN
Ui.LIGHT_RED, Ui.DARK_RED, Ui.LIGHT_GREEN
Ui.MID_BROWN_COLORS, Ui.DARK_BROWN_COLORS

-- Dialog creation
PanelKit.Dialog({ id, width, height, modal })
PanelKit.ClassicDialog({ panel, width, height, title, subtitle })
PanelKit.DialogFromSpec({ id, width, spec, title, padding, spacing })

-- Layout specification
spec = LayoutManager.Specification()
spec:AddTitle/AddSection/AddButtonRow/AddSpacer()
height = spec:CalculateDialogHeight({ padding, spacing })
spec:Render(layout)

-- Scrolling
PanelKit.ScrollArea({ parent, id, width, height })
PanelKit.OptionList({ parent, id, width, height, maxItems, onClick })

-- Show/Hide
dialog:ShowForPlayer(player)
dialog:HideForPlayer(player)
dialog:ShowForAll()
dialog:HideForAll()
```

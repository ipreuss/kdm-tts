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

## 2D vs 3D Button Decisions

**2D buttons** (via `PanelKit`, `Ui.Get2d()`):
- Fixed screen position
- Good for: global/menu actions, settings dialogs, navigation
- Example: Showdown setup dialog, MessageBox confirmations

**3D buttons** (via `object.createButton()`):
- Attached to game board objects
- Position relative to the object (moves with it)
- Good for: object-contextual actions, board controls
- Example: Deck reset buttons, card-specific actions, "Next Card" on revealed hunt cards

**Decision criteria:**

| Use Case | Button Type | Rationale |
|----------|-------------|-----------|
| Global confirmation | 2D | Not tied to any specific object |
| Deck reset on board | 3D | Action relates to specific board location |
| Settings/options | 2D | Menu-style, fixed position |
| Card action after reveal | 3D | Appears on/near the relevant card |
| Navigation (jump to board) | 2D | Global action, not contextual |

**Key insight:** If the action is contextual to a specific game board object, use 3D so the relationship is visually obvious.

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

## Real Code Examples

Copy-paste ready patterns from this codebase. These are production code, not hypotheticals.

### Example 1: Modal MessageBox with Manual Layout

From `MessageBox.ttslua` — modal confirmation dialog with custom positioning:

```lua
function MessageBox.Init()
    local ui = Ui.Get2d()

    local dialog = PanelKit.Dialog({
        id = "MessageBox",
        ui = ui,
        rectAlignment = "MiddleCenter",
        width = MessageBox.PANEL_WIDTH,
        height = MessageBox.MIN_PANEL_HEIGHT,
        color = "#00000000",  -- Transparent dialog background
        closeButton = false,
        perPlayer = false,
        modal = true,  -- Creates blocking overlay
    })
    MessageBox.dialog = dialog

    local panel = dialog:Panel()

    local chrome = PanelKit.ClassicDialog({
        panel = panel,
        id = "MessageBoxChrome",
        width = MessageBox.PANEL_WIDTH,
        height = MessageBox.MIN_PANEL_HEIGHT,
        inset = MessageBox.CHROME_PADDING,
        headerHeight = 0,  -- No title bar
        contentPadding = MessageBox.CONTENT_PADDING,
        footerPadding = MessageBox.FOOTER_PADDING,
        closeButton = false,
    })
    MessageBox.chrome = chrome

    -- Content positioned relative to chrome.contentX/Y
    local contentPanel = panel:Panel({
        id = "MessageBoxContent",
        rectAlignment = "UpperLeft",
        x = chrome.contentX,
        y = chrome.contentY,
        width = chrome.contentWidth,
        height = chrome.contentHeight,
        color = "#00000000",
    })

    -- Buttons manually positioned at bottom
    local totalButtonWidth = MessageBox.BUTTON_WIDTH * 2 + MessageBox.BUTTON_SPACING
    local firstButtonX = (chrome.contentWidth - totalButtonWidth) / 2

    contentPanel:Button({
        id = "OK",
        rectAlignment = "LowerLeft",
        x = firstButtonX,
        y = MessageBox.BUTTON_BOTTOM_PADDING,
        width = MessageBox.BUTTON_WIDTH,
        height = MessageBox.BUTTON_HEIGHT,
        text = "OK",
        textColor = Ui.LIGHT_BROWN,
        colors = Ui.DARK_BROWN_COLORS,
        onClick = function()
            MessageBox.Hide()
            if MessageBox.func then MessageBox.func() end
        end,
    })
end
```

**Key points:**
- `modal = true` creates a blocking overlay behind the dialog
- `color = "#00000000"` makes dialog transparent (chrome provides visuals)
- `chrome.contentX/Y/Width/Height` define the usable content area
- Manual button positioning for precise control

### Example 2: DialogFromSpec with LayoutManager

From `Strain.ttslua` — auto-sized dialog with sections and callbacks:

```lua
function Strain:InitConfirmationDialog()
    local width = 650

    local spec = LayoutManager.Specification()

    -- Section with callback to capture element reference
    spec:AddSection({
        label = "Story:",
        contentId = "MilestoneFlavorText",
        contentStyle = "Italic",
        contentColor = Ui.DARK_BROWN,
        indent = 15,
    }, function(section)
        -- Callback runs during DialogFromSpec - capture for later updates
        Strain.confirmationFlavorText = section.content
    end)

    spec:AddSpacer(10)

    spec:AddSection({
        label = "Game Effect:",
        contentId = "MilestoneRulesText",
        contentColor = Ui.DARK_BROWN,
        indent = 15,
    }, function(section)
        Strain.confirmationRulesText = section.content
    end)

    spec:AddSpacer(6)

    spec:AddSection({
        label = "Manual Steps:",
        contentId = "MilestoneManualText",
        contentColor = "#CC0000",  -- Red to draw attention
        indent = 15,
    }, function(section)
        Strain.confirmationManualText = section.content
    end)

    spec:AddSpacer(15)

    spec:AddButtonRow({
        spacing = 25,
        buttons = {
            {
                id = "MilestoneConfirmOK",
                text = "Confirm Milestone",
                width = 160,
                textColor = Ui.LIGHT_BROWN,
                colors = Ui.DARK_BROWN_COLORS,
                onClick = function(_, player)
                    Strain:ConfirmMilestone(player)
                end,
            },
            {
                id = "MilestoneConfirmCancel",
                text = "Cancel",
                width = 120,
                textColor = Ui.DARK_BROWN,
                colors = Ui.MID_BROWN_COLORS,
                onClick = function(_, player)
                    Strain:CancelMilestone(player)
                end,
            },
        }
    })

    local layoutParams = { padding = 12, spacing = 10 }

    local dialogResult = PanelKit.DialogFromSpec({
        id = "StrainMilestoneConfirmation",
        width = width,
        spec = spec,
        title = "Milestone Reached",
        subtitle = "A new milestone has been achieved",
        dialog = { color = "#00000000", closeButton = false },
        chrome = { closeButton = false },
        layout = layoutParams,
    })

    Strain.confirmationDialog = dialogResult.dialog
    Strain.confirmationPanel = dialogResult.panel
end

-- Later, update content dynamically:
Strain.confirmationFlavorText:SetText(milestone.flavorText)
Strain.confirmationRulesText:SetText(milestone.rulesText)
```

**Key points:**
- `spec:AddSection(..., callback)` captures element references during creation
- Captured elements can be updated later with `:SetText()`
- `DialogFromSpec` handles height calculation automatically
- `dialog` and `chrome` sub-tables configure those components

### Example 3: ScrollSelector for Selection Lists

From `Showdown.ttslua` — paired selectors for monster and level:

```lua
Showdown.monsterList = PanelKit.ScrollSelector({
    parent = Showdown.panel,
    id = "Monster",
    x = 20 + 3,
    y = -(109 + 3),  -- Negative Y = down from parent top
    width = 306 - 6,
    height = 216 - 6,
    contentWidth = 280,
    itemHeight = 30,
    fontSize = 16,
    textAlignment = "MiddleLeft",
    onSelect = function(_, option)
        if option then
            Showdown.SelectMonster(option)
        end
    end,
})

Showdown.levelList = PanelKit.ScrollSelector({
    parent = Showdown.panel,
    id = "Level",
    x = 341 + 3,
    y = -(109 + 3),
    width = 306 - 6,
    height = 216 - 6,
    contentWidth = 300,
    itemHeight = 30,
    fontSize = 16,
    textAlignment = "MiddleLeft",
    maxItems = Showdown.MAX_MONSTER_LEVEL_COUNT,  -- Pre-allocate!
    onSelect = function(level)
        if level then
            log:Debugf("Selected %s, %s", Showdown.monster.name, level.name)
            Showdown.level = level
        end
    end,
})

-- Populate monster list (with default selection)
Showdown.monsterList:SetOptionsWithDefault(Util.Map(Showdown.monsters, function(monster)
    return { text = monster.name, value = monster }
end), Campaign.data.lastMonster)

-- Update level list when monster changes
function Showdown.SelectMonster(option)
    local monster = option:OptionValue()
    local levelOptions = Util.Map(monster.levels, function(level)
        return { text = level.name, value = level }
    end)
    assert(#levelOptions <= Showdown.MAX_MONSTER_LEVEL_COUNT, "Too many levels")
    Showdown.levelList:SetOptions(levelOptions)
    option:Select()
    Showdown.level = monster.levels[1]
end
```

**Key points:**
- `maxItems` MUST be set to pre-allocate buttons (TTS dynamic creation bug)
- `SetOptionsWithDefault()` populates list and selects matching value
- `SetOptions()` for updates without default selection
- `option:OptionValue()` retrieves the `value` field from option data
- Negative Y values position elements downward from parent top

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

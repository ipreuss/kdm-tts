# Ui - User Interface Framework

## Framework Modules (in root)
- `Ui.ttslua` - Base 2D/3D UI builder, XML generation

## Component Modules
- `PanelKit.ttslua` - Dialog, ClassicDialog, ScrollArea, OptionList
- `LayoutManager.ttslua` - Two-stage XML layout specification
- `BattleUi.ttslua` - Showdown battle HUD
- `GlobalUi.ttslua` - Global navigation buttons
- `MessageBox.ttslua` - Modal dialogs
- `MilestoneBoard.ttslua` - Milestone tracking UI
- `Rules.ttslua` - Rulebook navigation
- `Bookmarks.ttslua` - Quick reference bookmarks

## Key Patterns

### PanelKit Dialog
```lua
local dialog = PanelKit.Dialog({
    title = "My Dialog",
    width = 400,
    height = 300,
})
dialog:AddButton({ text = "OK", onClick = handler })
dialog:Show()
```

### Color Constants
```lua
PanelKit.LIGHT_BROWN, PanelKit.DARK_BROWN
PanelKit.CLASSIC_BACKGROUND, PanelKit.CLASSIC_BUTTON
```

### LayoutManager
```lua
local layout = LayoutManager.Create()
layout:Row({ height = 30 })
layout:Cell({ width = 100 }):Label("Name:")
layout:Cell():Input({ id = "name" })
```

## Dependencies
- Core/Log (logging)
- Util/Check (validation)

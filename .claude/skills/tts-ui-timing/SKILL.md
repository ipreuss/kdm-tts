---
name: tts-ui-timing
description: TTS UI timing issues - when Show/Hide is safe, ApplyToObject timing, and checkbox interaction quirks. Use when UI operations fail with timing errors, setAttribute issues after ApplyToObject, or checkbox auto-toggle problems. Triggers on Object reference not set, setAttribute, ApplyToObject, Show Hide timing, checkbox toggle, UI timing.
---

# TTS UI Timing

TTS has specific timing requirements for UI operations. Many "Object reference not set" errors are timing issues.

## UI setAttribute After ApplyToObject

**Problem:** Calling `Show()`/`Hide()` immediately after `ApplyToObject()` causes `Object reference not set to an instance of an object`

**Root cause:** TTS hasn't finished processing the XML from `setXmlTable()` when `setAttribute()` is called. The element doesn't exist in TTS's internal state yet.

**Solution:** Set initial visibility via `active` param instead of calling `Hide()` in Init:

```lua
-- WRONG: Timing issue
local button = ui:Button({id = "Foo", ...})
ui:ApplyToObject()
button:Hide()  -- FAILS - element doesn't exist yet

-- CORRECT: Set initial state in params
local button = ui:Button({id = "Foo", ..., active = false})
ui:ApplyToObject()
-- Button starts hidden, no Hide() call needed
```

**When Show/Hide is safe:** After `PostInit()` or inside event handlers (UI has been processed by then)

## Dialog API Usage

**Correct Methods:**
- `dialog:ShowForPlayer(player)` — show to specific player
- `dialog:ShowForAll()` — show to all players
- `dialog:HideForAll()` — hide from all players

**Common Error:** Using `dialog:Show()` or `dialog:Hide()` (these methods don't exist in PanelKit).

## Checkbox Interaction Pattern

**Problem:** TTS automatically toggles checkbox visual state on click before calling the onClick handler.

**Solution:** Revert checkbox state in handler, show confirmation dialog, then explicitly set final state.

```lua
onClick = function(_, player)
    -- TTS has already auto-toggled the checkbox
    checkbox:Check(false)  -- Revert to unchecked
    showConfirmationDialog()
    -- On confirm: checkbox:Check(true)
end
```

## Player Object References

**Problem:** Player objects aren't stable references between different TTS callbacks.

**Solutions:**
1. Compare `player.color` strings instead of object references
2. Better: Eliminate player tracking for shared campaign state (milestones, settlement progress)

## Two-Phase Initialization

Modules that touch instantiated UI or wait for other systems register their handlers inside `Wait.frames(..., 20)`:

```lua
function Module.Init()
    -- Create UI elements
    ui:ApplyToObject()
end

function Module.PostInit()
    -- Wait.frames ensures UI elements are ready
    Wait.frames(function()
        -- Safe to call Show/Hide here
        Module.button:Show()
    end, 20)
end
```

**Key point:** Any module that touches instantiated UI registers handlers in `Wait.frames` to ensure UI elements exist.

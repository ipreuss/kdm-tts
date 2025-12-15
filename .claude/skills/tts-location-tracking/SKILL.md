---
name: tts-location-tracking
description: Working with the TTS Location system - tracking, drop handlers, and physical positions. Use when working with Location, AllObjects, drop handlers, OnEnter, physical position checks, or board-relative coordinates. Triggers on Location, AllObjects, drop handler, OnEnter, physical position, positionToWorld, board coordinates.
---

# TTS Location Tracking

The Location system provides named regions on game boards with object tracking and drop handlers.

## Location Tracking vs Physical Positions

**Problem:** `Location:AllObjects()` uses an internal tracking table updated via TTS events (`onObjectDrop`, `onObjectSpawn`). When objects are moved programmatically with `setPosition()` or `setPositionSmooth()`, no events fire, so the Location system doesn't know the object moved.

**Impact:**
- Tests checking `Location:AllObjects()` fail even though objects visually moved correctly
- Code relying on Location tracking misses programmatically moved objects

**Solution for tests:** Check physical positions using `Location:Rect()` bounds instead of `Location:AllObjects()`:

```lua
-- WRONG for programmatically moved objects:
local objects = location:AllObjects()
t:assertEqual(#objects, 1)  -- May fail even though card is visually there

-- CORRECT: Check physical position
local rect = location:Rect()
local cardPos = card.getPosition()
local inLocation = cardPos.x >= rect.x1 and cardPos.x <= rect.x2
                and cardPos.z >= rect.z1 and cardPos.z <= rect.z2
t:assertTrue(inLocation, "Card should be within location bounds")
```

**Solution for production code:** If you need Location tracking after programmatic moves, either:
1. Call `Location.OnEnter(object)` manually after moving
2. Use drop-based workflows where possible

## Simulating Drops with Location.OnEnter()

**Problem:** Tests need to trigger drop handlers without physically dropping objects.

**Solution:** Call `object.setPosition()` followed by `Location.OnEnter(object)`:

```lua
-- Simulate dropping an object at a location
local function simulateDrop(object, location)
    local targetPos = location:Center()
    targetPos.y = targetPos.y + 1  -- Slightly above surface
    object.setPosition(targetPos)
    Location.OnEnter(object)  -- Triggers drop handlers
end
```

This triggers handlers registered via `Location:AddDropHandler()`. More thorough than calling internal functions directly as it tests the full integration path.

**Benefits over calling internal functions:**
- Tests the drop handler registration
- Tests the event chain as it actually fires
- Catches issues with handler wiring

## Drop Handler Registration

Register handlers during `Module.Init()`, not during `Module.Setup()`. This ensures handlers are only registered once. Use a flag to prevent duplicate registration:

```lua
if not Hunt.dropHandlersRegistered then
    for i = 1, 11 do
        Location.Get("Hunt Track " .. i):AddDropHandler(function(object)
            if object.getGMNotes() == "Hunt Party" then
                Hunt.OnPartyArrival(i)
            end
        end)
    end
    Hunt.dropHandlersRegistered = true
end
```

## Board-Relative Coordinate Transformations

**Problem:** Game boards have scaling and rotation that affects coordinate transformation. Local coordinates don't map 1:1 to world coordinates.

**Example:** Hunt Board local X maps to world X with ~3x scale and inversion (positive local → negative world). Local Z is also inverted.

**Solution:** When adjusting board-relative locations:
1. Use `board.positionToWorld(localPos)` for accurate transformation
2. Test coordinate adjustments incrementally — don't calculate offsets from world coordinate differences
3. Use `>showpos` on selected objects to find actual positions

**Pattern for board-relative positioning:**

```lua
local board = NamedObject.Get("Hunt Board")
local localPosition = { x = 0.5, y = 0, z = 0.3 }
local worldPosition = board.positionToWorld(localPosition)

-- For incremental adjustment, modify local coords and re-transform
localPosition.x = localPosition.x + 0.1  -- Small local adjustment
worldPosition = board.positionToWorld(localPosition)
```

## TTS Coordinate System

TTS uses a **left-handed coordinate system** when viewed from above:

```
        -Z (away from you)
           ↑
           |
+X ←——————+——————→ -X
(left)     |        (right)
           ↓
        +Z (toward you)

Y = height above table (positive = up)
```

**Key points:**
- **Positive X goes LEFT** (counterintuitive!)
- **Positive Z goes DOWN** (toward you)
- **Y = 0** is below the table surface; typical spawn height is Y = 1-2

**Reference positions (world coordinates):**

| Location | Center X | Center Z | Notes |
|----------|----------|----------|-------|
| Table center | 0 | 0 | Origin |
| Settlement Board | 0 | 0 | Centered at origin |
| Showdown Board | 0 | ~0.7 | Slightly south of center |
| Hunt Board | 0 | ~-50 | Far north |
| Rulebooks | ~15 | 0 | East of settlement |
| Resource Rewards spawn | -10 | 0 | West of settlement |

**Common Y values:**
- Table surface: ~0.6
- Card spawn height: 1-2
- Showdown board surface: ~10.74

**Tips:**
- Use `>showpos` command to get coordinates of selected objects
- Use `>showloc <name>` to highlight a named location
- LocationData.ttslua contains all defined locations with coordinates

## Counting Objects at Locations

When counting cards at a location, handle both Card and Deck objects (cards merge into decks when stacked):

```lua
local function countCardsAtLocation(location)
    local count = 0
    for _, obj in ipairs(location:AllObjects()) do
        if obj.tag == "Card" then
            count = count + 1
        elseif obj.tag == "Deck" then
            count = count + obj.getQuantity()
        end
    end
    return count
end
```

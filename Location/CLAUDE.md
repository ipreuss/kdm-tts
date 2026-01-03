# Location - Board & Object Registry

## Modules
- `Location.ttslua` - Board position tracking, spawn locations, drop handlers
- `LocationData.ttslua` - Static location definitions (coordinates, names)
- `LocationGrid.ttslua` - Grid-based positioning for showdown board
- `NamedObject.ttslua` - TTS object GUID registry

## Key Patterns

### Location Lookup
```lua
local loc = Location.Get("Settlement Board")
local pos = loc:Center()  -- world position
```

### Named Objects
```lua
local guid = NamedObject.Get("Survivor Sheet 1")
local obj = getObjectFromGUID(guid)
```

### Drop Handlers
Register with `Location.AddDropHandler(locationName, callback)`.
Callback receives `(object, location)` when object dropped in zone.

## Coordinate System
- TTS uses left-handed coordinates
- +X = left, +Z = toward you, +Y = up
- Use `>showpos` command to debug positions

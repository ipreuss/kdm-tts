# Core - Infrastructure Modules

## Modules
- `Console.ttslua` - Developer console for debug commands
- `Log.ttslua` - Per-module logging with debug toggles

## Console Commands
Register commands via `Console.AddCommand(name, func, help)`.
Commands are invoked with `>command args` in TTS chat.

## Logging Pattern
```lua
local log = require("Kdm/Core/Log").ForModule("ModuleName")
log:Printf("Message with %s", "formatting")
log:Debugf("Debug message - toggleable per module")
```

## Dependencies
- Console requires nothing (bootstrap module)
- Log requires Console, Check, Util

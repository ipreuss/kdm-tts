---
paths: "**/*.ttslua"
---

# Lua Coding Conventions (Critical Reminders)

## Module Export Pattern

**ALWAYS return the module table directly:**
```lua
local Module = {}
function Module.Foo() ... end
return Module  -- ✅ Direct return
```

**NEVER use explicit export tables:**
```lua
return { Foo = Module.Foo }  -- ❌ Causes "forgotten export" bugs
```

## Fail-Fast Philosophy

- **Silent failures are the enemy** - crash visibly, don't hide errors
- **Use assertions** for required parameters and invalid state
- **Avoid pcall** - it obscures errors and makes debugging harder

```lua
assert(Check.Str(params.name, "name is required"))  -- ✅ Crash early
if not params.name then return end  -- ❌ Silent failure
```

## File Size Guidelines (SRP)

| Lines | Status |
|-------|--------|
| < 300 | Good |
| 300-500 | Watch |
| > 500 | Split - likely violates Single Responsibility |

## Check Module for Validation

```lua
assert(Check.Str(value, "must be string"))
assert(Check.Num(value, "must be number"))
assert(Check.Object(value, "must be TTS object"))
assert(Check(condition, "message with %s", arg))
```

## Full Reference

See `kdm-coding-conventions` skill for complete patterns, examples, and rationale.

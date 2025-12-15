---
name: tts-unknown-error
description: Debugging TTS <Unknown Error> messages and destroyed object issues. Use when encountering <Unknown Error> in TTS console, nil reference in async callback, object destroyed prematurely, or Archive.Clean race conditions. Triggers on Unknown Error, destroyed object, null reference, callback nil, Archive.Clean timing.
---

# TTS Unknown Error Debugging

When TTS shows `<Unknown Error>` in the console, it almost always means code tried to operate on a destroyed object. This skill helps diagnose and fix these issues.

## Root Cause: Destroyed Objects

**Problem:** `<Unknown Error>` in TTS console typically means code tried to operate on a destroyed object.

**Common causes:**
- Async callback tries to use an object that was destroyed
- Object reference held across frames after the object was destroyed
- `destruct()` called on an object, then later code tries to use it
- `Archive.Clean()` destroyed an object another operation still needs

**Debugging:** Add logging before operations to track object GUIDs and identify which object was destroyed prematurely. Check if object references are `null` in async callbacks.

## Archive.Clean() Race Conditions

**Problem:** `Archive.Clean()` destroys all spawned archive objects at staging positions. If multiple async operations are running concurrently, one operation's `Archive.Clean()` can destroy objects another operation still needs.

**Symptoms:**
- `<Unknown Error>` in async callback
- Object reference becomes `null` between when it was captured and when callback fires
- Error occurs "after everything completes" — actually occurs when delayed callback fires

**Example Bug:**
```lua
-- This code had a bug:
function ExecuteConsequences(milestone)
    -- Operation 1: Async - callback fires later
    ApplyFightingArt(cardName, function()
        SpawnFightingArtForSurvivor(cardName)  -- Uses Fighting Arts deck
    end)

    -- Operation 2: Runs immediately, doesn't wait for Operation 1
    SpawnStrangeResource("Iron")  -- Calls Archive.Clean()!
    -- Archive.Clean() destroys Fighting Arts deck
    -- Later, Operation 1's callback fires, but deck is null → <Unknown Error>
end
```

**Solution:** Chain operations that use `Archive.Clean()` so they don't overlap:
```lua
function ExecuteConsequences(milestone)
    if consequences.fightingArt then
        ApplyFightingArt(cardName, function()
            SpawnFightingArtForSurvivor(cardName)
            -- Run other spawn operations AFTER fightingArt completes
            if consequences.strangeResource then
                SpawnStrangeResource(consequences.strangeResource)
            end
        end)
    else
        -- No fightingArt, safe to run immediately
        if consequences.strangeResource then
            SpawnStrangeResource(consequences.strangeResource)
        end
    end
end
```

## Debugging Approach

1. **Add logging** to identify when async callbacks fire relative to other operations
2. **Log object references** (`tostring(obj)`) — `null` indicates destroyed object
3. **Create a TTS test command** (e.g., `>testplottwist`) to reproduce the issue consistently
4. **Trace which `Archive.Clean()` call** destroys the needed object

## Progressive Debug Logging Strategy

When functions don't execute, add logging **backwards through the call chain**:

```lua
-- 1. Start at the deepest point that should execute
function Archive.TakeFromDeck(params)
    log:Debugf("[DEBUG] TakeFromDeck START") -- Never appears? Check caller
    -- ...
end

-- 2. Add logging to the caller
function Strain:_TakeFromRewardsDeck(params)
    log:Debugf("[DEBUG] _TakeFromRewardsDeck START") -- Appears? Check function exists
    log:Debugf("[DEBUG] Archive.TakeFromDeck exists: %s", tostring(Archive.TakeFromDeck ~= nil))
    Archive.TakeFromDeck({...})
end

-- 3. Check at call site
log:Debugf("[DEBUG] Strain.Test._TakeRewardCard exists: %s", tostring(Strain.Test._TakeRewardCard ~= nil))
local ok = Strain.Test._TakeRewardCard(Strain, {...})
```

**Pattern:** Work backwards from where execution stops until you find the nil value or missing export.

## Related Issues

### putObject() Copies, Not Moves

**Problem:** TTS's `deck.putObject(card)` does NOT move the card into the deck — it **copies** the card data into the deck, leaving the original card object in place.

**Symptoms:**
- "Stray" cards appearing at staging positions after deck operations
- Cards falling through the table (y coordinate going negative)
- Duplicate cards accumulating over multiple test runs

**Solution:** Always destroy the original card after `putObject()`:
```lua
targetDeck.putObject(card)
card.destruct()  -- Destroy the original - putObject copied it
```

### Deck Formation at Same Position

**Problem:** Spawning multiple cards at same location creates a deck; can't `destruct()` individual cards

**Solution:** Either spawn at different positions, or destroy first card before spawning second

**Debug tip:** If cleanup fails silently, check if objects have auto-grouped into a deck

## Fail Fast Philosophy

**Fail fast with meaningful errors** — Don't silently ignore missing dependencies; log and fail clearly.

Use `assert(obj, "helpful message")` to fail loud and reveal timing issues.

Function existence checks should be rare and only used for:
- **Test environment compatibility** — where modules genuinely might not exist
- **Optional features** — where the functionality is truly optional
- **Never** for hiding missing required dependencies

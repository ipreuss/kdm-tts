# TTS-Specific Implementation Patterns

This document captures patterns, gotchas, and debugging approaches specific to Tabletop Simulator's Lua environment. For core architecture, see [ARCHITECTURE.md](../ARCHITECTURE.md). For testing patterns, see [TESTING.md](./TESTING.md).

---

## Checkbox Interaction Pattern

**Problem**: TTS automatically toggles checkbox visual state on click before calling the onClick handler.

**Solution**: Revert checkbox state in handler, show confirmation dialog, then explicitly set final state.
```lua
onClick = function(_, player)
    -- TTS has already auto-toggled the checkbox
    checkbox:Check(false)  -- Revert to unchecked
    showConfirmationDialog()
    -- On confirm: checkbox:Check(true)
end
```

---

## Dialog API Usage

**Correct Methods**: 
- `dialog:ShowForPlayer(player)` - show to specific player
- `dialog:ShowForAll()` - show to all players  
- `dialog:HideForAll()` - hide from all players

**Common Error**: Using `dialog:Show()` or `dialog:Hide()` (these methods don't exist in PanelKit).

---

## Player Object References

**Problem**: Player objects aren't stable references between different TTS callbacks.

**Solutions**:
1. Compare `player.color` strings instead of object references
2. Better: Eliminate player tracking for shared campaign state (milestones, settlement progress)

---

## Shared vs Personal UI Design

**Campaign-level UI** (visible to all players):
- Settlement milestones, timeline events, campaign progress
- Use `ShowForAll()` and allow any player to interact

**Player-specific UI** (individual sheets):
- Survivor sheets, player boards, personal inventory
- Use `ShowForPlayer(player)` and track player ownership

---

## TTS Debugging Approach

**Essential Patterns**:
- Add comprehensive debug logging with module-specific toggles in `Log.DEBUG_MODULES`
- **Fail fast with meaningful errors** - Don't silently ignore missing dependencies; log and fail clearly
- Log state changes at each step to trace execution flow
- Use `./updateTTS.sh` for rapid iteration and testing

**Function Existence Checks** should be rare and only used for:
- **Test environment compatibility** - where modules genuinely might not exist
- **Optional features** - where the functionality is truly optional, not required
- **Never** for hiding missing required dependencies - those should fail fast with clear error messages

---

## Runtime Error Diagnosis

**When encountering "attempt to call a nil value"**:
1. Add debug logging at the error point to identify what is nil
2. Work backward through execution with targeted logging
3. Test simple hypotheses before complex architectural changes
4. Often the root cause is simpler than initial assumptions (missing function vs. module loading issue)

---

## Archive System Debugging

The Archive system has a two-level structure that's important to understand when debugging "card not found" errors:

**Level 1: Archive → Deck/Container**
- `Archive.Take({ name = "Misc AI", type = "AI" })` looks up the archive using `Archive.Key(name, type)`
- The key maps to an archive name (e.g., `"Core Archive"`) via `Archive.index`
- The archive container is spawned and cached in `Archive.containers`

**Level 2: Container → Individual Card**
- `Container:Take({ name = "Card Name", type = "Card Type" })` searches inside the spawned deck
- **Critical**: Search requires BOTH `name` AND `gm_notes` (type) to match exactly (`Container.ttslua:137-142`)

**Common failure modes**:
1. **Archive name mismatch**: Passing an explicit `archive` parameter that doesn't exist as a TTS object (e.g., `"Strain Rewards"` is a deck inside Core Archive, not an archive itself)
2. **Card name typo**: Card names in the TTS save file must match exactly what the code expects
3. **Type mismatch**: A deck's `gm_notes` differs from its cards' `gm_notes` (e.g., deck is `"Rewards"` but cards inside are `"Fighting Arts"`)
4. **Cached container depletion**: `Archive.Take` removes objects from cached containers. Multiple calls for the same object fail unless `Archive.Clean()` is called between them to spawn a fresh container.

**Debugging steps**:
1. Check `savefile_backup.json` for exact `Nickname` and `GMNotes` values
2. Trace whether the code passes an explicit `archive` parameter (usually wrong) or lets auto-resolution work (usually right)
3. Compare to working patterns like `Showdown.ttslua:376` which takes "Misc AI" without explicit archive
4. If taking the same object twice, ensure `Archive.Clean()` is called between takes

**Pattern for mixed-type decks**: When a deck contains cards of different types (like Strain Rewards containing Fighting Arts, Vermin, and Resources), search by name only within that specific deck rather than relying on type matching.

---

## TTS Spawn Callbacks Are Async

**Critical:** TTS object spawning uses asynchronous callbacks. Code after a spawn call runs BEFORE the spawned object exists.

```lua
-- WRONG - deck goes into archive before card is added
local card = container:Take({
    spawnFunc = function(card)
        deck.putObject(card)  -- Called LATER
    end,
})
archive.putObject(deck)  -- Called IMMEDIATELY - deck has no card yet!

-- CORRECT - wait for spawn to complete
container:Take({
    spawnFunc = function(card)
        deck.putObject(card)
        archive.putObject(deck)  -- Now card is in deck
    end,
})
```

This applies to:
- `object.takeObject({ callback_function = ... })`
- `Container:Take({ spawnFunc = ... })`
- `Archive.Take({ spawnFunc = ... })`

Any logic depending on the spawned object must be inside the callback or use `Wait.frames`.

---

## Infinite Archives

**Behavior**: Infinite archives (bags with infinite contents) have special rules:

1. **Can't put objects back directly** - `infiniteArchive.putObject(obj)` does nothing unless `reset()` is called first
2. **reset() empties the archive** - After `reset()`, `putObject` works but the archive loses its original contents
3. **Pattern for returning decks**: After modifying a deck taken from an infinite archive, call `archive.reset()` then `archive.putObject(deck)` to restore it

**Identifying infinite archives**: Check `template_workshop.json` (the complete mod file with Lua stripped) to see object configurations.

**Common archives in this mod**:
- Core Archive (infinite)
- Fighting Arts Archive (infinite)
- Vermin Archive (infinite)

---

## Mod Configuration Reference

**File**: `template_workshop.json` contains the complete TTS mod save file with Lua scripts stripped out.

**Use cases**:
- Check how objects are configured (infinite vs regular bags, deck contents, etc.)
- Verify card names and `GMNotes` values
- Debug "object not found" errors by confirming exact naming

---

## putObject() Copies, Not Moves

**Problem**: TTS's `deck.putObject(card)` does NOT move the card into the deck - it **copies** the card data into the deck, leaving the original card object in place.

**Symptoms**:
- "Stray" cards appearing at staging positions after deck operations
- Cards falling through the table (y coordinate going negative)
- Duplicate cards accumulating over multiple test runs

**Solution**: Always destroy the original card after `putObject()`:
```lua
targetDeck.putObject(card)
card.destruct()  -- Destroy the original - putObject copied it
```

**Discovery method**: We traced stray cards by their GUID - the same GUID appeared both in the deck AND as a stray object, proving putObject copies rather than moves.

---

## TTS Unknown Error

**Problem**: `<Unknown Error>` in TTS console typically means code tried to operate on a destroyed object.

**Common causes**:
- Async callback tries to use an object that was destroyed
- Object reference held across frames after the object was destroyed
- `destruct()` called on an object, then later code tries to use it

**Debugging**: Add logging before operations to track object GUIDs and identify which object was destroyed prematurely.

---

## Archive.Clean() and Concurrent Async Operations

**Problem**: `Archive.Clean()` destroys all spawned archive objects at staging positions. If multiple async operations are running concurrently, one operation's `Archive.Clean()` can destroy objects another operation still needs.

**Symptoms**:
- `<Unknown Error>` in async callback
- Object reference becomes `null` between when it was captured and when callback fires
- Error occurs "after everything completes" - actually occurs when delayed callback fires

**Example - Plot Twist Milestone Bug (2024-12)**:
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

**Root Cause**: `SpawnStrangeResource` → `Archive.TakeFromDeck` → `Archive.Clean()` destroyed the Fighting Arts deck while `ApplyFightingArt`'s async callback was still pending.

**Solution**: Chain operations that use `Archive.Clean()` so they don't overlap:
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

**Debugging approach**:
1. Add logging to identify when async callbacks fire relative to other operations
2. Log object references (`tostring(obj)`) - `null` indicates destroyed object
3. Create a TTS test command (e.g., `>testplottwist`) to reproduce the issue consistently
4. Trace which `Archive.Clean()` call destroys the needed object

**Key insight**: The error message `<Unknown Error>` gives no indication of what object was destroyed or why. Granular logging showing object state (`params.target=null`) is essential for diagnosis.

---

## CardCustom Type Triggers Import Dialog

**Problem**: When putting a `CardCustom` type object (single custom card, not part of a deck) into a deck, TTS may show the "CUSTOM CARD" import dialog with empty URL fields.

**Symptoms**:
- Empty "CUSTOM CARD" dialog appearing during card transfers
- Dialog shows empty Face/Back URL fields
- Tests pass but dialog is visually distracting

**Cause**: `CardCustom` objects have different internal handling than cards that were originally part of decks.

**Investigation approach**: Check card's type via `object.type` - cards from decks are typically `Card`, standalone custom cards are `CardCustom`.

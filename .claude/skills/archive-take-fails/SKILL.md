---
name: archive-take-fails
description: Why did Archive.Take fail? Diagnose and fix when Archive.Take returns nil, "object not found", "card not found", or "couldn't find X in archive". Use when spawning from archive fails, Take returns nil, object should exist but isn't found, cards aren't spawning, archive lookups return nil. Triggers on Archive.Take nil, Archive.Take fails, object not found, card not found, not found in archive, spawn fails, Take returns nil, couldn't find, archive error.
---

# Archive.Take Fails — Diagnosis and Fix

**Question:** Why did `Archive.Take()` return nil or fail to find an object?

## Quick Diagnosis

| Symptom | Likely Cause | Jump to |
|---------|--------------|---------|
| Worked before, now fails | Cache depletion | [Cache Depletion](#cause-1-cache-depletion) |
| Never worked | Name/type mismatch | [Name Mismatch](#cause-2-nametype-mismatch) |
| First Take works, subsequent fail | Cache depletion | [Cache Depletion](#cause-1-cache-depletion) |
| Works in fresh save, fails in ongoing game | Cache depletion | [Cache Depletion](#cause-1-cache-depletion) |
| Error mentions wrong archive | Explicit archive parameter | [Wrong Archive](#cause-3-wrong-archive-parameter) |
| Works sometimes, fails randomly | Async caching conflict | [Cache Depletion](#cause-1-cache-depletion) |
| Card exists in TTS but not found | Missing archive registration | [Missing Registration](#cause-5-missing-archive-registration) |

---

## Cause 1: Cache Depletion

**Pattern:** Worked before, now fails (or first Take works, second fails)

**Root cause:** Archive containers are cached after first spawn. Taking an object removes it from the cache. If the container only had one instance, subsequent Takes fail.

**Fix:** Call `Archive.Clean()` before re-taking:

```lua
-- WRONG
local obj1 = Archive.Take({ name = "Hunt Party Base", type = "Figurine" })
obj1.destruct()
local obj2 = Archive.Take({ name = "Hunt Party Base", type = "Figurine" })  -- FAILS!

-- CORRECT
local obj1 = Archive.Take({ name = "Hunt Party Base", type = "Figurine" })
obj1.destruct()
Archive.Clean()  -- Clear cache, force fresh spawn
local obj2 = Archive.Take({ name = "Hunt Party Base", type = "Figurine" })  -- Works!
```

**Common scenarios:**
- `Recreate()` functions (destroy old, spawn new)
- Test setup/teardown cycles
- Taking multiple copies of same object
- Reset/restart flows

---

## Cause 2: Name/Type Mismatch

**Pattern:** Never worked, or works for some objects but not others

**Root cause:** Archive search requires BOTH `name` AND `type` (stored in `gm_notes`) to match exactly.

**Diagnosis:**

1. Open `savefile_backup.json`
2. Search for the object's `Nickname`
3. Check the exact spelling and `GMNotes` value

```json
{
  "Nickname": "Founding Stone",
  "GMNotes": "Gear"
}
```

**Common mistakes:**

| Mistake | Example |
|---------|---------|
| Typo in name | `"Founding Stones"` vs `"Founding Stone"` |
| Wrong type | `type = "Resource"` vs actual `GMNotes = "Gear"` |
| Extra spaces | `"Founding Stone "` (trailing space) |
| Case mismatch | `"founding stone"` vs `"Founding Stone"` |

**Fix:** Match savefile exactly:

```lua
-- Check savefile for exact values
Archive.Take({
    name = "Founding Stone",  -- Exact Nickname
    type = "Gear",            -- Exact GMNotes
})
```

---

## Cause 3: Wrong Archive Parameter

**Pattern:** Error mentions unexpected archive name

**Root cause:** Passing explicit `archive` parameter that doesn't match how the object is actually stored.

**Diagnosis:** Check if code passes `archive = "..."`:

```lua
-- WRONG - explicit archive that may not exist
Archive.Take({
    name = "Some Card",
    type = "AI",
    archive = "Nonexistent Archive"  -- Problem!
})

-- CORRECT - let auto-resolution find it
Archive.Take({
    name = "Some Card",
    type = "AI",
    -- No archive parameter - system looks it up
})
```

**How auto-resolution works:**
1. `Archive.Key(name, type)` generates lookup key
2. `Archive.index[key]` returns archive name
3. Archive container spawns from that location

Usually you should NOT pass explicit `archive` — let the system resolve it.

---

## Cause 4: Object Doesn't Exist

**Pattern:** Object genuinely missing from savefile

**Diagnosis:**

1. Search `savefile_backup.json` for the Nickname
2. If not found, object doesn't exist in save
3. Check if it's in an expansion that isn't loaded
4. Check if the object was renamed in a TTS update

**Fix:** Add the object to the save, or handle the missing case:

```lua
local obj = Archive.Take({ name = "New Object", type = "Type" })
if not obj then
    log:Errorf("Object not found - may need to be added to save")
    return
end
```

---

## Cause 5: Missing Archive Registration

**Pattern:** Card exists in TTS save but Archive.Take can't find it

**Root cause:** The card/deck isn't registered in `archiveEntries` in the expansion file.

**Diagnosis:**

1. **Check archive registration exists:**
   ```lua
   -- In Expansion/*.ttslua
   archiveEntries = {
       archive = "Correct Archive Name",  -- Must match guidNames
       entries = {
           { "Exact Card Name", "Correct Type" },
       },
   }
   ```

2. **Check GUID mapping exists:**
   ```lua
   guidNames = { ["abc123"] = "Archive Name" }
   ```

3. **Verify in TTS** that the GUID points to the right container

**Common issues:**
- Typo in archive name (doesn't match guidNames)
- Missing entry for the card
- Wrong type string in entries

**Fix:** Add proper registration in expansion file:

```lua
-- 1. Add GUID mapping
guidNames = { ["abc123"] = "My Archive" },

-- 2. Add archive entries
archiveEntries = {
    archive = "My Archive",
    entries = {
        { "Card Name", "Card Type" },
    },
},
```

---

## Debugging Commands

**Search template for card:**
```bash
# Find card in template
grep -i "nickname.*cardname" template_workshop.json

# Find archive registration
grep -r "cardname" Expansion/*.ttslua

# Check GUID mapping
grep "guidNames" Expansion/*.ttslua | grep -i "archivename"
```

**TTS Console:**
```
>debug Archive on
>interact Archive Name
```

Then manually inspect contents to verify card exists and names match.

---

## Debugging Checklist

When Archive.Take fails:

- [ ] **Did it work before?** → Try `Archive.Clean()` first
- [ ] **Check savefile** → Search `savefile_backup.json` for exact name/GMNotes
- [ ] **Check for typos** → Compare code string to savefile exactly
- [ ] **Check archive parameter** → Remove explicit `archive` if present
- [ ] **Add logging** → `log:Debugf("Taking: name=%s, type=%s", name, type)`

## Quick Fix Reference

```lua
-- Most common fix: cache depletion
Archive.Clean()
local obj = Archive.Take({ name = "...", type = "..." })

-- Verify name/type from savefile
-- Search savefile_backup.json, use exact Nickname and GMNotes

-- Remove explicit archive parameter if present
Archive.Take({
    name = "...",
    type = "...",
    -- archive = "..." -- Remove this line
})
```

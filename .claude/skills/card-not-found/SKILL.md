---
name: card-not-found
description: Debugging "card not found" and "couldn't find X in archive" errors in KDM TTS mod. Use when Archive.Take() fails, cards aren't spawning, or archive lookups return nil. Triggers on card not found, couldn't find, archive error, spawn failed, nil card.
---

# Card Not Found Debugging

## When to Use

Use when encountering:
- `"Couldn't find [CardName] (Type) in archive [ArchiveName]"`
- Cards not spawning from archive
- Archive lookups returning nil
- Silent failures in card operations

## Diagnostic Steps

### 1. Check Archive Registration

Does the archive entry exist in the expansion file?

```lua
archiveEntries = {
    archive = "Correct Archive Name",  -- Must match guidNames
    entries = {
        { "Exact Card Name", "Correct Type" },
    },
}
```

**Common issues:**
- Typo in archive name
- Missing entry for the card
- Wrong type string

### 2. Check GUID Mapping

Does the GUID point to the right container?

```lua
guidNames = { ["abc123"] = "Archive Name" }
```

**Verify in TTS:**
- The GUID exists in the save file
- Points to the correct infinite bag/deck

### 3. Verify TTS Card Name

Card names must match **exactly**:

```bash
# Search template for card
grep -i "cardname" template_workshop.json
```

**Or in TTS console:**
```
>interact Archive Name
```
Then manually inspect contents.

**Check for:**
- Typos
- Extra spaces
- Case sensitivity
- Unexpected `[variant]` suffixes

### 4. Check Type Matching

GMNotes must match exactly:

```lua
Archive.Take({ name = "Card Name", type = "Gear" })
-- Card in TTS must have GMNotes = "Gear"
```

**Common type mismatches:**
- `"Gear"` vs `"Equipment"`
- `"Fighting Arts"` vs `"Secret Fighting Arts"`
- `"Monster Resources"` vs `"Strange Resources"`

### 5. Review Variant Handling

If card is `"Item [special]"`, check that stats use canonical name:

```lua
weaponStats = {
    ["Item"] = { ... }  -- Canonical name only, no suffix
}
```

The system auto-matches `"Item [special]"` to `"Item"`.

### 6. Check Deck Membership

For resource rewards, verify which deck contains the card:

```bash
grep -i "cardname" template_workshop.json
```

Look at `ContainedObjects` to see the parent deck.

**Common mistake:** Assuming a resource is in "Strange Resources" when it's actually in "Monster Resources".

## Quick Debugging Commands

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

## Common Causes

| Symptom | Likely Cause |
|---------|--------------|
| Card never existed | Typo in name, card not in TTS save |
| Card exists but not found | Wrong archive registration |
| Works sometimes | Async caching conflict (see archive-system skill) |
| Type mismatch | GMNotes on card differs from code |

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/Archive.ttslua` — Archive lookup logic
- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Registration data
- `/Users/ilja/Documents/GitHub/kdm/template_workshop.json` — Actual TTS objects

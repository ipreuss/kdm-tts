---
name: rulebook-verification
description: Looking up KDM rulebook pages in template_workshop.json to verify game rules, monster rewards, or special mechanics. Use when wiki data is incomplete, verifying reward tables, checking game rules from source, or accessing showdown/aftermath pages. Triggers on rulebook page, verify rules, check rewards, wiki incomplete, rules verification, showdown page, aftermath, Core Rules state.
---

# Rulebook Page Verification

## When to Use

Use when:
- Wiki data is incomplete or suspect
- Verifying monster reward tables
- Checking special rules or mechanics
- Need authoritative game rule source
- Confirming showdown setup details
- Accessing showdown or aftermath pages for monster behavior analysis

## How Rulebook Pages Work in TTS

Rulebook pages are stored as **TTS object states with image URLs** in `template_workshop.json`. Each rulebook is a multi-state object where each state corresponds to a different page. State data includes `CustomImage.ImageURL` pointing to Steam-hosted or other images.

### Architecture

```
Rulebook Object (e.g., "Core Rules")
├── Nickname: "Core Rules"
├── States: {
│   ├── "71": { Nickname: "Legendary Monsters", CustomImage: { ImageURL: "..." } }
│   ├── "84": { Nickname: "Showdown: Butcher", CustomImage: { ImageURL: "..." } }
│   ├── "89": { Nickname: "Showdown: White Lion", CustomImage: { ImageURL: "..." } }
│   └── ... (90+ states in Core Rules)
}
```

## Lookup Process

### Step 1: Find the Rules Reference

Monster definitions reference rulebook pages:
```lua
rules = { "Core Rules", 71 }  -- [rulebook name, page state number]
```

### Step 2: Find Rulebook Object in Template

Search for the rulebook object in `template_workshop.json`:
```bash
grep -n '"Nickname": "Core Rules"' template_workshop.json
```

Then navigate to that line and find the `States` object (may be thousands of lines later).

### Step 3: Find the Specific Page State

Look for the state number within the `States` object:

```json
"States": {
    "89": {
        "Nickname": "Showdown: White Lion",
        "CustomImage": {
            "ImageURL": "https://steamusercontent-a.akamaihd.net/ugc/..."
        }
    }
}
```

### Step 4: Download and Process the Image

**CRITICAL: Image handling workflow (prevents errors)**

1. **Download to temporary file** (don't assume extension from URL):
   ```bash
   curl -sL "<URL>" -o /tmp/kdm_rulebook_pages/page.tmp
   ```

2. **Check actual file type** (URLs often lie):
   ```bash
   file /tmp/kdm_rulebook_pages/page.tmp
   ```
   - Output: "JPEG image data" → rename to `.jpg`
   - Output: "PNG image data" → rename to `.png`

3. **Rename with correct extension**:
   ```bash
   # If JPEG:
   mv /tmp/kdm_rulebook_pages/page.tmp /tmp/kdm_rulebook_pages/page.jpg
   # If PNG:
   mv /tmp/kdm_rulebook_pages/page.tmp /tmp/kdm_rulebook_pages/page.png
   ```

4. **Check file size** (Read tool limit is ~5MB):
   ```bash
   ls -lh /tmp/kdm_rulebook_pages/page.*
   ```

5. **If PNG > 5MB, convert to JPEG**:
   ```bash
   sips -s format jpeg -s formatOptions 80 /tmp/kdm_rulebook_pages/page.png --out /tmp/kdm_rulebook_pages/page.jpg
   ```
   - Quality 80 is good balance (70-90 acceptable)
   - Output filename MUST have `.jpg` extension
   - Images under 5MB typically work without conversion

6. **Read with Claude's Read tool**:
   ```
   Read tool on /tmp/kdm_rulebook_pages/page.jpg (or .png if small enough)
   ```
   - Filename extension MUST match actual content type
   - File MUST be <5MB

### Step 5: Document Findings Immediately

**Best practice:** Document findings right after reading each page. This prevents data loss if subsequent operations fail.

Create a notes file or update documentation with:
- State number and page name
- Key information extracted
- Any special rules or mechanics

## Core Rules State Mappings (Showdown Pages)

Known showdown page states in Core Rules:

| State | Monster |
|-------|---------|
| 84 | Showdown: Butcher |
| 85 | Showdown: King's Man |
| 86 | Showdown: The Hand |
| 87 | Showdown: Phoenix |
| 88 | Showdown: Screaming Antelope |
| 89 | Showdown: White Lion |
| 94 | Showdown: Watcher |
| 96 | Showdown: Gold Smoke Knight |

## Expansion Rulebook Locations

Each expansion has its own rulebook object:

| Rulebook Name | Typical Contents |
|---------------|------------------|
| `"Core Rules"` | Core monsters, main game rules (90+ states) |
| `"Gorm Rules"` | Gorm expansion rules and showdown |
| `"Dragon King Rules"` | Dragon King + The Tyrant showdowns |
| `"Sunstalker Rules"` | Sunstalker expansion |
| `"Spidicules Rules"` | Spidicules expansion |
| `"Flower Knight Rules"` | Flower Knight expansion |
| `"Dung Beetle Knight Rules"` | Dung Beetle Knight expansion |
| `"Lion Knight Rules"` | Lion Knight expansion |
| `"Slenderman Rules"` | Slenderman expansion |
| `"Manhunter Rules"` | Manhunter expansion |
| `"Lonely Tree Rules"` | Lonely Tree expansion |

**Expansion showdown pages** are typically states 4-6, but this varies. Some expansions have multiple showdown variants (e.g., Dragon King has both "Dragon King" and "The Tyrant" showdowns).

## Working Directory

Use `/tmp/kdm_rulebook_pages/` as working directory for downloads:

```bash
mkdir -p /tmp/kdm_rulebook_pages
cd /tmp/kdm_rulebook_pages
```

This keeps files organized and separate from other temp files.

## Example: Finding White Lion Showdown Page

1. **Find state reference**: State 89 in Core Rules
2. **Search template**:
   ```bash
   grep -n '"Nickname": "Core Rules"' template_workshop.json
   # Navigate to States section
   grep -A 10 '"89":' template_workshop.json | grep -A 5 "Showdown"
   ```
3. **Extract URL** from CustomImage.ImageURL
4. **Download and process**:
   ```bash
   curl -sL "<URL>" -o page.tmp
   file page.tmp  # Check type
   mv page.tmp page.jpg  # If JPEG
   ls -lh page.jpg  # Check size
   # If <5MB, read directly; if >5MB and PNG, convert first
   ```
5. **Read** with Read tool
6. **Document** findings from the showdown page

## Example: Beast of Sorrow Rewards

1. Monster definition: `rules = { "Core Rules", 71 }`
2. State 71 is "Legendary Monsters" page
3. Download and view image showing all legendary monster rewards including Beast of Sorrow
4. Extract reward table data

## Quick Search Commands

```bash
# Find rulebook object location
grep -n '"Nickname": "Core Rules"' template_workshop.json

# Find specific state (context needed - States may be far from Nickname)
grep -A 5 '"89":' template_workshop.json

# Find by state nickname
grep -B 2 -A 10 '"Nickname": "Showdown: White Lion"' template_workshop.json

# List all expansion rulebooks
grep '"Nickname":.*Rules"' template_workshop.json | grep -v "//\|Core Rules"
```

## When Wiki is Incomplete

The KDM wiki often has incomplete reward tables, especially for:
- Legendary monsters
- Expansion monsters
- Special monster variants (L4+)
- Showdown-specific mechanics
- Aftermath tables

**Rulebook images are authoritative** — use them to verify or fill gaps in wiki data.

## Image Processing Best Practices

1. **Always check file type first** — Don't trust URL extensions
2. **Document immediately after reading** — Prevents data loss on errors
3. **Convert large PNGs to JPEG** — Saves time and prevents Read tool failures
4. **Use quality 80 for conversions** — Good balance of quality/size
5. **Keep working directory clean** — Delete temp files after documenting

## Troubleshooting

### Read Tool Fails on Image

- **Check file size**: `ls -lh file.jpg` — must be <5MB
- **Check extension matches content**: `file file.jpg` should say "JPEG"
- **Convert PNG to JPEG** if needed
- **Re-download** if file is corrupted (check with `file` command)

### Can't Find State Number

- States object may be thousands of lines after the Nickname
- Use `grep -A 10000` to get more context
- Search for the specific state number: `grep '"89":' template_workshop.json`
- Check if you're looking in the right rulebook object

### Image URL Returns 404

- Steam URLs may expire or change
- Check if template_workshop.json is up to date
- Try re-loading from latest backup

## Limitations

- Images require manual inspection (no OCR available)
- State numbers may not match page numbers in physical rulebook
- Expansion structures vary (no standard state numbering)
- Large images require conversion before reading
- Some state nicknames may be generic ("Page 1", "Page 2") instead of descriptive

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/template_workshop.json` — TTS save with rulebook images
- `Expansion/*.ttslua` — Monster `rules` references linking to states
- `/tmp/kdm_rulebook_pages/` — Working directory for image downloads

## State Discovery Strategy

When you need to find a specific page but don't know the state number:

1. **Check monster definition** for `rules = { "Rulebook Name", state_number }`
2. **Search by nickname** if you know the page name: `grep "Showdown: White Lion"`
3. **Browse state range** for expansions (typically states 1-20)
4. **Extract all state nicknames** to build a map:
   ```bash
   grep -A 3 '"States":' template_workshop.json | grep '"Nickname":'
   ```

## Progressive Disclosure

For detailed state mapping tables and expansion-specific page layouts, see:
- [STATE_MAPPINGS.md](STATE_MAPPINGS.md) — Complete state number reference (if created)
- [EXPANSION_PAGES.md](EXPANSION_PAGES.md) — Expansion-specific page structures (if created)

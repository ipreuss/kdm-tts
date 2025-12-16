---
name: rulebook-verification
description: Looking up KDM rulebook pages in template_workshop.json to verify game rules, monster rewards, or special mechanics. Use when wiki data is incomplete, verifying reward tables, or checking game rules from source. Triggers on rulebook page, verify rules, check rewards, wiki incomplete, rules verification.
---

# Rulebook Page Verification

## When to Use

Use when:
- Wiki data is incomplete or suspect
- Verifying monster reward tables
- Checking special rules or mechanics
- Need authoritative game rule source
- Confirming showdown setup details

## How Rulebook Pages Work in TTS

Rulebook pages are stored as image URLs in `template_workshop.json`. Each rulebook is a multi-state object where each state is a different page.

## Lookup Process

### Step 1: Find the Rules Reference

Monster definitions reference rulebook pages:
```lua
rules = { "Core Rules", 71 }  -- [rulebook name, page state]
```

### Step 2: Find Rulebook in Template

Search for the rulebook object:
```bash
grep -A 50 '"Nickname": "Core Rules"' template_workshop.json
```

### Step 3: Find the Page State

Look for the `States` object within the rulebook. Each state number corresponds to a page:

```json
"States": {
    "71": {
        "Nickname": "Legendary Monsters",
        "CustomImage": {
            "ImageURL": "https://..."
        }
    }
}
```

### Step 4: View the Image

Download or view the `ImageURL` to see the actual rulebook page content.

## Example: Beast of Sorrow Rewards

1. Monster definition: `rules = { "Core Rules", 71 }`
2. State 71 is "Legendary Monsters" page
3. Image shows all legendary monster rewards including Beast of Sorrow

## Quick Commands

```bash
# Find rulebook object
grep -n '"Nickname": "Core Rules"' template_workshop.json

# Find specific state (may need to navigate to States section)
grep -A 5 '"71":' template_workshop.json

# Find image URL for a state
grep -B 2 -A 10 '"Nickname": "Legendary Monsters"' template_workshop.json
```

## When Wiki is Incomplete

The KDM wiki often has incomplete reward tables, especially for:
- Legendary monsters
- Expansion monsters
- Special monster variants (L4+)

**Rulebook images are authoritative** — use them to verify or fill gaps.

## Common Rulebook Names

| Name | Contents |
|------|----------|
| `"Core Rules"` | Main game rules, core monsters |
| `"Gorm Rules"` | Gorm expansion rules |
| `"Dragon King Rules"` | Dragon King expansion |
| `"Sunstalker Rules"` | Sunstalker expansion |

## Limitations

- Images require manual inspection (no OCR)
- State numbers may not match page numbers in physical book
- Some expansions may have different structures

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/template_workshop.json` — TTS save with rulebook images
- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Monster `rules` references

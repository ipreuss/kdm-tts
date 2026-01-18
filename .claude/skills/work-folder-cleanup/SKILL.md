---
name: work-folder-cleanup
description: Review work folders before deletion to prevent knowledge loss. Use when closing beads, during retrospectives, or when deleting work/<bead-id>/ folders. Triggers on work folder, delete folder, rm -rf work, cleanup work, archive work folder, close bead folder.
---

# Work Folder Cleanup

**Problem:** Work folders contain design decisions, research notes, and context that may not be captured elsewhere. Deleting without review loses knowledge.

## When This Applies

- Closing a bead and its work folder exists
- Retrospective cleanup phase
- Any `rm -rf work/kdm-*` command

## Before Deleting: Mandatory Review

### Step 1: List Contents

```bash
ls -la work/kdm-xxx/
```

### Step 2: Read Each File

For each file, ask:

| File Type | Question | If Yes → Action |
|-----------|----------|-----------------|
| `design.md` | Does this contain patterns not in code comments? | → Promote to ARCHITECTURE.md or skill |
| `research.md` | Are external URLs still useful? | → Add to relevant skill or code comment |
| `decisions.md` | Are rationales not obvious from code? | → Promote to ADR or ARCHITECTURE.md |
| `progress.md` | Any unfinished work not tracked in beads? | → Create bead for remaining work |
| `*.md` (other) | Would future developers benefit from this? | → Promote to appropriate location |

### Step 3: Check Staleness

**Staleness indicators (safe to delete without promotion):**
- Bead closed > 1 week ago AND learnings already processed
- Content contradicts actual implementation (code is source of truth)
- Information already captured in LEARNINGS.md processing
- Pure status tracking (superseded by bead history)

### Step 4: Promote or Delete

```
For each file:
├── Valuable content found?
│   ├── Yes → Copy to permanent location first
│   └── No → Safe to delete
└── All files reviewed?
    └── Yes → rm -rf work/kdm-xxx/
```

## Quick Reference: Promotion Targets

| Content Type | Target Location |
|--------------|-----------------|
| Design patterns | `.claude/skills/` (new or existing skill) |
| Architecture decisions | `ARCHITECTURE.md` or `docs/adr/` |
| API gotchas | Relevant skill (e.g., `tts-archive-spawning`) |
| External references | Code comments near usage |
| Process insights | Already in LEARNINGS.md → delete |

## Common Mistake

**Deleting without reading:**
```bash
# WRONG - skips review
rm -rf work/kdm-xxx/

# RIGHT - review first
ls work/kdm-xxx/
cat work/kdm-xxx/design.md
# ... assess each file ...
rm -rf work/kdm-xxx/
```

## Integration

- **Team Coach** uses during retrospective cleanup (Step 8)
- Triggered by `handover-manager` cleanup operations
- Complements `learning-capture` skill (captures insights, this preserves artifacts)

---
name: session-closing
description: |
  TRUE SESSION END only. Invoke when:
  - User says: done, finished, thanks, that's all, end session
  - Handover to another role created
  - Switching roles within session
  NOT for: waiting for input, asking questions, presenting options (use turn-complete instead)
triggers:
  - done
  - finished
  - thanks
  - that's all
  - end session
  - handover created
  - switching roles
---

# Session Closing Protocol

## When to Use

**ONLY at true session end:**
- User explicitly ends: "done", "finished", "thanks", "that's all", "end session"
- Handover to another role created
- Switching to different role within same conversation

**NOT for:**
- Waiting for user input → use `turn-complete`
- Asking questions → use `turn-complete`
- Presenting options → use `turn-complete`

## Step 1: Git Status Check

**Run BEFORE closing if any code was changed this session:**

```bash
git status
```

### Evaluate Uncommitted Changes

| Condition | Action |
|-----------|--------|
| Tests pass AND code-reviewer approved | ✅ Commit and push |
| Tests pass but no review yet | ⚠️ Flag in closing — work ready for review |
| Tests failing or incomplete | ⚠️ Flag in closing — work in progress |
| Process/doc changes only (no code) | ✅ Commit and push (no review needed) |

### What Needs Commits

| Directory | Tracked | Needs Commit? |
|-----------|---------|---------------|
| `*.ttslua`, `tests/` | ✅ Yes | Code changes need commit |
| `.claude/agents/`, `.claude/skills/` | ✅ Yes | Agent/skill updates need commit |
| `handover/` | ❌ No (gitignored) | Never commit |
| `.beads/` | ✅ Yes | Auto-synced by hooks |

### When Committing

```bash
git add <files>
git commit -m "[type]: [description]

Bead: kdm-xxx

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push
```

**Types:** feat, fix, refactor, test, docs, chore

## Step 2: Learning Capture (MANDATORY)

**Before closing, you MUST write to `handover/LEARNINGS.md`.**

### Part A: Self-Check Questions

Ask yourself:
1. Did I do something wrong or unwanted this session?
2. Did I fail to do something that should have been done?
3. Was I reminded to do something that should have been automatic?
4. Did I learn something new about the project?
5. Did I spend significant time understanding code? What documentation would have helped?

### Part B: Skill/Agent Usage Stats

**ALWAYS required, even if no learnings from Part A:**
- Which skills/agents did you use?
- Which were helpful?
- Which should have triggered but didn't?
- Which triggered unnecessarily?

### Part C: Write to File

**Use Edit tool to append to `/Users/ilja/Documents/GitHub/kdm/handover/LEARNINGS.md`:**

Find the `<!-- Add new learnings below this line -->` marker and add:

```markdown
### [YYYY-MM-DD] [Role] Brief title

**Context:** What you were working on
**Learning:** What you discovered (or "No process issues encountered")
**Suggested Action:** What should be done (or "None")
**Category:** skill | agent | doc | process | none

**Skills/Agents this session:**
- Used: [list all skills and agents invoked]
- Helpful: [which worked well]
- Should have triggered: [which didn't activate when expected]
- Unnecessary: [which triggered but weren't needed]
```

⚠️ **DO NOT just output to terminal — you MUST write to the file.**

## Step 3: Closing (use turn-complete)

After git check and learning capture, use `turn-complete` skill for signature + voice.

The closing message should summarize the session:
- What was accomplished
- What's uncommitted (if any) and why
- What the next session needs to do

## Remote Session Handling

| Command | Available | Fallback |
|---------|-----------|----------|
| `git` | ✅ Always | — |
| `say` | ❌ macOS only | `echo "[Voice] message"` |
| `bd` | ❌ Local only | Skip bead checks |

## Checklist

**Before ending session:**
- [ ] Ran `git status` (if code changed)
- [ ] Committed/pushed OR documented why not
- [ ] Wrote learning entry to LEARNINGS.md (with skill/agent stats)
- [ ] Used turn-complete for signature + voice
- [ ] If handover created: used handover-manager agent

## Complete Example

**Session end after code changes:**

1. Check git:
```bash
git status
# Shows 3 files modified, tests pass, reviewer approved
git add ResourceRewards.ttslua Expansion/Core.ttslua Expansion/Gorm.ttslua
git commit -m "fix: centralize resource validation

Bead: kdm-xyz

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push
```

2. Write learning entry to LEARNINGS.md

3. Final message with turn-complete:
```markdown
Session complete. Resource validation wurde zentralisiert.

Commits:
- abc1234: fix: centralize resource validation

**═══════════════════════════════════════**
**║      IMPLEMENTER ROLE END            ║**
**║      2025-12-10 14:30 UTC            ║**
**═══════════════════════════════════════**
```
```bash
say -v Viktor "Implementierer fertig. Session abgeschlossen."
```

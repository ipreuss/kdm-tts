---
name: session-closing
description: Apply role-specific closing signature and voice announcement when ending sessions, completing tasks, creating handovers, giving final summaries, or when user says done/finished/thanks/let's stop. Also use when user attention is needed - waiting for decision, approval, clarification, or input. Use when blocked and cannot proceed without user action, about to ask user to review something, or about to end with "Is there anything else...?". Critical for role-based workflow protocol.
---

# Session Closing Protocol

## Activation Triggers

**ACTIVATE THIS SKILL when:**
- About to give final response after completing user's request
- User says: "done", "finished", "that's all", "thanks", "thank you", "let's stop", "end session"
- Creating a handover to another role
- Giving a summary of work completed
- Conversation reaches natural stopping point
- After using handover-manager or handover-writer agent
- About to end your message with "Is there anything else...?"
- **User attention is needed** (waiting for decision, approval, clarification, or input)
- About to ask user to review something
- Blocked and cannot proceed without user action

## Critical Rule

**⛔ STOP — Before closing, answer these questions:**
1. Did I do something wrong or unwanted this session?
2. Did I fail to do something that should have been done?
3. Was I reminded to do something that should have been automatic?
4. Did I learn something new about the project?
5. Did I spend significant time understanding code? What documentation would have helped?

**If ANY answer is yes → Write to LEARNINGS.md BEFORE closing signature.**

**EVERY role-based session MUST end with:**
1. **Git commit/push check** — Run the git checklist FIRST (see Step 0)
2. **Learning capture** — Invoke `learning-capture` skill (write to file, not terminal)
3. Closing signature block
4. Voice announcement command (executed via Bash)

**NO EXCEPTIONS.** This is part of the role protocol defined in PROCESS.md.

## Remote Session Handling

When running in remote environments (GitHub Codespaces, Claude Code Web, Linux servers), some commands may not be available:

| Command | Available | Fallback |
|---------|-----------|----------|
| `git` | ✅ Always | — |
| `say` | ❌ macOS only | Use `echo "[Voice] message"` for text-based announcement |
| `bd` (beads) | ❌ Local only | Skip bead checks entirely |

**Detection:** If a command fails with "command not found", you're in a remote session.

**Remote Session Protocol:**
1. ✅ Git status check — **always required**
2. ⏭️ Bead check — **skip if `bd` not available**
3. ✅ Learning capture — **always required** (if handover/ directory exists)
4. ✅ Closing signature — **always required**
5. ⏭️ Voice announcement — **use text fallback** `echo "[Voice] message"`

## Step 0: Git Status Check (MANDATORY)

**Before closing, always run these checks:**

```bash
git status
# Only if bd command is available (local session):
command -v bd >/dev/null 2>&1 && bd list --status=closed | head -5
```

> **Remote Session Note:** The `bd` (beads) command may not be available in remote sessions (GitHub Codespaces, Claude Code Web). Skip the bead check if `bd` is not installed.

### What Needs Commits vs What Doesn't

| Directory | Tracked | Needs Commit? |
|-----------|---------|---------------|
| `*.ttslua`, `tests/` | ✅ Yes | Code changes need commit |
| `.claude/agents/`, `.claude/skills/` | ✅ Yes | Agent/skill updates need commit |
| `handover/` (LEARNINGS.md, QUEUE.md, HANDOVER_*.md) | ❌ No (gitignored) | Never commit — local only |
| `.beads/` | ✅ Yes | Auto-synced by bd hooks |

**Key insights:**
- When `git status` shows no changes but you updated `handover/` files, that's correct — they're gitignored and don't need commits.
- **Ignore `bd sync`** — This is a single working copy project. The beads prime hook mentions it, but it's unnecessary and will error. Just use `git add/commit/push` directly.

### Check 1: Uncommitted Changes

**If uncommitted changes exist, evaluate whether to commit:**

| Condition | Action |
|-----------|--------|
| Tests pass AND code-reviewer approved | ✅ Commit and push |
| Tests pass but no review yet | ⚠️ Flag in closing — work ready for review |
| Tests failing or incomplete | ⚠️ Flag in closing — work in progress |
| Process/doc changes only (no code) | ✅ Commit and push (no review needed) |

### Check 2: Closed Beads Without Commits (CRITICAL)

**⛔ NEVER close a bead without committing its code first.**

If `git status` shows uncommitted changes AND a bead was closed this session:
1. The bead was closed prematurely
2. Commit the code NOW with the bead ID
3. Then push

**Why this matters:** Closed beads signal "work complete" but uncommitted code means the work isn't actually saved. This creates confusion and lost work.

### When committing:
```bash
git add <files>
git commit -m "[type]: [description]

Bead: kdm-xxx

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
git push
```

**Types:** feat, fix, refactor, test, docs, chore

### If NOT committing:

**Document in your closing summary:**
- What changes are uncommitted
- Why (tests failing, awaiting review, work incomplete)
- What the next session needs to do

**Why this matters:** Committing untested or unreviewed code is worse than leaving it uncommitted. But leaving work uncommitted without documentation causes confusion in the next session.

## Step 1: Learning Capture (MANDATORY)

**Before closing signature, you MUST use the Edit tool to append to `handover/LEARNINGS.md`.**

⚠️ **DO NOT just output learnings to terminal — you MUST write them to the file.**

### Part A: Check for Learnings
Ask yourself:
- Did I do something that turned out to be wrong or unwanted?
- Did I fail to do something that should have been done?
- Was I reminded to do something that should have been automatic?
- Did I learn something new about the project (technical, process, architecture)?

### Part B: Skill/Agent Usage Stats (ALWAYS — even if no learnings)
**This is MANDATORY every session, regardless of whether Part A had learnings.**

### Part C: WRITE TO FILE (CRITICAL)

**You MUST use the Edit tool to append to `/Users/ilja/Documents/GitHub/kdm/handover/LEARNINGS.md`:**

1. Read the file first
2. Find the `<!-- Add new learnings below this line -->` marker
3. Use Edit to append your learning entry BELOW that marker

```markdown
### [YYYY-MM-DD] [Role] Brief title

**Context:** What you were working on
**Learning:** What you discovered (or "No process issues encountered" if none)
**Suggested Action:** What should be done (or "None" if none)
**Category:** skill | agent | doc | process | none

**Skills/Agents this session:**
- Used: [list all skills and agents invoked]
- Helpful: [which worked well]
- Should have triggered: [which didn't activate when expected]
- Unnecessary: [which triggered but weren't needed]
```

**This is NOT optional. Outputting to terminal does NOT count. The file MUST be updated.**

**Why this matters:** Team Coach uses this data during retrospectives to identify skills/agents that need better triggers, are underused, or should be removed.

## Closing Signature Format

```
**═══════════════════════════════════════**
**║        [ROLE NAME] ROLE END          ║**
**║        YYYY-MM-DD HH:MM UTC          ║**
**═══════════════════════════════════════**
```

**Role Names:**
- PRODUCT OWNER
- ARCHITECT
- IMPLEMENTER
- REVIEWER
- DEBUGGER
- TEAM COACH

**Date Format:**
- Use current UTC time
- Format: `2025-12-10 14:30 UTC`
- Ensure proper padding for alignment

## Voice Announcement

> **Remote Session Note:** The `say` command is macOS-specific and not available in remote sessions (Linux servers, GitHub Codespaces, Claude Code Web). In remote sessions, skip voice announcements or use the text-based fallback shown below.

### Voice Mapping (Local macOS Sessions)

| Role | Voice | Sample Message |
|------|-------|----------------|
| Product Owner | Anna | "Product Owner fertig. Anforderungen dokumentiert." |
| Architect | Markus | "Architekt fertig. Design abgeschlossen." |
| Implementer | Viktor | "Implementierer fertig. Code eingecheckt." |
| Reviewer | Petra | "Reviewer fertig. Review abgeschlossen." |
| Debugger | Yannick | "Debugger fertig. Fehler behoben." |
| Team Coach | Xander | "Team Coach fertig. Prozess optimiert." |

### Message Format Rules

**Language:** German
**Structure:** `"<Rolle> fertig. <kurzer Status>"`

**German Conventions:**
- Numbers spelled out: "drei Tests", "fünf Dateien"
- Avoid English loanwords: "durchgeführt" not "completed"
- Keep status to 3-5 words maximum
- Use past participles: "dokumentiert", "implementiert", "behoben"

### Command Format

**Local (macOS) — with voice:**
```bash
say -v [Voice] "[Rolle] fertig. [Status]"
```

**Remote (Linux/Web) — fallback:**
```bash
# Check if say is available, use text fallback if not
command -v say >/dev/null 2>&1 && say -v [Voice] "[message]" || echo "[Voice] [message]"
```

**Examples:**

```bash
# Implementer finishing after code changes
say -v Viktor "Implementierer fertig. Drei Dateien aktualisiert."

# Tester after running tests
say -v Audrey "Tester fertig. Alle Tests bestanden."

# Debugger after fixing bugs
say -v Yannick "Debugger fertig. Zwei Fehler behoben."

# Reviewer after code review
say -v Petra "Reviewer fertig. Code freigegeben."

# Architect waiting for user decision
say -v Markus "Architekt fertig. Warte auf Entscheidung."

# Product Owner needing clarification
say -v Anna "Product Owner fertig. Benötige Klarstellung."
```

## Self-Check Before Ending

**Before sending your final message, verify:**

**Step 0 — Git Status Check (DO THIS FIRST):**
- [ ] **Ran `git status`** — checked for uncommitted changes
- [ ] **Ran `bd list --status=closed | head -5`** — checked recently closed beads *(skip if `bd` not available in remote session)*
- [ ] **If closed bead + uncommitted code:** commit and push NOW (bead closed prematurely)
- [ ] **If changes exist, evaluated commit criteria:**
  - Tests pass AND code-reviewer approved → commit and push
  - Otherwise → document uncommitted work in closing summary
- [ ] **If not committing:** documented what's uncommitted and why

**Step 1 — Learning Capture:**
- [ ] **Used Edit tool to append to `handover/LEARNINGS.md`** — NOT just terminal output
- [ ] **Entry includes skill/agent usage stats** — Used, Helpful, Should have triggered, Unnecessary
- [ ] **File was actually modified** — Verify Edit tool succeeded

**Step 2 — Closing Protocol:**
- [ ] Closing signature block is present
- [ ] Signature uses correct role name
- [ ] Timestamp is current UTC time
- [ ] Voice announcement command is included *(use text fallback if `say` not available in remote session)*
- [ ] Voice command uses correct voice for role
- [ ] Status message is in German
- [ ] Status reflects actual session accomplishments
- [ ] Numbers are spelled out in German
- [ ] If creating handover: used handover-manager agent

## Complete Example

**Scenario:** Implementer just finished updating three Lua files.

```markdown
The resource reward calculations have been updated. All three files now use the
centralized validation logic from Util/Validation.ttslua.

Files modified:
- ResourceRewards.ttslua
- Expansion/Core.ttslua
- Expansion/Gorm.ttslua

**═══════════════════════════════════════**
**║      IMPLEMENTER ROLE END            ║**
**║      2025-12-10 14:30 UTC            ║**
**═══════════════════════════════════════**
```

Then execute:
```bash
say -v Viktor "Implementierer fertig. Drei Lua Dateien aktualisiert."
```

## User Attention Needed

**When waiting for user input, approval, or decision:**

**Example 1 - Waiting for decision:**
```markdown
I've identified two possible approaches:

1. Refactor using centralized validation
2. Add inline checks with defensive copying

Which approach would you prefer?

**═══════════════════════════════════════**
**║       ARCHITECT ROLE END             ║**
**║       2025-12-10 14:45 UTC           ║**
**═══════════════════════════════════════**
```

```bash
say -v Markus "Architekt fertig. Warte auf Entscheidung."
```

**Example 2 - Blocked on clarification:**
```markdown
The test specification is ambiguous regarding edge cases. Should the validator
accept nil values or throw an error?

**═══════════════════════════════════════**
**║        TESTER ROLE END               ║**
**║        2025-12-10 15:00 UTC          ║**
**═══════════════════════════════════════**
```

```bash
say -v Audrey "Tester fertig. Benötige Klarstellung."
```

## Handover Context

**When creating a handover to another role:**
1. Complete the handover file
2. Update QUEUE.md with PENDING status
3. Add closing signature
4. Add voice announcement mentioning handover

**Example:**
```bash
say -v Viktor "Implementierer fertig. Handover an Tester erstellt."
```

## Common Mistakes to Avoid

**DON'T:**
- **Close a bead without committing its code** — closed bead + uncommitted code = lost work
- **Skip `git status` check** — must always check for uncommitted changes
- **Commit without tests passing and code-reviewer approval** — unreviewed code is worse than uncommitted
- **Leave uncommitted work undocumented** — next session won't know what's pending
- Skip the closing signature
- Skip the voice announcement
- Use English in voice message
- Use wrong voice for role
- Use numbers as digits ("3" instead of "drei")
- End session with "Is there anything else?" without signature
- Give vague status ("Work done" instead of specific accomplishment)
- Wait for user response without closing signature

**DO:**
- **Check `bd list --status=closed`** — verify closed beads have their code committed
- **Always run `git status` first** — know what's uncommitted
- **Only commit when tests pass AND code-reviewer approved** (or for process/doc-only changes)
- **Document uncommitted work** when not committing
- Always include both signature and voice
- Use specific, concrete status
- Match voice to current role
- Spell out numbers in German
- Execute the say command via Bash tool
- Close even when waiting for user input

## Integration Points

**This skill complements:**
- PROCESS.md role definitions
- Handover queue protocol
- Role boundary enforcement
- Session startup protocol

**When this skill activates:**
- Check what role you're currently in (from session startup)
- Use that role's voice and name
- Reflect actual work done in status message
- Ensure proper German grammar and spelling

---
name: session-closing
description: Apply role-specific closing signature and voice announcement when ending sessions, completing tasks, creating handovers, giving final summaries, requesting user attention, or when user says done/finished/thanks/let's stop. Critical for role-based workflow protocol.
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

**EVERY role-based session MUST end with:**
1. Closing signature block
2. Voice announcement command (executed via Bash)

**NO EXCEPTIONS.** This is part of the role protocol defined in PROCESS.md.

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
- TESTER
- TEAM COACH

**Date Format:**
- Use current UTC time
- Format: `2025-12-10 14:30 UTC`
- Ensure proper padding for alignment

## Voice Announcement

### Voice Mapping

| Role | Voice | Sample Message |
|------|-------|----------------|
| Product Owner | Anna | "Product Owner fertig. Anforderungen dokumentiert." |
| Architect | Markus | "Architekt fertig. Design abgeschlossen." |
| Implementer | Viktor | "Implementierer fertig. Code eingecheckt." |
| Reviewer | Petra | "Reviewer fertig. Review abgeschlossen." |
| Debugger | Yannick | "Debugger fertig. Fehler behoben." |
| Tester | Audrey | "Tester fertig. Tests durchgeführt." |
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

```bash
say -v [Voice] "[Rolle] fertig. [Status]"
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

- [ ] Closing signature block is present
- [ ] Signature uses correct role name
- [ ] Timestamp is current UTC time
- [ ] Voice announcement command is included
- [ ] Voice command uses correct voice for role
- [ ] Status message is in German
- [ ] Status reflects actual session accomplishments
- [ ] Numbers are spelled out in German

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
- Skip the closing signature
- Skip the voice announcement
- Use English in voice message
- Use wrong voice for role
- Use numbers as digits ("3" instead of "drei")
- End session with "Is there anything else?" without signature
- Give vague status ("Work done" instead of specific accomplishment)
- Wait for user response without closing signature

**DO:**
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

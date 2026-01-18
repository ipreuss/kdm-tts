---
name: turn-complete
description: |
  MANDATORY before EVERY response to user in role-based workflow.
  Signals that user attention is needed and helps them return to context.
  Includes signature block and voice announcement.
triggers:
  - about to respond
  - waiting for input
  - asking question
  - presenting options
  - work complete
---

# Turn Complete Protocol

## When to Use

**EVERY TIME you finish your response and return control to user.**

This is NOT optional. Every response in role-based workflow ends with signature + voice.

## Quick Self-Check

Before your closing, ask yourself:
- Did I make an obvious mistake this turn?
- Did I forget something the user asked for?
- Am I about to say something that should trigger a skill/agent?

If yes to any: fix it before closing.

### Role-Specific Checks

**Implementer:**
- ⛔ Did I close a bead? → **Process violation!** Only PO (features/bugs) or Architect (tasks) may close beads. Create handover to appropriate role instead.
- ☑️ Did I commit code before creating handover? → Required by process.

**Architect:**
- ☑️ Did I verify code is committed before design verification?
- ☑️ Am I handing to PO even if bead was prematurely closed?

**Product Owner:**
- ☑️ Did I create Team Coach handover for significant learnings (doc/skill/process/agent)?

## Signature Format

```
**═══════════════════════════════════════**
**║        [ROLE NAME] ROLE END          ║**
**║        YYYY-MM-DD HH:MM UTC          ║**
**═══════════════════════════════════════**
```

**Role Names:** PRODUCT OWNER, ARCHITECT, IMPLEMENTER, REVIEWER, DEBUGGER, TEAM COACH

**Date Format:** Current UTC time, e.g., `2025-12-10 14:30 UTC`

## Voice Announcement

Execute via Bash after signature:

| Role | Voice | Command |
|------|-------|---------|
| Product Owner | Anna | `say -v Anna "Product Owner fertig. [Status]"` |
| Architect | Markus | `say -v Markus "Architekt fertig. [Status]"` |
| Implementer | Viktor | `say -v Viktor "Implementierer fertig. [Status]"` |
| Reviewer | Petra | `say -v Petra "Reviewer fertig. [Status]"` |
| Debugger | Yannick | `say -v Yannick "Debugger fertig. [Status]"` |
| Team Coach | Xander | `say -v Xander "Team Coach fertig. [Status]"` |

**Message Rules:**
- German language
- Structure: `"<Rolle> fertig. <kurzer Status>"`
- Numbers spelled out: "drei Tests", "fünf Dateien"
- Keep status to 3-5 words
- Use past participles: "dokumentiert", "implementiert", "behoben"

**Remote Sessions:** If `say` not available, use: `echo "[Voice] [message]"`

## Examples

**After completing a task:**
```markdown
Die Monster-Definition wurde aktualisiert.

**═══════════════════════════════════════**
**║      IMPLEMENTER ROLE END            ║**
**║      2025-12-10 14:30 UTC            ║**
**═══════════════════════════════════════**
```
```bash
say -v Viktor "Implementierer fertig. Monster aktualisiert."
```

**Waiting for decision:**
```markdown
Zwei Ansätze möglich:
1. Zentralisierte Validierung
2. Inline-Checks

Welchen bevorzugst du?

**═══════════════════════════════════════**
**║       ARCHITECT ROLE END             ║**
**║       2025-12-10 14:45 UTC           ║**
**═══════════════════════════════════════**
```
```bash
say -v Markus "Architekt fertig. Warte auf Entscheidung."
```

**Asking for clarification:**
```markdown
Soll der Validator nil-Werte akzeptieren oder einen Fehler werfen?

**═══════════════════════════════════════**
**║      IMPLEMENTER ROLE END            ║**
**║      2025-12-10 15:00 UTC            ║**
**═══════════════════════════════════════**
```
```bash
say -v Viktor "Implementierer fertig. Benötige Klarstellung."
```

## Common Mistakes

**DON'T:**
- Skip signature/voice (even for quick responses)
- Use English in voice message
- Use wrong voice for role
- Use digits ("3" instead of "drei")
- Give vague status ("fertig" without specifics)

**DO:**
- Always include both signature AND voice
- Use specific, concrete status
- Match voice to current role
- Spell out numbers in German

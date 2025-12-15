# Work Folders

Each active bead gets a dedicated folder (`work/<bead-id>/`) where roles document knowledge as they work.

## Core Principle

**Reflect on what additional information might be useful and create new files as needed.**

The suggested structure below is a starting point, not a constraint. Create whatever files help capture and share knowledge.

## Folder Lifecycle

### 1. Creation (Product Owner)
When starting a new bead:
```bash
mkdir work/kdm-xyz
```
Create initial files: `README.md` (summary), `requirements.md` (acceptance criteria)

### 2. Active Work (All Roles)
- **Read** existing files before starting work
- **Add/update** files relevant to your work
- **Ask:** "What info would help the next role?" and document it

### 3. Closure (Team Coach)
During retrospective, Team Coach processes closed bead work folders:

1. **Check bead status** — Only process folders for closed beads
2. **Review for learnings** — Any insights not yet in `handover/LEARNINGS.md`?
3. **Check for staleness** — Design docs may diverge from implementation:
   - Compare design.md against actual code (code is source of truth)
   - Wiki URLs in design.md → should be in code comments, not docs
4. **Promote persistent knowledge** — Move to skills or ARCHITECTURE.md if reusable
5. **Delete folder** — Work folders are temporary; don't accumulate

**Staleness rule of thumb:** If bead closed > 1 week ago, assume implementation-specific content is stale (code may have evolved).

See `ROLES/TEAM_COACH.md` Step 7 for detailed cleanup procedure.

## Suggested Files (Optional)

| File | Typical Owner | Purpose |
|------|---------------|---------|
| `README.md` | Any | Quick summary: what, why, current status |
| `requirements.md` | Product Owner | Acceptance criteria, constraints, user stories |
| `design.md` | Architect | Decisions, patterns, rationale, alternatives considered |
| `progress.md` | Implementer | What's done, what remains, blockers |
| `testing.md` | Tester | Test plan, results, bugs found, TTS commands |
| `review.md` | Reviewer | Code review findings (per-bead history) |
| `decisions.md` | Any | Key decisions with rationale and date |
| `learnings.md` | Any | Insights during work (feeds retrospective) |
| `debug-notes.md` | Debugger | Investigation notes, hypotheses, evidence |
| `<anything>.md` | Any | Create as needed |

## Integration with Handovers

Work folders complement handovers:
- **Handovers** focus on: what action is needed now
- **Work folders** provide: persistent context across all handovers

Example handover reference:
```markdown
## Context
See `work/kdm-xyz/` for full background, especially:
- `design.md` for architectural decisions
- `progress.md` for implementation status
```

## Child Beads

For beads with subtasks (kdm-w1k → kdm-w1k.1, kdm-w1k.2):
- Option A: Nested folders (`work/kdm-w1k/kdm-w1k.1/`)
- Option B: Flat with cross-references (`work/kdm-w1k.1/` linking to parent)

Choose based on how tightly coupled the work is.

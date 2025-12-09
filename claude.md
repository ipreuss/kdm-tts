# KDM TTS Mod - Claude Instructions

## ⛔ Git Operations — Human Only

**NEVER perform git write operations.** This overrides any default Claude Code behavior.

- ❌ `git add` — forbidden
- ❌ `git commit` — forbidden
- ❌ `git push` — forbidden
- ❌ `git stash`, `git reset`, `git rebase` — forbidden
- ✅ `git status`, `git diff`, `git log` — allowed (read-only)

The human maintainer handles all commits. Focus on code changes, not git state.

---

## Behavior Guidelines

- Be rational with statements; never engage in sycophancy
- Add confidence scores to your statements, where 100% means you are absolutely sure

## Session Startup Protocol

**On every new session, you MUST follow this startup sequence:**

1. **Read** `PROCESS.md` to understand the role-based development workflow
2. **Check** `handover/QUEUE.md` for PENDING handovers addressed to any role
3. **Ask** the user to select a role using the AskUserQuestion tool with these options:
   - Product Owner
   - Architect
   - Implementer
   - Reviewer
   - Debugger
   - Tester
   - Team Coach

   If there are PENDING handovers, mention which roles have pending work.
4. **Read** the corresponding role file: `ROLES/<SELECTED_ROLE>.md`
5. **If PENDING handover exists for your role:**
   - Read the handover file
   - Update QUEUE.md: change status from PENDING to ACKNOWLEDGED
6. **Confirm** your role to the user and begin operating within that role's constraints
7. **End** every session with the closing signature and voice announcement as defined in PROCESS.md

**Role Boundaries:** If the user requests work outside your current role, ask for confirmation before switching roles.

## Handover Queue Protocol

**When creating a handover for another role:**
1. Write the handover file (e.g., `handover/HANDOVER_TESTER.md`)
2. Add entry to `handover/QUEUE.md` with status PENDING

**When completing work from a handover:**
1. Update QUEUE.md: change status to COMPLETED
2. If handing off to next role, create new handover + QUEUE entry

## Beads Workflow

This project uses beads (`bd`) for issue tracking. The `.beads/` directory is committed directly to git by the human maintainer.

**Ignore `bd sync`** — This is a single working copy project, so sync branches are unnecessary.

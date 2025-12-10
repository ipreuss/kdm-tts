# Development Process

This document defines the default workflow for making changes to the KDM TTS mod. It complements:
- `CODING_STYLE.md` — Code conventions and syntax
- `TESTING.md` — Test strategy, patterns, and guidelines
- `ROLES/*.md` — Detailed role definitions

---

## Roles

Each AI chat session operates in exactly one role. Roles have distinct responsibilities and constraints to maintain separation of concerns.

**Role documentation:** See `ROLES/<ROLE>.md` for detailed responsibilities, constraints, and workflows:
- `ROLES/PRODUCT_OWNER.md` — Requirements, user stories, acceptance criteria
- `ROLES/ARCHITECT.md` — System design, patterns, technical feasibility
- `ROLES/IMPLEMENTER.md` — Coding workflow, patterns, review responses
- `ROLES/REVIEWER.md` — Code review process, checklists, handover format
- `ROLES/DEBUGGER.md` — Debugging patterns, logging, root cause analysis
- `ROLES/TESTER.md` — Acceptance testing, TestWorld usage, TTS console tests
- `ROLES/TEAM_COACH.md` — Process improvement, workflow optimization

### Role Workflow

**Code change flow:**
```
PO ─requirements─► Architect ─design─► Implementer ─code─► Reviewer ─reviewed─► Tester
                                                                                   │
PO ─acceptance criteria───────────────────────────────────────────────────────────►│
                                                                                   │
                        ◄──────────────────── acceptance tests ───────────────────┘
                        │
                    Reviewer ─reviewed─► Architect ─design ok─► PO (validation)
```

**All code goes through Reviewer** — including acceptance tests written by Tester.
**Architect verifies design compliance** — before PO validates requirements are met.

**Handoff points:**
1. Product Owner defines requirements → Architect designs solution
2. Architect provides design → Implementer writes code + implementation tests
3. Implementer completes changes → Reviewer reviews code and tests
4. Reviewer approves → Tester writes acceptance tests
5. Tester completes acceptance tests → Reviewer reviews acceptance tests
6. Reviewer approves → Architect verifies design compliance
7. Architect approves → Product Owner validates feature is complete
8. Findings at any stage may loop back to prior roles

### Bug Fast Path (Tester → Implementer)

For simple bugs, Tester may skip the Debugger role and hand directly to Implementer.

**Fast path criteria (ALL must be met):**
- [ ] Root cause identified with specific file:line
- [ ] Fix is < 10 lines
- [ ] Single module affected (no cross-module impact)
- [ ] Tester confidence > 90%

**Fast path handover must include:**
- Diagnosis rationale (why Tester is confident)
- Specific file and line numbers
- Suggested fix (before/after code snippet)

**When criteria not met:** Use standard Debugger path.

**Safeguard:** Implementer may escalate to Debugger if diagnosis is unclear or fix is more complex than expected.

**Middle ground — Debugger subagent:**
When Tester is uncertain about root cause but doesn't want full handover:
- Use `debugger` subagent for in-session diagnosis
- Subagent analyzes and recommends: fast path, standard path, or needs more investigation
- Available to both Tester and Implementer

```
Bug complexity spectrum:

Trivial (obvious fix)     → Tester → Implementer (fast path)
Needs diagnosis           → Tester → debugger subagent → Implementer
Complex/cross-module      → Tester → Debugger role (full handover)
```

**Reviewer is the default:**
All code goes through Reviewer — both implementation code (from Implementer) and acceptance tests (from Tester). Even small changes are easy to review and often surface code smells or test quality issues. The cost of a quick review is low; the cost of accumulated technical debt or bad test patterns is high.

**Two review modes:**
1. **External Reviewer role** — Separate session, full handover workflow (default for large changes)
2. **Code-reviewer subagent** — In-session review via `.claude/agents/code-reviewer.md` (for quick reviews)

**⚠️ Pre-handover review requirement:**
Before creating any handover that includes code changes beyond trivial fixes (typos, single-line tweaks), the implementing role MUST run the `code-reviewer` subagent. This catches issues early, before they cross role boundaries.

The subagent review does NOT replace the external Reviewer role for significant changes — it's an additional quality gate that happens before handover.

**Skip pre-handover review only for:**
- Documentation-only changes (no code)
- Pure data/configuration changes with integrity tests
- Trivial fixes (typos, single-line changes)

When skipping review, explicitly note why in the handover.

**Architect handover must specify TTS testing needs:**
When the design involves new TTS API interactions (archive operations, deck manipulation, object spawning, UI rendering), the Architect's handover must explicitly request TTS console tests in addition to headless tests. Headless tests verify business logic but cannot catch subtle TTS API issues (timing, callbacks, object state). The implementer is responsible for adding the specified TTS tests.

**Architect handover checklist for UI features:**
```
## TTS Testing Requirements
- [ ] Headless tests sufficient (no UI/visual elements)
- [ ] TTS console tests required for: [list specific behaviors]
- [ ] Spawn coordinates specified: [exact position or reference]
- [ ] Copy styling from: [existing UI element to use as template]
```

This forces explicit consideration of TTS-specific requirements upfront, preventing bugs that only surface at runtime.

### Bead Closure Authority

**Only two roles may close beads:**

| Role | May Close | Rationale |
|------|-----------|-----------|
| **Product Owner** | Feature beads, bug beads | Validates user-facing requirements are met |
| **Architect** | Technical task beads | Validates technical quality and design compliance |

**All other roles** (Implementer, Reviewer, Debugger, Tester) must **not** close beads directly. When work is complete:

1. Create a handover to the appropriate authority:
   - Features/bugs → handover to **Product Owner**
   - Technical tasks → handover to **Architect**
2. The receiving role reviews and closes the bead if acceptance criteria are met

**Closure requirements:**
- Beads may only be closed if adequate test coverage exists
- Before closing, verify: "What tests prove this works? Would a regression be caught?"
- If no tests exist, either add them or document why testing is not applicable
- For data/configuration changes, integrity tests may serve as acceptance tests

This ensures proper validation before marking work as done.

### Lightweight Workflow for Pure Refactoring

For behavior-preserving refactoring tasks, a streamlined workflow reduces handover overhead.

**Standard workflow:**
```
PO → Architect → Implementer → Reviewer → Tester → Reviewer → Architect → PO
```

**Lightweight refactoring workflow:**
```
PO (scope approval) → Architect → Implementer (with subagent review) → Tester → Architect (closure)
```

**Criteria for lightweight workflow (ALL must be met):**
- [ ] PO approved as "pure refactoring" upfront
- [ ] No new user-facing functionality
- [ ] No changed function signatures
- [ ] Existing test coverage for affected code
- [ ] code-reviewer subagent used during implementation

**Escalation triggers (switch to standard workflow):**
- Scope extends beyond original refactoring
- Tester finds behavioral bug (not just regression)
- Implementer or Tester has doubts about change scope

**Key differences from standard workflow:**
- PO approves scope upfront but skips final review
- External Reviewer skipped (code-reviewer subagent used instead)
- Architect closes technical task bead (not PO)
- Tester verifies no regressions, hands back to Architect

### Role Boundaries

**CRITICAL: Never switch roles within a session.**

Each session operates as exactly one role from start to finish. If you encounter work that belongs to a different role:

1. **Stop** — Do not perform the work
2. **Point it out** — Explain which role should handle it
3. **Create a handover** — Document the task for the appropriate role
4. **Leave it** — Do not attempt to "help" by doing the other role's work

**Examples:**
- If acting as Architect and implementation is needed: "This requires code changes, which is Implementer work. I'll create a handover for the Implementer."
- If acting as Implementer and a bug is found: "This is a bug that needs investigation. I'll document it for the Debugger role."
- If a handover addressed to another role is found: "This handover is for the Implementer, not the Architect. It should be processed in a separate Implementer session."

**Never:**
- Process handovers addressed to other roles
- "Quickly" do another role's work to save time
- Switch roles mid-session, even if asked

This strict separation ensures proper oversight, prevents mistakes, and maintains clear accountability.

---

## Handover System

### Handover Documents

All role-to-role handovers are stored in the `handover/` folder:

| Document | Purpose | Owner |
|----------|---------|-------|
| `QUEUE.md` | Central queue tracking all pending handovers | All roles |
| `LEARNINGS.md` | Insights and improvement ideas from all roles | Team Coach |
| `LATEST_REVIEW.md` | Most recent code review findings | Reviewer |
| `LATEST_DEBUG.md` | Most recent debug report | Debugger |

Task-specific handovers use descriptive names following this convention:
```
HANDOVER_<FROM>_<TO>_<SHORT_DESCRIPTION>.md
```

Examples:
- `HANDOVER_ARCHITECT_IMPLEMENTER_RESOURCE_REWARDS.md`
- `HANDOVER_TESTER_DEBUGGER_ONLOAD_ERROR.md`
- `HANDOVER_PROCESS_TEAM_COACH_ROLE.md` (broadcast to all roles)

### Handover Queue Workflow

The `handover/QUEUE.md` file serves as a central inbox to prevent missed or stale handovers:

```markdown
| Created | From | To | File | Status |
|---------|------|-----|------|--------|
| 2025-12-06 17:00 | Architect | Implementer | HANDOVER_ARCHITECT_IMPLEMENTER.md | PENDING |
```

**Status values:** PENDING → ACKNOWLEDGED → COMPLETED

**Workflow:**
1. **Session start:** Check QUEUE.md for PENDING entries addressed to your role
2. **When accepting work:** Read handover file, update status to ACKNOWLEDGED
3. **When completing work:** Update status to COMPLETED
4. **When handing off:** Write handover file + add new QUEUE entry with PENDING status

**Guidelines:**
- Each handover/status document is **replaced** (not appended) when a new handover occurs
- Include context, requirements/design, open questions, and relevant files
- The receiving role should read the handover/status documents before starting work. When implementation spans multiple PRs/sprints, update `handover/IMPLEMENTATION_STATUS.md` so future implementers can see exactly what has already landed and what remains.

### Handover File Management

**⚠️ Never modify an existing handover file.** This avoids race conditions where a role reads partial content during an edit.

**When updating a PENDING handover:**
1. **First:** Mark the old QUEUE.md entry as SUPERSEDED (prevents other role from processing it)
2. **Then:** Create the new handover file with updated content
3. **Finally:** Add new PENDING entry to QUEUE.md

**Status values:** PENDING → ACKNOWLEDGED → COMPLETED | SUPERSEDED

SUPERSEDED means "replaced by newer handover, do not process."

Keep descriptions short (1-3 words, use underscores). This makes handovers easier to find and understand without opening them.

### Handover Summary Requirement

**After creating a handover, summarize it in your response** before the session closing signature. This allows the user to see the handover contents without needing to open the file.

Include:
- Recipient role and file name
- Key points from the handover (2-5 bullet points)
- Any action items or decisions needed

This is especially important for broadcast handovers to multiple roles.

**Cleanup:** When a new top-level bead is started, clean up the handover folder by removing old completed handovers. This keeps the folder manageable and prevents confusion.

### Process Change Broadcasts

When any role updates PROCESS.md, they must broadcast the change to all other roles:

1. Create a new handover file (never modify existing handovers)
2. Add PENDING entries to QUEUE.md for all roles
3. Content should include:
   - What changed
   - Why it changed
   - Any immediate actions required

Roles receiving a process handover should:
1. Read and acknowledge the change
2. Mark the handover as COMPLETED
3. Apply the new process immediately

This ensures all roles stay synchronized on process changes, even mid-session.

### Learning Capture

**All roles** should document learnings as they work, not just during retrospectives. This creates a continuous improvement loop where insights are captured fresh.

**What to capture:**
- Patterns that worked well (potential skill material)
- Friction points or confusing APIs
- Missing documentation or unclear guidelines
- Ideas for new tools, agents, or automations
- Unexpected behaviors or gotchas

**How to capture:**
1. Open `handover/LEARNINGS.md`
2. Add an entry under "Unprocessed Learnings" with:
   - Date and your role
   - Brief title
   - Context, learning, and suggested action
   - Category: `skill | agent | doc | process | none`

**When to capture:**
- When you discover something that would have helped if you'd known it earlier
- When you work around a limitation or find a non-obvious solution
- When you think "someone should write this down"
- When handover context feels like it should be permanent knowledge

**Processing:** Team Coach consolidates learnings during retrospectives, updating skills/agents/docs as appropriate and clearing processed entries.

---

### Feature Retrospectives

**When Product Owner closes a feature bead**, they should create a handover to Team Coach requesting a retrospective if:
- The feature took multiple sessions across multiple roles
- Unexpected blockers or bugs were encountered
- The implementation deviated significantly from the original design
- Any role reported friction or process issues during development

**Skip retrospective for:**
- Small bug fixes or trivial features
- Features completed smoothly in 1-2 sessions
- Pure technical tasks with no process friction

---

### Retrospective Formats

**Learnings are captured continuously** via handover-writer during each handover, so retrospectives start with material already collected in `handover/LEARNINGS.md`.

**Choose format based on task complexity:**

| Format | Use When | Rounds |
|--------|----------|--------|
| **Standard** | Large features, 5+ handovers, significant issues | 5 rounds |
| **Light** | Small tasks, technical debt, minor friction | 1 round |

---

#### Standard Retrospective (5 rounds)

**Round 1 — Gather and Broadcast Learnings:**
Team Coach reviews `handover/LEARNINGS.md` for the feature, then:
- Gathers and organizes all learnings by category
- Creates handover to all involved roles with the collected feedback
- Asks each role to select 1-3 most important learnings

**Round 2 — Role Brainstorming:**
Each role:
- Reviews the organized learnings
- Selects 1-3 most important items from their perspective
- For each selected item, uses the `brainstorm` skill to generate at least 3 different solutions
- Creates handover back to Team Coach with selections and brainstormed solutions

**Round 3 — Synthesize Proposals:**
Team Coach:
- Reviews all role feedback and brainstormed solutions
- Synthesizes up to 3 concrete process change proposals
- Creates handover to all roles requesting Support/Oppose/Modify feedback

**Round 4 — Proposal Feedback:**
Each role:
- Reviews the synthesized proposals
- Provides Support/Oppose/Modify feedback for each proposal
- Creates handover back to Team Coach

**Round 5 — Implement:**
Team Coach:
- Incorporates feedback into final decisions
- Implements approved changes (updates skills, agents, docs, process)
- Logs processed learnings, clears from LEARNINGS.md
- Broadcasts summary to all roles

**Critical:** Always use handovers for feedback requests, never assume roles can respond in-session. Each role processes feedback in their own session.

---

#### Light Retrospective (1 round)

Team Coach reviews learnings and implements improvements directly:
- No feedback round needed for minor improvements
- Updates artifacts, logs processing, broadcasts summary

**Time-box:** Max 30 minutes.

---

#### Retrospective Handover Format

Product Owner creates `HANDOVER_PO_TEAMCOACH_RETRO_<FEATURE>.md` with:
- Feature summary and bead ID
- Roles involved
- Notable issues encountered
- Suggested retrospective format (Standard/Light)

---

## Bead Guidelines

### Bead Creation Guidelines

**Break features into sub-beads when:**
- It has distinct implementation phases (proof of concept → full implementation)
- It has independent sub-features that can be tested separately
- It will take more than one session to complete

**Create new beads for deferred work:**
When you discover a task that should be done but isn't part of the current scope, create a bead for it immediately rather than leaving a TODO comment or mental note. This ensures nothing falls through the cracks and makes the backlog visible.

Examples:
- "This would be cleaner with a refactor, but not now" → create bead
- "Edge case X should be handled eventually" → create bead
- "Documentation needs updating after this lands" → create bead

---

## Session Closing

### Session Closing Signature

**Whenever you need user input** — end of session, questions, design decisions, or waiting for next steps — provide a clear closing signature to indicate which role was active and when:

```
**═══════════════════════════════════════**
**║        [ROLE NAME] ROLE END          ║**
**║        YYYY-MM-DD HH:MM UTC          ║**
**═══════════════════════════════════════**
```

This helps the user immediately recognize which role they just spoke to and when, avoiding confusion when switching between roles across multiple conversations.

Include a brief session summary before the signature with key accomplishments and any outstanding tasks.

**Audio notification:** After the closing signature, execute a voice announcement with a brief status summary in German.

Each role has an assigned voice:

| Role | Voice | Command |
|------|-------|---------|
| Product Owner | Anna | `say -v Anna "..."` |
| Architect | Markus | `say -v Markus "..."` |
| Implementer | Viktor | `say -v Viktor "..."` |
| Reviewer | Petra | `say -v Petra "..."` |
| Debugger | Yannick | `say -v Yannick "..."` |
| Tester | Audrey | `say -v Audrey "..."` |
| Team Coach | Xander | `say -v Xander "..."` |

The message format is: `"<Rolle> fertig. <kurzer Status>"`

Examples of dynamic status messages:
- Product Owner: `say -v Anna "Product Owner fertig. Drei Anforderungen definiert"`
- Architect: `say -v Markus "Architekt fertig. Design übergeben"`
- Implementer: `say -v Viktor "Implementer fertig. Fünf Dateien geändert, alle Tests bestanden"`
- Reviewer: `say -v Petra "Reviewer fertig. Zwei Probleme gefunden"`
- Debugger: `say -v Yannick "Debugger fertig. Ursache identifiziert"`
- Tester: `say -v Audrey "Tester fertig. Sechs Tests hinzugefügt, ein Fehler gefunden"`
- Team Coach: `say -v Xander "Team Coach fertig. Neue Rolle eingeführt"`

Derive the status from actual session accomplishments. Spell out numbers as German words. Avoid English loanwords (use "Fehler" not "Bug").

---

## Development Workflow

### Test-First Loop

1. **Plan** – clarify the intent of the change (behavior, data shape, UI outcome) and note which modules are involved. Update or create ADRs/notes if the change affects architecture decisions.
2. **Specify** – write or extend the relevant test so it fails for the current implementation. If touching multiple layers, prefer starting with the highest-value test and add focused unit tests if needed.
3. **Implement** – modify the production code in small, reviewed commits while keeping tests red/green visible. Prioritize self-explanatory code (clear names, types, constants, structure) over added documentation; only document when code cannot carry the intent alone. When fixing a bug or untested path, first add/adjust a failing test that reproduces it before changing code.
4. **Verify** – run `lua tests/run.lua` (and any scenario scripts) until everything passes. If the change affects Tabletop Simulator behavior (especially TTS console commands, UI interactions, or Archive/deck operations), run `./updateTTS.sh` and perform TTS verification—headless tests alone are insufficient for TTS-specific functionality. **Always run `./updateTTS.sh` before asking the user to test in TTS.**
5. **Refine** – after green tests, scan for smells (brittle test setup, hidden dependencies, duplication) and introduce/refine seams or small refactors while keeping tests green; then re-verify. Apply the Boy Scout Rule: whenever you edit a file, leave it slightly better (naming, structure, guard clauses, comments, tests). If you uncover a larger refactor that is risky to tackle immediately, document it (see Architecture "Future Refactor Opportunities") so we don't lose the insight.

### Safety Net Principles

- **Baseline tests before edits** – confirm existing behavior has automated coverage (unit/integration). If coverage is missing for the code you are about to edit, add characterization tests that express the current behavior before changing logic.
- **Protect regressions** – when a bug is reported, reproduce it in a failing test before touching implementation code. The test should prove the fix and guard against future regressions.
- **Keep tests close to code** – place new specs in `tests/<area>_test.lua` and register them in `tests/run.lua` so they are part of the default `lua tests/run.lua` run.
- **Executable behavior specs** – when work changes a user-visible behavior or acceptance criteria, add/refresh a high-level test (integration/behavior) that documents the intent (the "what") alongside unit tests that cover "how."

### Implementation Guidelines

- **Research first** – when a new implementation task arrives, pause coding and investigate existing behavior, architecture notes, and related files/tests so the forthcoming plan is grounded in facts rather than assumptions.
- **Prefer existing patterns** – before implementing a new feature, look for similar functionality in the repo. When overlap exists, follow this loop:
  1. Secure the current behavior with characterization tests so the existing workflow is documented and protected.
  2. Extract the shared logic into a well-named, reusable abstraction.
  3. Keep legacy behavior green (tests passing) as you migrate it to the new abstraction.
  4. Implement the new feature on top of the abstraction, extending it as needed without breaking the original flow.
- **Produce a plan** – write down the proposed approach (touch points, test strategy, migration steps) alongside all assumptions and open questions that could influence the solution.
- **Share before coding** – present that plan to the reviewer/requester and wait for explicit confirmation before touching production code. Only start implementation work after all blocking questions are answered or assumptions validated.
- **Fail loudly over speculative fallbacks** – when a required resource (data deck, object, config, etc.) is missing, surface an explicit error and stop rather than silently falling back to unrelated sources.
- **Fail fast and meaningfully** – every subsystem must validate its inputs and surface actionable errors as close to the source as possible. Guard clauses and descriptive log messages are preferred over silent fallbacks.
- **Keep exported interfaces lean** – don't expose new parameters, flags, or configuration points unless client code demonstrably needs them.

### Value Extraction Checklist

When extracting hardcoded values from existing code (refactoring, creating utilities):

**Architect handover:**
- Mark which values need verification: "Values require verification: GRID.width, GRID.x1End (from Rules.ttslua:95-97)"
- Include source file and line numbers for extracted constants

**Implementer:**
- For coordinate/dimension/position values, create absolute-value tests
- Assert actual values (e.g., `width = 1.06 +/- 0.01`), not just consistency
- Document source: "x1End = 6.705129 (from Rules.ttslua:95)"

**Scope:** Apply to visual/positioning values. Skip for trivial extractions (strings, booleans).

**Why this matters:** Copy-paste extraction of coordinate values can introduce subtle bugs (e.g., using Y coordinate for width). Absolute-value tests catch these immediately.

### Debugging Guidelines

- **Debug runtime errors systematically** – when an error occurs at runtime (especially unexpected nil errors), verify your assumptions about why and where the error happens before fixing it. The preferred approach is to implement at least one regression test that reproduces the error.
- **Use debug logging when stuck** – when a TTS error is unclear (e.g., only visible in the in-game console), add targeted `log:Debugf(...)` statements near the failing code path to surface argument values and flow. Enable the relevant module temporarily by uncommenting it under `Log.DEBUG.MODULES` in `Log.ttslua`, and remember to disable the extra logging once finished.
- **Resist assumptions when debugging** – when encountering runtime errors, especially "attempt to call a nil value" errors, resist the urge to immediately implement complex solutions. Instead: (1) Add debug logging at the error point to verify what is actually nil, (2) Work backward from the error with targeted logging to trace the execution path, (3) Test simple hypotheses first before architectural changes.

### UI Guidelines

- **Use shared UI palette and components** – all dialogs and panels should rely on the palette constants defined in `Ui.ttslua` (for example, `Ui.CLASSIC_BACKGROUND`, `Ui.CLASSIC_HEADER`, `Ui.CLASSIC_SHADOW`, and `Ui.CLASSIC_BORDER`) and the reusable PanelKit helpers (such as `PanelKit.ClassicDialog`).
- **Respect defaults unless intentionally deviating** – when any shared component (UI or otherwise) exposes a default behavior, consume it rather than overriding it by habit.

### Screenshot Processing

Use the `screenshot-analyzer` subagent for analyzing screenshots:

1. Finds the newest screenshot on Desktop (or uses a specified path)
2. Checks file size — if > 5 MB, converts to JPEG automatically
3. Reads and analyzes the image with comprehensive descriptions

**Manual conversion** (if needed):
```bash
sips -s format jpeg screenshot.png --out screenshot.jpg
```

This reduces file size significantly and prevents context overflow when analyzing images.

### Available Subagents

Subagents provide specialized capabilities within a session. See `.claude/agents/` for full documentation.

| Subagent | Purpose | Model |
|----------|---------|-------|
| `code-reviewer` | Review code at milestones, before handover, or when stuck | opus |
| `debugger` | Diagnose bugs without full Debugger handover (for Tester and Implementer) | sonnet |
| `seam-finder` | Analyze modules for testability seams and refactoring opportunities | sonnet |
| `screenshot-analyzer` | Analyze screenshots with auto file discovery and size optimization | sonnet |
| `subagent-creator` | Create new custom subagents following best practices | sonnet |
| `beads-backlog-manager` | Query and manage the beads issue tracking system | haiku |
| `handover-manager` | Create handovers, update queue, cleanup completed entries | haiku |
| `handover-writer` | Compose well-structured handover content with role-aware templates | haiku |
| `refactoring-advisor` | Analyze code for SOLID violations, code smells, refactoring opportunities | sonnet |

### Available Skills

Skills provide domain knowledge that Claude automatically applies when context matches. See `.claude/skills/` for full documentation.

| Skill | Purpose | Triggers |
|-------|---------|----------|
| `legacy-code-testing` | Feathers' techniques for safely modifying untested code | legacy, untested, seam, characterization test |
| `kdm-tts-patterns` | TTS-specific patterns, async callbacks, object lifecycle, archive operations | TTS, spawn, callback, archive, deck, async |
| `kdm-coding-conventions` | Lua coding style, module exports, SOLID principles, error handling | Lua, module, export, style, SOLID, guard clause |
| `kdm-test-patterns` | Testing patterns, behavioral vs structural, TTSSpawner seam, TTS console tests | test, acceptance, unit, spy, mock, behavioral |
| `kdm-expansion-data` | Expansion data structures, archive system, card naming conventions | expansion, gear, monster, archive, card, deck |
| `kdm-ui-framework` | UI patterns, PanelKit, LayoutManager, color palette, dialog creation | UI, panel, dialog, PanelKit, LayoutManager, CLASSIC |
| `dry-violations` | Detects duplication when making similar changes in multiple places | copy-paste, same change, duplicate code, extract |
| `session-closing` | Ensures roles use closing signature and voice announcement | done, finished, thanks, handover, summary, waiting for user |

### Debugging Procedure

All coding roles (Implementer, Debugger, Tester) must follow this procedure when encountering a bug or unexpected behavior:

1. **Analyze the code** — Understand the relevant code paths and state
2. **Create hypotheses** — List one or more possible causes
3. **Select main hypothesis** — Choose the most likely cause to investigate first
4. **Write a failing test** — Preferably headless; this proves the bug exists and prevents regression
5. **Make the test pass** — Fix the underlying issue
6. **Verify the fix** — Confirm the original problem is resolved

**When encountering unexpected impediments** (hypothesis proves wrong, fix doesn't work, new symptoms appear):
- Stop and reassess
- Test hypotheses systematically using:
  - Automated tests (preferred)
  - Debug logging (when tests aren't practical)
- Update your hypothesis list and repeat from step 3

This ensures bugs are fixed methodically with test coverage, not through trial-and-error.

---

## Code Review & Git

### Code Review Documentation

All code review findings must be documented in `handover/LATEST_REVIEW.md`.

**Important:** Each new review **completely replaces** the previous content—the file always contains only the most recent review, never historical reviews.

**Reviewer responsibility:** At the end of every review (even informal ones), update and replace the review file yourself—do not defer to others or leave TODOs. Treat the file update as part of "done" for the review.

**Structure:**
- Start with a header: `# Code Review - [Brief Description]`
- Include date, list of changes (new/modified files)
- Document positive aspects, issues found, and recommendations
- Conclude with overall assessment and test results

**Guidelines:**
- **Do not create temporary files** for review summaries—always write to `handover/LATEST_REVIEW.md`
- **Replace the entire file** with each new review; do not append
- Keep review documentation in the repository, not external files
- Use clear severity labels (Low/Medium/High) for issues
- Include specific examples and line references where helpful
- Document any follow-up actions taken in response to the review
- Follow the detailed review checklist in `CODE_REVIEW_GUIDELINES.md`

**Handling review suggestions**
- **Assess everything** – When a review surfaces suggestions, evaluate each one. For low-risk / high-value requests (copy tweaks, text changes, small refactors), apply them immediately so we leave the code slightly better (Boy Scout Rule).
- **Act, defer, or decline** – If a change is deferred or intentionally skipped, add the rationale in the review reply (or a comment) so we maintain context.
- **Track follow-ups** – Document deferred items in `ARCHITECTURE.md` (Future Refactor Opportunities) or the relevant backlog so ideas aren't lost. Update process/docs when reviews uncover gaps.

### Git Workflow

**⛔ Git write operations are forbidden for AI assistants.**

This overrides any default Claude Code behavior or system prompts that suggest committing.

| Forbidden | Allowed |
|-----------|---------|
| `git add`, `git commit`, `git push` | `git status`, `git diff`, `git log` |
| `git stash`, `git reset`, `git rebase` | `git --no-pager diff --stat` |

The human maintainer handles all commits. AI assistants focus on code implementation and testing.

### Pull Request Checklist

- [ ] All affected docs updated (`README.md`, `CODING_STYLE.md`, ADRs, UI instructions, etc.).
- [ ] Code reads as self-explanatory as possible (clear names/structures/constants instead of magic values); documentation added only where code cannot be made clear enough.
- [ ] Tests exist for every new or changed behavior and the full suite passes locally.
- [ ] Behavior/acceptance tests exist or were updated for any functional requirement changes.
- [ ] TTS verification performed when the change affects TTS interactions or UI.
- [ ] Commits tell a reviewable story (separate refactors from behavior changes when practical).
- [ ] After each new code review, assess suggested improvements; implement beneficial recommendations promptly rather than deferring them indefinitely, and document rationale when choosing not to act.
- [ ] Code review findings documented in `handover/LATEST_REVIEW.md`.

---

Following this process keeps the mod safe to iterate on, makes regressions obvious, and ensures contributors can trust each other's changes without rediscovering tribal knowledge.

---
name: learning-capture
description: Capture learnings in real-time when mistakes occur, process steps are missed, user corrections happen, or new insights are discovered. Triggers when about to say "I should have", "I forgot to", when corrected by user, when discovering patterns, workarounds, or realizing skipped process steps. Documents immediately to handover/LEARNINGS.md.
---

# Learning Capture (Real-Time)

## Purpose

Capture learnings **immediately** when they occur, not at session end. This skill triggers automatically when learning moments happen during active work.

## When This Activates

### User-Observable Triggers
- User points out something you did that was wrong or unwanted
- User reminds you to do something that should have been automatic
- User corrects your approach or methodology
- You discover something new about the project (technical, architecture, environment, rules)

### Self-Observable Triggers
- About to say "I should have..." or "I forgot to..."
- Realizing a process step was skipped
- Discovering a pattern or technique that wasn't known before
- Finding a workaround or solution to a tricky problem
- Catching yourself violating a role boundary or process rule
- Learning something that changes how you'll approach similar tasks
- Spent significant time understanding code — what documentation would have helped?

## Instructions

When a learning moment occurs:

1. **Acknowledge immediately**: "I'll capture this learning right now."

2. **Read current state**:
   ```bash
   Read handover/LEARNINGS.md
   ```

3. **Append the learning** using this format:
   ```markdown
   ### [YYYY-MM-DD] [CurrentRole] Brief descriptive title

   **Context:** What were you working on when this occurred?
   **Learning:** What did you discover? What went wrong/right?
   **Suggested Action:** What should be done to prevent/improve this?
   **Category:** skill | agent | doc | process | none
   ```

4. **Be concise**: 2-4 sentences per field. Capture the insight while fresh.

5. **Choose category wisely**:
   - `skill` — Could improve or create a Claude Code skill
   - `agent` — Could improve or create a subagent
   - `doc` — Should update PROCESS.md, ARCHITECTURE.md, CLAUDE.md, etc.
   - `process` — Workflow or role procedure change needed
   - `none` — Just good to know, no specific action required

6. **Continue work**: After capturing (5-10 seconds), return to your current task.

## Examples

### Example 1: Forgot Process Step
```markdown
### [2025-12-10] [Implementer] Forgot to run tests before declaring feature complete

**Context:** Completed kdm-xyz feature implementation, handed over to Reviewer without running test suite.
**Learning:** The "Feature Complete" checklist in IMPLEMENTER.md includes "run test suite" but I skipped it. Reviewer had to send back for testing.
**Suggested Action:** Make test execution more prominent in Implementer completion checklist, or create a skill that triggers on "feature complete" declarations.
**Category:** process
```

### Example 2: User Correction
```markdown
### [2025-12-10] [Architect] Designed API without checking existing patterns

**Context:** Designing new resource reward API. User pointed out existing RewardSystem pattern I should have followed.
**Learning:** Should always grep for existing "*System" or "*Manager" patterns before designing new APIs. The codebase has established patterns that aren't all documented in ARCHITECTURE.md.
**Suggested Action:** Add "Check existing patterns" step to Architect design process. Consider documenting common patterns in ARCHITECTURE.md.
**Category:** process
```

### Example 3: New Discovery
```markdown
### [2025-12-10] [Debugger] TTS savefile uses GUID references, not direct object pointers

**Context:** Investigating why expansion terrain wasn't spawning. Discovered TTS savefiles use string GUIDs to reference objects, not direct Lua table references.
**Learning:** This affects how we search for objects in savefiles. Can't just follow Lua object references; must track GUID strings through JSON.
**Suggested Action:** Document TTS savefile architecture in ARCHITECTURE.md under "TTS Integration" section.
**Category:** doc
```

## Skill/Agent Usage Stats (ALWAYS CAPTURE)

**At session end, ALWAYS document skill/agent usage — even if no other learnings occurred.**

This data is critical for retrospectives to evaluate which skills/agents need improvement or removal.

```markdown
**Skills/Agents this session:**
- Used: [list all skills and agents invoked]
- Helpful: [which worked well and why]
- Should have triggered: [which didn't activate when expected]
- Unnecessary: [which triggered but weren't needed]
```

**If no other learnings:** Create a minimal entry with just the usage stats:
```markdown
### [YYYY-MM-DD] [Role] Session skill/agent usage

**Context:** [Brief description of work done]
**Learning:** No process issues encountered.
**Suggested Action:** None
**Category:** none

**Skills/Agents this session:**
- Used: handover-manager, kdm-coding-conventions
- Helpful: kdm-coding-conventions (caught pattern violation)
- Should have triggered: None
- Unnecessary: None
```

## Critical Rules

- **Trigger IMMEDIATELY** when learning occurs, not at end of session
- **ALWAYS capture skill/agent usage** at session end, even without other learnings
- **Keep it brief** — 2-4 sentences per field
- **Don't overthink** — capture the raw insight, Team Coach will consolidate later
- **Don't interrupt workflow** — add entry and continue
- **All roles use this** — Product Owner through Tester

## Meta-Learning Check

**After capturing a learning, ask yourself two questions:**

### 1. Is there a meta-learning?
A higher-level insight about the learning itself:
- Why did this mistake happen? Is there a pattern in this project?
- Could a skill/agent have prevented this?
- Does this reveal a gap in our process that affects multiple roles?
- Is this the second or third time this type of issue has occurred in this codebase?

### 2. Is there a general principle for this project?
A broader rule that applies across this codebase:
- What principle does this specific case illustrate for KDM development?
- Could this apply to other roles or modules in this project?
- Does this connect to our established patterns (SOLID, fail-fast, TTS patterns)?

**Example:**
- **Learning:** "Overwrote existing bead tags instead of extending them"
- **Meta-learning:** "This is the second time destructive modification caused problems in our workflow"
- **General principle:** "In KDM development, default to additive changes (extend) rather than destructive (replace) unless replacement is explicitly required"

If meta-learning or general principle exists, capture as separate entry with category `process` or `skill`.

## What Happens Next

Team Coach reviews `handover/LEARNINGS.md` during retrospectives and:
- Creates/updates skills based on `skill` category entries
- Creates/updates agents based on `agent` category entries
- Updates documentation based on `doc` category entries
- Proposes process changes based on `process` category entries
- Archives learnings to prevent file bloat

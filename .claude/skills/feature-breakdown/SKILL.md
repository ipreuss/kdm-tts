---
name: feature-breakdown
description: Guide Product Owner to split features into INVEST user stories and Architect to break designs into sequential tasks. ALWAYS use when creating beads, after brainstorming sessions, or during planning. Breaking work into smallest valuable pieces is always beneficial. Triggers on mentions of "user stories", "split", "breakdown", "INVEST", "story points", "planning", "bead creation", or after brainstorming completes.
---

# Feature Breakdown

## Purpose

Help Product Owner and Architect decompose features into the smallest pieces that can deliver value and be implemented as atomic commits. This is a CORE practice, not a fallback for "large" work—breaking down work reduces complexity and risk for ALL features.

## Core Principle

**Always break work into the smallest piece that:**
- Delivers standalone value (Product Owner stories)
- Can be implemented and committed as one unit (Architect tasks)

Benefits of smallest-possible breakdown:
- Reduces cognitive load
- Enables frequent integration
- Isolates problems quickly
- Provides early feedback
- Allows flexible prioritization

## When to Use

**For Product Owner:**
- ALWAYS after brainstorming feature content
- ALWAYS when creating a new bead/feature
- During all prioritization discussions
- When refining backlog items

**For Architect:**
- ALWAYS after brainstorming design for a feature
- ALWAYS when receiving a feature handover
- When planning any implementation work

## Product Owner: User Story Splitting

### INVEST Principles

Every user story must satisfy all six criteria:

| Principle | Meaning | Test Question |
|-----------|---------|---------------|
| **I**ndependent | Can be developed separately from other stories | "Can we build this without waiting for other stories?" |
| **N**egotiable | Details can be refined through conversation | "Are implementation details still open for discussion?" |
| **V**aluable | Delivers value to user or stakeholder | "What concrete value does this provide?" |
| **E**stimable | Can be sized by the team | "Can the Architect estimate effort?" |
| **S**mall | Fits in one development cycle | "Can this be implemented, tested, and validated in one session?" |
| **T**estable | Has clear acceptance criteria | "How will we know it's done?" |

### Story Splitting Process

1. **Review brainstorming output** — Understand the full feature scope
2. **Identify slices** — Look for natural boundaries:
   - By user role/persona
   - By workflow step
   - By data entity
   - By operation (CRUD)
   - By simple/complex cases
   - By interface type (UI vs API)
3. **Write stories** — One per slice, following format:
   ```
   As a [user type]
   I want [capability]
   So that [benefit]

   Acceptance Criteria:
   - AC1: [specific, testable criterion]
   - AC2: [specific, testable criterion]
   ```
4. **Validate INVEST** — Check each story against all six principles
5. **Keep splitting** — If story has 3+ acceptance criteria, consider splitting further
6. **Prioritize** — Order stories by:
   - User value (highest first)
   - Technical dependencies (foundations before features)
   - Risk reduction (unknowns early)
7. **Start small** — Hand over ONE story to Architect first

### Common Splitting Patterns

| Pattern | Example | When to Use |
|---------|---------|-------------|
| **Workflow steps** | "Create monster" → 1) Add basic stats, 2) Add resources, 3) Add AI | Multi-step processes |
| **Simple → Complex** | "Search monsters" → 1) By name, 2) By type, 3) Advanced filters | Incremental capability |
| **CRUD operations** | "Manage survivors" → 1) Create, 2) Read/View, 3) Update, 4) Delete | Data entities |
| **Spike + Feature** | 1) "Research PDF library", 2) "Extract character sheet data" | Unknown technology |
| **Happy path + Edges** | 1) "Valid input handling", 2) "Error handling and validation" | Risk management |
| **Data then UI** | 1) "Store monster data", 2) "Display monster in UI" | Layered architecture |
| **Read then Write** | 1) "View campaign list", 2) "Create new campaign" | Safe-first approach |

### Optimal Story Size

**Target: 1-3 acceptance criteria per story**

If story has 5+ criteria, always split. Even 3-4 criteria stories should be evaluated for splitting.

**Mindset shift:** Don't ask "Is this too large?" Ask "What's the smallest valuable piece I can deliver?"

## Architect: Task Breakdown

### Task Breakdown Philosophy

**Every design should be broken into smallest implementable units.**

A task is "too large" if it:
- Modifies 5+ files
- Cannot be described in one sentence
- Mixes concerns (data + UI, logic + integration)
- Would result in >200 line commit

**Always ask:** "What's the smallest piece I can hand off that the Implementer can complete and commit?"

### Task Breakdown Process

1. **Identify phases** — Natural implementation order:
   - Data structures / interfaces first
   - Core logic second
   - Integrations third
   - UI/presentation last
2. **Define handoff points** — Clear checkpoints between tasks:
   - Tests pass
   - Interface defined
   - Component complete
3. **Write sequential tasks** — Each with:
   - Specific scope (1-3 files preferred)
   - Dependencies on prior tasks
   - Verification criteria
4. **Create task handovers** — Use `architect-handover-planning` skill for detailed guidance

### Task Characteristics

**Good tasks are:**
- **Atomic** — Single concern, single commit
- **Sequential** — Each builds on previous work
- **Testable** — Can verify completion
- **Contained** — Limited file scope (1-3 files ideal, 5 max)
- **Time-bounded** — 15-60 minutes of implementation

**Example breakdown:**
```
Feature: Add monster AI behavior system

Task 1: Define AI behavior interface
- Files: src/game/monsters/ai/behavior.lua
- Verification: Interface compiles, type checks pass
- Commit: "Add AI behavior interface definition"

Task 2: Implement movement behavior
- Files: src/game/monsters/ai/movement.lua + tests
- Verification: Unit tests pass for movement
- Commit: "Implement movement AI behavior"

Task 3: Implement chase behavior
- Files: src/game/monsters/ai/chase.lua + tests
- Verification: Unit tests pass for chase
- Commit: "Implement chase AI behavior"

Task 4: Implement flee behavior
- Files: src/game/monsters/ai/flee.lua + tests
- Verification: Unit tests pass for flee
- Commit: "Implement flee AI behavior"

Task 5: Integrate behaviors with monster controller
- Files: src/game/monsters/monster.lua, tests/integration/
- Verification: Integration tests pass
- Commit: "Integrate AI behaviors into monster controller"
```

Notice: Each behavior is a separate task, not bundled. This allows:
- Each behavior to be tested independently
- Easier problem isolation
- Flexible scheduling (can pause after any task)
- Clearer commit history

## Integration with Other Skills

**Brainstorming → Feature Breakdown → Handover**

1. Use `brainstorming` skill to explore feature/design
2. Use `feature-breakdown` skill to split into stories/tasks (ALWAYS, not optionally)
3. Use `handover-manager` agent to create handovers

## Output Format

### Product Owner Output

After splitting, create a prioritized list:

```markdown
## Feature: [Name]

### User Stories (Prioritized)

**Story 1: [Title]** — PRIORITY: HIGH
As a [role]
I want [capability]
So that [benefit]

Acceptance Criteria:
- AC1: [criterion]
- AC2: [criterion]

INVEST Check:
- Independent: ✓ No dependencies
- Negotiable: ✓ Implementation details flexible
- Valuable: ✓ Provides [specific value]
- Estimable: ✓ Architect can size
- Small: ✓ ~1 session
- Testable: ✓ Clear ACs

**Story 2: [Title]** — PRIORITY: MEDIUM
[same format]

### Splitting Notes
[Explain how you broke down the original feature and why]

### Next Action
Hand over Story 1 to Architect via handover-manager agent.
```

### Architect Output

After breaking down design:

```markdown
## Design: [Name]

### Implementation Tasks (Sequential)

**Task 1: [Title]**
- Scope: [1-3 files and components]
- Dependencies: None
- Verification: [how to confirm complete]
- Commit message: "[verb] [what]"
- Estimated: [15-60 minutes]

**Task 2: [Title]**
- Scope: [1-3 files and components]
- Dependencies: Task 1 complete
- Verification: [how to confirm complete]
- Commit message: "[verb] [what]"
- Estimated: [15-60 minutes]

### Breakdown Rationale
[Explain how you split the design and why each task is atomic]

### Next Action
Create handover via handover-manager agent or architect-handover-planning skill.
```

## Tips

### For Product Owner

- **Default to smaller** — When unsure, split further
- **Single acceptance criterion is valid** — If it delivers value, it's a story
- **Prioritize ruthlessly** — Not everything needs to be built
- **Defer complexity** — Start with simple cases
- **Validate incrementally** — Test assumptions early
- **Think in slices, not layers** — Deliver end-to-end thin slices

### For Architect

- **One concern per task** — Mix concerns only when truly inseparable
- **Design for atomic commits** — Each task should be a single commit
- **Minimize coupling** — Tasks should be loosely dependent
- **Plan for learning** — Early tasks de-risk later ones
- **Document assumptions** — Make dependencies explicit
- **When in doubt, split** — Smaller tasks are always safer

## Warning Signs

### Product Owner Warning Signs

**Story needs further splitting if:**
- More than 3 acceptance criteria
- Contains words "and", "also", "additionally"
- Spans multiple user roles
- Mixes read and write operations
- Describes implementation approach (not what, but how)

### Architect Warning Signs

**Task needs further splitting if:**
- Touches 5+ files
- Mixes data structure and business logic
- Bundles multiple components/behaviors
- Description uses "and" or "then"
- Would take >1 hour to implement
- Cannot write clear single-sentence commit message

## References

- User story splitting: [https://agileforall.com/patterns-for-splitting-user-stories/](https://agileforall.com/patterns-for-splitting-user-stories/)
- INVEST criteria: Bill Wake, XP2003
- Atomic commits: "Refactoring: Improving the Design of Existing Code" (Martin Fowler)
- Task decomposition: "Working Effectively with Legacy Code" (Michael Feathers)

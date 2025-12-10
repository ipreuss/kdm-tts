---
name: brainstorming
description: Collaborative idea refinement through structured questioning. Use when refining rough ideas into designs, when requirements are unclear, when multiple approaches exist, or when the user describes a new feature. Triggers on phrases like "I want to", "we should", "how about", "what if", "idea for", "new feature", "not sure how". Role-aware - adapts behavior for Product Owner (requirements) or Architect (design).
---

# Brainstorming: Ideas Into Designs

Refine rough ideas into validated designs through collaborative dialogue. One question at a time, multiple choice when possible, incremental validation.

## When to Use

- User describes a new feature or idea
- Requirements are unclear or ambiguous
- Multiple valid approaches exist
- Before writing implementation plans or code
- When phrases appear: "I want to", "we should", "how about", "what if", "idea for"

## When NOT to Use

- Clear, mechanical tasks with obvious implementation
- Bug fixes with known root cause
- Refactoring with defined scope
- Tasks where requirements are already specified in a handover

## Announce at Start

> "I'll use the brainstorming skill to refine this idea before we commit to an approach."

---

## The Process

### Phase 1: Understand Context

1. **Check project state** — Scan relevant files, recent handovers, related beads
2. **Identify current role** — Adapt questioning depth:
   - **Product Owner:** Focus on user value, acceptance criteria, priority
   - **Architect:** Focus on technical constraints, patterns, dependencies

### Phase 2: Refine the Idea

**One question at a time.** If a topic needs exploration, break it into multiple questions.

**Prefer multiple choice** when options are clear:
```
Which users need this feature?
1. All players (default behavior)
2. Campaign owner only (permission-gated)
3. Configurable per-campaign
```

**Use open-ended** when exploring unknowns:
```
What problem does this solve for you?
```

**Focus areas by role:**

| Role | Question Focus |
|------|----------------|
| Product Owner | Purpose, users, success criteria, priority, edge cases |
| Architect | Constraints, dependencies, patterns, risks, testability |

### Phase 3: Explore Approaches

Once the idea is understood, propose **2-3 approaches** with trade-offs:

```markdown
## Approaches

### Option A: [Name] (Recommended)
- **How:** Brief description
- **Pros:** Fast to implement, reuses existing pattern
- **Cons:** Limited flexibility
- **Effort:** Low

### Option B: [Name]
- **How:** Brief description
- **Pros:** More flexible, handles future cases
- **Cons:** More complex, new pattern
- **Effort:** Medium

**My recommendation:** Option A because [reasoning].
```

**Lead with your recommendation** and explain why. YAGNI applies — favor simpler approaches.

### Phase 4: Validate Design

Present the design in **small sections (200-300 words)**. After each section, check:

> "Does this look right so far?"

**Sections to cover:**
1. Goal and scope
2. Components/modules affected
3. Data flow or state changes
4. Error handling approach
5. Testing strategy
6. Open questions

Be ready to revisit earlier sections if something doesn't fit.

---

## Role-Specific Outputs

### Product Owner Output

Create requirements handover for Architect:

```markdown
# Handover: PO → Architect

## Feature: [Name]

**Goal:** [One sentence]

**User Story:**
As a [user], I want [capability] so that [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Out of Scope:**
- Item explicitly excluded

**Priority:** [High/Medium/Low]

**Open Questions for Architect:**
- Technical question 1
- Technical question 2
```

Save to: `handover/HANDOVER_PO_ARCHITECT_<topic>.md`
Update: `handover/QUEUE.md` with PENDING entry

### Architect Output

Create design handover for Implementer (or proceed to `architect-handover-planning` skill for detailed task breakdown):

```markdown
# Handover: Architect → Implementer

## Feature: [Name]

**Design Decision:** [Chosen approach and rationale]

**Components:**
- Module A: [responsibility]
- Module B: [responsibility]

**Key Files:**
- `path/to/file.lua` — [what changes]

**Testing Requirements:**
- [ ] Headless tests for: [list]
- [ ] TTS console tests for: [list, if applicable]

**Constraints:**
- Constraint 1
- Constraint 2
```

Save to: `handover/HANDOVER_ARCHITECT_IMPLEMENTER_<topic>.md`
Update: `handover/QUEUE.md` with PENDING entry

---

## Key Principles

| Principle | Why |
|-----------|-----|
| **One question at a time** | Prevents overwhelming, enables focused exploration |
| **Multiple choice preferred** | Easier to answer, surfaces hidden assumptions |
| **YAGNI ruthlessly** | Remove unnecessary features from all designs |
| **Explore alternatives** | Always propose 2-3 approaches before settling |
| **Incremental validation** | Present in sections, validate each before continuing |
| **Be flexible** | Go back and clarify when something doesn't fit |

---

## Handover Integration

After completing brainstorming:

1. **Save design document** to appropriate handover file
2. **Update `handover/QUEUE.md`** with PENDING entry for recipient role
3. **Summarize handover** in your response (key points, action items)

The human maintainer handles git commits.

---

## Example Flow

```
User: "I want to add a button that shows remaining resources"

Claude: "I'll use the brainstorming skill to refine this idea.

First, let me understand the context — checking related modules..."

[Scans ResourceRewards.ttslua, UI patterns]

Claude: "I see we have ResourceRewards for showdown rewards.
Where should this button appear?

1. On the showdown board (near monster)
2. In settlement phase (resource management)
3. Both locations"

User: "1 - showdown board"

Claude: "Got it. What should happen when clicked?

1. Show popup with resource counts
2. Toggle an always-visible display
3. Something else?"

[Continues until design is clear, then presents in sections]
```

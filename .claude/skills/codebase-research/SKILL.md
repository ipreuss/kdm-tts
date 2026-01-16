---
name: codebase-research
description: Deep codebase analysis before design decisions. Use when Architect receives requirements that touch unfamiliar areas, when multiple implementation approaches exist, or when assessing technical feasibility. Triggers on "research the codebase", "understand how X works", "explore existing patterns", "before designing", or when Architect needs to investigate code before making decisions.
---

# Codebase Research

Comprehensive codebase analysis that produces documented findings before design decisions. Inspired by research-code pattern but adapted to our role-based workflow.

## When to Use

- Architect receives requirements touching unfamiliar modules
- Multiple valid implementation approaches exist
- Assessing technical feasibility of a request
- Need to understand existing patterns before designing
- Task complexity is Medium or higher (see depth table)

## When NOT to Use

- Simple bug fix with known location
- Requirements are clear and touch familiar code
- Design is already complete (use `architect-handover-planning` instead)
- Quick lookup of a specific function (just use Grep/Read directly)

## Announce at Start

> "I'll use the codebase-research skill to analyze relevant code before designing a solution."

---

## Research Depth by Complexity

| Complexity | File Count | Focus |
|------------|------------|-------|
| **Quick** | 5-10 files | Single module, direct path |
| **Standard** | 15-30 files | Cross-module, integration points |
| **Thorough** | 30+ files | Architecture-wide, security, performance |

**Determine complexity by asking:**
- How many modules will this touch? (1 = Quick, 2-3 = Standard, 4+ = Thorough)
- Are there integration points to map? (No = Quick, Some = Standard, Many = Thorough)
- Is this a new pattern or extending existing? (Extending = Quick, New = Standard/Thorough)

---

## The Process

### Phase 1: Define Research Scope

Before diving in, establish:

```markdown
## Research Scope

**Bead:** kdm-xxx
**Goal:** [What we're trying to understand]
**Questions to answer:**
1. [Specific question 1]
2. [Specific question 2]
3. [Specific question 3]

**Keywords to search:** [term1, term2, term3]
**Modules likely relevant:** [Module1, Module2]
```

### Phase 2: Search Strategy

Use the Explore subagent for comprehensive searches:

```
Task(subagent_type=Explore): "Find all code related to [topic].
Focus on: [specific aspects].
Depth: [quick/medium/very thorough]"
```

**Direct searches when target is clear:**
- `Grep` for patterns, function names, error messages
- `Glob` for file patterns (`**/*Monster*.ttslua`)
- `Read` for specific files identified

### Phase 3: Document Findings

Create `work/<bead-id>/research.md`:

```markdown
# Research: [Topic]

**Bead:** kdm-xxx
**Date:** YYYY-MM-DD
**Complexity:** Quick | Standard | Thorough

## Questions Answered

### Q1: [Question from scope]
**Finding:** [Answer with evidence]
**References:**
- `Path/To/File.ttslua:123-145` — [what this shows]
- `Other/File.ttslua:67` — [what this shows]

### Q2: [Question from scope]
...

## Existing Patterns Found

### Pattern: [Name]
**Where:** `Module.ttslua:100-150`
**How it works:** [Brief description]
**Reusable for our task:** Yes/No/Partially — [why]

### Pattern: [Name]
...

## Integration Points

| Module | File | How it connects |
|--------|------|-----------------|
| Monster | `Monster.ttslua:200` | Calls X when Y |
| Showdown | `Showdown.ttslua:150` | Listens to Z event |

## Risks and Concerns

- **Risk 1:** [Description] — Mitigation: [approach]
- **Risk 2:** [Description] — Mitigation: [approach]

## Open Questions (for Design Phase)

- [ ] [Question that design must answer]
- [ ] [Decision needed before implementation]

## Recommendations

1. [Recommended approach based on findings]
2. [Alternative if primary doesn't work]
```

### Phase 4: Summarize for Design

After completing research.md, provide brief summary:

```markdown
## Research Complete

**Key findings:**
1. [Most important finding]
2. [Second most important]
3. [Third]

**Recommended approach:** [One sentence]

**Risks to address in design:** [List]

**Ready for design phase.** See `work/<bead-id>/research.md` for full details.
```

---

## File References: Always Include Line Numbers

```markdown
# ❌ BAD: Vague reference
"The Monster module handles level configuration"

# ✅ GOOD: Specific with line numbers
"Monster level is configured in `Monster.ttslua:234-267` via the
`Monster.SetLevel()` function which validates against LEVEL_CONFIG table at line 45"
```

---

## Research Artifacts

### Primary: `work/<bead-id>/research.md`
Full findings, patterns, risks, recommendations.

### Optional: `work/<bead-id>/research-notes.md`
Scratchpad during investigation (can delete after research.md complete).

### Integration with design.md
Research informs but doesn't duplicate design. Reference research from design:

```markdown
## Design Context

Based on research (see `work/kdm-xxx/research.md`), key constraints:
- [Constraint 1 from research]
- [Constraint 2 from research]
```

---

## Quick Reference Checklist

Before marking research complete:

- [ ] All scope questions answered with file:line references
- [ ] Existing patterns documented (reusable vs not)
- [ ] Integration points mapped
- [ ] Risks identified with mitigations
- [ ] Recommendations provided
- [ ] research.md saved to work folder
- [ ] Summary provided to continue to design phase

---

## Common Rationalizations to Reject

| Rationalization | Reality |
|-----------------|---------|
| "I know this codebase well enough" | Document findings anyway — future sessions don't share your memory |
| "Research slows things down" | Undocumented research leads to repeated exploration |
| "No need to write down obvious things" | What's obvious now won't be in 2 weeks |
| "I'll just grep a few things" | Unstructured search misses integration points |
| "Design will reveal what we need" | Research prevents design rework |

---

## Integration with Architect Workflow

1. **Receive requirements** → Check if familiar territory
2. **If unfamiliar or complex** → Use codebase-research skill
3. **Complete research.md** → Document findings
4. **Proceed to design** → Use brainstorming skill if multiple approaches
5. **Design references research** → Don't duplicate, link to it

---

## Example: Quick Research

```markdown
# Research: Adding resource display to showdown

**Bead:** kdm-abc
**Date:** 2024-12-15
**Complexity:** Quick

## Questions Answered

### Q1: Where are resources tracked during showdown?
**Finding:** Resources not currently tracked during showdown.
ResourceRewards.ttslua handles post-showdown only.
**References:**
- `ResourceRewards.ttslua:1-50` — Module only activates on Showdown.End event
- `Showdown.ttslua:200-250` — No resource state during combat

### Q2: What UI patterns exist for showdown displays?
**Finding:** BattleUi uses LayoutManager for survivor stats display.
**References:**
- `BattleUi.ttslua:100-200` — Panel creation pattern
- `Ui/LayoutManager.ttslua` — Standard layout system

## Existing Patterns Found

### Pattern: Event-Driven Display
**Where:** `BattleUi.ttslua:150`
**How it works:** Subscribes to Showdown events, rebuilds UI on state change
**Reusable:** Yes — same pattern works for resource display

## Recommendations

1. Create new ShowdownResources module following BattleUi pattern
2. Subscribe to relevant events for resource changes
3. Use LayoutManager for consistent UI

**Ready for design phase.**
```

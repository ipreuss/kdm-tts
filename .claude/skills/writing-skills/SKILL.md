---
name: writing-skills
description: Apply TDD to skill creation - test with subagents before writing, iterate until bulletproof. Use when creating new skills, editing existing skills, or when Team Coach is improving process documentation. Triggers on skill creation, new skill, edit skill, process documentation.
---

# Writing Skills

**Core Principle:** "Writing skills IS Test-Driven Development applied to process documentation."

If you haven't watched an agent fail without the skill, you lack confidence the skill teaches the right thing.

## The Iron Law

**NO SKILL WITHOUT A FAILING TEST FIRST**

Applies to new skills AND edits. No exceptions for:
- "Simple additions"
- "Documentation updates"
- "Just adding a section"

---

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| Test case | Pressure scenario with subagent |
| Production code | Skill document (SKILL.md) |
| Test fails (RED) | Agent violates rule without skill |
| Test passes (GREEN) | Agent complies with skill present |
| Refactor | Close loopholes while maintaining compliance |

---

## When to Create Skills

**Create a skill when:**
- The technique wasn't intuitively obvious
- You'd reference it across projects
- The pattern applies broadly
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices documented elsewhere
- Project-specific conventions (use CLAUDE.md instead)

---

## Skill Types

| Type | Purpose | Examples |
|------|---------|----------|
| **Technique** | Concrete methods with steps | systematic-debugging, root-cause-tracing |
| **Pattern** | Ways of thinking about problems | defense-in-depth, test-driven-development |
| **Reference** | API docs, syntax, tool documentation | kdm-tts-patterns, kdm-expansion-data |

---

## SKILL.md Structure

### Frontmatter (Required)

```yaml
---
name: skill-name
description: Use when [triggering conditions]. Triggers on [keywords].
---
```

**Description field (max 1024 chars):**
- Third-person voice
- Starts with "Use when..."
- Focus on WHEN to use, not WHAT it does
- Include trigger keywords for Claude Search Optimization

### Standard Sections

1. **Overview** — One-paragraph purpose
2. **When to Use** — Triggering conditions
3. **Core Pattern/Process** — The actual technique
4. **Quick Reference** — Tables, checklists
5. **Common Mistakes** — Anti-patterns
6. **Integration** — Links to other skills

---

## Claude Search Optimization (CSO)

The description field determines if Claude loads the skill.

**Include in description:**
- Error messages agents might see
- Symptoms ("flaky", "hanging", "nil value")
- Synonyms for the concept
- Tool/module names

**Example:**
```yaml
description: Trace bugs backward through call stack to find source of invalid data. Use when errors surface deep in call stack, "attempt to call/index nil value" with long trace, origin of problematic data is unclear. Triggers on stack trace, nil value, call chain, trace backward.
```

---

## RED-GREEN-REFACTOR for Skills

### RED Phase: Establish Baseline

Test WITHOUT the skill:
1. Launch subagent with a pressure scenario
2. Document violations that occur
3. Note exact rationalizations agent uses

```markdown
## Pressure Test: [Scenario]

**Without skill:**
- Agent did X instead of Y
- Rationalized with "just this once"
- Skipped verification step
```

### GREEN Phase: Write Minimal Skill

Write ONLY what addresses observed violations:
1. Address specific failure modes
2. Include rationalization table
3. Add red flags section

### REFACTOR Phase: Close Loopholes

1. Test edge cases
2. Add explicit prohibitions for observed workarounds
3. Build "Common Rationalizations to Reject" table
4. Update description with violation symptoms

---

## Testing Different Skill Types

### Discipline-Enforcing Skills (TDD, verification)

Test with:
- Academic questions that tempt shortcuts
- Time pressure scenarios
- "Just this once" situations

**Success:** Compliance under maximum stress

### Technique Skills (debugging, tracing)

Test with:
- Application scenarios
- Variations of the problem
- Missing information situations

**Success:** Correct application to new scenarios

### Reference Skills (APIs, patterns)

Test with:
- Retrieval scenarios
- Application to real code
- Gap coverage (what's missing?)

**Success:** Agent finds and correctly uses reference

---

## Skill Design: Problem-Oriented, Not Domain-Oriented

**Skills should be organized by WHEN they trigger (use case/problem), not by domain taxonomy.**

### Bad: Domain-Oriented (grab-bag)
```yaml
name: kdm-tts-patterns
description: TTS patterns for KDM mod. Covers async spawn callbacks,
object lifecycle, deck operations, coordinate system, Archive.Clean timing...
```

Problem: Triggers on too many unrelated situations. When it loads, most content is irrelevant.

### Good: Problem-Oriented (focused)
```yaml
name: tts-unknown-error
description: Debugging TTS <Unknown Error> messages and destroyed object issues.
Use when encountering <Unknown Error> in TTS console, nil reference in async callback...
```

Benefit: Triggers on a specific problem. All content is relevant when loaded.

### Splitting Criteria

**Split a skill when:**
- It exceeds 300 lines
- It covers 3+ distinct problem types
- Different sections would trigger in different situations
- You find yourself saying "also covers X, Y, and Z"

**Don't split when:**
- Content is tightly coupled (understanding A requires B)
- Sections share context that would need repeating
- The skill is already problem-focused

### Skill Size Guidelines

| Size | Assessment |
|------|------------|
| < 150 lines | Good — focused and scannable |
| 150-300 lines | Acceptable — review for split opportunities |
| 300-500 lines | Review — likely needs splitting |
| > 500 lines | Split required — too broad |

---

## Skill File Organization

### Self-Contained (preferred)
Everything in SKILL.md. Use for most skills.

### With Examples
SKILL.md + example files. Use when code examples exceed 50 lines.

### Heavy Reference
SKILL.md + reference files. Use for API documentation, large pattern libraries.

**Our convention:** Keep skills under 300 lines. Split into problem-oriented skills if larger.

---

## Common Rationalizations to Reject

| Rationalization | Reality |
|-----------------|---------|
| "It's obviously clear" | Test it — obvious to you isn't obvious to agent |
| "Testing skills is overkill" | Skills that haven't been tested don't work |
| "No time to test" | Broken skills waste more time than testing |
| "I'll test after I write it" | That's tests-after, not TDD |
| "Just a small edit" | Small edits break skills too |

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| **Narrative examples** | "One time I fixed X by doing Y" — not reusable |
| **Multi-language dilution** | Same example in 5 languages — pick the most relevant |
| **Code in flowcharts** | Flowcharts for decisions, code blocks for code |
| **Generic labels** | "Process" → "Verify root cause before fix" |

---

## Skill Creation Checklist

- [ ] **RED:** Tested pressure scenario WITHOUT skill
- [ ] **RED:** Documented exact agent violations
- [ ] **RED:** Noted rationalizations agent used
- [ ] **GREEN:** Wrote minimal skill addressing violations
- [ ] **GREEN:** Verified agent now complies
- [ ] **REFACTOR:** Tested edge cases
- [ ] **REFACTOR:** Added rationalization table
- [ ] **REFACTOR:** Updated description with trigger keywords
- [ ] **DESIGN:** Skill is problem-oriented (not domain grab-bag)
- [ ] **DESIGN:** Skill under 300 lines (split if larger)

---

## Supporting References

For detailed guidance on specific topics:

- **`anthropic-best-practices.md`** — Skill structure, progressive disclosure, token efficiency
- **`persuasion-principles.md`** — Why certain phrasings work (authority, commitment, etc.)
- **`creation-log-example.md`** — Real example of skill extraction and bulletproofing process

---

## Integration

- **Team Coach** uses this when creating/editing skills
- **skill-manager** subagent follows these patterns
- Links to `test-driven-development` skill for TDD concepts
- Human maintainer handles git commits

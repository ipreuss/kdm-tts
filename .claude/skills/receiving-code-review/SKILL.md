---
name: receiving-code-review
description: Process code review feedback with technical rigor, not performative agreement. Use when receiving Reviewer handover, when code-reviewer subagent returns feedback, or before implementing review suggestions. Triggers on review feedback, reviewer comments, implementing suggestions, code review response.
---

# Receiving Code Review

**Core Principle:** "Verify before implementing. Ask before assuming. Technical correctness over social comfort."

Code review demands technical evaluation, not emotional performance.

## When to Use

- Receiving handover from Reviewer with findings
- When code-reviewer subagent returns feedback
- Before implementing any review suggestion

---

## The Six-Step Response Pattern

1. **READ** feedback completely — Don't skim
2. **UNDERSTAND** by restating requirements — What is actually being asked?
3. **VERIFY** against actual codebase — Is this accurate?
4. **EVALUATE** technical soundness — Does this make sense?
5. **RESPOND** with acknowledgment or pushback — Factual, not performative
6. **IMPLEMENT** one item at a time with testing

---

## Forbidden Responses (Performative Agreement)

Never use these phrases:

- "You're absolutely right!"
- "Great catch!"
- "Excellent point!"
- "Thanks for the thorough review!"

These represent performative agreement, not technical evaluation.

## Required Responses (Factual)

Instead, use factual acknowledgment:

- "Fixed. Extracted validation to Util/Guard.ttslua"
- "Addressed in Archive.ttslua:142-156"
- "Implemented. Added cross-module integration test"
- "Declined — conflicts with Architect design (see ADR-005)"

---

## Handling Feedback by Source

| Source | Trust Level | Approach |
|--------|-------------|----------|
| Reviewer role handover | High | Implement after understanding |
| code-reviewer subagent | Medium | Evaluate technically, may push back |
| External feedback | Low | Verify heavily, check context |

---

## When to Push Back

Push back with evidence when:

- Suggestion breaks existing functionality
- Reviewer lacks context for this module
- Feature violates YAGNI (not actually used)
- Conflicts with Architect's design decisions
- Performance implications reviewer missed

**Pushback format:**
```markdown
Declined: [suggestion]
Reason: [evidence-based explanation]
Alternative: [if applicable]
```

---

## YAGNI Check

When review suggests "proper implementation" or "should really have X":

1. **Grep** codebase for actual usage
2. **If unused** → Propose removing it entirely
3. **If used** → Implement properly

```bash
# Check if feature is actually used
grep -r "functionName" Kdm/ tests/
```

---

## Implementation Order

For multi-item feedback:

1. **Clarify** unclear items first (don't guess)
2. **Critical issues** — Fix immediately
3. **Important issues** — Fix before handover
4. **Simple fixes** — Quick wins
5. **Complex fixes** — May need design discussion
6. **Test each** individually before moving on

---

## Handling Unclear Feedback

When any item is unclear:

1. **STOP** before implementing anything
2. **Ask** for clarification on ALL unclear items
3. **Wait** for response — They may be related
4. **Then** implement with full understanding

Partial understanding risks wrong implementation.

---

## Gracefully Correcting When Wrong

When you were wrong about a pushback:

```markdown
You were right — I checked [X] and verified [Y].
Implementing now.
```

Avoid:
- Long apologies
- Defensiveness
- Over-explanation

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Performative agreement | Skips technical evaluation |
| Blind implementation | May introduce bugs |
| Batch changes without testing | Can't isolate what broke |
| Assuming reviewer correctness | Even experts make mistakes |
| Avoiding pushback | Valid concerns get buried |
| Proceeding without clarity | Wastes effort on wrong thing |
| **Skipping comments after commit** | Commit is checkpoint, not completion |

## ⛔ STOP: "APPROVED WITH COMMENTS" Means Fix Them

When you receive "APPROVED WITH MINOR FINDINGS" or "APPROVED WITH COMMENTS":

1. **Commit** current working code (safety checkpoint)
2. **Address ALL comments** — this is mandatory, not optional
3. **Re-invoke reviewer** to verify fixes
4. **Repeat** until pure APPROVED (no comments)

**The commit is a safety net, NOT permission to skip remaining work.**

If you disagree with a comment, push back with evidence (see "When to Push Back"). But you cannot simply ignore it.

---

## Red Flags — STOP Before Implementing

Stop and reconsider if you notice:

- Writing "You're absolutely right!" or similar performative phrases
- Implementing without verifying against the codebase
- Accepting all feedback without evaluation
- Implementing multiple items without testing each
- Skipping unclear items instead of asking for clarification
- Feeling pressure to agree rather than evaluate
- Not checking YAGNI on "proper implementation" suggestions

**If your response contains performative agreement, delete it and start with factual acknowledgment.**

---

## Integration

- Implementer receives from Reviewer via handover
- Use `code-reviewer` subagent for pre-handover checks
- Document rationale when declining suggestions
- Reference `verification-before-completion` after implementing
- Git commits require human approval

---
name: verification-before-completion
description: Ensures fresh verification evidence before any completion claims. Use before saying "done", "complete", "fixed", or "passing", before creating handovers, before session closing signature, or before claiming tests pass. Triggers on completion language, handover creation, or session end. Prevents "should work" and "probably fixed" claims.
---

# Verification Before Completion

**Core Principle:** "Evidence before assertions. Run the command. Read the output. THEN claim the result."

## The Iron Law

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE**

You cannot assert something passes unless you've executed the verification command yourself in the current session.

## When to Use

- Before saying "done", "complete", "fixed", or "passing"
- Before creating handovers to other roles
- Before the session closing signature
- Before claiming tests pass

## The Five-Step Gate Function

1. **IDENTIFY** the command proving the claim (e.g., `lua tests/run.lua`)
2. **RUN** the command fresh in this session
3. **READ** full output and check for errors
4. **VERIFY** output confirms the claim
5. **ONLY THEN** make the claim

Skipping any step is misrepresentation, not verification.

---

## Role-Specific Verification

| Role | Must Verify Before Handover |
|------|----------------------------|
| **Implementer** | `lua tests/run.lua` passes, code-reviewer subagent ran |
| **Tester** | All acceptance tests pass, TTS verification if UI |
| **Debugger** | Root cause identified with evidence, regression test written |
| **Reviewer** | All review items addressed or documented |

### Implementer Verification Template

```markdown
## Verification

**Tests:** Verified `lua tests/run.lua` — 47 tests passed, 0 failures
**Code Review:** code-reviewer subagent ran, findings addressed
**TTS:** [If UI changes] ./updateTTS.sh run, visual verification complete
```

### Tester Verification Template

```markdown
## Verification

**Headless Tests:** `lua tests/run.lua` — all acceptance tests pass
**TTS Tests:** [If applicable] `>testall` — X tests passed
**Visual:** [If UI] Screenshot/description of expected behavior confirmed
```

### Debugger Verification Template

```markdown
## Verification

**Root Cause:** Identified at [file:line] — [explanation]
**Evidence:** [debug output, stack trace, or test failure]
**Regression Test:** Written in [test file], currently FAILS as expected
```

---

## Forbidden Phrases

These indicate verification was skipped:

- "Tests should pass"
- "This probably fixes it"
- "I believe this works"
- "I'll verify later"
- "Should be fine"

## Required Phrases

Use evidence-based language:

- "Verified: `lua tests/run.lua` — 47 tests passed"
- "Confirmed: [specific evidence]"
- "Proven: Regression test now passes"

---

## Red Flags — STOP

Stop and follow the gate function if you notice:

- Speculative language ("should", "probably", "likely")
- Satisfaction before verification ("Great, that's done")
- Trusting previous session's results
- Partial verification ("I ran some tests")
- "The code looks correct"

---

## Common Verification Commands

| Claim | Verification Command |
|-------|---------------------|
| Tests pass | `lua tests/run.lua` |
| TTS tests pass | `./updateTTS.sh` then `>testall` in TTS |
| Code is ready | code-reviewer subagent |
| UI works | Screenshot or TTS visual check |

---

## Pre-Handover Checklist

Before using handover-manager or handover-writer:

- [ ] Ran verification command in THIS session
- [ ] Read FULL output (not just summary)
- [ ] Output confirms claim (not just "no errors")
- [ ] Evidence documented in handover

---

## Session Closing Checklist

Before the closing signature:

- [ ] All claims in session have evidence
- [ ] Final test run completed
- [ ] No "should pass" language in summary

---

## Why This Matters

Historical failures from skipping verification:
- "Tests pass" → undefined functions shipped
- "Feature complete" → missing edge cases
- "Bug fixed" → symptom masked, not resolved
- Hours wasted on false completion claims

---

## Integration

- Works with `session-closing` skill
- Pre-check for `handover-manager` subagent
- Git commits require human approval

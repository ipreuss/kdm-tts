# Creation Log Example: Systematic Debugging Skill

Reference example of extracting, structuring, and bulletproofing a critical skill. Adapted from [obra/superpowers](https://github.com/obra/superpowers).

---

## Source Material

Extracted debugging framework from personal CLAUDE.md:
- 4-phase systematic process (Investigation → Pattern Analysis → Hypothesis → Implementation)
- Core mandate: ALWAYS find root cause, NEVER fix symptoms
- Rules designed to resist time pressure and rationalization

---

## Extraction Decisions

### What to Include
- Complete 4-phase framework with all rules
- Anti-shortcuts ("NEVER fix symptom", "STOP and re-analyze")
- Pressure-resistant language ("even if faster", "even if I seem in a hurry")
- Concrete steps for each phase

### What to Leave Out
- Project-specific context (adapted separately)
- Repetitive variations of same rule
- Narrative explanations (condensed to principles)

---

## Structure Decisions

Following skill writing best practices:

1. **Rich description field** — Included symptoms and anti-patterns for CSO
2. **Keywords in description** — "root cause", "symptom", "workaround", "debugging"
3. **Phase-by-phase breakdown** — Scannable checklist format
4. **Anti-patterns section** — What NOT to do (critical for discipline skills)
5. **Rationalization table** — Common excuses with rebuttals
6. **Red flags section** — Warning signs to stop and reconsider

---

## Bulletproofing Elements

Framework designed to resist rationalization under pressure:

### Language Choices

| Weak | Strong |
|------|--------|
| "should" | "ALWAYS" |
| "try to" | "NEVER" |
| "consider" | "STOP and re-analyze" |
| "avoid" | "Don't skip past" |

Absolute language eliminates wiggle room for rationalization.

### Structural Defenses

- **Phase 1 required** — Can't skip to implementation
- **Single hypothesis rule** — Forces thinking, prevents shotgun fixes
- **Explicit failure mode** — "IF your first fix doesn't work" with mandatory action
- **Anti-patterns section** — Shows exactly what shortcuts look like

### Redundancy

- Root cause mandate appears in overview + when_to_use + Phase 1 + implementation rules
- "NEVER fix symptom" appears 4 times in different contexts
- Each phase has explicit "don't skip" guidance

---

## Testing Approach

Created validation tests using subagents (see `writing-skills/SKILL.md` for methodology):

### Test 1: Academic Context (No Pressure)
- Simple bug, no time pressure
- **Expected:** Complete investigation, full process
- **Result:** Perfect compliance

### Test 2: Time Pressure + Obvious Quick Fix
- User "in a hurry", symptom fix looks easy
- **Expected:** Resist shortcut, follow process
- **Result:** Resisted, found real root cause

### Test 3: Complex System + Uncertainty
- Multi-layer failure, unclear if can find root cause
- **Expected:** Systematic investigation through layers
- **Result:** Traced through all layers, found source

### Test 4: Failed First Fix
- Hypothesis doesn't work, temptation to add more fixes
- **Expected:** Stop, re-analyze, new hypothesis
- **Result:** Stopped, re-analyzed (no shotgun debugging)

**All tests passed.** No rationalizations found.

---

## Iterations

### Initial Version
- Complete 4-phase framework
- Anti-patterns section
- Basic structure

### Enhancement 1: Rationalization Table
- Added common excuses with rebuttals
- Catches "sounds reasonable" shortcuts

### Enhancement 2: Red Flags Section
- Warning signs to trigger self-check
- Explicit "STOP" conditions

### Enhancement 3: Project Integration
- Added Lua/TTS examples
- Linked to `root-cause-tracing` skill
- Referenced handover workflow

---

## Final Outcome

Bulletproof skill that:
- Clearly mandates root cause investigation
- Resists time pressure rationalization
- Provides concrete steps for each phase
- Shows anti-patterns explicitly
- Tested under multiple pressure scenarios
- Integrated with project workflow

---

## Key Insight

> Most important bulletproofing involves the anti-patterns section displaying exact shortcuts that seem justified under pressure. When encountering a temptation to "just add this one quick fix," seeing that precise pattern marked as incorrect generates protective cognitive resistance.

The rationalization table works because it pre-empts the excuse before it forms. The red flags section works because it creates a "stop and check" trigger at the moment of temptation.

---

## Checklist for New Skills

Use this when creating skills following TDD:

### Before Writing
- [ ] Identify source material
- [ ] List what to include vs. exclude
- [ ] Design test scenarios (at least 3)

### Structure
- [ ] Rich description with keywords
- [ ] Clear when-to-use triggers
- [ ] Step-by-step process (if technique)
- [ ] Anti-patterns section
- [ ] Rationalization table (6+ items)
- [ ] Red flags section

### Language
- [ ] Absolute language (ALWAYS/NEVER)
- [ ] Explicit failure modes
- [ ] "STOP and reconsider" triggers
- [ ] Redundancy at key decision points

### Testing
- [ ] Test with subagent (no pressure)
- [ ] Test with subagent (time pressure)
- [ ] Test with subagent (social pressure)
- [ ] Test with subagent (failed first attempt)

### Integration
- [ ] Project-specific examples
- [ ] Links to related skills
- [ ] Added to relevant role file(s)

---

*Adapted from obra/superpowers systematic-debugging CREATION-LOG.md*
*Purpose: Reference example for skill extraction and bulletproofing*

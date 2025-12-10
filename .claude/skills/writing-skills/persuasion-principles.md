# Persuasion Principles for Skill Design

LLMs respond to the same persuasion principles as humans. Research shows persuasion techniques more than doubled compliance rates (33% → 72%).

## The Seven Principles

### 1. Authority

**Definition:** Deference to expertise, credentials, or official sources.

**Application:** Use imperative language: "YOU MUST", "Never", "Always". Frame requirements as non-negotiable.

**Best for:** Discipline-enforcing skills, safety-critical practices.

**Example:**
> "Write code before test? Delete it. Start over. No exceptions."

### 2. Commitment

**Definition:** Consistency with prior actions, statements, or public declarations.

**Application:** Require announcements, force explicit choices, use tracking (TodoWrite).

**Best for:** Multi-step processes, accountability mechanisms.

**Example:**
> "When using a skill, you MUST announce: 'I'm using [Skill Name].'"

### 3. Scarcity

**Definition:** Urgency created by time limits or sequential dependencies.

**Application:** Establish immediate requirements that prevent "I'll do it later".

**Best for:** Verification requirements, preventing procrastination.

**Example:**
> "After completing a task, IMMEDIATELY request code review before proceeding."

### 4. Social Proof

**Definition:** Conformity to what others do or what's considered normal.

**Application:** Use universal patterns ("Every time", "Always"), establish norms through failure modes.

**Best for:** Documenting universal practices, reinforcing standards.

**Example:**
> "Checklists without tracking = steps get skipped. Every time."

### 5. Unity

**Definition:** Shared identity and "we-ness" or in-group belonging.

**Application:** Collaborative language emphasizing shared goals.

**Best for:** Collaborative workflows, team culture.

**Example:**
> "We're colleagues working together. I need your honest technical judgment."

### 6. Reciprocity

**Definition:** Obligation to return benefits received.

**Usage:** Use sparingly — can feel manipulative, rarely needed in skill design.

### 7. Liking

**Definition:** Preference for cooperating with those we like.

**Warning:** Don't use for compliance enforcement — creates sycophancy, conflicts with honest feedback.

---

## Principle Combinations by Skill Type

| Skill Type | Use | Avoid |
|------------|-----|-------|
| **Discipline-enforcing** | Authority + Commitment + Social Proof | Liking, Reciprocity |
| **Guidance/technique** | Moderate Authority + Unity | Heavy authority |
| **Collaborative** | Unity + Commitment | Authority, Liking |
| **Reference** | Clarity only | All persuasion |

---

## Why This Works

### Bright-Line Rules Reduce Rationalization

Absolute language ("NEVER", "NO EXCEPTIONS") eliminates decision fatigue and prevents rationalization.

Compare:
- ❌ "You should usually write tests first"
- ✅ "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"

### Implementation Intentions

Clear trigger-action pairings ("When X, do Y") are more effective than general guidance.

Compare:
- ❌ "Remember to verify your work"
- ✅ "Before saying 'done': Run `lua tests/run.lua`. Read output. THEN claim completion."

---

## Ethical Use

**Legitimate:**
- Ensuring critical practices are followed
- Creating effective documentation
- Preventing predictable failures

**Illegitimate:**
- Manipulating for personal gain
- Creating false urgency
- Guilt-based compliance

**The ethical test:** Would this technique serve the user's genuine interests if they fully understood it?

---

## Quick Reference

When designing a skill:

1. **What type is it?** (Discipline vs guidance vs reference)
2. **What behavior am I trying to change?**
3. **Which principle(s) apply?** (Usually authority + commitment for discipline)
4. **Am I combining too many?** (Don't use all seven)
5. **Is this ethical?** (Serves user's genuine interests?)

---
name: backlog-prioritization
description: Guide Product Owner in prioritizing backlog items with two core principles: (1) finish started work before starting new work, (2) technical debt and infrastructure improvements take precedence over new features. Use when prioritizing work, ordering the backlog, deciding what to work on next, reviewing upcoming work, or when asked about priority decisions.
---

# Backlog Prioritization

## Core Principles

### 1. Finish Started Work Before Starting New Work

**Work in progress (WIP) must be completed before starting new items.**

This is the highest priority. When work is started:
- Complete it before picking up anything new
- This includes all tasks for a started feature
- Half-finished work has zero value and creates confusion
- Context switching wastes time and introduces errors

### 2. Technical Debt and Infrastructure Before New Features

**Technical debt cleanup and infrastructure improvements ALWAYS take precedence over new feature development.**

When faced with a choice between fixing technical debt / improving infrastructure and building new features, debt and infrastructure win every time.

**Infrastructure improvements include:**
- Build system, CI/CD, deployment tooling
- Development environment setup and automation
- Testing infrastructure (test runners, fixtures, utilities)
- Process tooling (skills, agents, handover automation)
- Documentation systems and generators
- Performance monitoring and debugging tools

These have the same priority as technical debt because they multiply team effectiveness.

## Rationale

Technical debt compounds over time:
- Slows down future development
- Increases defect rates
- Makes the codebase harder to understand
- Reduces team morale and confidence
- Eventually blocks all forward progress

Cleaning up technical debt is an investment that pays dividends on every future feature. New features built on a clean codebase are:
- Faster to implement
- More reliable
- Easier to test
- Less likely to introduce new bugs

## Instructions

### When Prioritizing the Backlog

1. **Identify technical debt items**
   - Look for beads tagged with technical debt
   - Review handovers from Architect flagging technical issues
   - Check for DRY violations, code smells, test gaps
   - Note areas where developers report difficulty working

2. **Place technical debt at the top**
   - All technical debt items go before feature items
   - Within technical debt, prioritize by:
     - Impact (how many areas are affected?)
     - Pain level (how much does it slow development?)
     - Risk (what breaks if we ignore it?)

3. **Schedule features only after debt is addressed**
   - Features can be planned while debt work is in progress
   - But features should not be started until critical debt is cleared
   - Exception: critical production bugs (see below)

### Priority Order

```
0. Work in progress (finish what's started)
1. Critical production bugs (system down, data loss, security)
2. Technical debt cleanup / Infrastructure improvements
3. High-priority features
4. Medium-priority features
5. Low-priority features
6. Nice-to-have features
```

**Priority 0 is absolute.** No new work starts until in-progress work is complete. Check `bd list --status=in_progress` before starting anything new.

**Priority 2 includes both:**
- Technical debt (code quality, test gaps, DRY violations)
- Infrastructure (tooling, automation, process improvements)

### When Stakeholders Push for Features

**Common situation:** Stakeholders want new features but technical debt needs attention.

**Response template:**
```
I understand [feature X] would provide value. However, we have technical
debt that needs to be addressed first. This debt is currently:
- [Specific impact: slowing down development / causing bugs / etc.]

By cleaning this up first, we'll be able to deliver [feature X] faster
and more reliably. The total time to value will actually be shorter.

Timeline:
- Technical debt cleanup: [estimate from Architect]
- Then [feature X]: [estimate from Architect]
```

**Key message:** Technical debt is not "just cleanup" — it's enabling infrastructure for all future work.

### Exception: Critical Production Issues

The only thing that can jump the queue ahead of technical debt is:
- System is down
- Data loss is occurring
- Security vulnerability is actively exploited
- Users cannot perform core business functions

Even then, once the crisis is resolved, return immediately to technical debt work.

### Communicating with the Team

**To Architect:**
When handing over requirements, acknowledge technical debt priority:
```
Priority 1: Address technical debt in [module X]
Priority 2: [Feature Y] (to be started after debt cleanup)
```

**To stakeholders:**
Frame technical debt in business terms:
- "Reducing maintenance costs"
- "Improving system reliability"
- "Accelerating future development"
- "Preventing production incidents"

Avoid technical jargon like "refactoring," "code smell," or "coupling."

## Examples

### Example 1: Feature Request vs Known Debt

**Situation:**
- Stakeholder requests new settlement event tracking
- Architect has flagged DRY violations in existing event system
- Event system code is copied across 5 different modules

**Decision:**
```
Priority 1: Clean up event system DRY violations
Priority 2: Add settlement event tracking (will be easier after cleanup)
```

**Confidence:** 100% — This is the correct prioritization.

### Example 2: Multiple Debt Items

**Situation:**
- Test coverage gaps in survival actions module
- Hardcoded strings scattered across UI
- Legacy database schema causing query slowdowns

**Priority order:**
```
1. Legacy database schema (affects multiple features, causes production issues)
2. Test coverage gaps (prevents confident refactoring)
3. Hardcoded strings (painful but localized impact)
```

**Confidence:** 95% — Database schema has highest ROI, but specific context might adjust order.

### Example 3: Small Feature vs Major Debt

**Situation:**
- Quick win: Add single button to export survivor roster (2 hour task)
- Technical debt: Rewrite resource handling system (40 hour task)

**Decision:**
```
Priority 1: Rewrite resource handling system
Priority 2: Export button
```

**Rationale:** Size doesn't matter. The principle is absolute. Technical debt first.

**Confidence:** 100% — Principle applies regardless of effort estimates.

### Example 4: Stakeholder Escalation

**Situation:**
- CEO wants new dashboard feature for board presentation next month
- Critical technical debt in data aggregation layer affects reliability

**Response:**
```
"I understand the board presentation is important. However, our data
aggregation layer has technical debt that's causing reliability issues.
If we build the dashboard on top of this, we risk:
- Inaccurate data in the presentation
- Dashboard breaking after initial demo
- Longer total delivery time

My recommendation:
Week 1-2: Fix data aggregation layer
Week 3-4: Build dashboard on solid foundation

This gives us the dashboard with 2 weeks to spare before the board meeting,
and it will be reliable."
```

**Confidence:** 90% — This approach balances business needs with technical reality.

## Red Flags

Watch for these signs that debt is being deprioritized:

- "We'll circle back to that after this feature"
- "Let's just get this out the door first"
- "That's not user-facing, so it's not urgent"
- "We can live with this for now"

**Response:** Gently but firmly restate the principle. Technical debt doesn't age well.

## Verification

After prioritizing the backlog, check:
- [ ] No new work starts while work is in progress (`bd list --status=in_progress` is empty OR being worked on)
- [ ] All technical debt items are above all feature items
- [ ] Technical debt is ordered by impact and risk
- [ ] Features have clear acceptance criteria (for when debt is cleared)
- [ ] Stakeholders understand the prioritization rationale
- [ ] Architect has reviewed and confirmed debt items are accurately described

## Integration with Beads

When using `bd` for issue tracking:
- Tag technical debt beads appropriately
- Use comments to note impact and affected areas
- Reference technical debt beads in feature beads that depend on cleanup
- Close technical debt beads only after Reviewer confirms cleanup is complete

## Notes

- **This is a project policy**, not a suggestion. All roles should understand this principle.
- Product Owner enforces this priority in the backlog.
- Architect identifies and estimates technical debt.
- Implementer executes the cleanup.
- Reviewer verifies debt is truly resolved.

**Confidence on this principle:** 100% — This is the foundational rule for sustainable development.

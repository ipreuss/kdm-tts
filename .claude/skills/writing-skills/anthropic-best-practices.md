# Skill Authoring Best Practices

Reference for writing effective skills that Claude can discover and use successfully.

## Core Principles

### Conciseness Matters

The context window is shared with conversation history and system prompts. Challenge each piece of information:

> "Does Claude really need this explanation?"

Token efficiency is critical for frequently-loaded skills.

### Degrees of Freedom

Match instruction specificity to task fragility:

| Freedom Level | Use For | Format |
|---------------|---------|--------|
| **High** | Flexible approaches | Text instructions |
| **Medium** | Preferred patterns with variation | Pseudocode |
| **Low** | Fragile, error-prone operations | Specific code/scripts |

---

## Skill Structure

### Metadata Fields

**Name:** Use gerund form ("Processing PDFs", "Writing Tests")

**Description:**
- Third person voice
- Specify WHAT it does AND WHEN to use it
- Include trigger keywords
- Max 1024 characters

### Progressive Disclosure

Use file-based architecture:
1. SKILL.md contains overview and references
2. Detailed files loaded only when needed
3. Keep SKILL.md under 500 lines

### Organization Patterns

**1. High-level guide with external references**
```
SKILL.md → overview + links to details
├── api-reference.md
└── examples.md
```

**2. Domain-specific organization**
```
SKILL.md → overview + links by domain
├── tts-patterns.md
├── ui-patterns.md
└── data-patterns.md
```

**3. Conditional details**
```
SKILL.md → basic content + "For advanced usage, see X"
```

**Avoid:** Deeply nested references. Keep all reference files one level deep from SKILL.md.

---

## Content Guidelines

### Workflows

- Implement as sequential checklists
- Include feedback loops (validate → fix → repeat)
- Avoid time-sensitive information

### Writing Style

- Write for clarity, not impressiveness
- Use consistent terminology
- One concept per section
- Tables for comparisons
- Code blocks for examples

### Token Efficiency

For frequently-loaded skills:
- Getting-started workflows: under 150 words
- Total skill: under 200 words if possible
- Compress examples
- Use cross-references rather than repeating content

---

## Testing

### Test Across Models

Different models have different capabilities:
- Instructions effective for Opus may need more detail for Haiku
- Sonnet balances capability and speed

### Build Evaluations

Before deploying:
1. Test with pressure scenarios
2. Document failure modes
3. Iterate until reliable

---

## Quick Checklist

- [ ] Description starts with "Use when..."
- [ ] Trigger keywords in description
- [ ] Under 500 lines
- [ ] Progressive disclosure for details
- [ ] Tested with subagent
- [ ] Clear, consistent terminology

---
name: resource-rewards
description: KDM resource reward patterns and deck verification. Use when configuring monster rewards, verifying resource deck membership, understanding L4+ reward tiers, or debugging reward spawning. Triggers on resource rewards, monster rewards, strange resources, basic resources, L4 rewards, reward config.
---

# Resource Rewards

## When to Use

Use when:
- Configuring monster resource rewards
- Verifying which deck contains a resource
- Understanding L4+ monster reward patterns
- Debugging resource spawning issues
- Adding new reward configurations

## Resource Rewards Pattern

Resource rewards spawn from **existing decks on showdown board**, not fresh archive decks.

**Why**: If events during showdown allowed players to take resources early, those cards should not be available as rewards.

**Implementation**: `ResourceRewards.ttslua` inspects board decks, doesn't call `Archive.Take()`.

## Deck Verification (CRITICAL)

**Before adding resources to reward configs, verify which deck contains the card.**

### Common Mistake

Rulebook says "Add 4 Elytra to settlement storage" — this does NOT mean Elytra is a strange resource. The rulebook describes the **effect**, not the **deck category**.

### Verification Steps

1. **Check the expansion file** for deck definitions:
   ```lua
   components = {
       ["Monster Resources"] = "Dung Beetle Knight Resources",
       ["Strange Resources"] = "Dung Beetle Knight Strange Resources",
   }
   ```

2. **Search template_workshop.json** for the actual card:
   ```bash
   grep -i "elytra" template_workshop.json
   ```
   Look at `ContainedObjects` to see which deck contains it.

3. **Use TTS console** to inspect deck contents:
   ```
   >interact Dung Beetle Knight Strange Resources
   ```
   Visually inspect what cards are in the deck.

### Resource Category Hints

| Rulebook Language | Likely Category | Verify! |
|-------------------|-----------------|---------|
| "Add X to storage" | Could be ANY category | Always check |
| "Gain X monster resources" | Monster Resources | Usually correct |
| "Gain X strange resources" | Strange Resources | Usually correct |
| Named resource (e.g., "Elytra") | Check deck contents | Required |

## Level 4+ Monster Rewards

KDM doesn't define separate L4 reward tiers. Level 4+ monsters use **L3 rewards + unique bonuses**:

| Monster | Level | Base Rewards | Bonus |
|---------|-------|--------------|-------|
| Beast of Sorrow | 4 | L3 rewards | +1 Iron (strange) |
| Great Golden Cat | 4 | L3 rewards | +1 monster resource of choice |

**Pattern**: Higher-level variants grant the highest standard reward tier (L3) plus unique bonuses (strange resources, rare gear, extra monster resources).

**Don't look for "L4 rewards"** — they don't exist as a separate tier.

## Reward Configuration Structure

```lua
showdown = {
    resources = {
        basic = 4,    -- Basic resource deck draws
        monster = 4,  -- Monster resource deck draws
    },
},
```

For special rewards beyond deck draws, see monster-specific implementations.

## Why Verification Matters

`Archive.TakeFromDeck()` fails silently or errors when the card isn't in the specified deck. TTS testing catches this, but verification upfront is faster.

## Key Files

- `/Users/ilja/Documents/GitHub/kdm/ResourceRewards.ttslua` — Reward spawning logic
- `/Users/ilja/Documents/GitHub/kdm/Expansion/*.ttslua` — Deck definitions
- `/Users/ilja/Documents/GitHub/kdm/template_workshop.json` — Actual deck contents

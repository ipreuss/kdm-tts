---
name: dry-violations
description: Activates when about to write/edit similar or identical code in multiple locations. Use when making Edit/Write calls with similar code blocks to different files, when the same string literal or magic number appears in multiple edits, when adding a function that resembles existing functions discovered via Grep/Read, or when applying the same pattern/change to 2+ files in sequence. Prevents duplication before it happens.
---

# DRY Violations Detection and Resolution

## Purpose

This skill activates when Claude is about to make similar or identical changes in multiple locations, indicating a potential DRY violation. It provides guidance on recognizing duplication, extracting common logic, and safely refactoring to eliminate redundancy.

## Trigger Conditions

**Activate this skill when Claude is about to:**

1. **Make multiple Edit/Write calls with similar code blocks** — When preparing to write the same or very similar function/logic to 2+ files
2. **Use the same literal value in multiple edits** — When the same string literal (e.g., `"settlement"`) or magic number (e.g., `4`) appears in multiple Edit/Write operations
3. **Add logic that resembles existing code** — When about to Write/Edit a function and Grep/Read reveals similar logic already exists elsewhere
4. **Apply the same pattern sequentially** — When editing file X after having just made structurally identical changes to file Y
5. **Copy-paste between files** — When about to Write a code block that was just Read from another file
6. **Add parallel validation/error handling** — When about to Edit in a second file with validation logic that mirrors a recent edit
7. **Implement similar test structures** — When writing a second/third test function with identical setup/teardown patterns

## Workflow-Based Detection

### Observable Signals in Claude's Workflow

**Signal 1: Multiple Edit calls with similar new_string content**
```
If preparing edits where new_string in Edit call 1 resembles new_string in Edit call 2:
→ PAUSE and evaluate for extraction
```

**Signal 2: Same literal appears in consecutive tool calls**
```
If string literal "settlement" appears in:
- Edit call to Rules.ttslua (line 45)
- Edit call to Showdown.ttslua (line 78)
- Edit call to ResourceRewards.ttslua (line 23)
→ Consider extracting to Constants module
```

**Signal 3: Grep reveals existing similar logic**
```
User asks: "Add validation for container.data"
Claude runs: Grep pattern="container.data"
Result: Found in 3 files with identical validation logic
→ Before adding 4th instance, propose extraction
```

**Signal 4: Read-then-Write pattern (copy-paste)**
```
1. Read file A, observe function validateMonster()
2. About to Write file B with similar validateSurvivor()
→ Check if logic can be unified before writing
```

**Signal 5: Sequential structural edits**
```
Just completed: Edit ResourceRewards.ttslua (added error handling pattern)
Now preparing: Edit Rules.ttslua (same error handling pattern)
→ Flag as potential duplication
```

**Signal 6: Test pattern repetition**
```
Writing test function 2/3 with identical:
- Setup code (createTestContainer)
- Teardown code (cleanupTest)
- Assertion patterns
→ Consider test helpers or shared fixtures
```

## Recognition Patterns

### Code Duplication Indicators

**Structural duplication:**
```lua
-- File A
function processMonsterA(monster)
    if not monster then return end
    if not monster.data then return end
    -- logic
end

-- File B
function processMonsterB(monster)
    if not monster then return end
    if not monster.data then return end
    -- logic (same pattern, different context)
end
```

**Magic value duplication:**
```lua
-- Multiple files using same constants
local SETTLEMENT_PHASE = "settlement"
local MAX_SURVIVORS = 4
```

**Logic duplication:**
```lua
-- Similar conditional logic in different modules
if event.type == "showdown" and event.monster then
    -- pattern repeats across files
end
```

### When Duplication is Acceptable

**Rule of Three:** Don't extract until the pattern appears 3+ times (confidence: 85%)

**Acceptable duplication contexts:**
1. **Test code** — Clarity often outweighs DRY in tests
2. **Different domains** — Similar structure but unrelated concepts
3. **Temporary states** — Code in transition, not yet stable
4. **Performance-critical** — Inlining may be necessary
5. **External API compatibility** — Forced duplication by external constraints

## Extraction Strategies

### 1. Extract to Function

**When:** Same logic appears in multiple places within related modules

**Pattern:**
```lua
-- Before: Duplicated validation
function handleEventA(data)
    if not data or type(data) ~= "table" then
        Logger.error("Invalid data")
        return false
    end
    -- specific logic
end

function handleEventB(data)
    if not data or type(data) ~= "table" then
        Logger.error("Invalid data")
        return false
    end
    -- specific logic
end

-- After: Extracted validation
function validateData(data, context)
    if not data or type(data) ~= "table" then
        Logger.error("Invalid data in " .. context)
        return false
    end
    return true
end

function handleEventA(data)
    if not validateData(data, "EventA") then return false end
    -- specific logic
end

function handleEventB(data)
    if not validateData(data, "EventB") then return false end
    -- specific logic
end
```

### 2. Extract to Module/Utility

**When:** Same logic needed across unrelated modules

**Create shared utility:**
```lua
-- Util/Validation.ttslua
Validation = {}

function Validation.requireTable(value, name)
    if not value or type(value) ~= "table" then
        error(name .. " must be a table")
    end
    return value
end

return Validation
```

### 3. Extract Constants

**When:** Same literal values appear in multiple places

**Pattern:**
```lua
-- Before: Magic values scattered
if phase == "settlement" then end
if currentPhase == "settlement" then end

-- After: Centralized constants
-- Constants.ttslua
Constants = {
    PHASE_SETTLEMENT = "settlement",
    PHASE_SHOWDOWN = "showdown",
    MAX_SURVIVORS = 4
}

-- Usage
if phase == Constants.PHASE_SETTLEMENT then end
```

### 4. Template Method Pattern

**When:** Similar structure but different steps

**Pattern:**
```lua
-- Base behavior with customization points
function processTemplate(data, validator, transformer)
    if not validator(data) then return nil end
    local transformed = transformer(data)
    return transformed
end

-- Specific implementations
function processMonster(data)
    return processTemplate(
        data,
        validateMonsterData,
        transformMonsterData
    )
end
```

## Safe Extraction Protocol

### Step 1: Create Characterization Tests

**Before extracting, ensure behavior is captured:**

```lua
-- TTSTests/DuplicationRefactorTests.ttslua
function testCurrentBehaviorA()
    local result = moduleA.duplicatedFunction(testInput)
    Assert.areEqual(expected, result)
end

function testCurrentBehaviorB()
    local result = moduleB.duplicatedFunction(testInput)
    Assert.areEqual(expected, result)
end
```

### Step 2: Extract Incrementally

**Process:**
1. Identify exact duplication boundaries
2. Create new shared function with identical logic
3. Replace ONE call site
4. Run tests
5. Replace next call site
6. Run tests
7. Repeat until all call sites use shared version

**Never:** Replace all call sites at once without testing

### Step 3: Verify Equivalence

**Checklist:**
- [ ] All original call sites now use extracted version
- [ ] All tests pass
- [ ] No behavior changes observed
- [ ] Error handling preserved
- [ ] Edge cases still handled correctly

### Step 4: Clean Up

**After successful extraction:**
- Remove old duplicated code
- Update related documentation
- Consider if further abstraction needed

## Decision Framework

### Should I Extract This Duplication?

**YES if:**
- Change appears in 3+ places (Rule of Three)
- Logic is stable and unlikely to diverge
- Extraction improves clarity
- All duplicates are truly identical in intent
- You have tests covering the behavior

**NO if:**
- Only 2 occurrences exist (wait for third)
- Code is in flux, not yet stable
- Domains are unrelated (coincidental duplication)
- Extraction would obscure intent
- No tests exist yet (write tests first)

**MAYBE — Investigate further:**
- Similar structure but different details
- Code is in test suite
- Performance-critical path
- External API contracts involved

## Examples from KDM Codebase

### Example 1: Container Validation

**Duplication pattern:**
Multiple modules validate container state before operations.

**Before:**
```lua
-- In multiple files
if not container or not container.data then
    error("Invalid container")
end
```

**After:**
```lua
-- Util/Container.ttslua
function Container.validate(container, operation)
    if not container or not container.data then
        error("Invalid container for " .. operation)
    end
    return container
end

-- Usage
Container.validate(container, "resource reward")
```

### Example 2: Event Data Extraction

**Duplication pattern:**
Multiple event handlers extract and validate event data.

**Consider extracting:**
```lua
-- Common pattern across event handlers
function extractEventData(eventData, requiredFields)
    if not eventData then return nil end

    local extracted = {}
    for _, field in ipairs(requiredFields) do
        if not eventData[field] then
            Logger.error("Missing required field: " .. field)
            return nil
        end
        extracted[field] = eventData[field]
    end

    return extracted
end
```

### Example 3: Test Setup Duplication

**Acceptable duplication in tests:**
```lua
-- Test clarity often outweighs DRY
function testResourceRewardA()
    local container = createTestContainer()
    local event = {type = "hunt", data = {}}
    -- test-specific logic
end

function testResourceRewardB()
    local container = createTestContainer()
    local event = {type = "settlement", data = {}}
    -- test-specific logic
end

-- This is OK - each test is clear and independent
```

## Warning Signs

**Stop and reassess if extraction leads to:**

1. **God objects** — Utility module doing too many unrelated things
2. **Over-parameterization** — Function needs 5+ parameters to handle all cases
3. **Boolean flags** — `doSpecialThing` parameter that changes behavior
4. **Unclear naming** — Can't name the extracted function clearly
5. **Test complexity** — Tests become harder to understand after extraction

## Integration with KDM Workflow

**When Claude detects duplication (before executing tool calls):**

1. **Pause** before making duplicate changes
2. **Self-check**: "Am I about to write/edit similar code in a second location?"
3. **Inform** user about detected pattern with specific evidence:
   - "I notice I'm about to add similar validation logic to Rules.ttslua that I just added to Showdown.ttslua"
   - "The string literal 'settlement' will appear in 3 different files after these edits"
   - "Grep shows this error handling pattern already exists in 2 other modules"
4. **Propose** extraction strategy with confidence score
5. **Ask** if extraction should be done now or deferred
6. **If extracting:** Follow safe extraction protocol
7. **If deferring:** Document location for future refactoring

**Self-Monitoring Checklist (run before Edit/Write calls):**
- [ ] Does this code block resemble something I just read/wrote?
- [ ] Am I using the same literal value I used in a previous edit?
- [ ] Did Grep reveal similar logic when I searched earlier?
- [ ] Is this the 2nd/3rd time I'm writing this pattern in this session?
- [ ] Would extracting this improve the codebase?

**Confidence scoring:**
- 90%+: Clear duplication, obvious extraction point
- 70-89%: Likely duplication, extraction recommended
- 50-69%: Possible duplication, investigation needed
- <50%: Coincidental similarity, extraction not recommended

## Response Template

When duplication is detected:

```
[DRY VIOLATION DETECTED]

**Pattern:** [describe the duplication]
**Locations:** [list files/functions]
**Confidence:** [X]% that extraction would improve code

**Recommendation:**
[Extract to function/module/constant]

**Proposed extraction:**
[code sketch]

**Would you like me to:**
1. Extract now (with characterization tests)
2. Make the duplicate change and defer extraction
3. Investigate further before deciding
```

## Tools to Use

**For detection:**
- Grep: Find similar patterns across files
- Read: Compare suspected duplicate implementations
- Glob: Find all files that might contain duplication

**For extraction:**
- Read: Understand full context of each duplicate
- Write: Create new shared utility module
- Edit: Update call sites to use extracted version

**For verification:**
- Bash: Run test suite after each step
- Read: Review test results for regressions

## Summary

This skill helps maintain code quality by:
1. Detecting duplication early
2. Recommending appropriate extraction strategies
3. Guiding safe refactoring with tests
4. Knowing when duplication is acceptable

**Core principle:** Always make duplication visible and intentional, never accidental.

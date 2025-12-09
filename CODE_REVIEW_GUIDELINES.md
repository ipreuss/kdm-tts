# Code Review Guidelines

This document captures lessons learned from code reviews and establishes a checklist for reviewing code changes effectively.

## Bug Prevention & Regression Testing

### Regression Tests for Fixed Bugs
When a bug is fixed, a regression test must be added to prevent it from reappearing.

**Example from this review:**
- The variable ordering bug in `Survivor.newSurvivor` (where `survivor` was referenced before declaration) was fixed but no test was added to catch similar ordering issues.
- **Action:** Add a test that would fail if the bug reappears, such as verifying the function doesn't throw errors during creation.

**Guideline:** For every bug fix, ask:
1. Is there a test that would have caught this bug?
2. If not, add one before considering the fix complete.
3. Document the bug scenario in the test name or comment.

## Breaking Changes & API Stability

### All Changes Must Maintain Test Suite Integrity
**CRITICAL RULE: Changes that cause test failures indicate breaking changes and require careful handling.**

**Example from recent review:**
- LayoutManager changed default font sizes (AddTitle: 20→24, AddContent: 15→16)
- This broke existing tests that expected the old defaults
- **Problem:** No indication whether changes were intentional design decisions or accidental side effects
- **Impact:** Existing code depending on these defaults will have different visual appearance

**Required Process for Breaking Changes:**

1. **Identify Breaking Changes Early**
   - Any test failures after implementation indicate potential breaking changes
   - Changes to default parameter values are always breaking changes
   - API signature changes require migration planning

2. **Document Intent and Impact**
   - **Are the changes intentional?** Clearly state design rationale
   - **What will break?** Identify all code that depends on changed behavior
   - **Migration path:** Provide clear upgrade instructions

3. **Version and Communicate Changes**
   - Consider semantic versioning for API changes
   - Update documentation to reflect new defaults/behavior
   - Add migration guide for consumers of changed APIs

4. **Fix or Update Tests Appropriately**
   - **If change is intentional:** Update test expectations to match new behavior
   - **If change is accidental:** Revert to maintain backward compatibility
   - **Never ignore failing tests** - they indicate real problems

### Detecting Unintentional Breaking Changes

**Red flags in code review:**
- Test failures with no explanation of intent
- Default value changes without documentation
- API modifications without version considerations
- Changes that affect existing behavior without clear rationale

**Questions to ask:**
1. **Why did this test fail?** Is it catching a real regression or outdated expectation?
2. **Was this change intentional?** Can the author explain the design decision?
3. **Who will be affected?** What code depends on the changed behavior?
4. **Is there a migration path?** How should consumers adapt to the change?

### Examples of Proper Breaking Change Handling

**❌ BAD: Unintentional breaking change**
```lua
-- Changed default without documentation
function AddTitle(params)
    fontSize = params.fontSize or 24  -- Was 20, now 24 - WHY?
end
```

**✅ GOOD: Intentional, documented breaking change**
```lua
-- BREAKING CHANGE v2.1: Increased default title fontSize from 20 to 24
-- for better accessibility and visual hierarchy.
-- Migration: Explicitly pass fontSize=20 to maintain old appearance.
function AddTitle(params)
    fontSize = params.fontSize or 24
end
```

## Test Quality as Code Quality Indicator

### Complex Tests Signal Design Problems
Tests that require extensive setup, mocking, or use of reflection (`debug.getupvalue`) indicate the production code needs refactoring toward SOLID principles.

**Example from this review:**
- Early `survivor_test.lua` used `debug.getupvalue` to access internal state, requiring complex navigation through upvalues.
- **Intermediate step:** Refactored to expose `Survivor.Test.stubUi()` for dependency injection, making tests simpler.
- **Deeper issue:** Even needing `Test.stubUi()` is a code smell indicating UI dependencies are tightly coupled to core logic.
- **Better solution:** Extract core creation logic (like `CreateSurvivor`) that naturally has no UI dependencies, eliminating the need for test-only stub functions.

**Guideline:** When reviewing tests, look for:
- Excessive use of mocking or stubbing (suggests tight coupling)
- Use of reflection or debug facilities (suggests hidden dependencies)
- Long setup sections (suggests the API is hard to use)
- Tests that break when implementation details change (suggests testing internals rather than behavior)
- Need for test-only helper functions (suggests missing abstractions or separation of concerns)

**Action:** Treat complex tests as a code smell prompting refactoring toward:
- Dependency injection as a temporary improvement
- **Better:** Identify and extract the abstraction that's trying to emerge (e.g., separating core logic from UI coordination)
- Smaller, focused functions with natural boundaries
- Clear separation of concerns where each layer can be tested independently
- Testable APIs that don't require special test-only entry points

### The Abstraction Principle
**If you need test-only APIs, there's likely a missing abstraction.** The internals you're exposing for testing probably represent a concept that deserves to be a first-class abstraction in your production code.

**Example:**
- Instead of: `Module.Test.stubDependencies()` to inject stubs
- Ask: What abstraction is hiding? Perhaps a `DependencyProvider` or separation of concerns between coordination and core logic
- Refactor: Extract that abstraction, making it naturally testable without special test hooks

## Code Clarity Over Convention

### Self-Explanatory Code First
Prefer code that explains itself over relying on conventions or documentation.

**Example from this review:**
- Initial proposal used underscore prefix `_TestStubUi` to indicate test-only functions.
- **Better solution:** Used `Survivor.Test.stubUi()` to make the intent explicit through structure rather than naming convention.

**Guideline:** When reviewing code:
1. **Ask:** Can a new team member understand this without reading documentation?
2. **Prefer:** Explicit structure (e.g., `Module.Test` table) over implicit conventions (e.g., underscore prefix)
3. **Question:** Is this convention documented? Is it consistently applied?
4. **Consider:** Could the same clarity be achieved through better naming, types, or structure?

### Examples of Self-Explanatory vs. Convention-Based

**Convention-based (requires knowledge):**
```lua
function Module._helperFunction()  -- underscore means internal/test-only (convention)
```

**Self-explanatory:**
```lua
Module.Test = {
    helperFunction = function()  -- clearly separated, intent explicit
    end
}
```

## Test Coverage for Changed Code

### All Changed Code Must Be Tested
Every line of changed production code should have corresponding test coverage. Cover the implementation details with unit tests and capture the user-visible intent with executable behavior/acceptance tests whenever a change affects functionality.

**Example from this review:**
- Initially, `Names.getName` parameter rename from `male` to `gender` changed production code.
- **Good:** Tests were added for the new API.
- **Gap:** No test verified that old callers were migrated.

**Guideline:** For each changed function:
1. Verify existing tests still pass
2. Add new tests for new behavior
3. Update tests for changed behavior
4. Check that all code paths in the change are exercised
5. Verify callers are updated if the signature changed

- [ ] Behavior/acceptance test documents user-facing changes or regression fixes

## Test Categories and Dependencies

### When External Dependencies Are Appropriate
Not all test dependencies are bad. Different test categories serve different purposes and have different requirements.

**Test Categories:**

1. **Unit Tests**
   - Test individual functions/modules in isolation
   - Should have NO external dependencies (files, network, etc.)
   - Fast execution (milliseconds)
   - Use mocking/stubbing sparingly, only for unavoidable dependencies
   - Should run anywhere without setup

2. **Integration Tests**
   - Test how components work together
   - May have controlled external dependencies (test databases, fixtures)
   - Slower execution (seconds)
   - Use test-specific data, not production data
   - Should be reproducible and isolated

3. **Validation Tests**
   - Verify consistency between code and external assets/data
   - **Intentionally depend on production data/files**
   - Purpose: Catch synchronization issues between code and assets
   - Examples: Verifying names in code match cards in save file, checking translations exist for all keys
   - Slower execution, may fail due to data changes (which is the point)

**Example from this review:**
- `savefile_decks_test.lua` is a validation test that intentionally reads `savefile_backup.json`
- Purpose: Ensure Names module and character card decks stay synchronized
- The external dependency is not a flaw—it's the entire point of the test
- If the dependency breaks, that indicates a real problem (data drift)

**Guideline:** When reviewing tests with external dependencies, ask:
1. **What category is this test?** Unit tests shouldn't have external dependencies. Validation tests should.
2. **Is the dependency intentional?** Validation tests legitimately need external data.
3. **Is it documented?** Tests with intentional external dependencies should explain why.
4. **Does it belong here?** Consider separating validation tests from unit tests as the suite grows.

### Documenting Test Dependencies

When a test intentionally depends on external files or data, document this clearly.

**Good practice:**
```lua
-- Validation test: Ensures Names module and character decks stay synchronized.
-- This test intentionally reads savefile_backup.json to catch data drift
-- between code definitions and game assets.

local SAVE_PATH = "savefile_backup.json"

local function readSave()
    local file, err = io.open(SAVE_PATH, "r")
    if not file then
        error(("Could not open %s: %s\nThis test requires the savefile to validate code/asset consistency."):format(SAVE_PATH, err))
    end
    -- ...
end
```

**Key elements:**
- Comment explaining the test category (validation)
- Clear statement that dependency is intentional
- Error messages that explain what's needed and why
- Purpose of the dependency (catching data drift)

### Balancing Test Isolation and Real-World Validation

**Unit tests** should be isolated and fast. If a unit test needs external data, that's a code smell.

**Validation tests** should use real data. Using test fixtures defeats the purpose—you'd be validating consistency between test data and test code, not production reality.

**The trade-off:**
- Validation tests may fail when data changes (expected behavior)
- They may be slower (acceptable for their purpose)
- They require setup (the external files must exist)
- But they catch real problems that unit tests can't

**Guideline:** Don't force validation tests to be unit tests. Accept the trade-offs for the value they provide.

## Consistency & Brittleness

### Constants Must Replace All Literals
When introducing constants or enums, ensure they're used consistently everywhere, not mixed with literals.

**Example from this review:**
- Introduced `Names.Gender.male` and `Names.Gender.female` constants
- **Good:** Changed from booleans to strings at the same time
- **Potential issue:** If any code still used string literals `"male"` directly instead of the constant

**Guideline:** When introducing constants:
1. Search codebase for all literal usages of the value
2. Replace all occurrences with the constant
3. Consider making the constant the single source of truth (e.g., by not exporting the raw value)
4. Add assertion/validation that only constant values are used

### Detecting Brittleness

**Common brittle patterns:**
- Magic numbers or strings scattered in code
- Duplicate constants defined in multiple places
- Hard-coded array indices or positions
- Assumptions about data structure that aren't validated
- Tests that depend on internal implementation details
- Code that uses reflection to access private state

**Guideline:** When reviewing, ask:
1. **Will this break if we:** Rename a function? Reorder parameters? Change internal structure?
2. **Are assumptions validated:** With assertions or type checks?
3. **Is coupling necessary:** Or can it be reduced through interfaces/abstractions?
4. **Are literals replaced:** With named constants?

### Polymorphism Over Conditionals

**CRITICAL RULE: Avoid type-based conditionals in favor of polymorphism.**

Type-based conditional logic violates the Open/Closed Principle and creates maintenance burdens.

**Anti-Pattern (❌ BAD):**
```lua
-- String-based type checking - violates polymorphism
if element.type == "title" then
    totalHeight = totalHeight + element.titleHeight
elseif element.type == "section" then
    totalHeight = totalHeight + element.sectionHeight
elseif element.type == "spacer" then
    totalHeight = totalHeight + element.spacerHeight
-- Adding new types requires modifying this function
end
```

**Strategy Pattern (✅ GOOD):**
```lua
-- Strategy objects handle their own behavior
local strategies = {
    title = TitleStrategy,
    section = SectionStrategy,
    spacer = SpacerStrategy,
}
totalHeight = totalHeight + strategies[element.type]:calculateHeight(element)
```

**Polymorphism (✅ BETTER):**
```lua
-- Each element knows how to calculate its own height
totalHeight = totalHeight + element:calculateHeight()
```

**Benefits of polymorphic approach:**
- **Extensible:** New element types don't require core modifications
- **Maintainable:** Each type encapsulates its own behavior
- **Testable:** Each strategy/type can be tested independently
- **Follows SOLID principles:** Open/Closed, Single Responsibility

**Guideline:** When reviewing, flag any code that:
1. Uses string-based type checking (`if type == "something"`)
2. Has long chains of `if/elseif` based on object types
3. Requires modification when adding new types
4. Concentrates type-specific logic in a single function

### Refactoring for Robustness

**Before (brittle):**
```lua
if gender == true then  -- Boolean literal
    -- ...
end
```

**After (robust):**
```lua
if gender == Names.Gender.male then  -- Named constant
    -- ...
end
```

### Test-Only Exports Code Smell

**CRITICAL: Functions exported by a module but only used in tests indicate a Single Responsibility Principle (SRP) violation.**

When a function is exported solely for testing purposes, this suggests the module is mixing abstraction levels:
1. The function operates at a different abstraction level than the module's primary responsibility
2. There's a missing module where this function would be naturally public
3. The current module has multiple responsibilities that should be separated

**The SRP Connection:**
A test-only export reveals that the module contains functionality at two levels:
- **High-level:** The module's primary purpose (e.g., UI management, state coordination)
- **Low-level:** Internal operations that tests need access to (e.g., deck manipulation, data transformation)

When tests need direct access to low-level operations, it indicates these operations deserve their own module where they would be naturally public.

**Detection Process:**
1. For each exported function in module's `return { ... }` statement
2. Search for usages outside the module itself
3. If the function is only used:
   - Internally within the module, AND
   - Externally only in test files or test harnesses
4. Flag as SRP violation / abstraction level mismatch

**Resolution Options:**

**Option A (Preferred): Extract to appropriate abstraction level**
- Identify the responsibility the function represents
- Create a new module at that abstraction level
- The function becomes naturally public in the new module
- Both production code and tests consume the new module

```lua
-- BEFORE: Strain.ttslua exports RemoveFightingArtFromArchive for tests
-- but only uses it internally via ReverseConsequences

-- AFTER: Extract to FightingArtsArchive.ttslua
-- FightingArtsArchive.ttslua
return {
    AddCard = FightingArtsArchive.AddCard,      -- Naturally public
    RemoveCard = FightingArtsArchive.RemoveCard, -- Naturally public
}

-- Strain.ttslua consumes it
local FightingArtsArchive = require("Kdm/FightingArtsArchive")
function Strain:ExecuteConsequences(milestone)
    FightingArtsArchive.AddCard(fightingArt)
end

-- TTSTests.ttslua also consumes it - no smell!
local FightingArtsArchive = require("Kdm/FightingArtsArchive")
FightingArtsArchive.RemoveCard(cardName)  -- Natural cleanup
```

**Option B (Last resort): Explicit test interface**
- Use only when extraction is impractical
- Use the `_test = { ... }` pattern (see Campaign.ttslua, Timeline.ttslua)
- Document why extraction was not feasible

```lua
return {
    -- Public API
    Init = Module.Init,
    DoThing = Module.DoThing,
    
    -- Test-only exports (explicit - document why extraction not feasible)
    _test = {
        InternalHelper = Module.InternalHelper,
    },
}
```

**Guideline:** When reviewing exports:
1. Check if each exported function is used in production code by external modules
2. If only used internally + tests, identify the SRP violation
3. Recommend extraction to appropriate abstraction level
4. Only accept `_test = { ... }` pattern when extraction is impractical

## Review Checklist

Use this checklist for every code review:

## Review Process

### Phase 1: Initial Assessment
- [ ] **MANDATORY: Review ALL modified files systematically** - Check git status and examine every modified file's changes, not just a subset
- [ ] **Assess change scope first** - Multiple modified files (especially core + tests) indicates major implementation work, not minor tweaks
- [ ] **Always get complete diff before drawing conclusions** - Use `git diff` for all files or individual file diffs to see full change scope
- [ ] **ALWAYS verify actual file content before reporting syntax errors** - Git diff output frequently contains formatting artifacts (like `[mend)`, `2m+`, color codes) that appear as syntax errors but aren't in the actual file  
- [ ] **View actual files first for any suspected issues** - Use `view` tool to check file content directly before making syntax error claims
- [ ] **Test execution confirms validity** - If tests pass, apparent "syntax errors" in diffs are likely artifacts
- [ ] Look for stray characters like "m", "2m+", ANSI color codes, or diff line markers that aren't real code
- [ ] When in doubt, always prioritize actual file content over diff appearance
- [ ] Run syntax checks or tests to confirm the file is valid before reporting syntax errors

### Phase 2: Functional Review

### TTS Test Review
When reviewing TTS tests (`TTSTests.ttslua`, `TTSTests/*.ttslua`), verify that tests exercise real code paths, not just data validation:

- [ ] **Entry Point:** Does the test call the real public API, not just test helpers?
- [ ] **Event Flow:** If the feature uses events, does the test trigger them naturally (via source action), not manually fire them?
- [ ] **Outcome Verification:** Does the test verify user-visible results (UI state, spawned objects), not just internal state?
- [ ] **Mutation Test:** Would breaking the feature's code cause this test to fail?

**Anti-pattern (data validation masquerading as integration test):**
```lua
-- ❌ Weak: Only validates data exists - never tests actual feature
local monster = Showdown.Test.MonsterByName("White Lion")
local level = findLevelByName(monster, "Level 1")
local rewards = level.showdown.resources
if rewards.basic == 4 and rewards.monster == 4 then
    log:Printf("TEST RESULT: PASSED")
end
-- Problem: Test passes even if button never appears because setup code is broken
```

**Proper integration test:**
```lua
-- ✅ Strong: Calls real entry point, events fire naturally, verifies user-visible outcome
Showdown.Setup("White Lion", "Level 1")  -- Real API, events fire naturally
Wait.condition(function()
    return ResourceRewards.IsButtonVisible()  -- User-visible outcome
end)
if ResourceRewards.IsButtonVisible() then
    log:Printf("TEST RESULT: PASSED")
end
```

**Why this matters:** Data validation tests give false confidence. They pass when data is correct but integration is broken. Real integration tests catch: event handlers not registered, module state not set before events, async timing issues, UI not updated after operations.

### Bug Prevention
- [ ] Are there regression tests for any bugs that were fixed?
- [ ] Do tests cover the bug scenario explicitly?

### Breaking Changes & API Stability
- [ ] Do all tests pass? If not, are failures explained and intentional?
- [ ] Are default parameter value changes documented with clear rationale?
- [ ] Do API changes include migration guidance for existing consumers?
- [ ] Are breaking changes properly versioned and communicated?
- [ ] Is there clear documentation of what behavior changed and why?

### Test Quality
- [ ] Are tests simple and focused?
- [ ] Is excessive mocking/stubbing a sign of coupling issues?
- [ ] Do tests use public APIs rather than reflection?
- [ ] Are test setups reasonable in size?
- [ ] Are tests categorized appropriately (unit/integration/validation)?
- [ ] Are intentional external dependencies documented with rationale?
- [ ] **Are any exported functions only used internally + tests?** (SRP violation - see Test-Only Exports section)

### Code Clarity
- [ ] Is the code self-explanatory without documentation?
- [ ] Are conventions explicit (structure) rather than implicit (naming)?
- [ ] Can a new developer understand the intent?

### Coverage
- [ ] Does every changed line have test coverage?
- [ ] Are all code paths tested?
- [ ] Are edge cases covered?
- [ ] Are callers of changed APIs tested?
- [ ] **For new test files:** Is the file registered in tests/run.lua?

### Value Extraction (Refactoring)
- [ ] **For value extraction refactors:** Did you verify extracted constants against their source file (not just tests)?
- [ ] **For coordinate/dimension values:** Do tests assert absolute values (e.g., `width = 1.06`), not just consistency?
- [ ] **Are source locations documented?** (e.g., "x1End = 6.705129 (from Rules.ttslua:95)")

### Cross-Module Integration Tests
- [ ] **Does new/changed code call functions from other modules?** If yes, verify:
- [ ] Integration test exists that exercises the real call path (A → B)
- [ ] The immediate dependency (B) is not stubbed — only deeper dependencies (C) may be mocked
- [ ] Test would fail if the called function were removed from B's exports

**Why this matters:** Client code accessing unexported fields/functions only fails at TTS runtime (5-10 minute debug cycles). Headless integration tests catch these in seconds. This is the Implementer's responsibility, not the Tester's.

### Data Integration Tests
- [ ] **Does feature integrate with expansion data?** If yes, verify:
- [ ] At least one test uses real expansion data via `require("Kdm/Expansion/...")`
- [ ] Tests would fail if expansion data had typos (e.g., "Elder Cat Tooth" vs "Elder Cat Teeth")
- [ ] Mock data is only used where appropriate (TTS objects, timing, etc.)
- [ ] **Mutation test:** Would a typo in Core.ttslua cause this test to fail?

**Why this matters:** Mock-data tests give false confidence. They pass when data is correct but integration is broken. Real-data tests catch: typos in expansion files, missing data fields, incorrect data wiring.

### Consistency
- [ ] Are new constants used everywhere (no remaining literals)?
- [ ] Are patterns applied consistently across the codebase?
- [ ] Are enums/constants the single source of truth?

### Brittleness
- [ ] Are magic values replaced with named constants?
- [ ] Are assumptions validated with assertions?
- [ ] Will code break if implementation details change?
- [ ] Are tests coupled to implementation or behavior?

### Guard Clause Overuse
- [ ] Are guard clauses used only for **realistic** cases, not defensive programming?
- [ ] Does each early return have a plausible scenario where it triggers?
- [ ] Are nil checks justified by actual nil-producing code paths?

**Anti-pattern:** Adding `if x == nil then return end` "just in case" when `x` can never be nil in practice. This clutters code and hides real bugs.

**Good guard clause:** Validates user input, external API responses, or optional parameters.
**Bad guard clause:** Checks internal state that the code structure already guarantees.

**Example:**
```lua
-- BAD: Defensive programming - caller always provides valid deck
function processDeck(deck)
    if deck == nil then return end  -- When would this happen?
    if deck.cards == nil then return end  -- Structure guarantees this
    ...
end

-- GOOD: Guard for realistic case
function processDeck(deck)
    if #deck.cards == 0 then return end  -- Empty deck is valid but nothing to do
    ...
end
```

### Polymorphism
- [ ] Are type-based conditionals avoided in favor of polymorphism?
- [ ] Does code use Strategy Pattern or object methods instead of string type checking?
- [ ] Can new types be added without modifying existing functions?
- [ ] Are `if/elseif` chains based on object types refactored to use polymorphism?

### Abstraction and Duplication Audit
**Every code review must include this analysis:**

#### Manual Calculations
- [ ] Are there pixel offsets, magic numbers, or coordinate calculations that should be in framework code (LayoutManager, PanelKit, UI helpers)?
- [ ] Are positioning calculations duplicated that could be handled by layout elements?
- [ ] Are there hardcoded dimensions that should come from shared constants?

#### Cross-Module Duplication
- [ ] Does similar code exist in other panels/dialogs in the codebase?
- [ ] Are there repeated patterns indicating a missing abstraction?
- [ ] Could shared logic be extracted into reusable components?

#### Unused Framework Features
- [ ] Are existing abstractions (e.g., `PanelKit.AutoSizedDialog`, `Specification:Render()`) being bypassed with manual implementations?
- [ ] Could existing helpers replace boilerplate code?
- [ ] Is the code reinventing functionality that already exists?

#### Hardcoded Values
- [ ] Are constants hardcoded that should come from shared sources (chrome dimensions, default heights, spacing)?
- [ ] Are configuration values duplicated between specification and render phases?
- [ ] Could magic numbers be replaced with named constants from the framework?

**Document findings** in a dedicated review section with priority labels (High/Medium/Low) and specific refactoring recommendations.

### SOLID Principles Analysis
**CRITICAL: Even when code appears clean, systematically check each SOLID principle for improvement opportunities**

#### Single Responsibility Principle (SRP)
- [ ] Does each class/module have exactly one reason to change?
- [ ] Are any functions doing multiple distinct things that could be separated?
- [ ] Could responsibilities be better distributed across different classes?
- [ ] Are there hidden responsibilities that should be extracted?
- [ ] **File size check:** Is the file over 500 lines? Over 1000 lines is a strong SRP smell.

**File Size Guidelines:**
| Lines | Assessment |
|-------|------------|
| < 300 | ✅ Good - easy to navigate and understand |
| 300-500 | ⚠️ Watch - may be approaching too many responsibilities |
| 500-1000 | 🔶 Review - likely mixing responsibilities, consider splitting |
| > 1000 | 🔴 Split - almost certainly violates SRP |

**Example from this codebase:** `TTSTests.ttslua` (1285 lines, 30+ functions across 7 unrelated test domains) should be split into `TTSTests/*.ttslua` with one file per test domain.

#### Open/Closed Principle (OCP)
- [ ] How easy would it be to extend this code without modifying it?
- [ ] Are there extension points where new behavior could be added?
- [ ] Could Strategy or Template Method patterns make this more extensible?
- [ ] Are configuration points externalized to support future requirements?

#### Liskov Substitution Principle (LSP)
- [ ] Can derived classes be used anywhere their base class is expected?
- [ ] Are abstractions properly designed without surprising behavior?
- [ ] Do subclasses strengthen rather than weaken base class contracts?
- [ ] Could polymorphic interfaces be improved for better substitutability?

#### Interface Segregation Principle (ISP)
- [ ] Are interfaces focused and cohesive rather than broad?
- [ ] Could large interfaces be broken into smaller, more specific ones?
- [ ] Do clients depend only on methods they actually use?
- [ ] Are there "fat" interfaces that force unnecessary dependencies?

#### Dependency Inversion Principle (DIP)
- [ ] Do high-level modules depend on abstractions rather than concrete implementations?
- [ ] Are dependencies injected rather than created internally?
- [ ] Could hard dependencies be inverted through interfaces?
- [ ] Are there opportunities to reduce coupling through abstraction?

### DRY Principle (Don't Repeat Yourself)
- [ ] Are there duplicate code blocks that could be extracted into functions?
- [ ] Are constants, configurations, or logic repeated across multiple files?
- [ ] Could common patterns be abstracted into reusable components?
- [ ] Are there copy-paste sections that should be unified?
- [ ] Is the same business logic implemented in multiple places?
- [ ] Could repeated parameter sets be consolidated into configuration objects?

### Phase 3: Proactive Design Review
**CRITICAL: Balance improvement opportunities against YAGNI (You Aren't Gonna Need It) and DTSTTCPW (Do The Simplest Thing That Could Possibly Work)**

#### SOLID Analysis for Improvement Identification
**Purpose: Identify opportunities, not mandate implementation**

**Single Responsibility:**
- [ ] What responsibilities could be separated if future changes demanded it?
- [ ] Are there obvious violations causing current maintenance pain?
- [ ] Note: In dynamic languages, some responsibility mixing is acceptable

**Open/Closed:**
- [ ] Where would future extensions be particularly painful with current design?
- [ ] Are there simple changes that would make extension easier without over-engineering?
- [ ] Avoid: Creating abstractions for hypothetical requirements

**Liskov Substitution:**
- [ ] Are there polymorphic relationships that could be cleaner?
- [ ] Only relevant where inheritance/polymorphism already exists

**Interface Segregation:**
- [ ] Are there obviously oversized objects causing cognitive overload?
- [ ] Note: Less critical in dynamically typed languages like Lua
- [ ] Focus on clarity over strict interface segregation

**Dependency Inversion:**
- [ ] Are there hard dependencies that currently cause testing or flexibility pain?
- [ ] Could simple dependency injection solve current problems?
- [ ] Avoid: Abstracting dependencies that work fine as concrete implementations

#### Pragmatic Design Assessment
- [ ] **Current Pain Points:** What's actually hard to maintain, test, or modify now?
- [ ] **Obvious Extension Seams:** Where would likely future changes happen?
- [ ] **Over-Engineering Risks:** What abstractions would be premature?
- [ ] **YAGNI Check:** Are we solving problems we don't actually have?

#### Appropriate Scope for Changes
- [ ] **Fix Now:** Obvious SOLID violations causing current pain
- [ ] **Note for Later:** Potential improvement areas when requirements emerge
- [ ] **Explicitly Avoid:** Over-abstraction for hypothetical futures
- [ ] **Sweet Spot:** Simple changes that improve current code without predicting unknown futures

## Boy Scout Rule

**Always leave the code a bit better than you found it.**

When making changes, look for small, low-risk improvements that can be included alongside your primary work:

### Candidate Improvements
- Extract a pure function that's buried in a large function
- Add dependency injection to a function you're already modifying
- Split a file that's grown too large if you're already changing it
- Remove dead code you encounter
- Clarify confusing variable names in code you're touching

### Scope Guidelines
- **Do:** Small refactors in files you're already modifying
- **Do:** Improvements that make your primary change cleaner
- **Don't:** Large refactors unrelated to your current task
- **Don't:** Changes that require extensive new test coverage
- **Don't:** Refactors in files you're not otherwise touching

### Selecting Improvements
When a review identifies future refactoring opportunities, prioritize:
1. **Lowest risk first:** Pure function extraction, dead code removal
2. **Highest test value:** Changes that eliminate `debug.getupvalue` or reduce stub count
3. **Already touching:** Only refactor code in files you're modifying anyway

## Process Integration

These guidelines should be applied at multiple stages:

1. **During development:** Use as a checklist before submitting code
2. **During code review:** Verify each guideline is met
3. **During refactoring:** Identify and fix violations proactively
4. **When onboarding:** Teach these principles to new team members

## Continuous Improvement

This document should evolve based on lessons learned from future code reviews. When you discover a pattern or issue not covered here, add it to maintain a living reference of best practices.

### Recent Updates

**2025-12-09: Added Value Extraction Checklist and Test Registration Check**
- Added "Value Extraction (Refactoring)" section to review checklist
- Reviewer must verify extracted constants match source file
- Coordinate/dimension values require absolute-value tests (not just consistency)
- Source locations should be documented in code
- Added test file registration check: new test files must be in tests/run.lua
- Addresses root causes from kdm-w1k.4 retrospective (button width bug, unregistered tests)

**2025-12-09: Added Data Integration Tests Checklist**
- Added checklist for features integrating with expansion data
- Tests must use real expansion data, not mocks, for data integration features
- Added "mutation test" question: Would a typo in Core.ttslua fail this test?
- Distinguishes when mock data is appropriate vs not appropriate
- Addresses root cause from kdm-w1k.2 retrospective (mock-data tests passed but didn't verify real integration)

**2025-12-07: Added Cross-Module Integration Test Review**
- Added checklist for verifying cross-module integration tests exist
- When code calls another module, integration test must exercise real call path
- Immediate dependency must not be stubbed (only deeper dependencies may be mocked)
- Test must fail if called function removed from exports
- Implementer responsibility, not Tester's

**2025-12-07: Added TTS Test Review Guidelines**
- Added checklist for reviewing TTS integration tests
- Tests must call real public APIs, not just test helpers
- Tests must let events fire naturally, not manually fire them
- Tests must verify user-visible outcomes (UI state, spawned objects)
- Tests must fail when the feature's code is broken (mutation test)
- Added anti-pattern example showing data validation masquerading as integration test
- Added proper integration test example

**2025-12-07: Added Guard Clause Overuse Check**
- Guard clauses should only be used for realistic cases, not defensive programming
- Added checklist items and examples distinguishing good vs bad guard clauses
- Anti-pattern: nil checks for values that can never be nil

**2025-12-06: Added File Size Guidelines for SRP**
- Added concrete line count thresholds for identifying SRP violations
- Files over 1000 lines are almost certainly violating SRP
- Added checklist item for file size review
- Documented `TTSTests.ttslua` as a codebase example requiring refactoring

**2025-11-27: Added Abstraction and Duplication Audit**
- Added mandatory analysis section for every code review
- Requires checking for manual calculations that belong in framework code
- Requires cross-module comparison to identify repeated patterns
- Requires verification that existing framework features are being used
- Requires flagging hardcoded values that should come from shared sources
- Documents findings with priority labels and refactoring recommendations

**2025-11-20: Added Change Scope Assessment Requirements**
- Added mandatory systematic review of ALL modified files after reviewer missed major implementation
- Enhanced diff inspection to require complete change scope assessment before conclusions
- Emphasized that multiple modified files (core + tests) indicates major work requiring thorough review
- Added requirement to get complete diff view before making any review determinations

**2025-11-20: Strengthened Diff Inspection Requirements**
- Enhanced diff inspection checklist with stronger language requiring actual file verification
- Added "ALWAYS verify actual file content before reporting syntax errors" as mandatory step
- Emphasized that passing tests indicate apparent syntax errors are likely diff artifacts
- Added examples of common diff artifacts (`[mend)`, ANSI codes) that masquerade as syntax errors

**2025-11-25: Added DRY Principle to Review Checklist**
- Added dedicated DRY (Don't Repeat Yourself) principle section to systematic review process
- Included checks for duplicate code blocks, repeated constants, common patterns, and copy-paste sections
- Emphasized consolidation of repeated business logic and parameter sets
- Filled significant gap in fundamental code review principles

**2025-11-24: Added Balanced Proactive SOLID Analysis**
- Added SOLID principles checklist balanced against YAGNI and DTSTTCPW principles
- Established 3-phase review process emphasizing pragmatic improvement identification over mandatory implementation
- Distinguished between "fix now" violations vs "note for later" opportunities
- Emphasized finding current pain points and obvious extension seams without over-engineering
- Added guidance on avoiding premature abstraction while identifying genuine improvement opportunities
- Noted reduced importance of Interface Segregation in dynamically typed languages like Lua

**2025-11-24: Added Breaking Changes & API Stability Guidelines**
- Added critical section on handling breaking changes and maintaining test suite integrity
- Established requirements for documenting intentional vs accidental API changes
- Added guidelines for version management, migration paths, and impact assessment
- Emphasized that test failures indicate breaking changes requiring careful handling
- Updated review checklist to catch undocumented breaking changes

**2025-11-24: Added Polymorphism Over Conditionals Guideline**
- Added critical design rule: Avoid type-based conditionals in favor of polymorphism
- Established Strategy Pattern as preferred approach for type-specific behavior
- Added anti-pattern examples showing string-based type checking violations
- Emphasized Open/Closed Principle compliance for extensible systems
- Updated review checklist to detect and prevent type-based conditional anti-patterns

**2025-11-18: Added Diff Inspection to Review Checklist**
- Added section on verifying actual file content vs. diff artifacts
- Git diff output can contain formatting artifacts (like "m", "2m+") that appear as syntax errors
- Emphasized viewing actual files and running syntax checks before reporting errors

**2025-11-18: Added Test Categories and Dependencies section**
- Clarified when external test dependencies are appropriate (validation tests)
- Distinguished between unit, integration, and validation test categories
- Added guidance on documenting intentional test dependencies
- Emphasized that validation tests legitimately need production data to catch real drift issues

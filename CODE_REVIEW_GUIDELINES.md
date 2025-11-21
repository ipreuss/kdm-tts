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

## Review Checklist

Use this checklist for every code review:

### Diff Inspection & Scope Assessment
- [ ] **MANDATORY: Review ALL modified files systematically** - Check git status and examine every modified file's changes, not just a subset
- [ ] **Assess change scope first** - Multiple modified files (especially core + tests) indicates major implementation work, not minor tweaks
- [ ] **Always get complete diff before drawing conclusions** - Use `git diff` for all files or individual file diffs to see full change scope
- [ ] **ALWAYS verify actual file content before reporting syntax errors** - Git diff output frequently contains formatting artifacts (like `[mend)`, `2m+`, color codes) that appear as syntax errors but aren't in the actual file  
- [ ] **View actual files first for any suspected issues** - Use `view` tool to check file content directly before making syntax error claims
- [ ] **Test execution confirms validity** - If tests pass, apparent "syntax errors" in diffs are likely artifacts
- [ ] Look for stray characters like "m", "2m+", ANSI color codes, or diff line markers that aren't real code
- [ ] When in doubt, always prioritize actual file content over diff appearance
- [ ] Run syntax checks or tests to confirm the file is valid before reporting syntax errors

### Bug Prevention
- [ ] Are there regression tests for any bugs that were fixed?
- [ ] Do tests cover the bug scenario explicitly?

### Test Quality
- [ ] Are tests simple and focused?
- [ ] Is excessive mocking/stubbing a sign of coupling issues?
- [ ] Do tests use public APIs rather than reflection?
- [ ] Are test setups reasonable in size?
- [ ] Are tests categorized appropriately (unit/integration/validation)?
- [ ] Are intentional external dependencies documented with rationale?

### Code Clarity
- [ ] Is the code self-explanatory without documentation?
- [ ] Are conventions explicit (structure) rather than implicit (naming)?
- [ ] Can a new developer understand the intent?

### Coverage
- [ ] Does every changed line have test coverage?
- [ ] Are all code paths tested?
- [ ] Are edge cases covered?
- [ ] Are callers of changed APIs tested?

### Consistency
- [ ] Are new constants used everywhere (no remaining literals)?
- [ ] Are patterns applied consistently across the codebase?
- [ ] Are enums/constants the single source of truth?

### Brittleness
- [ ] Are magic values replaced with named constants?
- [ ] Are assumptions validated with assertions?
- [ ] Will code break if implementation details change?
- [ ] Are tests coupled to implementation or behavior?

## Process Integration

These guidelines should be applied at multiple stages:

1. **During development:** Use as a checklist before submitting code
2. **During code review:** Verify each guideline is met
3. **During refactoring:** Identify and fix violations proactively
4. **When onboarding:** Teach these principles to new team members

## Continuous Improvement

This document should evolve based on lessons learned from future code reviews. When you discover a pattern or issue not covered here, add it to maintain a living reference of best practices.

### Recent Updates

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

**2025-11-18: Added Diff Inspection to Review Checklist**
- Added section on verifying actual file content vs. diff artifacts
- Git diff output can contain formatting artifacts (like "m", "2m+") that appear as syntax errors
- Emphasized viewing actual files and running syntax checks before reporting errors

**2025-11-18: Added Test Categories and Dependencies section**
- Clarified when external test dependencies are appropriate (validation tests)
- Distinguished between unit, integration, and validation test categories
- Added guidance on documenting intentional test dependencies
- Emphasized that validation tests legitimately need production data to catch real drift issues

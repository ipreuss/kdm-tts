---------------------------------------------------------------------------------------------------
-- Weapon Pairing Acceptance Tests
--
-- Tests for weapon pairing system (kdm-rbl.3) specification.
--
-- These tests verify the pairing LOGIC independently of BattleUi infrastructure.
-- The logic tested here matches CalcWeapons behavior in BattleUi.ttslua:
--   - Same-name pairing: weaponCounts[name] > 1
--   - Cross-name pairing: pairingCounts[pairingGroup] > 1
--   - Separate entries for different names
--   - Merged entries for same names
--
-- SCOPE:
--   - Cross-name pairing via pairingGroup (Aya's Spear + Aya's Sword)
--   - Same-name pairing (Bone Hatchet x2)
--   - Separate display entries for cross-name pairs
--   - Merged display for same-name pairs
---------------------------------------------------------------------------------------------------

local Test = require("tests.framework")

---------------------------------------------------------------------------------------------------
-- Pure weapon calculation logic (mirrors BattleUi.CalcWeapons pairing behavior)
---------------------------------------------------------------------------------------------------

-- Calculate weapon results with pairing logic
-- This is a pure function that captures the weapon pairing specification
local function calcWeaponResults(weaponsAndModifiers)
    -- Phase 1: Collect weapons and count for pairing
    local weaponCounts = {}     -- counts by canonicalName (for same-name pairing)
    local pairingCounts = {}    -- counts by pairingGroup (for cross-name pairing)
    local uniqueWeapons = {}

    for _, wm in ipairs(weaponsAndModifiers) do
        local weapon = wm.weapon
        local name = weapon.canonicalName

        -- Count occurrences
        weaponCounts[name] = (weaponCounts[name] or 0) + 1

        -- Only include first occurrence of each weapon name
        if weaponCounts[name] == 1 then
            table.insert(uniqueWeapons, wm)
        end

        -- Track pairingGroup for cross-name pairs
        if weapon.stats.pairingGroup then
            pairingCounts[weapon.stats.pairingGroup] = (pairingCounts[weapon.stats.pairingGroup] or 0) + 1
        end
    end

    -- Sort alphabetically by name
    table.sort(uniqueWeapons, function(wm1, wm2)
        return wm1.weapon.canonicalName < wm2.weapon.canonicalName
    end)

    -- Phase 2: Calculate results with pairing speed bonus
    local results = {}
    for _, wm in ipairs(uniqueWeapons) do
        local weapon = wm.weapon
        local modifiers = wm.modifiers
        local baseSpeed = weapon.stats.speed + (modifiers.speed or 0)
        local speed = math.max(1, baseSpeed)

        -- Apply pairing speed bonus
        if weapon.stats.paired then
            -- Check same-name pairing first
            local isPaired = weaponCounts[weapon.canonicalName] > 1
            -- Then check cross-name pairing via pairingGroup
            if not isPaired and weapon.stats.pairingGroup then
                isPaired = (pairingCounts[weapon.stats.pairingGroup] or 0) > 1
            end
            if isPaired then
                speed = speed + weapon.stats.speed
            end
        end

        table.insert(results, {
            name = weapon.canonicalName,
            speed = speed,
        })
    end

    return results
end

---------------------------------------------------------------------------------------------------
-- Test Helpers
---------------------------------------------------------------------------------------------------

-- Create a weapon object with stats
local function createWeapon(name, stats)
    return {
        canonicalName = name,
        stats = stats,
    }
end

-- Create a weapon-and-modifiers entry
local function wm(weapon, modifiers)
    return {
        weapon = weapon,
        modifiers = modifiers or {},
    }
end

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Cross-name pairing (Aya's Spear + Sword)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Aya's Spear and Sword are paired when both equipped", function(t)
    -- Aya's weapons: speed 2, paired, pairingGroup = "Aya's weapons"
    local ayasSpear = createWeapon("Aya's Spear", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })
    local ayasSword = createWeapon("Aya's Sword", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })

    local weaponsAndModifiers = {
        wm(ayasSpear),
        wm(ayasSword),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    -- Find results
    local spearResult, swordResult
    for _, result in ipairs(results) do
        if result.name == "Aya's Spear" then spearResult = result end
        if result.name == "Aya's Sword" then swordResult = result end
    end

    t:assertNotNil(spearResult, "Aya's Spear should be in results")
    t:assertNotNil(swordResult, "Aya's Sword should be in results")
    t:assertEqual(4, spearResult.speed, "Aya's Spear speed should be doubled (2 -> 4)")
    t:assertEqual(4, swordResult.speed, "Aya's Sword speed should be doubled (2 -> 4)")
end)

Test.test("ACCEPTANCE: Aya's weapons are NOT paired when only one equipped", function(t)
    -- Only Aya's Spear equipped
    local ayasSpear = createWeapon("Aya's Spear", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })

    local weaponsAndModifiers = {
        wm(ayasSpear),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    t:assertEqual(1, #results, "Should have 1 weapon result")
    t:assertEqual("Aya's Spear", results[1].name)
    t:assertEqual(2, results[1].speed, "Aya's Spear speed should NOT be doubled (only one equipped)")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Separate display for cross-name pairs
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Aya's weapons display as 2 separate entries", function(t)
    local ayasSpear = createWeapon("Aya's Spear", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })
    local ayasSword = createWeapon("Aya's Sword", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })

    local weaponsAndModifiers = {
        wm(ayasSpear),
        wm(ayasSword),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    -- Should have 2 separate entries (not merged)
    t:assertEqual(2, #results, "Should display 2 separate weapon entries")

    -- Verify both names are present
    local names = {}
    for _, result in ipairs(results) do
        names[result.name] = true
    end
    t:assertTrue(names["Aya's Spear"], "Should have Aya's Spear entry")
    t:assertTrue(names["Aya's Sword"], "Should have Aya's Sword entry")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Same-name pairing (Bone Hatchet)
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Bone Hatchet x2 is paired (merged into 1 entry)", function(t)
    -- Two Bone Hatchets: speed 1, paired, NO pairingGroup (same-name pairing)
    local boneHatchet1 = createWeapon("Bone Hatchet", {
        speed = 1, accuracy = 6, strength = 3,
        paired = true
    })
    local boneHatchet2 = createWeapon("Bone Hatchet", {
        speed = 1, accuracy = 6, strength = 3,
        paired = true
    })

    local weaponsAndModifiers = {
        wm(boneHatchet1),
        wm(boneHatchet2),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    -- Should merge into 1 entry (same name)
    t:assertEqual(1, #results, "Should display 1 merged entry for same-name paired weapons")
    t:assertEqual("Bone Hatchet", results[1].name)
    t:assertEqual(2, results[1].speed, "Bone Hatchet speed should be doubled (1 -> 2)")
end)

Test.test("ACCEPTANCE: Single Bone Hatchet is NOT paired", function(t)
    -- Only one Bone Hatchet
    local boneHatchet = createWeapon("Bone Hatchet", {
        speed = 1, accuracy = 6, strength = 3,
        paired = true
    })

    local weaponsAndModifiers = {
        wm(boneHatchet),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    t:assertEqual(1, #results, "Should have 1 weapon result")
    t:assertEqual("Bone Hatchet", results[1].name)
    t:assertEqual(1, results[1].speed, "Bone Hatchet speed should NOT be doubled (only one)")
end)

---------------------------------------------------------------------------------------------------
-- ACCEPTANCE TESTS: Edge cases
---------------------------------------------------------------------------------------------------

Test.test("ACCEPTANCE: Mixed weapons - only matching pairs get speed bonus", function(t)
    -- Mix of Aya's weapons (paired) and a regular weapon
    local ayasSpear = createWeapon("Aya's Spear", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })
    local ayasSword = createWeapon("Aya's Sword", {
        speed = 2, accuracy = 7, strength = 3,
        paired = true, pairingGroup = "Aya's weapons"
    })
    local regularSword = createWeapon("Founding Stone", {
        speed = 2, accuracy = 7, strength = 1
    })

    local weaponsAndModifiers = {
        wm(ayasSpear),
        wm(ayasSword),
        wm(regularSword),
    }

    local results = calcWeaponResults(weaponsAndModifiers)

    t:assertEqual(3, #results, "Should have 3 weapon entries")

    -- Find each result
    local spearResult, swordResult, stoneResult
    for _, result in ipairs(results) do
        if result.name == "Aya's Spear" then spearResult = result end
        if result.name == "Aya's Sword" then swordResult = result end
        if result.name == "Founding Stone" then stoneResult = result end
    end

    -- Aya's weapons are paired
    t:assertEqual(4, spearResult.speed, "Aya's Spear should be paired (speed 4)")
    t:assertEqual(4, swordResult.speed, "Aya's Sword should be paired (speed 4)")
    -- Founding Stone is not paired
    t:assertEqual(2, stoneResult.speed, "Founding Stone should NOT be paired (speed 2)")
end)

package.path = "./?.lua;./?/init.lua;" .. package.path

local bootstrap = require("tests.support.bootstrap")
bootstrap.setup()

-- Enable Check test mode for headless testing (allows tables instead of TTS userdata)
local Check = require("Kdm/Util/Check")
Check.Test_SetTestMode(true)

local Test = require("tests.framework")

local testFiles = {
    "tests.array_test",
    "tests.names_test",
    "tests.survivor_test",
    "tests.savefile_decks_test",
    "tests.timeline_search_test",
    "tests.campaign_test",
    "tests.archive_test",
    "tests.campaign_migrations_test",
    "tests.panelkit_test",
    "tests.timeline_dialog_test",
    "tests.hunt_showhide_test",
    "tests.showdown_showhide_test",
    "tests.timeline_showhide_test",
    "tests.timeline_schedule_test",
    "tests.strain_test",
    "tests.strain_archive_integration_test",
    "tests.vermin_archive_test",
    "tests.basic_resources_archive_test",
    "tests.layoutmanager_test",
    "tests.consequence_applicator_test",
    "tests.strain_spawn_rewards_test",
    "tests.acceptance.walking_skeleton_test",
    "tests.acceptance.strain_acceptance_test",
}

for _, file in ipairs(testFiles) do
    require(file)
end

local success = Test.run()

-- Disable test mode and verify cleanup
Check.Test_SetTestMode(false)
assert(not Check.Test_IsTestMode(), "Check test mode was not properly disabled")

if not success then
    os.exit(1)
end

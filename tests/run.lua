package.path = "./?.lua;./?/init.lua;" .. package.path

local bootstrap = require("tests.support.bootstrap")
bootstrap.setup()

local Test = require("tests.framework")

local testFiles = {
    "tests.array_test",
    "tests.names_test",
    "tests.survivor_test",
    "tests.savefile_decks_test",
}

for _, file in ipairs(testFiles) do
    require(file)
end

local success = Test.run()
if not success then
    os.exit(1)
end

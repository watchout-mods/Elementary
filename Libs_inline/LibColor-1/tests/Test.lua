-- Put here the path to the "TestSuite" folder. Relative to this file, or
-- absolute. Prefer relative though.
PathToSuite = "TestSuite/"

-- Put here includes you need. Most likely this will be the code you want to test
-- they will be loaded before the tests but after WoWUnit and LibStub
Files = {
	"../LibColor-1.lua",
}

-- Put here paths to the files containing the test cases. Paths are relative to
-- this file, but may be absolute too. Prefer relative though.
-- Test cases will be run in the order they are registered. That means in the
-- order they are listed here!
Tests = {
	"TestDoesCompile.lua",
	"TestConversion.lua",
}

-- Better not change below here, this is required.
dofile(PathToSuite .. "Include_Commandline.lua");

local WoWUnit = LibStub("WoWUnit-1.0");
local Test = WoWUnit:NewSuite("Syntax-check");
local lib;


-- samples taken from https://color.adobe.com/create/color-wheel/
-- "HSB" equals "HSV" here
Testsamples = {
	{ -- color
		CMYK = {0, 66, 32, 61},
		RGB = {100, 34, 69},
		LAB = {25, 33, -6},
		HSV = {329, 66, 39}, -- (H: 0 ... 359)
	}
}


Test.RequiresModules.Wowcompat = true;

--[[ +++++++++++++++++++++++++ Initializing stuff +++++++++++++++++++++++++ ]]--
function Test:SetUp(key, testname)
	lib = LibStub("Veil-1");
end

function Test:TearDown(key, testname)
	lib = nil;
end

--[[ ++++++++++++++++++++++++++ The actual tests ++++++++++++++++++++++++++ ]]--
function Test:Test1()
end


local WoWUnit = LibStub("WoWUnit-1.0");
local Test = WoWUnit:NewSuite("Syntax-check");
local lib;



Test.RequiresModules.Wowcompat = true;

--[[ +++++++++++++++++++++++++ Initializing stuff +++++++++++++++++++++++++ ]]--
function Test:SetUp(key, testname)
	lib = LibStub("LibColor-1");
end

function Test:TearDown(key, testname)
	lib = nil;
end


--[[ ++++++++++++++++++++++++++ The actual tests ++++++++++++++++++++++++++ ]]--
function Test:TestCreate()
	lib(function(...) end);
end


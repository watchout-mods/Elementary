---
-- This Library is meant to help spreading the load when an addon is using - or
-- rather has to use the OnUpdate script element for multiple purposes in a
-- single cycle and waiting for a time, then again do a big load of stuff... etc.
-- 
-- Using this library should make it easier to even out the cpu-usage of almost
-- every addon that has something to show in the ui that does not only sit there
-- unmoving for all eternity.
-- 
-- ** DO NOT EMBED THIS LIBRARY IF YOU ONLY DO A SINGLE TASK ON ONUPDATE. SEE **
--    THE FUNCTION  GetGlobalUpdater(precision)  FOR THIS PURPOSE.  EMBEDDING 
--    WILL CREATE
-- A PRIVATE UPDATER THAT CAN BE CONFIGURED FREELY BUT WILL NOT BE OF ANY USE
-- WHEN ONLY CALLING A SINGLE JOB.**
-- @class file
-- @name LibOnUpdate.lua


local MAJOR, MINOR = "LibOnUpdate-1", 2;
local OldLib = LibStub(MAJOR, true);
local Lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR);
if not Lib then return end -- No Upgrade needed.

local META_WEAK_K = {__mode = "k"};

local Prototype = {};
local PrototypeSettings = {};
local ManageFPS;
local GenericUpdaters = setmetatable({}, {
	__index = function(self, k)
		self[k] = {};
		return Lib:CreateUpdater(k, self[k]);
	end,
});
local UpdatersSources = setmetatable({}, {
	__mode = "k",
	__index = function(t, k)
		t[k] = setmetatable({}, META_WEAK_K);
		return t[k];
	end
});

--[[ TODO for 1.1
Global updaters. Make specialized manager function that can increase time
between updates.
]]
Lib.Intervals = {}
---
-- Constant for approximately real-time execution (~20 fps)
Lib.Intervals.REALTIME = .1; -- values are approximate max time between updates
---
-- Constant for sub-realtime execution (~2 fps)
Lib.Intervals.SHORT  = .5;
Lib.Intervals.MEDIUM =  2;
Lib.Intervals.LONG   = 16;
Lib.Intervals.AGES   = 64;
Lib.LIBONUPDATE_REALTIME = "REALTIME";
Lib.LIBONUPDATE_SHORT = "SHORT";
Lib.LIBONUPDATE_LONG = "LONG";
Lib.LIBONUPDATE_VERYLONG = "AGES";

-- config values
local Grace = 1 - .4;
local SecondsPerManageFPS = 5;

--[[ TODO for 1.1-2.0, do not add Updaters and UpdaterFrames in the mixins
local Updaters = {};
local UpdaterFrames = {};
Lib.Updaters = Updaters;
Lib.UpdaterFrames = UpdaterFrames;
]]

local min = min;
local floor = floor;
local warn = function(...)
	geterrorhandler()(strjoin(" ", tostringall(...)), 2);
end
local die = function(...)
	error(strjoin(" ", tostringall(...)), 2);
end
local empty = function()
	warn("This function would not be called if everything was peachy.");
end;


---
-- <b>NYF</b> Returns a generic updater
-- @name Lib:GetUpdater
-- @param interval, possible values are Lib.{REALTIME|SHORT|MEDIUM|LONG|AGES}
-- Generic updaters feature a special manager method that makes it possible to
-- increase the time between updates to achieve a slower execution when the
-- updater is not used to minimal capacity.
-- That method aims at +/- 10% accuracy
function Lib:GetUpdater(interval)
	interval = interval or "SHORT";
	if not Lib.Intervals[interval] then
		die("GetUpdater: Argument 1 (interval) invalid");
	end
	if GenericUpdaters[interval] then
		return GenericUpdaters[interval];
	else
		GenericUpdaters[interval] = Lib:Create(Lib.Intervals[interval]);
		return GenericUpdaters[interval];
	end
end

---
-- <b>NYF</b> Registers a function for a generic updater
-- @name Lib:GetUpdater
-- @param interval, possible values are Lib.{REALTIME|SHORT|MEDIUM|LONG|AGES}
-- Generic updaters feature a special manager method that makes it possible to
-- increase the time between updates to achieve a slower execution when the
-- updater is not used to minimal capacity.
function Lib:RegisterUpdater(interval, ...)
	if not Lib.Intervals[interval] then
		die("RegisterUpdater: Argument 1 (interval) invalid:", interval);
	end
	local fire = Lib:GetUpdater(interval).RegisterUpdater(self, ...);
	UpdatersSources[self][fire] = true; -- the 'self' here is deliberate
	return fire;
end

---
-- Removes all updaters registered by "this" object.
-- @param self
-- 
-- if self is a different object than this library, this method will remove only
-- updaters registered by the object in question. Basically this feature only
-- works on embedded libraries, or when you pass a custom self argument to
-- RegisterUpdater and RemoveAllUpdaters.
-- 
-- if self is this library, it will throw a warning through the current error
-- handler and do nothing.
function Lib:RemoveAllUpdaters()
	if type(self) ~= "table" then
		die("RemoveAllUpdaters: self must be a table");
	end
	if self == Lib then
		--@debug@
		warn("This method should only be called on an embedded library.");
		--@end-debug@
		return;
	end
	
	for k,v in pairs(UpdatersSources[self]) do
		Lib.RemoveUpdater(self, k);
		UpdatersSources[self][k] = nil;
	end
end

---
-- Removes all updaters registered by "this" object.
-- @param self
-- @param fire the fire method once returned from RegisterUpdater
-- 
-- if self is a different object than this library, this method will remove only
-- updaters registered by the object in question. Basically this feature only
-- works on embedded libraries, or when you pass a custom self argument to
-- RegisterUpdater and RemoveAllUpdaters.
-- 
-- if self is this library, it will throw a warning through the current error
-- handler and do nothing.
function Lib:RemoveUpdater(fire)
	if type(self) ~= "table" then
		die("RemoveUpdater: self must be a table");
	end
	if self == Lib then
		--@debug@
		warn("This method should only be called on an embedded library.");
		--@end-debug@
		return;
	end
	if not UpdatersSources[self][fire] then
		--@debug@
		warn("The Updater was not found for the given namespace (self).");
		--@end-debug@
		return;
	end
	
	for k,v in pairs(GenericUpdaters) do
		v:UnregisterUpdater(fire);
	end
end

function Lib:CreateUpdater(interval, target)
	
end


function Lib:Create(interval, target)
	target = target or {};
	prefix = tostring(prefix or "");
	suffix = tostring(suffix or "");
	
	-- Closure variables
	local UpdaterFrame;
	local Updaters = {};
	local UpdatersCount = 1;
	local UpdatesPerSecond = 1/(interval or 1);
	local Step = 1;
	local OldStep = 1; -- debug variable - see ManageFPS
	local LimitManageFPS = 0; -- Not clean. Use additional timer to limit this.
	local UpdatesPerManageFPS = floor(UpdatesPerSecond*SecondsPerManageFPS);
	
	-- Insert management function / update an old one
	Updaters[1] = function()
		pcall(target.ManageFPS, target);
	end;
	
	-- create or re-use the UpdaterFrame
	local function CreateUpdaterFrame()
		if not UpdaterFrame then
			UpdaterFrame = CreateFrame("frame");
			UpdaterFrame:Hide(); -- hide so it won't kick off before we're done w setup
			UpdaterFrame:EnableMouse(false); -- make sure this is not clickable

			local pos = 1;
			UpdaterFrame:SetScript("OnUpdate", function(self, elapsed)
				-- Having UpdatersCount in min(...) effectively prevents calling the
				-- empty() functions.
				for i=pos, min(UpdatersCount, pos+Step-1), 1 do
					Updaters[i](elapsed);
				end
				
				pos = pos+Step;
				if pos > #Updaters then
					pos = 1;
				end
			end);
		end
		return UpdaterFrame;
	end

	---
	-- Register a method or function that is called when this updater is active
	-- @name :RegisterUpdater(func|"methodname"[, arg])
	-- @param self self is used in this function solely to define a namespace
	--        for callbacks, see below for details.
	-- @param func string or function.
	-- @param arg optional and of variable type
	-- @return handle. Due to the way how this works this is of type FUNCTION.
	--        In most cases you <b>DO NOT</b> want to call this function.
	--
	-- Call type RegisterUpdater(self, func[, arg]) results in:
	--   func([arg,] elapsed)
	-- 
	-- Call type RegisterUpdater(self, "string"[, arg]) results in:
	--   * if self is not a table or does not have a key entry with a value that
	--     is a function, an error will be generated.
	--   self["string"]([arg,] elapsed)
	function target:RegisterUpdater(func, arg)
		local fire;
		-- ("methodname"[, arg]) style
		if type(func) == "string" then -- whether self[func] is actually valid
			func = self[func];         -- is checked below
			arg = arg or self;
		end
		if type(func) ~= "function" then
			print(MAJOR..":", "self:", self, "self[func]", self[func]);
			print(MAJOR..":", "func:", func_t, func, "arg:", type(arg), arg);
			die("RegisterUpdater: Illegal type for arg1 or arg2.");
		end
		
		if arg ~= nil then
			fire = function(...)
				local success, msg = pcall(func, arg, ...);
				if not success then geterrorhandler()(msg); end
			end
		else
			fire = function(...)
				local success, msg = pcall(func, ...);
				if not success then geterrorhandler()(msg); end
			end
		end
		UpdatersCount = UpdatersCount+1;
		Updaters[UpdatersCount] = fire;

		-- only create the updater frame when needed.
		if not UpdaterFrame then CreateUpdaterFrame() end
		UpdaterFrame:Show();
		return fire;
	end

	---
	-- Removes an updater from the list of updaters-to-call.
	-- 
	-- <p>If the last updater was removed the Library will hide the frame,
	-- effectively going 100% idle and not using any cpu time anymore. Until a new
	-- Updater is once again registered and the game goes on...</p>
	-- 
	-- @param func Handle returned from an RegisterUpdater() call.
	function target:UnregisterUpdater(func)
		if type(func) ~= "function" then
			die("Illegal type for argument 1, 'function' expected have '"..type(func).."'");
		end
		
		for i=2, #Updaters, 1 do
			if Updaters[i] == func then
				tremove(Updaters[i])
				i=i-1;
				UpdatersCount = UpdatersCount-1;
			end
		end
		
		-- disable if there's no registered updaters
		if UpdatersCount <= 1 then
			UpdaterFrame:Hide()
		end
	end

	---
	-- Removes all updaters from the list of updaters-to-call.
	function target:UnregisterAllUpdaters()
		-- save manager function
		local manage = Updaters[1];
		-- clear
		wipe(Updaters);
		UpdatersCount = 1;
		-- add manager to updaters again
		Updaters[1] = manage;
		-- disable OnUpdate script handler
		UpdaterFrame:Hide();
	end

	---
	-- Starts this updater if not already running, but only if there actually is at
	-- least one registered function to handle
	function target:StartUpdater()
		if UpdatersCount > 1 then
			UpdaterFrame:Show();
		else
			UpdaterFrame:Hide();
		end
		target:ManageFPS();
	end

	---
	-- Stops this updater
	function target:StopUpdater()
		UpdaterFrame:Hide();
	end

	---
	-- Set the desired number of updates per second (UPS).
	-- 
	-- <p>Note that the UPS can not exceed your FPS. Though, using higher values 
	-- than current  FPS  will not result in the callback to be called more than
	-- once  in  a  single on-update period,  instead  the  library periodically 
	-- analyses the framerate so that an optimal update rate is achieved.</p>
	--
	-- <p>Using  values  lower  than  a normal frame rate is strongly suggested,
	-- otherwise this library is useless.<br>
	-- The actual achieved update rate  depends  on  the  number  of  registered
	-- callbacks, and the current frame rate.<br>
	-- eg. if there a single registered callback with a desired UPS of 30  and a
	-- frame rate of 60fps,  then the actual update rate will be right  on spot.
	-- This is true for any  (multiples of two) - 1  in the number of registered
	-- callbacks  (as there is an additional internal callback which is required
	-- for the management of the frame rate).  That  is  unless  the load of the
	-- callbacks is high enough to reduce the frame rate.</p>
	function target:SetUpdatesPerSecond(ups)
		if not type(ups) == "number" then
			return error("SetUpdatesPerSecond: Argument 1 expected to be of type number, got "..type(ups));
		end
		
		UpdatesPerSecond = ups;
		UpdatesPerManageFPS = floor(ups*SecondsPerManageFPS);
		target:ManageFPS();
	end

	function target.ManageFPS()
		-- -------------------------------- --
		-- NEVER USE self IN THIS FUNCTION! --
		-- -------------------------------- --
		-- we don't need to update fps/ups on every cycle; lets throttle this
		if LimitManageFPS < UpdatesPerManageFPS then
			LimitManageFPS = LimitManageFPS + 1;
			return;
		end
		LimitManageFPS = 0;
		--print("Managing FPS")
		-- determine the target updates per second, we can't surpass the frames per
		-- second though.
		local fps = GetFramerate();
		local ups = min(UpdatesPerSecond, fps);
		local len = #Updaters;
		-- calculate the required step value
		Step = floor(Grace + (UpdatersCount*ups)/fps);
		-- calculate possible number of onupdate calls per cycle
		local calls = (Step*UpdatesPerSecond)
		-- step must be > 0
		if(Step < 1) then
			Step = 1;
		end
		-- done
		
		if OldStep ~= Step then
			--print(MAJOR, ": Step", Step, "FPS:", floor(fps*100)/100, "UPS:", floor(ups*100)/100, "UpdatersCount:", UpdatersCount);
			OldStep = Step;
		end
	end
	
	---
	-- Update the libonupdate contained in source
	function target:Upgrade(source)
		if source then
			Updaters, UpdatersCount, UpdatesPerSecond = Lib:HandleUpgrade(source);
		else
			return MAJOR, MINOR, Updaters, UpdatersCount, UpdatesPerSecond;
		end
	end
	
	return target;
end

function Lib:HandleUpgrade(source)
	local major, minor = source:Upgrade();
	if major ~= MAJOR then
		error(MAJOR..": Can not upgrade from different major version. THIS CODE SHOULD NOT BE REACHED.");
	end
	if minor >= MINOR then
		return;
	end
	
	-- put code here to upgrade from different minor versions
	return select(3, source:Upgrade());
end


--[[ ---------------------------------------------------------------------- ]]--
--[[                            EMBEDDING  STUFF                            ]]--
--[[ ---------------------------------------------------------------------- ]]--
Lib.MixinTargets = Lib.MixinTargets or {}; -- get mixins from old library
local mixins = {
	"RegisterUpdater", "RemoveUpdater", "RemoveAllUpdaters",
	"StartUpdaters", "StopUpdaters",
	"SetUpdatesPerSecond",
	"LIBONUPDATE_SHORT","LIBONUPDATE_LONG","LIBONUPDATE_VERYLONG",
	"LIBONUPDATE_REALTIME",
};

function Lib:Embed(target)
	-- self:Create(target);
	self.MixinTargets[target] = true;
	for k,v in pairs(mixins) do
		target[v] = Lib[v];
	end
end

--[[ LibOnUpdate:OnEmbedDisable( target )
	Unregister all updaters when the target disables.
	
	@param target (object) - target object that is being disabled
]]
function Lib:OnEmbedDisable(target)
	target:UnregisterAllUpdaters();
end

-- re-embed (if and older version of lib was loaded first)
if oldminor and MINOR > oldminor then
	for target,_ in pairs(MixinTargets) do
		for _,name in pairs(mixins) do
			target[name] = Prototype[name];
		end
	end
end

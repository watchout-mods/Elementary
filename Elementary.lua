local MAJOR, Addon = ...;
LibStub("AceAddon-3.0"):NewAddon(Addon, MAJOR,
	"LibColor-1"
);
local this, FontStringBuffer = {}, {};
local ElementaryFont, AlphaUpdateEvents;

local DefaultConfig, Config = {
	profile = {
		ALPHA_COMBAT  = 0.7,
		ALPHA_TARGET  = 0.7,
		ALPHA_CASTING = 0.5,
		ALPHA_POWER   = 0.3,
		ALPHA_IDLE    = 0,
		show_details  = true,
	},
}, {};

function Addon:OnInitialize()
	-- load config from acedb-savedvariable
	Config = LibStub("AceDB-3.0"):New(MAJOR.."Options", DefaultConfig, true);
	-- load options from savedvariables
	ElementaryOptions = setmetatable(ElementaryOptions or {}, {__index=DefaultOptions});

	CreateFont("ElementaryFont");
	ElementaryFont = _G.ElementaryFont;
	ElementaryFont:CopyFontObject("GameFontNormal");
	ElementaryFont:SetTextColor(1, 1, 1, .7);
	ElementaryFont:SetJustifyH("LEFT");
	ElementaryFont:SetJustifyV("MIDDLE");
	ElementaryFont:SetShadowOffset(0,0);
	do
		local p, s, f = ElementaryFont:GetFont();
		ElementaryFont:SetFont(p, 12);
	end
end

function Addon:OnEnable()
	do -- create the container frame
		local cf = CreateFrame("frame", "Elementary-Container-Frame", UIParent);
		self.Container = cf;
		cf:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		cf:SetHeight(350);
		cf:SetWidth(512);
		--cf:RegisterEvent("UNIT_COMBOPOINTS");
		for k,v in pairs(AlphaUpdateEvents) do
			cf:RegisterEvent(k);
		end
		cf:SetAlpha(.7);
		cf:SetScript("OnEvent", function(self, e, ...)
			Addon:OnEvent(e, ...);
		end)

		-- Debug texture to show where HUD is
		-- local T = cf:CreateTexture();
		-- T:SetAllPoints(cf);
		-- T:SetColorTexture(1, 0, 0, .0);
	end
	do
		--[[
		local t = self.Container:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		t:SetText(UnitName("player"));
		t:SetPoint("TOP", self.Container, "BOTTOM", 0, 0)
		t:SetWidth(100);
		t:SetHeight(20);
		]]
		--[[
		local Breeze = LibStub("Breeze-1");
		Breeze:link("Elementary-Health", function(self, n, ... )
			t:SetText(n)
		end)
		]]
	end

	-- hook character panel display
	hooksecurefunc("ToggleCharacter", self.OnCharPanelToggle);
	-- create health watcher

	self:Update()
end

function Addon:GetConfig()
	return Config;
end

function Addon:GetOption(option)
	return Config.profile[option];
end

function Addon:SetOption(option, value)
	Config.profile[option] = value;

	self:Update()
end

---
-- Causes an update of the HUD display
function Addon:Update()
	-- Re-calc alpha values
	self:OnEvent("ELEMENTARY_LOAD");
end

-- Hook that is run when toggling the character panel.
function Addon:OnCharPanelToggle()
	local self = Addon; -- since it is called from bliz as plain function
	if self:GetOption("show_details") == "Character Panel" then
		local enable = PaperDollFrame:IsVisible()
		            or PetPaperDollFrame:IsVisible()
					or SkillFrame:IsVisible()
					or ReputationFrame:IsVisible()
					or TokenFrame:IsVisible();
		-- 
		for name, module in self:IterateModules() do
			if module:IsEnabled() then 
				if enable and module.OnShowDetails then
					module:OnShowDetails();
				elseif not enable and module.OnHideDetails then
					module:OnHideDetails();
				end
			end
		end
	end
end

do -- alpha calculation for HUD
	-- TODO: Update to only re-calculate required values. E.g. only re-calc "d"
	--       on UNIT_HEALTH, etc.
	--       However, performance-impact is extremely low even when doing full
	--       Calculation on each event.
	local a, b, c, d, f = 0, 0, 0, 0, 0;
	function Addon:OnEvent(e, unit)
		unit = unit or "player";
		if AlphaUpdateEvents[e] and (unit == "player" or unit == "target") then
			local cfg = Config.profile;
			a = ((UnitCastingInfo(unit) or UnitChannelInfo(unit)) and cfg.ALPHA_CASTING) or 0;
			if unit == "player" then
				b = ((InCombatLockdown()) and cfg.ALPHA_COMBAT) or 0;
				c = (((UnitPowerMax(unit)-UnitPower(unit)) > 0) and UnitPower(unit) ~= 0 and cfg.ALPHA_POWER) or 0;
				d = (((UnitHealthMax(unit)-UnitHealth(unit)) > 0) and cfg.ALPHA_POWER) or 0;
				f = (UnitName("target") and cfg.ALPHA_TARGET) or 0;
			end
			
			a = max(a, b, c, d, f, cfg.ALPHA_IDLE);
			if a <= 0 then
				self.Container:Hide();
			else
				self.Container:SetAlpha(a);
				self.Container:Show();
			end
		end
	end
end
	

---
-- Returns the texture path of this addon.
-- For convenience, if you pass it a string, it will also concatenate that to
-- the end
function Addon:GetTexturePath(file)
	return "Interface\\AddOns\\"..MAJOR.."\\Textures\\" .. (file or "");
end

---
-- Offers the option to create a FontString object without the need to
-- create a frame first.
-- 
-- All font-strings returned will be sanitized to a certain degree. However
-- errors are always possible.
function Addon:CreateFontString(layer, justify, width, height)
	local t;
	if #FontStringBuffer > 0 then
		t = FontStringBuffer[#FontStringBuffer];
		FontStringBuffer[#FontStringBuffer] = nil;
		-- Sanitize texture
		t:ClearAllPoints();
	else
		t = self.Container:CreateFontString(nil, layer);
	end
	FontStringBuffer[t] = false; -- Set texture as unavailable
	
	t:SetFontObject(GameFontNormal);
	t:SetFontObject(ElementaryFont);
	t:SetParent(self.Container);
	t:SetJustifyH(justify or "LEFT");
	t:SetWidth(width or 100); t:SetHeight(height or 10);
	return t;
end

---
-- Free a FontString previously created by :CreateFontString().
-- @param fontstring the FontString to free.
function Addon:FreeFontString(fontstring)
	if FontStringBuffer[fontstring] == nil then
		error("This texture is not managed by Elementary. Only use "..
				":FreeTexture for textures created by :CreateTexture");
	end
	if FontStringBuffer[fontstring] == false then
		FontStringBuffer[#FontStringBuffer+1] = fontstring;
		FontStringBuffer[fontstring] = #FontStringBuffer;
	end
end

do local C = nil;
	function Addon:GetPowerColor(power)
		if not C then
		local c, LC = self.Colors, LibStub("LibColor-1");
		c.POWER_FOCUS_DIM = {LC:ModifyLuminosity(.8, c.POWER_FOCUS)}
		C = {};
		C[-1]= self:CreateColorBlender({.8,.8,.8,1},{1,1,1,1});    -- PLACEHOLDER
		C[0] = self:CreateColorBlender({.6,0,.4,1},{0,.5,.8,1});   -- MANA
		C[1] = self:CreateColorBlender({.6,0,.0,1},{.6,0,.0,1});   -- RAGE
		C[2] = self:CreateColorBlender(c.POWER_FOCUS_DIM,c.POWER_FOCUS_DIM); -- FOCUS
		C[3] = self:CreateColorBlender({.8,.8,.0,1},{.8,.8,.0,1}); -- ENERGY
		--C[4] = self:CreateColorBlender(c.POWER_CHI,c.POWER_CHI); -- CHI
		C[6] = self:CreateColorBlender(c.POWER_RUNIC_POWER,c.POWER_RUNIC_POWER); -- RUNIC_POWER

		C[8] = self:CreateColorBlender({.1,.2,.5,1},{.3,.52,.9,1});-- LUNARPOWER
		end
	
		return C[power or UnitPowerType("player")] or C[-1];
	end
end

AlphaUpdateEvents = { -- this is local
	PLAYER_REGEN_ENABLED = true,         PLAYER_REGEN_DISABLED = true,
	PLAYER_TARGET_CHANGED = true,        UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,  UNIT_POWER = true, UNIT_HEALTH = true,
	UNIT_DISPLAYPOWER = true,
	ELEMENTARY_LOAD = true, -- not an actual game event, used only in the first call
}


-- local MODULE, MAJOR, addon = "_Source_Health", ...;
-- local Module = addon:NewModule(MODULE) or error("Can not create module");
-- local Reg, this, veil = LibStub("Breeze-1"), nil, nil;

-- function Module:OnInitialize()
-- 	veil = Reg:register_source("Elementary-Health", function(s, n)
-- 		print(n)
-- 		if    n==0 then Module:Disable()
-- 		elseif n>0 then Module:Enable() end
-- 	end, "NUMBER")
-- end

-- function Module:OnEnable()
-- 	if not this then
-- 		local fire = veil.fire;
-- 		this = CreateFrame("frame")
-- 		this:SetScript("OnEvent", function(self)
-- 			fire(self, UnitHealth("player"))
-- 		end)
-- 	end
-- 	this:RegisterEvent("UNIT_HEALTH_FREQUENT");
-- end

-- function Module:OnDisable()
-- 	this:UnregisterAllEvents();
-- end

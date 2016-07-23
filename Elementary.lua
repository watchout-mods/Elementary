local MAJOR, Addon = ...;
LibStub("AceAddon-3.0"):NewAddon(Addon, MAJOR,
	"LibColor-1"
);
local this, FontStringBuffer = {}, {};
local ElementaryFont, AlphaUpdateEvents;

function Addon:OnInitialize()
	-- load config from acedb-savedvariable
	local Config = LibStub("AceDB-3.0"):New(MAJOR.."_Config", DefaultConfig, true);
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
	-- create the container frame
	do
		local cf = CreateFrame("frame", "Elementary-Container-Frame", UIParent);
		self.Container = cf;
		cf:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		cf:SetHeight(350);
		cf:SetWidth(512);
		cf:RegisterEvent("UNIT_DISPLAYPOWER");
		cf:RegisterEvent("UNIT_COMBOPOINTS");
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
end

function Addon:GetOption(option)
	return ElementaryOptions[option];
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
	local a, b, c, d, f = 0, 0, 0, 0, 0;
	function Addon:OnEvent(e, unit)
		unit = unit or "player";
		if AlphaUpdateEvents[e] and (unit == "player" or unit == "target") then
			a = ((UnitCastingInfo(unit) or UnitChannelInfo(unit)) and self.C_CASTING_ALPHA) or 0;
			if unit == "player" then
				b = ((InCombatLockdown()) and self.C_COMBAT_ALPHA) or 0;
				c = (((UnitPowerMax(unit)-UnitPower(unit)) > 0) and UnitPower(unit) ~= 0 and self.C_POWER_ALPHA) or 0;
				d = (((UnitHealthMax(unit)-UnitHealth(unit)) > 0) and self.C_POWER_ALPHA) or 0;
				f = (UnitName("target") and self.C_TARGET_ALPHA) or 0;
			end
			
			a = max(a, b, c, d, f, self.C_IDLE_ALPHA);
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

local PowerColors = nil;
function Addon:GetPowerColor(power)
	if not PowerColors then
		PowerColors = {}
		PowerColors[-1] = self:CreateColorBlender({.8,.8,.8,1},{1,1,1,1});   -- PLACEHOLDER
		PowerColors[0] = self:CreateColorBlender({.6,0,.4,1},{0,.5,.8,1});   -- MANA
		PowerColors[1] = self:CreateColorBlender({.6,0,.0,1},{.6,0,.0,1});   -- RAGE
		PowerColors[2] = self:CreateColorBlender({.6,0,.0,1},{.6,0,.0,1});   -- FOCUS
		PowerColors[3] = self:CreateColorBlender({.8,.8,.0,1},{.8,.8,.0,1}); -- ENERGY
	end
	
	return PowerColors[power or UnitPowerType("player")] or PowerColors[-1];
end

Addon.C_COMBAT_ALPHA = 0.7;
Addon.C_TARGET_ALPHA = 0.7;
Addon.C_CASTING_ALPHA = 0.5;
Addon.C_POWER_ALPHA = 0.3;
Addon.C_IDLE_ALPHA = 0;

AlphaUpdateEvents = { -- this is local
	PLAYER_REGEN_ENABLED = true,         PLAYER_REGEN_DISABLED = true,
	PLAYER_TARGET_CHANGED = true,        UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_CHANNEL_START = true, UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,  UNIT_MANA = true,   UNIT_HEALTH = true,
	GEARBOX_LOAD = true, -- not an actual game event, used only in the first call
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

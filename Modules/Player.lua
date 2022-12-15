local MODULE, ADDON, Addon = "Player", ...;
local MAJOR = ADDON.."."..MODULE;

-- functions that "fix" the fontstring positioning problem:
-- This only happens when it is applied to a fontstring created by a
-- frame that is transformed!
-- SetShadowColor (only when changing)
-- SetJustifyH/V (only when changing)
--  -> SetJustifyV("CENTER") == SetJustifyV("MIDDLE") BUT, changing from
--     CENTER to MIDDLE (and vice versa) will update the font position


-- LibStub throws error on its own if Lib is not found
local ArcBar = LibStub("ArcBar-1");
local LibRotate = LibStub("LibRotate-1");

local Module = Addon:NewModule(MODULE,
	"LibColor-2", "LibOnUpdate-1"
) or error(MAJOR..": Can not create module");

-- localized globals
local tpath = Addon:GetTexturePath();
local GetTime = GetTime;

-- DEBUG
_G.MainRing = Module; 


function Module:OnEnable()
	local w,  h  =  250, 1000;
	local ox, oy = -610, 500;
	local r = 1480/2 - 7.5;
	local t = 7.5 * 2 + 60;
	--  bar = ArcBar:Create(textures, origin_x, origin_y, angle, scale, ccw);
	self:CreateRightBar(w, h, ox, oy, r, t, .35);
	self:CreateLeftBar(w, h, ox, oy, r, t, .35);
	--Addon:RegisterUpdater("UpdateBar1Border", self);
end

local HealthEvents = {
	UNIT_HEALTH_FREQUENT = true,
	PLAYER_ENTERING_WORLD = true,
};
local PowerEvents = {
	UNIT_AURA = true,
	UNIT_DISPLAYPOWER = true,
	PLAYER_ENTERING_WORLD = true,
};
local CastEvents = {
	UNIT_SPELLCAST_START = true,
	UNIT_SPELLCAST_DELAYED = true,
	PLAYER_TARGET_CHANGED = true,
	PLAYER_ENTERING_WORLD = true,
};
local ChannelEvents = {
	--CURRENT_SPELL_CAST_CHANGED = true,
	-- channeling, all events below have following args:
	-- caster (unit), spellname, spellrank, spell lineID counter, spell id
	UNIT_SPELLCAST_CHANNEL_START = true,
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	PLAYER_TARGET_CHANGED = true,
	PLAYER_ENTERING_WORLD = true,
};
local StopEvents = {
	UNIT_SPELLCAST_STOP = true,
	UNIT_SPELLCAST_FAILED = true,
	UNIT_SPELLCAST_CHANNEL_STOP = true,
	PLAYER_TARGET_CHANGED = true,
	PLAYER_ENTERING_WORLD = true,
	--UNIT_SPELLCAST_INTERRUPTED = true,
};


function Module:CreateRightBar(w, h, ox, oy, r, t, scale)
	local f, tx = nil, {};
	
	f = tpath.."MainBar";
	tx.BAR = ArcBar:CreateArcTexture(f, "ARTWORK", w, h, ox, oy, r, t, 56, -28, nil);
	
	tx.BARBG = ArcBar:CreateArcTexture(f, "BACKGROUND", w, h, ox, oy, r, t, 56, -28, nil);
	tx.BARBG:SetVertexColor(self.GetColor("BLACK", .4));
	
	f = tpath.."MainBarBorder";
	tx.BORDER = ArcBar:CreateArcTexture(f, "ARTWORK", w, h, ox, oy, r, t, 56, -28, nil);
	
	tx.BORDERBG = ArcBar:CreateArcTexture(f, "BACKGROUND", w, h, ox, oy, r, t, 56, -28, nil);
	tx.BORDERBG:SetVertexColor(self.GetColor("BLACK", .4));
	
	local bar = ArcBar:CreateArcBar(tx, 0, 0, -28, scale);
	bar.CastUnit = "player";
	bar.Unit = "player";
	bar:SetParent(Addon.Container);
	bar:SetColor(Addon:GetPowerColor());
	bar:SetBorderColor(self.CreateColorBlender("WHITE","WHITE"));
	bar:SetValue(1);
	bar:SetBorderValue(0);
	bar:SetAlpha(1);
	bar:SetAttachmentPoint(UIParent, "CENTER", 400, 0);

	-- create cast info text
	local casttext = Addon:CreateFontString(nil, "RIGHT", 300, 30);
	bar:AddBorderRegion(casttext, "RIGHT", 4, 1, 0, false);

	-- create max cast time text
	local casttimemaxtext = Addon:CreateFontString(nil, "RIGHT", 300, 30);
	bar:AddBorderRegion(casttimemaxtext, "BOTTOMRIGHT", -4, 1, 1, false);

	-- create cast time text
	local casttimetext = Addon:CreateFontString(nil, "RIGHT", 300, 30);
	bar:AddBorderRegion(casttimetext, "TOPRIGHT", -4, 1, 0, false);
	
	-- create bar tip text (HP value etc.)
	local tiptext = Addon:CreateFontString(nil, "LEFT", 300, 30);
	bar:AddTipRegion(tiptext, "LEFT", 5);
	
	local lastf = -1;
	local function UpdateBar(self)
		local cur, mx = UnitPower(bar.Unit), UnitPowerMax(bar.Unit);
		local f = cur/(mx or 1);
		if f ~= lastf then
			self:SetValue(f);
			tiptext:SetText(cur.." ("..(floor(100*f)).."%)");
			lastf = f;
		end
	end
	self.UpdateBar1 = UpdateBar
	self.UpdateRightMainBar = UpdateBar
	self:RegisterUpdater(self.LIBONUPDATE_REALTIME, UpdateBar, bar);
	
	local function CastTimeUpdate(T, frac)
		casttimetext:SetText(format("%.2f",T*frac));
	end
	
	for e,_ in pairs(PowerEvents)   do bar.Frame:RegisterEvent(e) end
	for e,_ in pairs(CastEvents)    do bar.Frame:RegisterEvent(e) end
	for e,_ in pairs(ChannelEvents) do bar.Frame:RegisterEvent(e) end
	for e,_ in pairs(StopEvents)    do bar.Frame:RegisterEvent(e) end
	bar.Frame:HookScript("OnEvent", function(self, event, unit, ...)
		if unit == bar.CastUnit then
			--print(MAJOR, event);
			--print(MAJOR, unit, ...);
			if CastEvents[event] then
				local sname, _, ecastid = ...;
				local name, _, _, startt, endt, _, castid, noninterruptible = UnitCastingInfo(unit);
				--print(MAJOR, "Castinfo:", UnitCastingInfo(unit));
				if name then
					local casttime = (endt-startt)/1000;
					local curtime = GetTime()-startt/1000;
					--print(MAJOR, event, ":", endt, startt, casttime);
					bar:AnimateBorder(casttime, curtime, CastTimeUpdate);
					casttext:SetText(name);
					casttimemaxtext:SetText(casttime);
				end
			end
			if ChannelEvents[event] then
				local sname, _, ecastid = ...;
				local name, _, _, startt, endt, _, castid, noninterruptible = UnitChannelInfo(unit);
				--print(MAJOR, "Channelinfo:", UnitChannelInfo(unit));
				if name then
					local casttime = (endt-startt)/1000;
					local curtime = GetTime()-startt/1000;
					--print(MAJOR, event, ":", endt, startt, casttime, curtime);
					bar:AnimateBorderInverse(casttime, curtime, CastTimeUpdate);
					casttext:SetText(name);
					casttimemaxtext:SetText(casttime);
				end
			end
			if StopEvents[event] then
				local sname, _, ecastid = ...;
				--print(MAJOR, event, ...);
				if not (UnitChannelInfo(unit)) and not (UnitCastingInfo(unit)) then
					bar:StopBorderAnimation();
					casttext:SetText("");
					casttimemaxtext:SetText("");
					casttimetext:SetText("");
				end
			end
			if PowerEvents[event] then
				local p = UnitPowerType(unit);
				if p ~= bar.PowerType then
					bar:SetColor(Addon:GetPowerColor(p));
					bar.PowerType = p;
				end
			end
		end
		unit = unit or bar.CastUnit;
	end);
	bar.Frame:HookScript("OnShow", function(self, ...)
		local unit = bar.CastUnit;
		local name, _, _, startt, endt, _, castid, noninterruptible = UnitCastingInfo(unit);
		if name then
			local casttime = (endt-startt)/1000;
			local curtime = GetTime()-startt/1000;
			bar:AnimateBorder(casttime, curtime, CastTimeUpdate);
			casttext:SetText(name);
			casttimemaxtext:SetText(casttime);
			return
		end
		local name, _, _, startt, endt, _, castid, noninterruptible = UnitChannelInfo(unit);
		if name then
			local casttime = (endt-startt)/1000;
			local curtime = GetTime()-startt/1000;
			bar:AnimateBorderInverse(casttime, curtime, CastTimeUpdate);
			casttext:SetText(name);
			casttimemaxtext:SetText(casttime);
			return
		end
		-- ~ ELSE
		bar:StopBorderAnimation();
		casttext:SetText("");
		casttimemaxtext:SetText("");
		casttimetext:SetText("");
	end);

	_G.ABT = bar;
	self.RIGHT = bar;
end

function Module:CreateLeftBar(w, h, ox, oy, r, t, scale)
	local f, tx = nil, {};
	
	local Color_Interruptible = self.CreateColorBlender("ORANGE", "RED");
	local Color_Noninterruptible = self.CreateColorBlender("GREY90", "GREY90");

	f = tpath.."MainBar-Mirror";
	tx.BAR = ArcBar:CreateArcTexture(f, "ARTWORK", w, h, ox, oy, r, t, 56, -28, true);

	tx.BARBG = ArcBar:CreateArcTexture(f, "BACKGROUND", w, h, ox, oy, r, t, 56, -28, true);
	tx.BARBG:SetVertexColor(self.GetColor("BLACK", .4));
	
	f = tpath.."MainBarBorder-Mirror";
	tx.BORDER = ArcBar:CreateArcTexture(f, "ARTWORK", w, h, ox, oy, r, t, 56, -28, true);
	
	tx.BORDERBG = ArcBar:CreateArcTexture(f, "BACKGROUND", w, h, ox, oy, r, t, 56, -28, true);
	tx.BORDERBG:SetVertexColor(self.GetColor("BLACK", .4));
	
	local bar = ArcBar:CreateArcBar(tx, 0, 0, -28, scale, true, nil);
	bar.CastUnit = "target";
	bar.Unit = "player";
	bar:SetParent(Addon.Container);
	bar:SetColor(self.CreateColorBlender({1,0,0,1},{0,.6,0,1}));
	bar:SetBorderColor(self.CreateColorBlender("GRAY","WHITE"));
	bar:SetValue(1);
	bar:SetBorderValue(0);
	bar:SetAlpha(1);
	bar:SetAttachmentPoint(UIParent, "CENTER", -400, 0);

	-- create cast info text
	local casttext = Addon:CreateFontString(nil, "LEFT", 300, 30);
	bar:AddBorderRegion(casttext, "LEFT", 4, 1, 0, false);

	-- create cast info text
	local casttimemaxtext = Addon:CreateFontString(nil, "LEFT", 300, 30);
	bar:AddBorderRegion(casttimemaxtext, "BOTTOMLEFT", -4, 1, 1, false);

	-- create cast info text
	local casttimetext = Addon:CreateFontString(nil, "LEFT", 300, 30);
	bar:AddBorderRegion(casttimetext, "TOPLEFT", -4, 1, 0, false);
	
	-- create bar tip text (HP value etc.)
	local tiptext = Addon:CreateFontString(nil, "RIGHT", 300, 30);
	bar:AddTipRegion(tiptext, "RIGHT", -5);
	
	local lastf = -1;
	local function UpdateBar(self)
		local cur, mx = UnitHealth("player"), UnitHealthMax("player");
		local f = cur/(mx or 1);
		if f ~= lastf then
			self:SetValue(f);
			tiptext:SetText(cur.." ("..(floor(100*f)).."%)");
			lastf = f;
		end
	end
	self.UpdateBar2 = UpdateBar
	self.UpdateLeftMainBar = UpdateBar
	self:RegisterUpdater(self.LIBONUPDATE_REALTIME, UpdateBar, bar);
	
	local function CastTimeUpdate(T, frac)
		casttimetext:SetText(format("%.2f",T*frac));
	end
	
	for e,_ in pairs(CastEvents)    do Addon.Container:RegisterEvent(e) end
	for e,_ in pairs(ChannelEvents) do Addon.Container:RegisterEvent(e) end
	for e,_ in pairs(StopEvents)    do Addon.Container:RegisterEvent(e) end
	Addon.Container:HookScript("OnEvent", function(self, event, unit, ...)
		if event == "PLAYER_TARGET_CHANGED" then
			unit = "target";
		end
		if unit == bar.CastUnit then
			--print(MAJOR, event);
			--print(MAJOR, unit, ...);
			local t = GetTime()*1000;
			if CastEvents[event] then
				local sname, _, ecastid = ...;
				local name, _, _, startt, endt, _, castid, noninterruptible = UnitCastingInfo(unit);
				--print(MAJOR, "Castinfo:", UnitCastingInfo(unit));
				if name then
					local casttime = (endt-startt)/1000;
					local curtime = GetTime()-startt/1000;
					--print(MAJOR, event, ":", endt, startt, casttime);
					bar:AnimateBorder(casttime, curtime, CastTimeUpdate);
					casttext:SetText(name);
					casttimemaxtext:SetText(casttime);
					if noninterruptible then
						bar:SetBorderColor(Color_Noninterruptible);
					else
						bar:SetBorderColor(Color_Interruptible);
					end
				end
			end
			if ChannelEvents[event] then
				local sname, _, ecastid = ...;
				local name, _, _, startt, endt, _, castid, noninterruptible = UnitChannelInfo(unit);
				--print(MAJOR, "Channelinfo:", UnitChannelInfo(unit));
				if name then
					local casttime = (endt-startt)/1000;
					local curtime = GetTime()-startt/1000;
					--print(MAJOR, event, ":", endt, startt, casttime);
					bar:AnimateBorderInverse(casttime, curtime, CastTimeUpdate);
					casttext:SetText(name);
					casttimemaxtext:SetText(casttime);
					if noninterruptible then
						bar:SetBorderColor(Color_Noninterruptible);
					else
						bar:SetBorderColor(Color_Interruptible);
					end
				end
			end
			if StopEvents[event] then
				local sname, _, ecastid = ...;
				--print(MAJOR, event, ...);
				if not (UnitChannelInfo(unit)) and not (UnitCastingInfo(unit)) then
					bar:StopBorderAnimation();
					casttext:SetText("");
					casttimemaxtext:SetText("");
					casttimetext:SetText("");
				end
			end
		end
		unit = unit or bar.Unit;
	end);
	bar.Frame:HookScript("OnShow", function(self, ...)
		local unit = bar.CastUnit;
		local name, _, _, startt, endt, _, castid, noninterruptible = UnitCastingInfo(unit);
		if name then
			local casttime = (endt-startt)/1000;
			local curtime = GetTime()-startt/1000;
			bar:AnimateBorder(casttime, curtime, CastTimeUpdate);
			casttext:SetText(name);
			casttimemaxtext:SetText(casttime);
			return
		end
		local name, _, _, startt, endt, _, castid, noninterruptible = UnitChannelInfo(unit);
		if name then
			local casttime = (endt-startt)/1000;
			local curtime = GetTime()-startt/1000;
			bar:AnimateBorderInverse(casttime, curtime, CastTimeUpdate);
			casttext:SetText(name);
			casttimemaxtext:SetText(casttime);
			return
		end
		-- ~ ELSE
		bar:StopBorderAnimation();
		casttext:SetText("");
		casttimemaxtext:SetText("");
		casttimetext:SetText("");
	end);

	self.LEFT = bar;
end

function Module:OnDisable()
	self.MainBar1:Hide();
	self.MainBar2:Hide();
end

function Module:GetOptions()
	
	
	return
end

------------------------------- LOCAL FUNCTIONS --------------------------------
local function SetValueBar(self, frac)
	if frac*0 ~= 0 then frac = 0; end -- check if this is a valid number or NaN!
	if self.OldBarValue ~= frac then
		local angle = (frac) * (28*2) - (28);
		self.Bar.Texture:SetTexCoord(self.Rotater:getRotationValues(-angle));
		self.Bar.Texture:SetVertexColor(self.GetBarColor(frac));
		self.OldBarValue = frac;
	end
end

local function SetValueBorder(self, frac)
	if frac*0 ~= 0 then frac = 0; end -- check if this is a valid number or NaN!
	if self.OldBorderValue ~= frac then
		local angle = (frac) * (28.7*2) - (28.7);
		self.Border.Texture:SetTexCoord(self.Rotater:getRotationValues(-angle));
		self.Border.Texture:SetVertexColor(self.GetBorderColor(frac));
		self.OldBorderValue = frac;
	end
end

--- Forces an update of all display elements
local function ForceUpdate(self)
	local oldval;
	oldval = self.OldBarValue;
	self.OldBarValue = nil;
	self:SetValueBar(oldval);

	oldval = self.OldBorderValue;
	self.OldBorderValue = nil;
	self:SetValueBorder(oldval);
end

function Module:UpdateBar1Border(elapsed)
	--local tex = self.MainBar1Border.Texture;
	--tex:SetVertexColor(self.MainBar1Border.GetColor(elapsed*100%1));
end
------------------------------ /LOCAL FUNCTIONS --------------------------------

local AttributesSupported_Bar = {
	ColorEmpty = "COLOR",
	ColorFull  = "COLOR",
}
local AttributesSupported_Border = {
	Color      = "COLOR",
	ColorPulse = "COLOR",
}
local ModulesSupported = {
	MainBar1 = AttributesSupported_Bar,
	MainBar1Border = AttributesSupported_Border,
	MainBar2 = AttributesSupported_Bar,
	MainBar2Border = AttributesSupported_Border,
}
Module.ModulesSupported = ModulesSupported;

function Module:GetSupportedModules()
	local m = {};
	for k,v in pairs(ModulesSupported) do
		tinsert(m, k);
	end
	return m;
end

function Module:GetModuleAttributes(m)
	-- check module
	if not ModulesSupported[m] then
		return error(tostring(self.name)..": Module `"..tostring(m)..
			"` not supported.");
	end
	
	local atts = {};
	for k,v in pairs(ModulesSupported) do
		tinsert(atts, k);
	end
end

function Module:SetModuleAttribute(m, attribute, value)
	-- check module
	if not ModulesSupported[m] then
		return error(tostring(self.name)..": Module `"..tostring(m)..
			"` not supported.");
	end
	
	-- check attribute
	local atts = ModulesSupported[m];
	if not attribute or not atts[attribute] then
		return error(tostring(self.name)..": Module `"..tostring(m)..
			"` does not support attribute `"..tostring(attribute).."`");
	end
	
	-- check value
	local validater = atts[attribute];
	if type(validater) == "string" then
		if type(value) ~= validater then
			return error
		end
	elseif type(validater) == "function" then
		
	else
		return error(tostring(self.name)..": Module `"..tostring(m)..
			"` uses incorrect validater type of `"..type(validater)..
			"` (This error indicates an error in the module itself!)");
	end
	
	local module = self[m];
	
	return self:OnSetModuleAttribute(m, attribute, value);
end

function Module:OnSetModuleAttribute(m, attribute, value)
	
end

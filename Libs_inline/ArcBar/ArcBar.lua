-- This library is extremely specific, hence even though I tried to create
-- something of general use, it might only ever be useful for the addon
-- THUD.
local MAJOR, MINOR = "ArcBar-1", 1;
local Lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR);
--if not Lib then return; end
local LibRotate = LibStub("LibRotate-1");
local LibColor = LibStub("LibColor-2");

local cos, sin = cos, sin;
local HALFPI = math.pi;

-- DEBUG
local function nprint(...)
	if true then return; end
	
	local t = {...};
	local m = 0;
	for k,v in pairs(t) do
		m = max(m, k);
	end
	for i=1, m, 1 do
		if type(t[i]) == "number" then
			t[i] = format("%.2f", t[i]);
		else
			t[i] = tostring(t[i]);
		end
	end
	print(unpack(t));
end
-- /DEBUG

local ProduceTexture;
do
	local TexFactory = nil;
	ProduceTexture = function()
		if not TexFactory then
			TexFactory = CreateFrame("frame", MAJOR .. "-Texture-Factory", UIParent);
			TexFactory:SetPoint("CENTER", 0, 0)
			TexFactory:SetSize(10, 10);
			TexFactory:EnableMouse(false);
			TexFactory:Show();
		end
		
		local tex = TexFactory:CreateTexture();
		tex:SetScale(1);
		return tex;
	end
end

---
-- opening: Opening angle in degrees (gamma)
-- rot: rotational offset angle in degrees (alpha)
-- th: thickness of the bar
function Lib:CreateArcTexture(file, layer, w, h, o_x, o_y, r, th, opening, rot, mirror)
	-- sanity checks
	if w <= 0 or h <= 0 then
		error("width and height must be greater than zero.");
	end
	-- more ... TODO

	local mask_file = file;

	local rt = LibRotate:new();
	rt:mirror(mirror);
	rt:setTexture(file, w, h);
	if mirror then
		rt:setOrigin(-o_x + w, o_y);
		rt:setRectangle(-w, h, o_x, -o_y);
	else
		rt:setOrigin(o_x, o_y);
		rt:setRectangle(w, h, -o_x, -o_y);
	end

	local tex = ProduceTexture();
	tex:SetTexture(file);
	tex:SetDrawLayer(layer);
	tex:SetSize(w, h);

	local maskTexture = tex:GetParent():CreateMaskTexture();
	maskTexture:SetTexture(mask_file);
	maskTexture:SetAllPoints(tex);
	tex:AddMaskTexture(maskTexture);    

	-- local tex2 = CreateTexture();
	-- tex2:SetTexture(file);
	-- tex2:SetTexCoord(rt:getRotationValues(rot + opening * 0.5));
	-- tex2:SetDrawLayer(layer);
	-- tex2:SetAllPoints(tex);

	if mirror then
		function tex:SetArcRotation(frac)
			tex:SetTexCoord(rt:getRotationValues(-opening * frac));
		end
	else
		function tex:SetArcRotation(frac)
			tex:SetTexCoord(rt:getRotationValues(opening * frac));
		end
	end

	function tex:GetRotater()
		return rt;
	end
	
	function tex:_GetRotationOrigin()
		if mirror then
			return "CENTER", tex, "BOTTOMRIGHT", s, 0;
		else
			return "CENTER", tex, "BOTTOMLEFT", -s, 0;
		end
	end
	
	function tex:SetOrigin(relpoint, pos_x, pos_y)
		tex:ClearAllPoints();
		if mirror then
			tex:SetPoint("RIGHT", tex:GetParent(), relpoint, -pos_x, pos_y);
		else
			tex:SetPoint("LEFT", tex:GetParent(), relpoint, pos_x, pos_y);
		end
	end
	
	function tex:GetCalculationValues()
		return r, w, h, o_x, o_y, th, opening, rot;
	end
	
	tex.values = { R = r, W = w, H = h, OX = o_x, OY = o_y,
		TH = th, OPENING = opening, ROT = rot }
	tex:SetArcRotation(0);
	
	nprint(MAJOR, "Calculation values: [r, w, h, o_x, o_y, th, opening, rot]", tex:GetCalculationValues());
	nprint(MAJOR, "Effective scale:", tex:GetEffectiveScale());
	return tex;
end

local function CreateFrameAnimation(bar, frame, duration, startangle, workangle, ccw)
	print(MAJOR, "CreateRotateInAnimation", startangle, workangle);
	local ag = frame:CreateAnimationGroup();
	if ccw then
		startangle = -startangle;
	else
		workangle = -workangle;
	end

	ag:HookScript("OnFinished", function(self, force, ...)
		print(time(), "ag finished", force, ...);
	end);
	
	return ag;
end

local function CreateBarAnimation(bar)
	local ag = bar.Frame:CreateAnimationGroup();
	local offset_s = 0;
	local offset_i = 1;
	-- create bar animation
	local progress = ag:CreateAnimation("Animation");
	progress:SetDuration(1);
	progress:SetOrder(1);
	
	---
	-- @param T total animation time in seconds, if the animation ran from 0 to
	--        max.
	-- @param t time in seconds where the animation "is now". Optional.
	function bar:AnimateBar(T, t, func)
		-- Given T = 10 and t = 2
		-- offset_s = 0.2
		-- offset_i = 0.8
		-- duration: 8
		ag:Stop();
		
		offset_s = (t or 0)/T;
		offset_i = 1-offset_s;
		progress:SetDuration(T-(t or 0));
		
		if func and type(func) == "function" then
			progress:SetScript("OnUpdate", function(self)
				local v = offset_s + self:GetProgress()*offset_i;
				bar:SetValue(v);
				func(T, v);
			end);
		else
			progress:SetScript("OnUpdate", function(self)
				bar:SetValue(offset_s + self:GetProgress()*offset_i);
			end);
		end
		
		ag:Play();
	end
	---
	-- Empties the bar instead of filling it
	function bar:AnimateBarInverse(T, t, func)
		ag:Stop();
		
		offset_s = (t or 0)/T;
		offset_i = 1-offset_s;
		progress:SetDuration(T-(t or 0));
		
		if func and type(func) == "function" then
			progress:SetScript("OnUpdate", function(self)
				local v = offset_s + self:GetProgress()*offset_i;
				bar:SetValue(1-v);
				func(T, 1-v);
			end);
		else
			progress:SetScript("OnUpdate", function(self)
				bar:SetValue(1 - offset_s - self:GetProgress()*offset_i);
			end);
		end
		
		ag:Play();
	end
	function bar:StopBarAnimation()
		ag:Stop();
	end
	
	return ag;
end	

local function CreateBorderAnimation(bar, frame, border, angle, ccw)
	local ag = border:CreateAnimationGroup();
	if ccw then
		angle = -angle;
	end
	local offset_s = 0;
	local offset_i = 1;
	
	-- Rotate-In
	local rot = ag:CreateAnimation("Rotation");
	rot:SetDegrees(angle);
	rot:SetDuration(0);
	rot:SetOrigin(bar:GetOriginPoint(true));
	rot:SetOrder(0);

	local fadein = ag:CreateAnimation("Alpha");
	fadein:SetDuration(0);
	fadein:SetFromAlpha(0);
	fadein:SetToAlpha(1);
	fadein:SetOrder(0);
	
	local progress = ag:CreateAnimation("Animation");
	progress:SetDuration(1);
	progress:SetOrder(1);
	
	local fadeout = ag:CreateAnimation("Alpha");
	fadeout:SetDuration(0);
	fadeout:SetFromAlpha(1);
	fadeout:SetToAlpha(0);
	fadeout:SetOrder(2);
	
	ag:SetScript("OnFinished", function(self)
		bar:SetBorderValue(0);
	end);
	ag:SetScript("OnStop", function(self)
		bar:SetBorderValue(0);
	end);

	---
	-- @param T total animation time in seconds, if the animation ran from 0 to
	--        max.
	-- @param t time in seconds where the animation "is now". Optional, use nil
	--        for default
	-- @param func is a callback
	function bar:AnimateBorder(T, t, func)
		ag:Stop();
		
		offset_s = (t or 0)/T;
		offset_i = 1-offset_s;
		progress:SetDuration(T-(t or 0));
		
		if func and type(func) == "function" then
			progress:SetScript("OnUpdate", function(self)
				local v = offset_s + self:GetProgress()*offset_i;
				bar:SetBorderValue(v);
				func(T, v);
			end);
		else
			progress:SetScript("OnUpdate", function(self)
				bar:SetBorderValue(offset_s + self:GetProgress()*offset_i);
			end);
		end
		
		ag:Play();
	end
	---
	-- Animate border, emptying the bar instead of filling it up
	-- @param T total animation time in seconds, if the animation ran from 0 to
	--        max.
	-- @param t time in seconds where the "is now". Optional.
	-- @param func is a callback
	function bar:AnimateBorderInverse(T, t, func)
		ag:Stop();

		offset_s = (t or 0)/T;
		offset_i = 1-offset_s;
		progress:SetDuration(T-(t or 0));
		
		if func and type(func) == "function" then
			progress:SetScript("OnUpdate", function(self)
				local v = offset_s + self:GetProgress()*offset_i;
				bar:SetBorderValue(1-v);
				func(T, 1-v);
			end);
		else
			progress:SetScript("OnUpdate", function(self)
				bar:SetBorderValue(1 - offset_s - self:GetProgress()*offset_i);
			end);
		end
		
		ag:Play();
	end
	function bar:StopBorderAnimation()
		ag:Stop();
	end
	
	return ag;
end

---
-- textures ... a table of texture objects created by Lib:CreateTexture. The 
--              table can contain the following keys (case-sensitive):
--                BACKGROUND
--                BAR
--                BAROVER
--                BORDER
--                BORDEROVER
--                [0-9]+ (numeric index)
--              all textures will be the same size in the UI.
-- origin_x ... the x value of where the origin of the arc should be in the UI
-- origin_y ... like origin_x of course
-- angle ...... angle of the "first" point of the arc, when the 2nd point is
--              in clockwise direction from the first. The angle starts on the
--              x-axis on the right side of the pole.
-- ccw ........ The bar EMPTIES counter-clockwise
local CreateUtilityFunctions;
local textures_allowed = {
	BAR = "BAR",
	BARBG = "BARBG",
	BORDER = "BORDER",
	BORDERBG = "BORDERBG",
	BG = "BG"
};
function Lib:CreateArcBar(input_textures, origin_x, origin_y, angle, scale, ccw, dbg)
	local bar = {};
	local container = CreateFrame("frame");
	container:SetWidth(100);
	container:SetHeight(100);
	container:SetParent(UIParent);
	container:SetPoint("CENTER", UIParent);
	container:SetScale(scale);
	container:SetMovable(true);

	if dbg then
		local t = container:CreateTexture();
		t:SetAllPoints(container);
		t:SetColorTexture(0, 1, 0, .5);
	end
	
	local frame = CreateFrame("frame", container);
	local textures = {};
	local ORIGINPOINT = "BOTTOMLEFT"; -- replace fixed origin point with variable
	local RelativeOriginX, RelativeOriginY = 0,0;
	if ccw then -- TODO
	end
	
	frame:SetPoint("CENTER", container, "CENTER");
	frame:SetWidth(100);
	frame:SetHeight(100);
	frame:SetParent(container);
	frame:Show();
	frame:EnableMouse(false);

	if dbg then
		local t = frame:CreateTexture();
		t:SetAllPoints(container);
		t:SetColorTexture(0, 0, 1, .5);
	end
	
	local TipPointOuter = ProduceTexture();
	TipPointOuter:SetColorTexture(1, 0, 0, 0);
	TipPointOuter:SetDrawLayer("BORDER");
	TipPointOuter:SetWidth(10);
	TipPointOuter:SetHeight(10);
	TipPointOuter:SetParent(frame);
	--[[
	local TipPointInner = ProduceTexture();
	TipPointInner:SetColorTexture(1, 1, 0);
	TipPointInner:SetDrawLayer("BORDER");
	TipPointInner:SetWidth(10);
	TipPointInner:SetHeight(10);
	TipPointInner:SetParent(container);
	]]
	do
		textures = {};
		for k,v in pairs(textures_allowed) do
			if input_textures[k] then
				textures[k] = input_textures[k];
				textures[k]:SetParent(frame);
				textures[k]:SetOrigin("CENTER", origin_x, origin_y);
			end
		end
		for k,v in ipairs(input_textures) do
			tinsert(textures, v);
		end
	end
	
	-- Closure-Variables used in the functions below
	local BarValue, BorderValue;
	local BarColor = LibColor.CreateColorBlender("WHITE", "WHITE");
	local BorderColor = LibColor.CreateColorBlender("WHITE", "WHITE");
	
	function bar:SetAttachmentPoint(relframe, relpoint, ox, oy)
		container:ClearAllPoints();
		--container:SetPoint("CENTER", relframe, relpoint, ox-RelativeOriginX, oy-RelativeOriginY);
		container:SetPoint("CENTER", relframe, relpoint, ox, oy);
	end
	---
	-- Returns the origin point of this bar so that it can be used in a
	-- SetPoint(...) or Rotation:SetOrigin(...) call like
	--   rot:SetOrigin(bar:GetOriginPoint());
	--
	function bar:GetOriginPoint(effective)
		if effective then
			return "BOTTOMLEFT",
			       origin_x*frame:GetEffectiveScale(),
				   origin_y*frame:GetEffectiveScale();
		else
			return "BOTTOMLEFT", origin_x, origin_y;
		end
	end
	function bar:SetBorderValue(frac)
		-- TODO: What happens if there is no Tex BAR
		if frac ~= BorderValue and textures.BORDER then
			-- make sure frac is of the right value
			if frac*0 ~= 0 then frac = 0; end
			if frac < 0 then frac = 0; end
			if frac > 1 then frac = 1; end
			textures.BORDER:SetArcRotation(1-frac);
			textures.BORDER:SetVertexColor(BorderColor(frac))
			BorderValue = frac;
		end
	end
	function bar:SetBorderColor(color)
		if textures.BORDER and type(color) == "function" then
			BorderColor = color;
			textures.BORDER:SetVertexColor(BorderColor(BorderValue or 0));
		end
	end
	-- @param offset radius offset.
	local function GetTipCoords(self, inner, value, offset)
		value = value or BarValue;
		
		if textures.BAR then
			--local _, ox, oy = bar:GetOriginPoint();
			local r,w,h,ox,oy,th,opening,rot = textures.BAR:GetCalculationValues();
			local x, y;
			offset = offset or 0;
			
			if inner then
				th = 0;
				offset = -offset;
			end
			
			-- absolute
			--x = ox + (r+th)*cos(value*opening + rot);
			--y = oy + (r+th)*sin(value*opening + rot);
			-- relative
			if ccw then
				x = -(r+th+offset)*cos(- value*opening - rot) - ox;
				y = -(r+th+offset)*sin(- value*opening - rot) - 0;
			else
				x =  (r+th+offset)*cos(value*opening + rot) + ox;
				y =  (r+th+offset)*sin(value*opening + rot) - 0;
			end
			
			return x, y;
		end
	end
	-- duplicate of GetTipCoords to at least have something - for now:
	local GetBorderTipCoords = GetTipCoords;
	
	function bar:SetValue(frac)
		if frac ~= BarValue and textures.BAR then
			if frac*0 ~= 0 then frac = 0; end
			textures.BAR:SetArcRotation(1-frac);
			textures.BAR:SetVertexColor(BarColor(frac))
			BarValue = frac;
			
			--print(MAJOR, GetTipCoords());
			TipPointOuter:ClearAllPoints();
			TipPointOuter:SetPoint("CENTER", GetTipCoords());
		end
	end

	function bar:SetColor(color)
		if type(color) == "function" then
			BarColor = color;
			textures.BAR:SetVertexColor(BarColor(BarValue or 0));
		end
	end
	
	---
	-- Adds a Region that is to be positioned at the tip of the Bar (aka as the
	-- bar fills or empties, the region will move with it)
	-- FontStrings behave somewhat special in 4.0.6, ONLY add them
	-- directly, NOT as a child region that is attached to the region you add - 
	-- actually it's best if you don't add any region with child regions.
	-- @param region the region to add. this must be a table value and support
	--   the region interface.
	-- @param point point of the child region where it is to be attached
	-- @param ox x offset
	-- @param oy y offset
	-- @param inner specify if inner or outer tip is to be used. NYI
	-- @param reparent if set to true, sets the parent frame to the correct
	--   container frame.
	function bar:AddTipRegion(region, point, ox, oy, inner, reparent)
		if not region.SetPoint or type(region.SetPoint) ~= "function" then
			return error("Argument 1 must be a region or support the interface");
		end
		if reparent then
			region:SetParent(container);
		end
		region:SetPoint(point, TipPointOuter, "CENTER", ox or 0, oy or 0);
	end

	---
	-- Adds a Region positioned at a certain progress location in the progress
	-- bar.
	-- 
	-- @param value    a numerical value from 0 to 1 representing the position
	--                 of the region on the bar
	-- @param offset   a radial offset starting with value 0 at the inner edge
	--                 of the bar and 1 is at the outer edge
	-- @param region   the region to add. This must be a table value and
	--                 support the region interface.
	-- @param point    point of the child region where it is to be attached
	-- @param ox       x offset
	-- @param oy       y offset
	-- @param inner    specifies if inner or outer tip is to be used. NYI
	-- @param reparent if set to true, sets the parent frame to the correct
	--                 container frame.
	function bar:AddProgressRegion(value, offset, region, point, pox, poy, reparent)
		if not region.SetPoint or type(region.SetPoint) ~= "function" then
			return error("Argument 1 must be a region or support the interface");
		end
		local _, _, _, _, _, _, _, _, th = textures.BAR:GetCalculationValues();
		local scale = container:GetScale();
		local offset_v = (offset or 0.5) * th;
		local x, y;

		if reparent then
			region:SetParent(container);
		end
		
		if region:GetParent() ~= container then
			x, y = GetTipCoords(self, inner, value, offset_v / scale);
			x = x * container:GetScale();
			y = y * container:GetScale();
		else
			x, y = GetTipCoords(self, inner, value, offset_v);
		end

		region:SetPoint(point, container, "CENTER", x, y);
	end

	---
	-- Adds a Region that is to be positioned at the border of the Bar. In
	-- contrast to AddTipRegion, this will remain static relative to the bar
	-- source
	-- FontStrings behave somewhat special in 4.0.6, ONLY add them
	-- directly, NOT as a child region that is attached to the region you add - 
	-- actually it's best if you don't add any region with child regions.
	-- @param region the region to add. this must be a table value and support
	--   the region interface.
	-- @param point point of the child region where it is to be attached
	-- @param radius offset
	-- @param inner specify if inner or outer tip is to be used. NYI
	-- @param reparent if set to true, sets the parent frame to the correct
	--   container frame.
	-- @param value value from 0 to 1 indicating the position of the  region on
	--   the bar.
	function bar:AddBorderRegion(region, point, offset, inner, value, reparent)
		if not region.SetPoint or type(region.SetPoint) ~= "function" then
			return error("Argument 1 must be a region or support the interface");
		end
		local x, y;
		if reparent then
			region:SetParent(container);
			x, y = GetBorderTipCoords(self, inner, value, offset / container:GetScale());
		elseif region:GetParent() ~= container then
			x, y = GetBorderTipCoords(self, inner, value, offset / container:GetScale());
			x = x * container:GetScale();
			y = y * container:GetScale();
		end
		region:SetPoint(point, container, "CENTER", x, y);
	end
	
	CreateUtilityFunctions(bar, frame, container, ccw);
	
	bar.Animation = CreateFrameAnimation(bar, frame, 0.1, 90+angle, 90, ccw);
	--bar.CastAnimation = CreateBorderAnimation(bar, frame, textures.BORDER, angle/2, ccw);
	if textures.BORDER then
		bar.CastAnimation = CreateBorderAnimation(bar, frame, textures.BORDER, 0, ccw);
	end
	if textures.BAR then
		bar.CreateBarAnimation = CreateBarAnimation;
	end

	-- Expose Frames and stuff for debugging purposes
	bar.Frame = frame;
	bar.Textures = textures;
	bar.Container = container;
	bar.GetTipCoords = GetTipCoords;
	bar.GetBorderTipCoords = GetBorderTipCoords;
	bar.CCW = not not ccw;
	
	return bar;
end


---
-- These are primitive methods that mostly mimic an existing interface by
-- proxying the method call to the respective frame. They are only here to make
-- the function above a little less overwhelming.
function CreateUtilityFunctions(bar, frame, container, ccw)
	local moving = false;
	function bar:SetParent(parent)
		container:SetParent(parent);
	end
	function bar:ToggleMoving()
		if moving then
			container:StopMovingOrSizing();
			moving = false;
		else
			container:StartMoving();
			moving = true;
		end
	end
	function bar:SetAlpha(frac)
		container:SetAlpha(frac);
	end
	function bar:Hide()
		container:Hide();
	end
	function bar:Show()
		container:Show();
	end
	function bar:Toggle()
		if container:IsShown() then
			container:Hide();
		else
			container:Show();
		end
	end	
end

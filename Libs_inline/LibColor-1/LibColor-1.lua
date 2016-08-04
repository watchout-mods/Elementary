local MAJOR, MINOR = "LibColor-1", 1;
local Lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR);
if not Lib then return; end
---
-- LibColor provides a number of functions that operate on colors.
-- With strong type checking, LibColor assures consistent return values and
-- minimal error output.
--
-- Color types
-- -----------
--
-- LibColor supports three variants of color representation in most functions:
--  ; Color list: A list of individual values for each color part (Red,  Green,
--    Blue and optionally Alpha)
--  ; Color name: A string representing a color name, like "PURPLE". These
--    values are pre-defined in the library. See *Color names* below.
--  ; Color table: A table representing an *array* of three (for RGB) or four
--    values (for RGBA). The table representation is restricted to the array
--    part for better performance (as opposed to the blizzard variant of
--    defining red, green and blue with string indexes ('r', 'g', 'b', 'a').
--
-- Color names
-- -----------
-- 
-- LibColor supports the basic colors like RED, GREEN and BLUE, and so on. You
-- can find a complete list in the source or by dumping the contents of the
-- table `LibColor.Colors`.
-- 
-- Additionally, LibColor imports colors from `PowerBarColor` as `POWER_<Name>`
-- and from `RAID_CLASS_COLORS` as `CLASS_<Name>`. To prevent possible errors,
-- the colors `POWER_UNKNOWN` and `POWER_` have been added as well.
--
-- Since the table `LibColors.Colors` is accessible from outside the library, it
-- is theoretically possible to extend it. Since I can not prevent it in any way
-- other than preventing access to the table, I will here suggest a naming
-- convention for those:
-- 
--     '_' *ADDONNAME* '_' *COLORNAME*
-- 
-- So grid might have it's custom color `BACKGROUND`. You would name it
-- `_GRID_BACKGROUND`. This also means that this library will never declare a
-- color starting with an underscore.
-- 
-- @class module
--/

local min, max = math.min, math.max;

local ColorStrings = {
--  COLOR  = { R, G, B, A},
	RED    = { 1, 0, 0, 1}, GREEN  = { 0, 1, 0, 1}, BLUE   = { 0, 0, 1, 1},
	PURPLE = { 1, 0, 1, 1}, PINK   = { 1,.2,.7, 1}, YELLOW = { 1, 0, 1, 1},
	BLACK  = { 0, 0, 0, 1}, GREY   = {.5,.5,.5, 1}, WHITE  = { 1, 1, 1, 1}, 
	GREY10 = {.1,.1,.1, 1}, GREY20 = {.2,.2,.2, 1}, GREY30 = {.3,.3,.3, 1},
	GREY40 = {.4,.4,.4, 1}, GREY50 = {.5,.5,.5, 1}, GREY60 = {.6,.6,.6, 1},
	GREY70 = {.7,.7,.7, 1}, GREY80 = {.8,.8,.8, 1}, GREY90 = {.9,.9,.9, 1},
	DARKGREY   = {.2,.2,.2, 1}, LIGHTGREY  = {.8,.8,.8, 1},
	DARKRED    = {.4, 0, 0, 1}, LIGHTRED   = { 1,.6,.6, 1},
	DARKGREEN  = { 0,.4, 0, 1},
	DARKBLUE   = { 0, 0,.4, 1},
	DARKPURPLE = {.4, 0,.4, 1},
	HEALTH     = { 0, 1, 0, 1}, POWER_UNKNOWN = {.6,.6,.6, 1}, 
}
ColorStrings.GRAY = ColorStrings.GREY;
ColorStrings.POWER_ = ColorStrings.POWER_UNKNOWN;

do -- mix in colors from PowerBarColor
	for k,v in pairs(PowerBarColor or {}) do
		if type(k) == "string" and v.r then
			ColorStrings["POWER_"..k] = { v.r, v.g, v.b, 1 };
		end
	end
	-- chi is called LIGHT_FORCE ... whatever
	ColorStrings.POWER_CHI = ColorStrings.POWER_LIGHT_FORCE;
	-- Make mana color a bit easier on the eye
	ColorStrings.POWER_MANA = {.1, .2, 1, 1};
end
do -- mix in colors from RAID_CLASS_COLORS
	for k,v in pairs(RAID_CLASS_COLORS) do
		local tbl = {v[r], v[g], v[b], v[a] or 1};
		ColorStrings["CLASS_"..tostring(k)] = tbl;
	end
end

-- mix color constants into the Lib
for k,v in pairs(ColorStrings) do
	Lib[k] = v;
end
Lib.Colors = ColorStrings;

local getColor, blendColor, createColorBlender;
local isColorTable, isColorList, isColorName, isColor;
local tostringall, strjoin = tostringall, strjoin;

local function liberr(f, ...)
	error(MAJOR..":", ...);
end

local function argerr(f, argnum, expect, got)
	liberr(("Bad argument #%s to `%s' (%s expected, got %s)"):format(argnum, f, expect, got));
end

---
-- Returns whether the given table is a valid "Blizzard" color table.
-- 
-- Blizzard color tables are of the form:
--     { r = <0..1>, g = <0..1>, b = <0..1>[, a = <0..1>]}
-- 
-- @returns true if the given table is a valid Blizzard color table, false
-- otherwise.
local function isBlizColorTable(self, tbl)
	if not tbl or type(tbl)~="table" or not tbl.r or not tbl.g or not tbl.b then
		return false;
	end
	
	return isColorList(self, tbl.r, tbl.g, tbl.b, tbl.a);
end

---
-- r,g,b,a = Lib:GetColor(String [, Alpha])
-- r,g,b,a = Lib:GetColor(ColorTable) (See Lib:isColorTable())
-- r,g,b,a = Lib:GetColor(Red, Green, Blue[, Alpha])
--
-- Returns Red, Green, Blue and Alpha values from various input types.
-- Possible input types are:
--   ;String: any string that equals an available color constant. An optional
--            alpha value may be added.
--   ;Table:  as by convention of :isColorTable function
--   ;List:   a list of three or four real number values directly as arguments
--            to this function
--
-- Color tables contain four numerically indexed items for values R, G, B, A
function Lib:getColor(c, ...)
	--print(MAJOR, c, ...);
	local input_t = type(c);
	local argc = select('#', ...) + 1;
	local red, green, blue, alpha;
	
	if input_t == "string" then
		local cs = ColorStrings[c];
		if cs and isColorTable(self, cs) then
			local alpha1 = ...
			red, green, blue, alpha = unpack(cs);
			-- TODO: Typecheck of alpha1
			if alpha1 and alpha1*0 == 0 and alpha1 <= 1 and alpha1 >= 0 then
				alpha = alpha1;
			end
		end
	elseif input_t == "table" then
		if isColorTable(self, c) then
			red, green, blue, alpha = unpack(c);
		end
	elseif (argc == 4 or argc == 3) and isColorList(self, c, ...) then
		red, green, blue, alpha = c, ...;
	end
	
	if not red then
		error("Not a color <"..strjoin(", ", tostringall(c, ...))..">");
	end
	return red, green, blue, alpha;
end



---
-- DEPRECATED. DO NOT USE.
-- boolean = Lib:IsColorValue(...)
-- 
function Lib:IsColorValue(...)
	error("DEPRECATED.");
	for i=1, select("#", ...) do
		local v = select(i, ...);
		if (not v) or (type(v)~="number") or v*0~=0 then return false; end
	end
	return true;
end

---
-- Trims a value to the range 0..1
-- @param v the value to trim
-- @return if the value is in the range <0..1>,  or nil,  it will return exactly 
-- that value.  If the value is `< 0` it will return `0`,  if the value is `> 1` 
-- then it will return `1`.
function Lib:TrimValue(v)
	if v then
		if v < 0 then
			return 0;
		elseif v > 1 then 
			return 1;
		end
	end
	return v;
end

---
-- boolean = Lib:IsColorName(Name)
-- Returns whether the given name represents a valid color.
-- No color names containing special characters like accents, umlauts, etc. are
-- planned.
-- Color names contain only UPPER CASE characters A-Z, the character "_" or
-- numbers (no decimal point, comma, or whatever)
-- The name argument is currently automatically UPPER CASED, however this
-- behaviour may change to improve performance.
--
-- Use Lib:GetColorNames() to get a list of (currently) valid names.
function Lib:IsColorName(name)
	return not not ColorStrings[name or ''];
end

---
-- boolean = Lib:IsColorList(Red, Green, Blue[, Alpha])
-- Returns whether the given values represent a valid color list.
-- Alpha is optional and thus may be a number from 0 to 1 or false or nil.
function Lib:IsColorList(R, G, B, A)
	if (type(R) ~= "number") or (R*0~=0) or (R < 0) or (R > 1) then return false; end
	if (type(G) ~= "number") or (G*0~=0) or (G < 0) or (G > 1) then return false; end
	if (type(B) ~= "number") or (B*0~=0) or (B < 0) or (B > 1) then return false; end
	A = A or 1;
	if (type(A) ~= "number") or (A*0~=0) or (A < 0) or (A > 1) then return false; end
	return true;
end

---
-- boolean = Lib:IsColorTable(Mixed | Table)
-- Returns whether the given value/table is a valid color table.
--
-- Color tables contain three or four numerically indexed items for values
-- <Red, Green, Blue, Alpha>, where individual values must range from 0 to 1 and
-- Alpha is optional and thus may be a number from 0 to 1 or false or nil.
-- The first item must be at index 1 and the table must be gapless - that means
-- color red is at index 1, green index 2, blue index 3 and alpha may or may not
-- exist but if it does, it is at index 4.
-- @param tbl the argument to test
-- @return true if the given parameter is a valid color table
function Lib:isColorTable(tbl)
	if (not tbl) or (type(tbl) ~= "table") or (#tbl ~= 3 and #tbl ~= 4) then
		return false;
	end
	
	return isColorList(self, tbl[1], tbl[2], tbl[3], tbl[4]);
end

---
-- Returns whether the given value describes a color in any possible form.
-- @param ... any value
-- @return **true** if the given parameters can be interpreted as one of the
-- color types, **false** otherwise.
function Lib:IsColor(...)
	return isColorList(self, ...) or isColorTable(self, ...) or isColorName(self, ...);
end

---
-- r,g,b,a = Lib:BlendColor(from, to, frac)
-- Blends between two colors and returns the blended color
--
-- @param from Color starting color
-- @param to   Color end color
-- @param frac Number may be any number from 0 to 1. 0 will return exactly the
--             "from" color, 1 will return exactly the color "to", numbers in
--             between are blended proportionally.
-- @returns List style color (Red, Green, Blue, Alpha)
function Lib:blendColor(col_from, col_to, pos)
	local cfr, cfg, cfb, cfa = getColor(self, col_from);
	local ctr, ctg, ctb, cta = getColor(self, col_to);
	if not cfr or not ctr then
		error(MAJOR..":blendColor(...) one of arguments <1,2> is not a color.");
	end
	if not pos or type(pos) ~= "number" then
		error(MAJOR..":blendColor(...) argument 3 (pos) must be a number from 0 to 1.");
	end
	if pos < 0 then pos = 0; end;
	if pos > 1 then pos = 1; end;
	return cfr + ((ctr-cfr) * pos), cfg + ((ctg-cfg) * pos),
		   cfb + ((ctb-cfb) * pos), cfa + ((cta-cfa) * pos);
end

---
-- blender = Lib:createColorBlender(from, to)
-- Blends between two colors and returns the blended color
--
-- @param from Color starting color
-- @param to   Color end color
-- @returns function (r,g,b,a = blender(frac))
function Lib:createColorBlender(col_from, col_to)
	local cfr, cfg, cfb, cfa = getColor(self, col_from);
	local ctr, ctg, ctb, cta = getColor(self, col_to);
	local cdr, cdg, cdb, cda = ctr-cfr, ctg-cfg, ctb-cfb, cta-cfa;
	if not cfr or not ctr then
		error(MAJOR..":createColorBlender(...) one of arguments <1,2> is not a color.");
	end
	---
	-- r,g,b,a = blend(frac)
	-- Blends between two colors and returns the blended color
	-- @param frac Number<0..1> `0` will return exactly the "from" color supplied
	--             to CreateColorBlender(...) and `1` will return exactly the
	--             color "to". Numbers in between are blended proportionally.
	--             
	-- @returns List style color (Red, Green, Blue, Alpha)
	local function blend(pos)
		if not pos or type(pos) ~= "number" then
			error(MAJOR.."::ColorBlender(...) argument 1 (pos) must be a number from 0 to 1. But is: "..tostring(pos));
		end
		if pos < 0 then pos = 0; end;
		if pos > 1 then pos = 1; end;
		return cfr + cdr*pos, cfg + cdg*pos, cfb + cdb*pos, cfa + cda*pos;
	end
	return blend;
end

---
-- Desaturates the given color to retain only Luminosity.
--
-- NYT
--
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:Desaturate(...)
	local r,g,b,a = getColor(self, ...);
	local l = (min(r,g,b)+max(r,g,b))/2;
	
	return l, l, l, a;
end

---
-- Naiive function to modify the luminosity of a color using linear blending.
-- The function should not be assumed to be anywhere near correct HSL conversion
-- but rather "Quick and dirty".
-- 
-- NYT
--
-- @param value Number<0..1> Where 0 means black and 1 means white.
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:ModifyLuminosity_old(value, ...)
	if type(value) ~= "number" then
		argerr("ModifyLuminosity", " argument 1 (value) must be a number from 0 to 1. But is: "..tostring(pos));
	end
	local r,g,b,a = getColor(self, ...);
	local low, high = min(r,g,b), max(r,g,b);
	local lum = (low+high)/2;
	if value > lum then
		return blendColor(self, {r,g,b,a}, {getColor("WHITE", a)}, (1-value)/(value-lum));
	else
		return blendColor(self, {getColor("BLACK", a)}, {r,g,b,a}, lum/(lum-value));
	end
end

---
-- Function to modify the luminosity of a color using RGB-HSL conversion.
-- 
-- NYT
--
-- @param value Number<0..1> Where 0 means black and 1 means white.
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:GetLuminosity(value, ...)
	if type(value) ~= "number" then
		argerr("GetLuminosity", " argument 1 (value) must be a number from 0 to 1. But is: "..tostring(pos));
	end
	local r, g, b, a = getColor(self, ...);
	local hi, lo = max(r, g, b), min(r, g, b);

	return (hi + lo) / 2;
end

---
-- Function to modify the luminosity of a color using RGB-HSL conversion.
-- 
-- NYT
--
-- @param factor Number<0 .. inf.> a factor that is applied to the luminosity
--           value. The result is bounded by 0 .. 1.
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:ModifyLuminosity(factor, ...)
	if type(factor) ~= "number" then
		argerr("ModifyLuminosity", " argument 1 (factor) must be a number from 0 to 1. But is: "..tostring(pos));
	elseif factor < 0 then
		argerr("ModifyLuminosity", " argument 1 (factor) must be a number from 0 to 1. But is: "..tostring(pos));
	end
	local h,s,l,a = self.RGBtoHSL(getColor(self, ...));
	return self.HSLtoRGB(h, s, max(1, l * factor), a);
end

---
-- Function to set the luminosity of a color using RGB-HSL conversion.
-- 
-- NYT
--
-- @param value Number<0..1> Where 0 means black and 1 means full hue.
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:SetLuminosity(value, ...)
	if type(value) ~= "number" then
		argerr("ModifyLuminosity", " argument 1 (value) must be a number from 0 to 1. But is: "..tostring(pos));
	end
	local h,s,l,a = self.RGBtoHSL(getColor(self, ...));
	return self.HSLtoRGB(h, s, value, a);
end

---
-- Returns a color that should be reasonably readable as text in front of a
-- background colored with the color supplied as argument.
-- 
-- @param ... any value that can be passed to :GetColor(...)
-- @return r, g, b, a values
function Lib:GetColorForText(...)
	local r,g,b,a = getColor(self, ...);
	local low, high = min(r,g,b), max(r,g,b);
	local lum = (low+high)/2;
	if lum < .6666666 then
		return getColor(self, "WHITE");
	else
		return getColor(self, "DARKGREY");
	end
end


---
-- Converts an RGB color value to HSL.
-- Conversion formula adapted from http://en.wikipedia.org/wiki/HSL_color_space.
-- Ported from http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
--
-- This function was not tested yet!
--
-- @param   r  Number<0..1>  The red color value
-- @param   g  Number<0..1>  The green color value
-- @param   b  Number<0..1>  The blue color value
-- @param   a  Number<0..1>  The alpha value
-- @return  h, s, l, a       The HSL representation
--
function Lib.RGBtoHSL(r, g, b, a)
	local hi, lo = max(r, g, b), min(r, g, b);
	local h, s, l = 0, 0, (hi + lo) / 2;

	if hi ~= lo then -- not greyscale
		local d = hi - lo;
		if l > 0.5 then
			s = d / (2 - hi - lo);
		else
			s = d / (hi + lo);
		end
		
		if hi == r and g < b then   h = (g - b) / d + (6);
		elseif hi == r then         h = (g - b) / d + (0);
		elseif hi == g then         h = (b - r) / d + 2;
		elseif hi == b then         h = (r - g) / d + 4;
		end
		h = h / 6;
	end
	
	return h, s, l, a;
end

---
-- Converts an HSL color value to RGB. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSL_color_space. And ported from
-- http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
--
-- This function was not tested yet!
--
-- @param   h  Number<0..1>  The hue value
-- @param   s  Number<0..1>  The saturation value
-- @param   l  Number<0..1>  The lightness value
-- @param   a  Number<0..1>  The alpha value
-- @return  r, g, b, a       The RGB representation
--
function Lib.HSLtoRGB(h, s, l, a)
	local r, g, b = l, l, l;

	if s ~= 0 then
		local function hue2rgb(p, q, t)
			if t < 0 then t = t + 1;
			elseif t > 1 then t = t - 1; end
			
			if t < 1/6 then return p + (q - p) * 6 * t; end
			if t < 1/2 then return q; end
			if t < 2/3 then return p + (q - p) * (2/3 - t) * 6; end
			return p;
		end

		local p, q;
		if l < .5 then
			q = l * (1 + s);
		else
			q = l + s - l * s;
		end
		p = 2 * l - q;
		r = hue2rgb(p, q, h + 1/3);
		g = hue2rgb(p, q, h);
		b = hue2rgb(p, q, h - 1/3);
	end

	return r, g, b, a;
end

---
-- Converts an RGB color value to HSV. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space. And ported from
-- http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
--
-- This function was not tested yet!
--
-- @param   r  Number       The red color value
-- @param   g  Number       The green color value
-- @param   b  Number       The blue color value
-- @return  h, s, v, a      The HSV representation
--
function Lib.RGBtoHSV(r, g, b, a)
	local hi, lo = max(r, g, b), min(r, g, b);
	local h, s, v = 0, 0, hi;
	
	if hi ~= lo then
		local d = hi - lo;
		s = d / hi;

		if hi == r and g < b then   h = (g - b) / d + 6;
		elseif hi == r then         h = (g - b) / d + 0;
		elseif hi == g then         h = (b - r) / d + 2;
		else                        h = (r - g) / d + 4; -- hi == b
		end
		h = h / 6;
	end

	return h, s, v, a;
end

---
-- Converts an HSV color value to RGB. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space. And ported from
-- http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
--
-- This function was not tested yet!
--
-- @param   h  Number    The hue
-- @param   s  Number    The saturation
-- @param   v  Number    The value
-- @return  r, g, b, a   The RGB representation
--
function Lib.HSVtoRGB(h, s, v, a)
	local r, g, b = 0, 0, 0;

	local i = floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);

	if i == 0 or i == 6 then   return v, t, p, a;
	elseif i == 1 then         return q, v, p, a;
	elseif i == 2 then         return p, v, t, a;
	elseif i == 3 then         return p, q, v, a;
	elseif i == 4 then         return t, p, v, a;
	elseif i == 5 then         return v, p, q, a;
	end

	return r, g, b, a;
end

-- assign the functions to variables local-to-file for better performance
getColor = Lib.getColor;
blendColor = Lib.blendColor;
createColorBlender = Lib.createColorBlender;
isColorTable = Lib.isColorTable;

isColor = Lib.IsColor;
isColorList = Lib.IsColorList;
isColorName = Lib.IsColorName;

Lib.GetColor = getColor;
Lib.BlendColor = blendColor;
Lib.CreateColorBlender = createColorBlender;
Lib.IsColorTable = isColorTable;
Lib.IsBlizColorTable = isBlizColorTable;

--[[ ---------------------------------------------------------------------- ]]--
--[[                            EMBEDDING  STUFF                            ]]--
--[[ ---------------------------------------------------------------------- ]]--
do -- Embedding
	Lib.MixinTargets = Lib.MixinTargets or {};
	local mixins = {
		"GetColor", "BlendColor", "CreateColorBlender", "ModifyLuminosity",
		"IsColor", "IsColorTable", "IsBlizColorTable", "IsColorList", "IsColorName",
		"GetColorForText",
		"Colors", -- contains color constants
	};

	function Lib:Embed(target)
		for _,name in pairs(mixins) do
			target[name] = Lib[name];
		end
		self.MixinTargets[target] = true;
	end

	-- re-embed (if old lib was loaded first)
	if oldminor and MINOR > oldminor then
		for target,_ in pairs(Lib.MixinTargets) do
			Lib:Embed(target);
		end
	end
end
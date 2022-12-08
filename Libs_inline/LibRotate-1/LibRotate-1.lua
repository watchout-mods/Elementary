--[[
 This library supplies methods for rotating textures around a freely defineable
 rotation center.
 
 Basic usage:
  
]]

local MAJOR, MINOR = "LibRotate-1", 3
local Lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not Lib then return; end

local cos, sin, asin, acos, sqrt;
do -- if not run within WoW, these functions are missing
	-- WoW functions work on degrees instead of radians... We prefer performance in WoW here.
	-- TODO: Use radians in input values to get rid of this and use math lib functions instead.
	local pi_180 = math.pi / 180.0;
	local pi_180_inv = 180.0 / math.pi;
	cos = cos or function(v)
		return math.cos(pi_180 * v);
	end;
	sin = sin or function(v)
		return math.sin(pi_180 * v);
	end;
	asin = asin or function(v)
		return math.asin(v) * pi_180_inv;
	end;
	acos = acos or function(v)
		return math.acos(v) * pi_180_inv;
	end;
	sqrt = math.sqrt;
end

local Prototype = {};

function Lib:new()
	local t = {}
	for k,v in pairs(Prototype) do
		if type(v) == "table" then
			t[k] = {};
			for l,w in pairs(v) do
				t[k][l] = w;
			end
		else
			t[k] = v;
		end
	end
	return t;
end

Lib.newTextureRotater = Lib.new;
Lib.newRotateTexture = Lib.newTextureRotater;

Prototype.Texture = {
	Width = 1,
	Height = 1,
	Path = "",
	Mirror = false,
};
Prototype.Origin = {
	X = 0,
	Y = 0,
};
Prototype.Rectangle = {
	Width = 1,
	Height = 1,
	OriginOffsetX = 0,
	OriginOffsetY = 0,
};
Prototype.Angle = 0; -- Angle in degrees
Prototype.Temp = false;

--[[
Sets the origin of the rotation (in pixels when the given width/height in
setTexture was correct).
The Coordinate-Origin is the top left of the image and increases to the
right and bottom.
]]
function Prototype:setOrigin(x, y)
	self.Origin.X = x;
	self.Origin.Y = y;
	
	-- reset temporary calculation values
	self.Temp = false;
end

--- :setRectangle
-- offsetX/Y: Offset of the 
function Prototype:setRectangle(w, h, offsetX, offsetY)
	self.Rectangle.Width = w;
	self.Rectangle.Height = h;
	self.Rectangle.OriginOffsetX = offsetX or 0;
	self.Rectangle.OriginOffsetY = offsetY or 0;
	
	-- reset temporary calculation values
	self.Temp = false;
end

--[[
@param tex
	Texture path
@param w and h
	Use these to set the texture dimensions. This way it should be easier to
	come up with the correct values of Origin, etc.
	Ommit or set to zero to use WoW's relational coordinates.
]]
function Prototype:setTexture(tex, w, h)
	self.Texture.Width = w or 1;
	self.Texture.Height = h or 1;
	self.Texture.Path = tex;
	
	-- reset temporary calculation values
	self.Temp = false;
end

function Prototype:mirror(mirror)
	self.Texture.Mirror = not not mirror; -- converts to true bool
end

function Prototype:getRotationValues(delta)
	if not self.Temp then
		local R1,R2,R3,R4,R1Y,R2Y,R3Y,R4Y;
		local alpha,beta,gamma,epsilon;
		R1 = sqrt(
			(self.Rectangle.OriginOffsetX)^2 +
			(self.Rectangle.OriginOffsetY+self.Rectangle.Height)^2
		);
		R2 = sqrt(
			(self.Rectangle.OriginOffsetX+self.Rectangle.Width)^2 +
			(self.Rectangle.OriginOffsetY+self.Rectangle.Height)^2
		);
		R3 = sqrt(
			(self.Rectangle.OriginOffsetX)^2 +
			(self.Rectangle.OriginOffsetY)^2
		);
		R4 = sqrt(
			(self.Rectangle.OriginOffsetX + self.Rectangle.Width)^2 +
			(self.Rectangle.OriginOffsetY)^2
		);
		R1Y,R2Y,R3Y,R4Y = R1,R2,R3,R4;
		
		alpha, beta, gamma, epsilon = 0, 0, 0, 0;
		if R1 ~= 0 then
			alpha   = acos((self.Rectangle.OriginOffsetX) / (R1));
		end
		if R2 ~= 0 then
			beta    = acos((self.Rectangle.OriginOffsetX+self.Rectangle.Width) / (R2));
		end
		if R3 ~= 0 then
			gamma   = acos((self.Rectangle.OriginOffsetX) / (R3));
		end
		if R4 ~= 0 then
			epsilon = acos((self.Rectangle.OriginOffsetX+self.Rectangle.Width) / (R4));
		end
		self.Temp = {R1,R2,R3,R4,R1Y,R2Y,R3Y,R4Y, alpha, beta, gamma, epsilon};
	end
	if not delta or delta*0 ~= 0 then delta = 0; end
	
	local R1,R2,R3,R4,R1Y,R2Y,R3Y,R4Y,alpha,beta,gamma,epsilon = unpack(self.Temp);
	local ox = self.Origin.X;
	local oy = self.Origin.Y;
	local tw = self.Texture.Width;
	local th = self.Texture.Height;
	--local delta = self.Angle;
	--[[ Points
		P1 o--------o P2
		   |        |
		   |        |
		P3 o--------o P4
	]]
	local P1X, P1Y, P2X, P2Y, P3X, P3Y, P4X, P4Y;
	
	if self.Rectangle.OriginOffsetY + self.Rectangle.Height < 0 then
		P1X = (ox + (cos(      delta - alpha) * R1 )) / tw;
		P2X = (ox + (cos(      delta - beta)  * R2 )) / tw;
		P1Y = (oy - (sin(180 - delta + alpha) * R1Y)) / th;
		P2Y = (oy - (sin(180 - delta + beta)  * R2Y)) / th;
	else
		P1X = (ox + (cos(delta + alpha) * R1 )) / tw;
		P2X = (ox + (cos(delta + beta)  * R2 )) / tw;
		P1Y = (oy - (sin(delta + alpha) * R1Y)) / th;
		P2Y = (oy - (sin(delta + beta)  * R2Y)) / th;
	end

	if self.Rectangle.OriginOffsetY < 0 then
		P3X = (ox + (cos(      delta - gamma  ) * R3 )) / tw;
		P4X = (ox + (cos(      delta - epsilon) * R4 )) / tw;
		P3Y = (oy - (sin(180 - delta + gamma  ) * R3Y)) / th;
		P4Y = (oy - (sin(180 - delta + epsilon) * R4Y)) / th;
	else
		P3X = (ox + (cos(delta + gamma  ) * R3)) / tw;
		P4X = (ox + (cos(delta + epsilon) * R4)) / tw;
		P3Y = (oy - (sin(delta + gamma  ) * R3Y)) / th;
		P4Y = (oy - (sin(delta + epsilon) * R4Y)) / th;
	end
	--[[
	print(R1, R2, R3, R4);
	print("alpha:", alpha, "beta:", beta);
	print("P1", "(", P1X, P1Y, ")");
	print("P2", "(", P2X, P2Y, ")");
	print("P3", "(", P3X, P3Y, ")");
	print("P4", "(", P4X, P4Y, ")");
	]]
	-- obj:SetTexCoord(ULx,ULy,LLx,LLy,URx,URy,LRx,LRy); -- blizz function desc
	-- obj:SetTexCoord(P1x,P1y,P3x,P3y,P2x,P2y,P4x,P4y); -- with my points
	if self.Texture.Mirror then
		return P2X, P2Y, P4X, P4Y, P1X, P1Y, P3X, P3Y;
	else
		return P1X, P1Y, P3X, P3Y, P2X, P2Y, P4X, P4Y;
	end
end
-- /run amhud.Bar1.rt:getRotationValues(90)


-- Below is WIP for 1.1
local Lib2 = {};
local ev = [[return function(delta)
	local CosDelta = cos(delta);
	local SinDelta = sin(delta);
	--local P1X = (ox + (cos(alpha+delta) * R1)) / tw;
	local P1X = (ox + (cos(alpha+delta) * R1)) / tw;
	-- | cos(alpha+delta) = $CosAlpha$*CosDelta-$SinAlpha$*SinDelta
	-- (ox + (CosAlpha*x - SinAlpha*y) * R1) / tw
	-- (ox + CosAlpha*x*R1 - SinAlpha*y*R1) / tw
	-- ox/tw + x*(CosAlpha*R1/tw) - y*(SinAlpha*R1/tw)
	-- C0A = ox/tw
	-- C0B = oy/th
	-- C1A = CosAlpha*R1/tw
	-- C1B = SinAlpha*R1/tw
	local P1X = $C0A$ + CosDelta*$C1A$ - SinDelta*$C1B$
	
	local P1Y = (oy - (sin(alpha+delta) * R1)) / th;


	local P2X = (ox + (cos(beta+delta) * R2)) / tw;
	local P2Y = (oy - (sin(beta+delta) * R2)) / th;

	local P3X = ($C0A$ + (CosDelta * R3)/tw);
	local P3Y = ($C0B$ - (SinDelta * R3)/th);
	local P4X = ($C0A$ + (CosDelta * R4)/tw);
	local P4Y = ($C0B$ - (SinDelta * R4)/th);
	-- obj:SetTexCoord(ULx,ULy,LLx,LLy,URx,URy,LRx,LRy); -- blizz function desc
	-- obj:SetTexCoord(P1x,P1y,P3x,P3y,P2x,P2y,P4x,P4y); -- with my points
	return $RET$;
end]]


function Lib2:New()
	local Values = {
		Origin_X = 0,
		Origin_Y = 0,
		Rect_Width = 0,
		Rect_Height = 0,
		Rect_OriginOffsetX = 0,
		Rect_OriginOffsetY = 0,
		Texture_Width = 0,
		Texture_Height = 0,
	}
	local grv, grvp;
	local function GetRotationValuesUnparsed(delta)
		local R1,R2,R3,R4, alpha, beta;
		Values.R1 = sqrt((Values.Rect_OriginOffsetX)^2 + (Values.Rect_Height)^2);
		Values.R2 = sqrt((Values.Rect_OriginOffsetX+Values.Rect_Width)^2 + (Values.Rect_Height)^2);
		Values.R3 = Values.Rect_OriginOffsetX;
		Values.R4 = Values.R3 + Values.Rect_Width;
		Values.Alpha = asin(self.Rect_Height / R1);
		Values.Beta  = asin(self.Rect_Height / R2);
		Values.CosAlpha = cos(Values.Alpha);
		Values.SinAlpha = sin(Values.Alpha);
		Values.CosBeta  = cos(Values.Beta);
		Values.SinBeta  = sin(Values.Beta);

		if Values.Texture_Mirror then
			Values.RET = "P2X, P2Y, P4X, P4Y, P1X, P1Y, P3X, P3Y";
		else
			Values.RET = "P1X, P1Y, P3X, P3Y, P2X, P2Y, P4X, P4Y";
		end
		local ox = self.Origin.X;
		local oy = self.Origin.Y;
		local tw = self.Texture.Width;
		local th = self.Texture.Height;
		--local delta = self.Angle;
		--  Points
		--	P1 +--------+ P2
		--	   |        |
		--	   |        |
		--	P3 +--------+ P4
		
	end
	
	local function SetOrigin(x, y)
		Values.Origin_X = x;
		Values.Origin_Y = y;
		
		-- reset temporary calculation values
		grvp = GetRotationValuesUnparsed;
	end
	
	---
	-- Rotater:SetRectangle(w, h, offsetX, offsetY)
	-- @param w This (and h) is used to set the dimensions of the "viewport"
	--          rectangle for the texture.
	-- @param h see w
	-- @param offsetX (and offsetY) is used to define how far away the rectangle
	--          is from the center point of the rotation. The offset values are
	--          relative to the lower left corner of the rectangle and values
	--          grow in upper-right direction.
	-- @param offsetY see offsetX
	local function SetRectangle(w, h, offsetX, offsetY)
		Values.Rectangle_Width = w;
		Values.Rectangle_Height = h;
		Values.Rectangle_OriginOffsetX = offsetX or 0;
		Values.Rectangle_OriginOffsetY = offsetY or 0;
		
		-- reset temporary calculation values
		grvp = GetRotationValuesUnparsed;
	end
	
	---
	-- Rotater:SetTextureDimensions(w, h)
	-- @param w see h
	-- @param h Use w and h to set the texture dimensions. This way it should be
	--          easier to come up with the correct values of Origin, etc. Ommit
	--          or set to zero to use WoW's relational coordinates.
	--          The dimensions do *not* have to correspond to any real pixel
	--          sizes. They do not even have to result in the correct aspect
	--          ratio - however, it is strongly suggested that they do.
	local function SetTextureDimensions(w, h)
		Values.Texture_Width = w or 1;
		Values.Texture_Height = h or 1;
		
		-- reset temporary calculation values
		grvp = GetRotationValuesUnparsed;
	end
	
	---
	-- Rotater:Mirror(mirror)
	-- @param mirror boolean whether to mirror the texture along the x axis
	local function Mirror(mirror)
		Values.Texture_Mirror = (mirror == true); -- converts to true bool

		-- reset temporary calculation values
		grvp = GetRotationValuesUnparsed;
	end

	local grv = [[function GetRotationValues(delta)
		if not delta or delta*0 ~= 0 then delta = 0; end

		local R1,R2, alpha, beta;
		R1 = sqrt(
			(self.Rectangle.OriginOffsetX)^2 +
			(self.Rectangle.Height)^2
		);
		R2 = sqrt(
			(self.Rectangle.OriginOffsetX+self.Rectangle.Width)^2 +
			(self.Rectangle.Height)^2
		);
		alpha = asin(self.Rectangle.Height / R1);
		beta  = asin(self.Rectangle.Height / R2);
		self.Temp = {R1, R2, alpha, beta};
		
		local R1, R2, alpha, beta = unpack(self.Temp);
		local R3 = self.Rectangle.OriginOffsetX;
		local R4 = R3 + self.Rectangle.Width;
		local ox = self.Origin.X;
		local oy = self.Origin.Y;
		local tw = self.Texture.Width;
		local th = self.Texture.Height;
		--local delta = self.Angle;
		--  Points
		--	P1 +--------+ P2
		--	   |        |
		--	   |        |
		--	P3 +--------+ P4
		
		local cosdelta = cos(delta);
		local sindelta = sin(delta);
		local P1X = (ox + (cos(alpha+delta) * R1)) / tw;
		local P1Y = (oy - (sin(alpha+delta) * R1)) / th;
		local P2X = (ox + (cos(beta+delta) * R2)) / tw;
		local P2Y = (oy - (sin(beta+delta) * R2)) / th;
		local P3X = (ox + (cos(delta) * R3)) / tw;
		local P3Y = (oy - (sin(delta) * R3)) / th;
		local P4X = (ox + (cos(delta) * R4)) / tw;
		local P4Y = (oy - (sin(delta) * R4)) / th;
		-- obj:SetTexCoord(ULx,ULy,LLx,LLy,URx,URy,LRx,LRy); -- blizz function desc
		-- obj:SetTexCoord(P1x,P1y,P3x,P3y,P2x,P2y,P4x,P4y); -- with my points
		if self.Texture.Mirror then
			return P2X, P2Y, P4X, P4Y, P1X, P1Y, P3X, P3Y;
		else
			return P1X, P1Y, P3X, P3Y, P2X, P2Y, P4X, P4Y;
		end
	end]]
	
end

local function CreateLibRotateTester()
	local LibRotate = LibStub("LibRotate-1");

	local rotation = 0;
	local origin_x, origin_y = 0,0;

	--[[
	local texwidth, texheight = 512, 512;
	local rect_width,rect_height,rect_offsetx,rect_offsety = texwidth,texheight,0,0; 
	local testtex = "Interface\\Addons\\THUD\\Textures\\LRT-Circle";
	local rotater = LibRotate:new();
	rotater:setTexture("", texwidth, texheight);
	rotater:setOrigin(256, 256);
	rotater:setRectangle(512, 512, 256, -256);
	]]
	local texwidth, texheight = 50, 100;
	local rect_width,rect_height,rect_offsetx,rect_offsety = texwidth,texheight,0,0; 
	local testtex = "Interface\\Addons\\THUD\\Textures\\Half-Ring-1";
	local rotater = LibRotate:new();
	rotater:setTexture("", texwidth, texheight);
	rotater:setOrigin(5, 50);
	rotater:setRectangle(50, 50, 0, -0);
	
	local f = CreateFrame("frame");
	f:SetBackdrop({ 
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16, 
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	});
	f:SetWidth(300);
	f:SetHeight(300);
	f:SetPoint("CENTER",UIParent);
	f:EnableMouse(true);
	f:CreateTitleRegion();
	f:GetTitleRegion():SetAllPoints(f);

	local tex = f:CreateTexture()
	tex:SetTexture(testtex);
	tex:SetDrawLayer("OVERLAY");
	tex:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10);
	tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10);
	
	local close = CreateFrame("button");
	close:SetWidth(28);
	close:SetHeight(28);
	close:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -5, 10);
	close:SetNormalTexture("Interface\\BUTTONS\\CancelButton-Up");
	close:SetPushedTexture("Interface\\BUTTONS\\CancelButton-Down");
	close:SetHighlightTexture("Interface\\BUTTONS\\CancelButton-Highlight", "ADD");
	close:SetScript("OnClick", function() f:Hide(); end);
	close:EnableMouse(true);
	close:Raise();

	-- explanatory frame
	local tf = CreateFrame("frame");
	tf:SetBackdrop({ 
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16, 
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	});
	tf:SetWidth(300);
	tf:SetHeight(300);
	tf:SetPoint("TOPLEFT", f, "BOTTOMLEFT");
	tf:EnableMouse(false);
	
	local tftexw = tf:GetWidth()/3;
	local tftexh = tf:GetHeight()/3;
	
	local tt = tf:CreateTexture();
	tt:SetDrawLayer("BORDER");
	tt:SetPoint("CENTER");
	tt:SetWidth(tf:GetWidth()/3)
	tt:SetHeight(tf:GetHeight()/3)
	tt:SetTexture(testtex);
	
	local psize = 5;
	local pTL = tf:CreateTexture();
	pTL:SetTexture(1, 0, 0)
	pTL:SetWidth(psize);
	pTL:SetHeight(psize);
	local pTR = tf:CreateTexture();
	pTR:SetTexture(0, 1, 0)
	pTR:SetWidth(psize);
	pTR:SetHeight(psize);
	local pBR = tf:CreateTexture();
	pBR:SetTexture(0, 0, 1)
	pBR:SetWidth(psize);
	pBR:SetHeight(psize);
	local pBL = tf:CreateTexture();
	pBL:SetTexture(1, 1, 1)
	pBL:SetWidth(psize);
	pBL:SetHeight(psize);
	local zero = tf:CreateTexture();
	zero:SetTexture()
	zero:SetWidth(psize);
	zero:SetHeight(psize);
	zero:SetPoint("CENTER", tt, "TOPLEFT")
	
	local function update()
		local ULx,ULy,LLx,LLy,URx,URy,LRx,LRy = rotater:getRotationValues(rotation);
		rotater:setOrigin(origin_x, origin_y);
		rotater:setRectangle(rect_width,rect_height,rect_offsetx,rect_offsety);
		tex:SetTexCoord(rotater:getRotationValues(rotation));
		
		pTL:ClearAllPoints();
		pTL:SetPoint("CENTER", tt, "TOPLEFT", ULx*tftexw, -ULy*tftexh);
		pTR:ClearAllPoints();
		pTR:SetPoint("CENTER", tt, "TOPLEFT", URx*tftexw, -URy*tftexh);
		pBR:ClearAllPoints();
		pBR:SetPoint("CENTER", tt, "TOPLEFT", LRx*tftexw, -LRy*tftexh);
		pBL:ClearAllPoints();
		pBL:SetPoint("CENTER", tt, "TOPLEFT", LLx*tftexw, -LLy*tftexh);
	end
	
	-- modifier frame
	local optionstable = {
		type = "group",
		name = "LibRotate Tester",
		childGroups = "tab",
		args = {
			rotation = {
				name = "Rotation",
				type = "range", step = 1,
				order = 1,
				min = -360,
				max = 360,
				width = "full",
				set = function(info,val)
					val = tonumber(val);
					rotation = val;
					update();
				end,
				get = function() return rotation or 0; end,
			},
			originx = {
				name = "Origin X",
				type = "range", step = 1,
				order = 2,
				min = -texwidth,
				max = texwidth,
				set = function(info,val)
					val = tonumber(val);
					origin_x = val;
					update();
				end,
				get = function() return origin_x or 0; end,
			},
			originy = {
				name = "Origin Y",
				type = "range", step = 1,
				order = 3,
				min = -texheight,
				max = texheight,
				set = function(info,val)
					val = tonumber(val);
					origin_y = val;
					update();
				end,
				get = function() return origin_y or 0; end,
			},
			rectangle = {
				name = "Selection Rectangle", order = 9, type = "group",
				inline = true,
				args = {
					rectwidth = {
						name = "Rectangle Width",
						type = "range", step = 1,
						order = 1,
						min = -texwidth,
						max = texwidth,
						set = function(info,val)
							val = tonumber(val);
							rect_width = val;
							update();
						end,
						get = function() return rect_width or 0; end,
					},
					rectheight = {
						name = "Rectangle Height",
						type = "range", step = 1,
						order = 2,
						min = -texheight,
						max = texheight,
						set = function(info,val)
							val = tonumber(val);
							rect_height = val;
							update();
						end,
						get = function() return rect_height or 0; end,
					},
					rectox = {
						name = "Rectangle Offset X",
						type = "range", step = 1,
						order = 3,
						min = -texwidth,
						max = texwidth,
						set = function(info,val)
							val = tonumber(val);
							rect_offsetx = val;
							update();
						end,
						get = function() return rect_offsetx or 0; end,
					},
					rectoy = {
						name = "Rectangle Offset Y",
						type = "range", step = 1,
						order = 4,
						min = -texheight,
						max = texheight,
						set = function(info,val)
							val = tonumber(val);
							rect_offsety = val;
							update();
						end,
						get = function() return rect_offsety or 0; end,
					},
				},
			},
			values = {
				order = 10, type = "description",
				name = function()
					local names = {"R1","R2","R3","R4","R1Y","R2Y","R3Y","R4Y",
						"alpha", "beta", "gamma", "epsilon"};
					local out = {"Calculation values|n"};
					for k,v in ipairs(rotater.Temp or {}) do
						out[#out+1] = names[k];
						out[#out+1] = ":";
						out[#out+1] = v;
						out[#out+1] = ";|n ";
					end
					
					return strconcat(unpack(out));
				end
			},
		},
	};

	local AceGUI = LibStub("AceGUI-3.0")
	local AceConfig = LibStub("AceConfig-3.0");
	local AceConfigDialog = LibStub("AceConfigDialog-3.0");
	-- Create a container frame
	local cf = AceGUI:Create("Frame")
	cf:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	cf:SetTitle("AceGUI-3.0 Example")
	cf:SetStatusText("Status Bar")
	cf:SetLayout("Flow")
	-- add the config table
	AceConfig:RegisterOptionsTable("LRT", optionstable);
	AceConfigDialog:Open("LRT", cf);
	cf:SetPoint("TOPLEFT", f, "TOPRIGHT");
	cf:SetWidth(400);
	cf:SetHeight(400);
end
do
	SlashCmdList["LRT"] = CreateLibRotateTester;
	SLASH_LRT1 = "/lrt";
end
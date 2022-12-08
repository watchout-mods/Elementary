describe("LibRotate", function()
	local Lib = require("spec/_setup");

	local tex_path = "Interface\\Addons\\Elementary\\Textures\\Half-Ring-1";
	local tex_width, tex_height = 50, 100;
	local rect_width, rect_height, rect_offsetx, rect_offsety = tex_width, tex_height, 0, 0; 

	local function dbg(...)
		local params = { ... };
		for i = 1, #params do
			params[i] = ("% .3f"):format(params[i]);
		end
		print("VALUES", unpack(params));
	end

	it("methods are called without errors", function()
		local rotater = Lib:new();
		rotater:setTexture(tex_path, tex_width, tex_height);
		rotater:setOrigin(5, 50);
		rotater:setRectangle(50, 50, 0, -0);

		for rot = 0, 90, 9  do
			dbg(rot, rotater:getRotationValues(rot))
		end
	end)
end)
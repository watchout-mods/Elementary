local MODULE, MAJOR, addon = "_Options", ...;
local Module = addon:NewModule(MODULE) or error("Can not create module");

local Options, GUICategory

if true then return end
local L = LibStub("AceLocale-3.0"):GetLocale(MAJOR, true);


function Module:OnInitialize()
	local AceConfig = LibStub("AceConfig-3.0");
	local AceConfigDialog = LibStub("AceConfigDialog-3.0");

	AceConfig:RegisterOptionsTable(MAJOR, Options);
	GUICategory = AceConfigDialog:AddToBlizOptions(MAJOR, nil, nil);
end

Options = {
	type = "group",
	name = L.ADDONNAME,
	desc = L.ADDONDESC,
	childGroups = "tab",
	args = {
		gui = {
			name = "Config dialog",
			order = 1,
			guiHidden = true,
			dialogHidden = true,
			type = "execute",
			func = function() InterfaceOptionsFrame_OpenToCategory(GUICategory); end,
		},
		enable = {
			name = L.CFG_ENABLE,
			desc = L.CFG_ENABLE_DESC,
			order = 1,
			type = "toggle",
			set = function(info,val)
				if val then
					addon:Enable();
				else
					addon:Disable();
				end
			end,
			get = function()
				return addon:IsEnabled();
			end,
		},
		general = {
			name = L.CFG_GENERAL,
			desc = L.CFG_GENERAL_DESC,
			order = 2,
			type = "group",
			args = {
			},
		},
		modules = {
			name = L.CFG_MODULES,
			desc = L.CFG_MODULES_DESC,
			order = 3,
			type = "group",
			args = {
			},
		},
		sources = {
			name = L.CFG_DATASRC,
			desc = L.CFG_DATASRC_DESC,
			order = 3,
			type = "group",
			args = {
			},
		},
	},
};

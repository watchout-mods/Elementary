local MODULE, MAJOR, addon = "Options", ...;
local Module = addon:NewModule(MODULE) or error("Can not create module");

local Options, GUICategory

do -- Create english locale
	local L = LibStub("AceLocale-3.0"):NewLocale(MAJOR, "enUS", true);
	L.ADDONNAME = MAJOR;
	L.ADDONDESC = "This add-on provides a simplistic clean curved HUD experience.";
	L.ENABLE = "Enable";
	L.CFG_ENABLE_DESC = "Enable add-on";
	L.CFG_PLAYER = "Player";
	L.CFG_PLAYER_DESC = "Player display";
	L.CFG_HEALTH = "Health";
	L.CFG_HEALTH_DESC = "Health";
	L.CFG_HEALTH_STRING = "Health text format";
	L.CFG_HEALTH_STRING_DESC = "Defines the formatting of the health text";
	L.CFG_POWER = "Power";
	L.CFG_POWER_DESC = "Power";
	L.CFG_POWER_STRING = "Power text format";
	L.CFG_POWER_STRING_DESC = "Defines the formatting of the current power's text";
	L.CFG_ALPHA         = "Alpha";
	L.CFG_ALPHA_DESC    = "Alpha";
	L.CFG_ALPHA_COMBAT  = "Combat alpha";
	L.CFG_ALPHA_TARGET  = "Targeting alpha";
	L.CFG_ALPHA_POWER   = "Power alpha";
	L.CFG_ALPHA_CASTING = "Casting alpha";
	L.CFG_ALPHA_IDLE    = "Idle alpha";
	L.CFG_ALPHA_COMBAT_DESC  = "HUD alpha value (visibility) when you are in combat";
	L.CFG_ALPHA_TARGET_DESC  = "HUD alpha value (visibility) if a target is selected";
	L.CFG_ALPHA_POWER_DESC   = "HUD alpha value (visibility) when your current power is not full and not exactly zero";
	L.CFG_ALPHA_CASTING_DESC = "HUD alpha value (visibility) when casting";
	L.CFG_ALPHA_IDLE_DESC    = "The GUI will not go below this alpha value.";
end

local L = LibStub("AceLocale-3.0"):GetLocale(MAJOR, true);

function Module:OnInitialize()
	local AceConfig = LibStub("AceConfig-3.0");
	local AceConfigDialog = LibStub("AceConfigDialog-3.0");

	AceConfig:RegisterOptionsTable(MAJOR, Options);
	GUICategory = AceConfigDialog:AddToBlizOptions(MAJOR, nil, nil);
	Options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon:GetConfig());
end

Options = {
	type = "group",
	name = L.ADDONNAME,
	desc = L.ADDONDESC,
	childGroups = "tab",
	args = {
		enable = {
			name = L.ENABLE,
			desc = L.CFG_ENABLE_DESC,
			order = 1, type = "toggle",
			guiHidden = true,
			dialogHidden = true,
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
		player = {
			name = L.CFG_PLAYER,
			desc = L.CFG_PLAYER_DESC,
			order = 2, type = "group",
			args = {
				alpha = {
					name = L.CFG_ALPHA,
					desc = L.CFG_ALPHA_DESC,
					order = 1, type = "group", inline = true,
					args = {
						alpha_combat = {
							name = L.CFG_ALPHA_COMBAT,
							desc = L.CFG_ALPHA_COMBAT_DESC,
							order =  1, type = "range",
							min = 0, max = 1, bigStep = .01, isPercent = true,
							set = function(info,val)
								addon:SetOption("ALPHA_COMBAT", val);
							end,
							get = function()
								return addon:GetOption("ALPHA_COMBAT");
							end,
						},
						alpha_target = {
							name = L.CFG_ALPHA_TARGET,
							desc = L.CFG_ALPHA_TARGET_DESC,
							order =  2, type = "range",
							min = 0, max = 1, bigStep = .01, isPercent = true,
							set = function(info,val)
								addon:SetOption("ALPHA_TARGET", val);
							end,
							get = function()
								return addon:GetOption("ALPHA_TARGET");
							end,
						},
						alpha_casting = {
							name = L.CFG_ALPHA_CASTING,
							desc = L.CFG_ALPHA_CASTING_DESC,
							order =  3, type = "range",
							min = 0, max = 1, bigStep = .01, isPercent = true,
							set = function(info,val)
								addon:SetOption("ALPHA_CASTING", val);
							end,
							get = function()
								return addon:GetOption("ALPHA_CASTING");
							end,
						},
						alpha_power = {
							name = L.CFG_ALPHA_POWER,
							desc = L.CFG_ALPHA_POWER_DESC,
							order =  4, type = "range",
							min = 0, max = 1, bigStep = .01, isPercent = true,
							set = function(info,val)
								addon:SetOption("ALPHA_POWER", val);
							end,
							get = function()
								return addon:GetOption("ALPHA_POWER");
							end,
						},
						alpha_idle = {
							name = L.CFG_ALPHA_IDLE,
							desc = L.CFG_ALPHA_IDLE_DESC,
							order =  5, type = "range",
							min = 0, max = 1, bigStep = .01, isPercent = true,
							set = function(info,val)
								addon:SetOption("ALPHA_IDLE", val);
							end,
							get = function()
								return addon:GetOption("ALPHA_IDLE");
							end,
						},
					},
				},
				health = {
					name = L.CFG_HEALTH,
					desc = L.CFG_HEALTH_DESC,
					order = 1, type = "group", inline = true,
					args = {
						text_health = {
							name = L.CFG_HEALTH_STRING,
							desc = L.CFG_HEALTH_STRING_DESC,
							disabled = true,
							order = 10, type = "select",
							values = {
								value = "%d",
								percent = "%d%%",
								value_percent = "%d (%d%%)",
								percent_value = "(%d%%) %d",
							},
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
					},
				},
				power = {
					name = L.CFG_POWER,
					desc = L.CFG_POWER_DESC,
					order = 1, type = "group", inline = true,
					args = {
						text_power = {
							name = L.CFG_POWER_STRING,
							desc = L.CFG_POWER_STRING_DESC,
							disabled = true,
							order = 11, type = "select",
							values = {
								value_percent = ""
							},
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
					},
				},
			},
		},
	},
};


local OptionsMenu = {}

local Locale = {
	["OptionsMenu"] = "OptionsMenu",
}
OptionsMenu.Locale = Locale
SloppyPlus:RegisterModule(OptionsMenu, "options", OptionsMenu.Locale["OptionsMenu"])

local options = {
	name = "SloppyPlus",
	handler = SloppyPlus,
	type = "group",
	args = {
		general = {
			type = "group",
			childGroups = "tab",
			name = "General",
		}
	}
}
OptionsMenu.options = options

options.args.general.args = {
	general = {
		order = 1,
		type = "group",
		name = "General",
	},
	cvar_support = {
		order = 2,
		type = "group",
		name = "CVar Support",
	}
}
options.args.general.args.cvar_support.args = {
	nameplates = {
		order = 2,
		type = "group",
		inline = true,
		name = "Nameplate Distance",
	},
	console_errors = {
		order = 3,
		type = "group",
		inline = true,
		name = "Lua Errors",
	},
}

function OptionsMenu:Initialize()
	-- General General
	options.args.general.args.general.args = {
		reagent_alert = {
			order = 1,
			type = "toggle",
			name = "Enable Reagent Alert",
			set = function(info, value)
				print(info, value)
				self.defaults.use_reagent_alert = value
			end,
			get = function(...)
				return self.defaults.use_reagent_alert
			end,
		}
	}
	-- General CVAR Support Settings
	options.args.general.args.cvar_support.args.cvar_allow = {
		order = 1,
		type = "toggle",
		name = "Enable CVAR Overriding",
		desc = "Enable/Disable the feature controls in this menu",
		set = function(info, value)
			self.defaults.cvars.enable_cvar_overrides = value
		end,
		get = function(...)
			return self.defaults.cvars.enable_cvar_overrides
		end,
	}
	options.args.general.args.cvar_support.args.nameplates.args = {
		allow_nameplated = {
			order = 1,
			type = "toggle",
			name = "Enable",
			set = function(info, value)
				self.defaults.cvars.allow_nameplated = value
			end,
			get = function(...)
				if not self.defaults.cvars.enable_cvar_overrides then return false end
				return self.defaults.cvars.allow_nameplated
			end,
		},
		nameplate_distance = {
			-- nameplateMaxDistance
			order = 2,
			name = "Nameplate Distance",
			type = "range",
			max = 41,
			min = 20,
			step = 1,
			get = function(info, value)
				return self.defaults.cvars.nameplate_max_distance
			end,
			set = function(info, value)
				self.defaults.cvars.nameplate_max_distance = value
			end,
		}
	}
	options.args.general.args.cvar_support.args.console_errors.args = {
		-- scriptErrors
		allow_errors = {
			order = 1,
			type = "toggle",
			name = "Error Control",
			desc = "Enable/Disable LUA Error Controls",
			set = function(info, value)
				self.defaults.cvars.console_error_control = value
			end,
			get = function(...)
				if not self.defaults.cvars.enable_cvar_overrides then return false end
				return self.defaults.cvars.console_error_control
			end,
		},
		error_controls = {
			order = 2,
			type = "select",
			values = {["disable_arena"] = "Disable in Arena", ["disable_always"] = "Disable Always", ["enable_always"] = "Enable Always"},
			name = "LUA Error Configuration",
			set = function(info, value)
				if not self.defaults.cvars.enable_cvar_overrides or not self.defaults.cvars.console_error_control then
					return
				end
				self.defaults.cvars.console_error_zones = value
			end,
			get = function(...)
				if not self.defaults.cvars.enable_cvar_overrides or not self.defaults.cvars.console_error_control then
					return ""
				end
				return self.defaults.cvars.console_error_zones
			end,
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SloppyPlus_options", self.options)
end

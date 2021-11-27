-- https://wowpedia.fandom.com/wiki/Using_the_AddOn_namespace
-- addonName, addonTable = ...
-- addonName, SloppyPlus = ...
SloppyPlus = LibStub("AceAddon-3.0"):NewAddon("SloppyPlus", "AceConsole-3.0") -- , "AceEvent-3.0")
SloppyPlus.modules = {}


SloppyPlus.sessionInfo = {
	["login_time"] = nil,
	["playerClassIndex"] = nil,
	['playerLevel'] = nil,
	["playerFaction"] = nil,
}
-- Track the classes in the game.
SloppyPlus.classTable = {} -- i.e: [4] = {[className] = "Rogue", ["classFile"] = "ROGUE"}
SloppyPlus.required_reagents = nil

local SLocale = SloppyPlus.Locale
SloppyPlus.dbRevisionClassic = 4
SloppyPlus.playerUnit = "player"


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


function SloppyPlus:Initialize()
	if self.defaults then return end
	self.defaults = {
		use_reagent_alert = true,

		cvars = {
			-- Main CVAR enable/disable feature.
			enable_cvar_overrides = true,
			-------------------
			-- Child CVAR Settings.
			allow_nameplated = true,
			-- SetCVar("nameplateMaxDistance", 41)
			nameplate_max_distance = 41,
			-- SetCVar("scriptErrors", 0)
			console_error_control = false,
			console_error_zones = "Disabled",

		},
	}
	-- Keep our own internal "Class" table, Don't trust Blizzard API.
	-- Some tables in TBC have deathknight/monk/demonhunter wtf.
	for classIndex=1, GetNumClasses() do
		local className, classFile, classID = GetClassInfo(classIndex)
		if className ~= nil and classFile ~= nil and classID ~= nil then
			self.classTable[classID] = {    --Ex:  4
				["className"] = className,  --     "Rogue"
				["classFile"] = classFile,  --     "ROGUE"
			}
		end
	end
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

	-- Initialize DB
	-- self.db = LibStub:GetLibrary("AceDB-3.0"):New("SloppyPlusDB", self.defaults, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SloppyPlus_options", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SloppyPlus_options", "SloppyPlus")
	-- self.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileReset", "ProfileReset")
	for _, module in pairs(self.modules) do
		module:Initialize()
		-- Give every submodule a reference to important data.
		module.defaults = self.defaults
		module.sessionInfo = self.sessionInfo
		module.classTable = self.classTable
	end
end

function SloppyPlus:PreInitialize()
	self.sessionInfo.playerClassIndex = select(3, UnitClass("player"))
	self.sessionInfo.playerLevel = UnitLevel("player")
	self.sessionInfo.playerFaction =  UnitFactionGroup("player") -- "Alliance" or "Horde"
end

function SloppyPlus:RegisterModule(module, key, localized_name)
	-- Every submodule must call RegisterModule to hook into framework.
	if self.modules[key] then return end
	self.modules[key] = module
	self.modules[key].key = key
	self.modules[key].localizedName = localized_name
end

--[[
On PLAYER_ENTERING_WORLD check
IsInInstance()

If so run:
RequestRaidInfo()

then wait for the event:
UPDATE_INSTANCE_INFO

Then call:
GetInstanceInfo()
]]--

function SloppyPlus:ZoneInfo()
	-- local isArena, isRegistered = IsActiveBattlefieldArena()
	-- local instanceType = select(2, GetInstanceInfo())
	local instanceType = select(2, IsInInstance())
end

function SloppyPlus:EnteringWorldTasks()
	if self.defaults.cvars.enable_cvar_overrides then
		if self.defaults.cvars.allow_nameplated then
			SetCVar("nameplateMaxDistance", self.defaults.cvars.nameplate_max_distance)
		end
		-- if self.defaults.cvars.console_error_control then
		-- 	   SetCVar("scriptErrors", 0)
		-- end
	end
end


local primary_frame = CreateFrame("Frame")
primary_frame:ClearAllPoints()
primary_frame:Hide()

primary_frame:RegisterEvent("PLAYER_LOGIN")
primary_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
primary_frame:RegisterEvent("UPDATE_INSTANCE_INFO")
primary_frame:SetScript("OnEvent", function(self, event, ...)
	if event == 'PLAYER_LOGIN' then
		-- We note the time that we logged in.
		SloppyPlus.sessionInfo.login_time = GetTime()
		SloppyPlus:PreInitialize()
		SloppyPlus:Initialize()
		self:UnregisterEvent("PLAYER_LOGIN")
	elseif event == 'PLAYER_ENTERING_WORLD' then
		RequestRaidInfo()
		SloppyPlus:EnteringWorldTasks()
	elseif event == 'UPDATE_INSTANCE_INFO' then
		SloppyPlus:ZoneInfo()
	end
end)
SloppyPlus.primary_frame = primary_frame


-- primary_frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- primary_frame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")

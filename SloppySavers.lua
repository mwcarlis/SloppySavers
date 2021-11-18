-- https://wowpedia.fandom.com/wiki/Using_the_AddOn_namespace
-- addonName, addonTable = ...
-- addonName, SloppyPlus = ...
SloppyPlus = LibStub("AceAddon-3.0"):NewAddon("SloppyPlus", "AceConsole-3.0") -- , "AceEvent-3.0")


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
}


function SloppyPlus:Initialize()
	if self.defaults then return end
	self.defaults = {
		reagent_alert = false,

		cvars = {
			-- Main CVAR enable/disable feature.
			enable_cvar_overrides = true,
			-- Child CVAR Settings.
			allow_nameplated = true,
			nameplate_max_distance = 41,
			hide_console_errors = false,
			-- SetCVar("nameplateMaxDistance", 41)
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
				self.defaults.reagent_alert = value
			end,
			get = function(...)
				return self.defaults.reagent_alert
			end,
		}
	}
	-- General CVAR Support Settings
	options.args.general.args.cvar_support.args.cvar_allow = {
		order = 1,
		type = "toggle",
		name = "Enable CVAR Overriding",
		desc = "Enable/Disable the feature controls in this menu.",
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
	options.args.general.args.cvar_support.args.console_errors = {
		-- scriptErrors
		order = 3,
		type = "toggle",
		name = "Hide Lua Errors",
		set = function(info, value)
			self.defaults.cvars.hide_console_errors = value
		end,
		get = function(...)
			if not self.defaults.cvars.enable_cvar_overrides then return false end
			return self.defaults.cvars.hide_console_errors
		end,
	}

	-- Initialize DB
	-- self.db = LibStub:GetLibrary("AceDB-3.0"):New("SloppyPlusDB", self.defaults, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SloppyPlus_options", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SloppyPlus_options", "SloppyPlus")
	-- self.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileReset", "ProfileReset")
end

function SloppyPlus:GetMessage(info)
	print('get message: ', info)
end

function SloppyPlus:SetMessage(info, values)
	print('set message: ', info, values)
end



function SloppyPlus:DetectPlayer()
	self.sessionInfo.playerClassIndex = select(3, UnitClass("player"))
	self.sessionInfo.playerLevel = UnitLevel("player")
	self.sessionInfo.playerFaction =  UnitFactionGroup("player") -- "Alliance" or "Horde"

	self.required_reagents = {
		["ROGUE"] = {
			["Flash Powder"] = {
				["minimum_count"] = 50,
			},
			["Wound Poison V"] = {
				["minimum_count"] = 10,
			},
			["Crippling Poison II"] = {
				["minimum_count"] = 10,
			},
			["Mind-numbing Poison III"] = {
				["minimum_count"] = 0,
			},
			-- Common Items
			["Greater Rune of Warding"] = {},
		},
		["WARLOCK"] = {
			["Soul Shard"] = {},
			-- Common Items
			["Greater Rune of Warding"] = {},
			["Star's Tears"] = {
				["minimum_count"] = 50,
			},
		},
		["PRIEST"] = {
			-- Priest Candles and shit
			-- Common Items.
			["Greater Rune of Warding"] = {},
			["Star's Tears"] = {
				["minimum_count"] = 10,
			},
		}
	}
	for k, _ in pairs(self.required_reagents) do
		self.required_reagents[k]['Heavy Netherweave Bandage'] = {
			["minimum_count"] = 50,
		}
	end
end

function SloppyPlus:ZoneInfo()
-- local isArena, isRegistered = IsActiveBattlefieldArena()
end

function SloppyPlus:EnteringWorldTasks()
	if self.defaults.cvars.enable_cvar_overrides then
		if self.defaults.cvars.allow_nameplated then
			SetCVar("nameplateMaxDistance", self.defaults.cvars.nameplate_max_distance)
		end
		if self.defaults.cvars.hide_console_errors then
			SetCVar("scriptErrors", 0)
		else
			SetCVar("scriptErrors", 1)
		end
	end
end


function SloppyPlus:HandleIcon(item_name, values, index)
	if not values or not values.minimum_count then return end
	local count = GetItemCount(item_name, false, false, false)
	if count >= values.minimum_count then return end
	local itemTexture = select(10, GetItemInfo(item_name))
	if not itemTexture then return end
	if not self.primary_frame.textures[index] then
		local texture = self.primary_frame:CreateTexture("reminder"..index)
		texture:Hide()
		if index == 1 then -- This is the first icon
			texture:SetPoint("CENTER")
		else
			texture:SetPoint("LEFT", self.primary_frame.textures[index-1], "RIGHT")
		end
		self.primary_frame.textures[index] = texture
		texture:SetTexture(itemTexture)
	else
		local texture = self.primary_frame.textures[index]
		texture:Hide()
		texture:SetTexture(itemTexture)
	end
	return true
end

function SloppyPlus:ReagentAlerts(event, ...)
	if not self.sessionInfo.login_time then return end
	 -- Is it too soon since login to check bags?
	local now_t = GetTime()
	if now_t - 30 < self.sessionInfo.login_time then return end
	if not self.sessionInfo.playerClassIndex then return end
	if not self.classTable[self.sessionInfo.playerClassIndex] then return end

	local classFile = self.classTable[self.sessionInfo.playerClassIndex].classFile
	if not self.required_reagents[classFile] then return end

	print('Login_t', self.sessionInfo.login_time, 'now_t: ', now_t, now_t - 30)

	self.primary_frame:Hide()
	if not self.defaults.reagent_alert then return false end

	local index = 0
	for item_name, values in pairs(self.required_reagents[classFile]) do
		if self:HandleIcon(item_name, values, index + 1) then
			index = index + 1
		end
	end
	if index == 0 then return end
	local xoff = 0
	local width = 40 -- self.primary_frame.textures[1]:GetWidth()
	if math.fmod(index, 2) == 0 and index > 1 then
		local adjustment = -1
		if index == 2 then
			adjustment = 0
		end
		-- Even number of icons
		xoff = adjustment * (width * (index / 2 - 1)) - (width / 2)
	else
		-- Odd number of icons
		xoff = -1 * (width * ((index + 1) / 2 - 1))
	end
	print("offsets: ", index, width, xoff)
	local height = 40 -- self.primary_frame.textures[1]:GetHeight()
	self.primary_frame:SetSize(width * index, height)
	self.primary_frame:SetPoint("CENTER", xoff - 10, 150)
	self.primary_frame:Show()
	for idx = 1, index do
		self.primary_frame.textures[idx]:Show()
	end
	C_Timer.After(5, function()
		self.primary_frame:Hide()
		for k, v in pairs(self.primary_frame.textures) do
			self.primary_frame.textures[k]:Hide()
		end
	end)
end


local primary_frame = CreateFrame("Frame")
primary_frame:RegisterEvent("PLAYER_LOGIN")
primary_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
primary_frame:SetScript("OnEvent", function(self, event, ...)
	-- print('Sloppy Plus: ', event, ...)
	if event == 'PLAYER_LOGIN' then
		-- We note the time that we logged in.
		SloppyPlus.sessionInfo.login_time = GetTime()

		SloppyPlus:Initialize()
		SloppyPlus:DetectPlayer()
		self:UnregisterEvent("PLAYER_LOGIN")
	elseif event == 'PLAYER_ENTERING_WORLD' then
		SloppyPlus:EnteringWorldTasks()
		SloppyPlus:ReagentAlerts(event, ...)
	end
end)
SloppyPlus.primary_frame = primary_frame
primary_frame.textures = {}
primary_frame:ClearAllPoints()
primary_frame:Hide()

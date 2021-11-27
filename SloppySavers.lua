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



function SloppyPlus:PreInitialize()
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

	self.sessionInfo.playerClassIndex = select(3, UnitClass("player"))
	self.sessionInfo.playerLevel = UnitLevel("player")
	self.sessionInfo.playerFaction =  UnitFactionGroup("player") -- "Alliance" or "Horde"
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
end

function SloppyPlus:Initialize()
	-- Initialize DB
	-- self.db = LibStub:GetLibrary("AceDB-3.0"):New("SloppyPlusDB", self.defaults, true)
	-- self.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
	-- self.db.RegisterCallback(self, "OnProfileReset", "ProfileReset")
	for _, module in pairs(self.modules) do
		-- Give every submodule a reference to important data.
		-- We must give them this data before we call their Initialize() handler.
		module.defaults = self.defaults
		module.sessionInfo = self.sessionInfo
		module.classTable = self.classTable
	end
end

function SloppyPlus:PostInitialize()
	for _, module in pairs(self.modules) do
		-- The last step to initialize submodules is call their handler.
		module:Initialize()
	end
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SloppyPlus_options", "SloppyPlus")
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
		SloppyPlus:PostInitialize()
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

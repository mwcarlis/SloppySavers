std = "lua51"
max_line_length = false
exclude_files = {
	".luacheckrc",
	"LICENSE",
	"README.md",
	"setup.sh",
	"SloppySavers.toc",
}
ignore = {
	"211", -- Unused local variable
	"211/SLocale", -- Unused local variable "SLocale"

	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
}
globals = {
	"_G",
	"bit",

	-- misc custom
	"CUSTOM_CLASS_COLORS",
	"LibStub",

	-- This Addon
	"SloppyPlus",

	-- Blizzard API
	"addonName",
	"C_Timer",
	"CreateFrame",
	"Enum",
	"GetClassInfo",
	"GetInventorySlotInfo",
	"GetItemCount",
	"GetItemInfo",
	"GetInventoryItemLink",
	"GetNumClasses",
	"GetTime",
	"SetCVar",
	"UIParent",
	"UnitClass",
	"UnitFactionGroup",
	"UnitLevel",
	"UnitPowerType",
}

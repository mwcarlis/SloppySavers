local CHEST_SLOT = GetInventorySlotInfo("CHESTSLOT")

-- Example From: https://github.com/Shestak/ShestakUI/blob/master/ShestakUI/Modules/Misc/SlotItemLevel.lua
local scanner = CreateFrame("GameTooltip", "SlopSlotScanningTooltip", nil, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")
local scannerGlobalName = scanner:GetName().."TextLeft"
-- scanner:Hide() -- You can't parse the tooltip if frame is hidden.

local function parse_rune(msg)
	local minute_regex = "^Greater Rune of Warding %((%d+) (min)%)"
	local duration, unit = string.match(msg, minute_regex)
	if duration and unit then
		-- Convert from minutes to seconds
		return tonumber(duration) * 60
	end

	local hour_regex = "^Greater Rune of Warding %((%d+) (hour)%)"
	duration, unit = string.match(msg, hour_regex)
	if duration and unit then
		-- Convert from hour to seconds.
		return tonumber(duration) * 60 * 60
	end

	local seconds_regex = "^Greater Rune of Warding %((%d+) (sec)%)"
	duration, unit = string.match(msg, seconds_regex)
	if duration and unit then
		-- This is seconds already.
		return tonumber(duration)
	end
	return 0
end

local ToolTipScanner = {}

function ToolTipScanner:greater_rune_duration()
	--[[ Get the remaining enchant duration of "Greater Rune of Warding."

	Returns the number of seconds remaining on the "Greater Rune of Warding."
	]]--
	local itemLink = GetInventoryItemLink("player", CHEST_SLOT)
	if not itemLink then return 0 end -- Returning zero here may be premature
	local hasItem = scanner:SetInventoryItem("player", CHEST_SLOT)
	if not hasItem then return 0 end -- Returning zero here may be premature

	local base_regex ="^Greater Rune of Warding"
	for k, v in pairs(_G) do
		if type(k) == "string" and string.sub(k, 1, string.len(scannerGlobalName)) == scannerGlobalName then
			if v.GetText then
				local msg = v:GetText()
				if msg and string.find(msg, base_regex) then
					return parse_rune(msg)
				end
			end
		end
	end
	-- We never found it, therefore its zero.
	return 0
end

SloppyPlus.ToolTipScanner = ToolTipScanner

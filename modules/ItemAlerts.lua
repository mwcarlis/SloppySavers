
local ItemAlerts = {}

local Locale = {
	["ItemAlerts"] = "ItemAlerts",
}
ItemAlerts.Locale = Locale
SloppyPlus:RegisterModule(ItemAlerts, "items", ItemAlerts.Locale["ItemAlerts"])

ItemAlerts.pending = false

function ItemAlerts:Initialize()
	self.item_alerts = {
		["DRUID"] = {
			["Flintweed Seed"] = {},
			["Wild Quillvine"] = {},
		},
		["HUNTER"] = {},
		["MAGE"] = {
			["Arcane Dust"] = {},
		},
		["PALADIN"] = {
			["Symbol of Divinity"] = {},
			["Symbol of Kings"] = {},
		},
		["PRIEST"] = {
			["Sacred Candle"] = {
				["minimum_count"] = 55,
			},
			["Heavy Runecloth Bandage"] = {
				["minimum_count"] = 55,
			},
		},
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
				["minimum_count"] = 10,
			},
		},
		["SHAMAN"] = {
			["Ankh"] = {},
		},
		["WARLOCK"] = {
			["Soul Shard"] = {},
		},
		["WARRIOR"] = {},
	}
	for classFile, _ in pairs(self.item_alerts) do
		self.item_alerts[classFile] = {
			["Greater Rune of Warding"] = {
				["minimum_duration"] = 10 * 60, -- 10 minutes in seconds.
				["minimum_count"] = 5,
				["duration"] = SloppyPlus.ToolTipScanner.greater_rune_duration,
			},
		}
	end

	local powerType = UnitPowerType("player")
	for classFile, _ in pairs(self.item_alerts) do
		self.item_alerts[classFile]['Heavy Netherweave Bandage'] = {
			["minimum_count"] = 50,
		}
		-- TODO: We probably don't even need to load this.
		-- I bet we can detect the power type when we load.
		if powerType == Enum.PowerType.Mana then
			-- It is only applicable for mana users.
			self.item_alerts[classFile]["Star's Tears"] = {
					["minimum_count"] = 50,
			}
		end
	end
	-- This is kind of a clean up & a generalization.
	-- We assume if you specified a minimum_count, but not a count method
	-- then you should use GetItemCount.
	for classFile, values in pairs(self.item_alerts) do
		for item_name, item_values in pairs(values) do
			if not item_values.minimum_count then
				item_values.count = function() return nil end
			elseif not item_values.count then
				-- By Default we assume this is Inventory based.
				item_values.count = function()
					return GetItemCount(item_name, false, false, false)
				end
			end
			if not item_values.duration or not item_values.minimum_duration then
				item_values.duration = function() return nil end
				item_values.minimum_duration = nil
			end
		end
	end
end

-- function ItemAlerts:CreateIcon(num_icons)
-- 	local name = self.icon_frame:GetName()
-- 	local key = name.."Icon"..index
-- 	if not self.icon_frame.textures[index] then
-- 		local frame = CreateFrame("Button", key, _G[name.."Icons"], "ItemAlertsButtonTemplate")
-- 	else
-- 	end
-- end

function ItemAlerts:GetIcon(item_name)
	if not SloppyPlus.Icons[item_name] or not SloppyPlus.Icons[item_name].icon then
		-- TODO: This only works if item is in our inventory.
		return select(10, GetItemInfo(item_name))
	else
		return SloppyPlus.Icons[item_name].icon
	end
end

function ItemAlerts:GetTexture(index)
	local texture
	if not self.icon_frame.textures[index] then
		texture = self.icon_frame:CreateTexture("reminder"..index)
		self.icon_frame.textures[index] = texture
		texture.duration_text = self.icon_frame:CreateFontString(texture, "OVERLAY", "GameTooltipText")
		texture.count_text = self.icon_frame:CreateFontString(texture, "OVERLAY", "GameTooltipText")
		texture:Hide()
		if index == 1 then -- This is the first icon
			texture:SetPoint("CENTER", self.icon_frame, "CENTER")
		else
			texture:SetPoint("LEFT", self.icon_frame.textures[index-1], "RIGHT")
		end
		local xoff = 5
		local yoff = 5
		texture.count_text:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", -xoff, yoff)
		texture.count_text:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE") -- , MONOCHROME")

		texture.duration_text:SetPoint("TOPLEFT", texture, "TOPLEFT", xoff, -yoff)
		texture.duration_text:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE")
	else
		texture = self.icon_frame.textures[index]
		texture:Hide()
	end
	texture.count_text:Hide()
	texture.duration_text:Hide()
	return texture
end

function ItemAlerts:HandleIcon(item_name, values, index)
	if not values or not values.minimum_count then return end
	local classFile = self.classTable[self.sessionInfo.playerClassIndex].classFile

	local use_count = false
	local count = values.count()
	local use_duration = false
	local duration = values.duration()

	if count and values.minimum_count then use_count = true end
	if duration and values.minimum_duration then use_duration = true end

	if (use_count and use_duration) then
		if count >= values.minimum_count and duration >= values.minimum_duration then return end
	elseif use_duration then
		if duration >= values.minimum_duration then return end
	elseif use_count then
		if count >= values.minimum_count then return end
	else return end

	local itemTexture = ItemAlerts:GetIcon(item_name)
	if not itemTexture then return end

	local texture = ItemAlerts:GetTexture(index)
	if use_count and count < values.minimum_count then
		texture.count_text:SetText(tostring(count))
		texture.count_text:Show()
	end
	if use_duration and duration < values.minimum_duration then
		-- TODO: Round to Hour/Minute/Seconds.
		texture.duration_text:SetText(tostring(duration).." s")
		texture.duration_text:Show()
	end
	texture:SetTexture(itemTexture)
	return true
end

function ItemAlerts:ReagentAlerts()
	if not self.sessionInfo.playerClassIndex then return end
	if not self.classTable[self.sessionInfo.playerClassIndex] then return end

	local classFile = self.classTable[self.sessionInfo.playerClassIndex].classFile
	if not self.item_alerts[classFile] then return end

	self.icon_frame:Hide()
	if not self.defaults.use_reagent_alert then return end

	local index = 0
	for item_name, values in pairs(self.item_alerts[classFile]) do
		if ItemAlerts:HandleIcon(item_name, values, index + 1) then
			index = index + 1
		end
	end
	if index == 0 then return end
	local width = 40 -- self.icon_frame.textures[1]:GetWidth()
	local height = 40 -- self.icon_frame.textures[1]:GetHeight()

	local xoff = 0 -- (-1 * ((index * width) / 2)) - (index * 5)
	self.icon_frame:SetSize(width * index, height)
	-- print("offsets: ", index, width, xoff, self.icon_frame:GetWidth())
	self.icon_frame:SetPoint("RIGHT", "UIParent", "CENTER", xoff, 50)
	self.icon_frame:Show()
	for idx = 1, index do
		self.icon_frame.textures[idx]:Show()
	end
	-- C_Timer.After(10, function()
	-- 	-- Persist the icons for some time, then hide them.
	-- 	self.icon_frame:Hide()
	-- 	for k, v in pairs(self.icon_frame.textures) do
	-- 		self.icon_frame.textures[k]:Hide()
	-- 	end
	-- end)
end

function ItemAlerts:MediateAlerts(event, ...)
	if not self.sessionInfo.login_time then return end
	 -- Is it too soon since login to check bags?
	local now_t = GetTime()
	if self.defaults.use_reagent_alert and now_t - 30 < self.sessionInfo.login_time then
		if not self.pending then
			-- Hacky workaround, at login the client doesn't know what
			-- is in your bags. Instead of trying to figure out bag events,
			-- just add some delay after we log in.
			self.pending = true
			C_Timer.After(10, function()
				ItemAlerts:ReagentAlerts()
				self.pending = false
			end)
		end
	else
		ItemAlerts:ReagentAlerts()
	end
end

local icon_frame = CreateFrame("Frame")
icon_frame.textures = {}
ItemAlerts.icon_frame = icon_frame
icon_frame:Hide()
icon_frame:ClearAllPoints()

icon_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
icon_frame:SetScript("OnEvent", function(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		ItemAlerts:MediateAlerts(event, ...)
	end
end)

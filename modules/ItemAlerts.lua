
local ItemAlerts = {}

local Locale = {
	["ItemAlerts"] = "ItemAlerts",
}
ItemAlerts.Locale = Locale
SloppyPlus:RegisterModule(ItemAlerts, "items", ItemAlerts.Locale["ItemAlerts"])

function ItemAlerts:Initialize()
	self.inventory_items = {
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
			["Sacred Candle"] = {},
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
	self.enchant_durations = {}
	for k, _ in pairs(self.inventory_items) do
		self.enchant_durations[k] = {
			["Greater Rune of Warding"] = {
				["minimum_duration"] = 10 * 60, -- 10 minutes in seconds.
			},
		}
	end
	for k, _ in pairs(self.inventory_items) do
		self.inventory_items[k]['Heavy Netherweave Bandage'] = {
			["minimum_count"] = 50,
		}
		self.inventory_items[k]["Greater Rune of Warding"] = {
			["minimum_count"] = 5,
		}
		self.inventory_items[k]["Star's Tears"] = {
			-- It is only applicable for mana users.
				["minimum_count"] = 50,
				["applicable"] = function()
					local powerType = UnitPowerType("player")
					if not powerType then return false end
					return powerType == Enum.PowerType.Mana
				end,
		}
	end
	-- 	C_Timer.After(5, function()
	-- 		print('GreaterRune:', SloppyPlus.ToolTipScanner.greater_rune_duration())
	-- end)
end

function ItemAlerts:HandleIcon(item_name, values, index)
	if not values or not values.minimum_count then return end
	local count = GetItemCount(item_name, false, false, false)
	if count >= values.minimum_count then return end
	local itemTexture = select(10, GetItemInfo(item_name))
	if not itemTexture then return end
	if not self.icon_frame.textures[index] then
		local texture = self.icon_frame:CreateTexture("reminder"..index)
		texture:Hide()
		if index == 1 then -- This is the first icon
			texture:SetPoint("CENTER")
		else
			texture:SetPoint("LEFT", self.icon_frame.textures[index-1], "RIGHT")
		end
		self.icon_frame.textures[index] = texture
		texture:SetTexture(itemTexture)
	else
		local texture = self.icon_frame.textures[index]
		texture:Hide()
		texture:SetTexture(itemTexture)
	end
	return true
end

function ItemAlerts:ReagentAlerts(event, ...)
	if not self.sessionInfo.login_time then return end
	 -- Is it too soon since login to check bags?
	local now_t = GetTime()
	if now_t - 30 < self.sessionInfo.login_time then return end
	if not self.sessionInfo.playerClassIndex then return end
	if not self.classTable[self.sessionInfo.playerClassIndex] then return end

	local classFile = self.classTable[self.sessionInfo.playerClassIndex].classFile
	if not self.inventory_items[classFile] then return end

	self.icon_frame:Hide()
	if not self.defaults.use_reagent_alert then return false end

	local index = 0
	for item_name, values in pairs(self.inventory_items[classFile]) do
		if self:HandleIcon(item_name, values, index + 1) then
			index = index + 1
		end
	end
	if index == 0 then return end
	local xoff = 0
	local width = 40 -- self.icon_frame.textures[1]:GetWidth()
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
	local height = 40 -- self.icon_frame.textures[1]:GetHeight()
	self.icon_frame:SetSize(width * index, height)
	self.icon_frame:SetPoint("CENTER", xoff - 10, 150)
	self.icon_frame:Show()
	for idx = 1, index do
		self.icon_frame.textures[idx]:Show()
	end
	C_Timer.After(5, function()
		self.icon_frame:Hide()
		for k, v in pairs(self.icon_frame.textures) do
			self.icon_frame.textures[k]:Hide()
		end
	end)
end

local icon_frame = CreateFrame("Frame")
icon_frame:Hide()
icon_frame:ClearAllPoints()
icon_frame.textures = {}
ItemAlerts.icon_frame = icon_frame

icon_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
icon_frame:SetScript("OnEvent", function(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		ItemAlerts:ReagentAlerts(event, ...)
	end
end)

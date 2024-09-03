-------------------------------------------------------------------------------
-- ElvUI Mythic+ Datatext By Crackpotx
-------------------------------------------------------------------------------
local E, _, _, P, _ = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local L = E.Libs.ACL:GetLocale("ElvUI_MythicPlusDatatext", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local format = format
local strjoin = strjoin
local sort = sort
local tinsert = tinsert
local tsort = table.sort

local C_ChallengeMode_GetDungeonScoreRarityColor = C_ChallengeMode.GetDungeonScoreRarityColor
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_GetOverallDungeonScore = C_ChallengeMode.GetOverallDungeonScore

local C_MythicPlus_RequestCurrentAffixes = C_MythicPlus.RequestCurrentAffixes
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetCurrentSeason = C_MythicPlus.GetCurrentSeason
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_MythicPlus_GetSeasonBestForMap = C_MythicPlus.GetSeasonBestForMap
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel

local SecondsToClock = SecondsToClock

local CastSpellByID = CastSpellByID
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellKnown = IsSpellKnown
local LoadAddOn = LoadAddOn
local ToggleLFDParentFrame = ToggleLFDParentFrame

local SECONDS_PER_HOUR = SECONDS_PER_HOUR

local displayString = ""
local mpErrorString = ""
local rgbColor = { r = 0, g = 0, b = 0 }
local frame = CreateFrame("Frame", "ElvUI_MythicPlusDatatextMenu", E.UIParent, "UIDropDownMenuTemplate")

local dungeons = {}
local dungeonNames = {}
local timerData = {
	[168] = { 1224, 1632, 2040 }, -- The Everbloom
	[198] = { 1260, 1680, 2100 }, -- Darkheart Thicket
	[199] = { 1080, 1440, 1800 }, -- Black Rook Hold
	[244] = { 1320, 1760, 2200 }, -- Atal'Dazar
	[248] = { 1404, 1728, 2160 }, -- Waycrest Manor
	[456] = { 1080, 1440, 1800 }, -- Throne of the Tides
	[463] = { 1188, 1584, 1980 }, -- Dawn of the Infinite: Galakrond's Fall
	[464] = { 1224, 1632, 2040 }, -- Dawn of the Infinite: Murozond's Rise
}

local abbrevs = {
	[168] = L["EB"], -- The Everbloom
	[198] = L["DHT"], -- Darkheart Thicket
	[199] = L["BRH"], -- Black Rook Hold
	[244] = L["AD"], -- Atal'Dazar
	[248] = L["WM"], -- Waycrest Manor
	[456] = L["TOTT"], -- Throne of the Tides
	[463] = L["FALL"], -- Dawn of the Infinite: Galakrond's Fall
	[464] = L["RISE"], -- Dawn of the Infinite: Murozond's Rise
}--[[
local dungeonTeleports = {
	[168] = 159901, -- The Everbloom (Path of the Verdant)
	[198] = 424163, -- Darkheart Thicket (Path of the Nightmare Lord)
	[199] = 424153, -- Black Rook Hold (Path of the Ancient Horrors)
	[244] = 424187, -- Atal'Dazar (Path of the Golden Tomb)
	[248] = 424167, -- Waycrest Manor (Path of the Heart's Bane)
	[456] = 424142, -- Throne of the Tides (Path of the Tidehunter)
	[463] = 424197, -- Dawn of the Infinite: Galakrond's Fall (Path of Twisted Time)
	[464] = 424197, -- Dawn of the Infinite: Murozond's Rise (Path of Twisted Time)
}
]]

local labelText = {
	mPlus = L["M+"],
	mpKey = L["M+ Key"],
	mplusKey = L["Mythic+ Key"],
	mplusKeystone = L["Mythic+ Keystone"],
	keystone = L["Keystone"],
	key = L["Key"],
	none = ""
}

local affixes = {
	[1] = L["Overflowing"],
	[2] = L["Skittish"],
	[3] = L["Volcanic"],
	[4] = L["Necrotic"],
	[5] = L["Teeming"],
	[6] = L["Raging"],
	[7] = L["Bolstering"],
	[8] = L["Sanguine"],
	[9] = L["Tyrannical"],
	[10] = L["Fortified"],
	[11] = L["Bursting"],
	[12] = L["Grievous"],
	[13] = L["Explosive"],
	[14] = L["Quaking"],
	[16] = L["Infested"],
	[117] = L["Reaping"],
	[119] = L["Beguiling"],
	[120] = L["Awakened"],
	[121] = L["Prideful"],
	[122] = L["Inspiring"],
	[123] = L["Spiteful"],
	[124] = L["Storming"],
	[128] = L["Tormented"],
	[129] = L["Infernal"],
	[130] = L["Encrypted"],
	[131] = L["Shrouded"],
	[132] = L["Thundering"],
	[134] = L["Entangling"],
	[135] = L["Afflicted"],
	[136] = L["Incorporeal"],
	[137] = L["Shielding"],
}

local function GetKeystoneDungeonList()
	local maps = C_ChallengeMode_GetMapTable()
	for i = 1, #maps do
		local mapName, _, _, texture = C_ChallengeMode_GetMapUIInfo(maps[i])
		dungeons[i] = { id = maps[i], name = mapName, abbrev = abbrevs[maps[i]], timerData = timerData[maps[i]], texture = texture }
		dungeonNames[maps[i]] = mapName
	end

	sort(dungeons, function(a, b)
		return a.name < b.name
	end)
end

local function GetPlusString(duration, timers)
	if duration <= timers[1] then
		return "+++"
	elseif duration <= timers[2] and duration > timers[1] then
		return "++"
	elseif duration <= timers[3] and duration > timers[2] then
		return "+"
	else
		return ""
	end
end

--[[
local function CreateMenu(self, level)
	local sorted = {}
	local i = 1
	for _, map in pairs(dungeons) do
		if IsSpellKnown(map.teleport) then
			sorted[i] = { name = map.name, teleport = map.teleport, texture = map.texture }
			i = i + 1
		end
	end

	if #sorted > 0 then
		sort(sorted, function(a, b)
			return a.name < b.name
		end)

		for _, map in pairs(sorted) do
			UIDropDownMenu_AddButton({
				hasArrow = false,
				notCheckable = true,
				colorCode = "|cffffffff",
				text = map.name,
				icon = map.texture,
				func = function()
					local spellName = GetSpellInfo(map.teleport)
					local button = CreateFrame("Button", "ElvUI_MythicPlusDatatextMenu", E.UIParent, "InsecureActionButtonTemplate")
					button:SetAttribute("type", "spell")
					button:SetAttribute("spell", spellName)
					button:Click("LeftButton", true)
				end,
			})
		end
	end
end
]]

local function OnEnter(self)
	local keystoneId, keystoneLevel = C_MythicPlus_GetOwnedKeystoneChallengeMapID(), C_MythicPlus_GetOwnedKeystoneLevel()
	local currentAffixes = C_MythicPlus_GetCurrentAffixes()
	local currentScore = C_ChallengeMode_GetOverallDungeonScore()
	local curerntSeason = C_MythicPlus_GetCurrentSeason()
	local color = C_ChallengeMode_GetDungeonScoreRarityColor(currentScore)

	DT.tooltip:ClearLines()

	if currentSeason ~= nil then
		if keystoneId ~= nil then
			DT.tooltip:AddLine(L["Your Keystone"])
			DT.tooltip:AddDoubleLine(L["Dungeon"], dungeonNames[keystoneId], 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
			DT.tooltip:AddDoubleLine(L["Level"], keystoneLevel, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
			DT.tooltip:AddLine(" ")
		end

		DT.tooltip:AddLine((L["Season %d"]):format(currentSeason - 8))
		DT.tooltip:AddDoubleLine(L["Mythic+ Rating"], currentScore, 1, 1, 1, color.r, color.g, color.b)
		if #affixes > 0 then
			DT.tooltip:AddDoubleLine(L["Affixes"], ("%s, %s, %s"):format(affixes[currentAffixes[1].id], affixes[currentAffixes[2].id], affixes[currentAffixes[3].id]), 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
		end
		DT.tooltip:AddLine(" ")

		if currentScore > 0 then
			for _, map in pairs(dungeons) do
				local inTimeInfo, overTimeInfo = C_MythicPlus_GetSeasonBestForMap(map.id)
				local affixScores, overAllScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(map.id)

				if overAllScore ~= nil then
					if overAllScore and inTimeInfo or overTimeInfo then
						local dungeonColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(overAllScore)
						if not dungeonColor then
							dungeonColor = HIGHLIGHT_FONT_COLOR
						end

						-- highlight the players key
						if E.db.mplusdt.highlightKey and map.id == keystoneId then
							DT.tooltip:AddDoubleLine(map.name, overAllScore, E.db.mplusdt.highlightColor.r, E.db.mplusdt.highlightColor.g, E.db.mplusdt.highlightColor.b, dungeonColor.r, dungeonColor.g, dungeonColor.b)
						else
							DT.tooltip:AddDoubleLine(map.name, overAllScore, nil, nil, nil, dungeonColor.r, dungeonColor.g, dungeonColor.b)
						end
					else
						if E.db.mplusdt.highlightKey and map.id == keystoneId then
							DT.tooltip:AddLine(map.name, E.db.mplusdt.highlightColor.r, E.db.mplusdt.highlightColor.g, E.db.mplusdt.highlightColor.b)
						else
							DT.tooltip:AddLine(map.name)
						end
					end

					if affixScores and #affixScores > 0 then
						-- sort fortified before tyrannical
						tsort(affixScores, function(x, y) return x.name < y.name end)
						for _, affixInfo in ipairs(affixScores) do
							local r, g, b = 1, 1, 1

							-- add an exclamation graphic to what this week's main affix (fort or tyran)
							local fortTyran = (affixInfo.name == affixes[currentAffixes[1].id]) and ("%s%s"):format(affixInfo.name, "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:14:14|t") or affixInfo.name

							if affixInfo.overTime then r, g, b = .6, .6, .6 end
							if affixInfo.durationSec >= SECONDS_PER_HOUR then
								DT.tooltip:AddDoubleLine(fortTyran, format("%s (%s%d)", SecondsToClock(affixInfo.durationSec, true), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), r, g, b, r, g, b)
							else
								DT.tooltip:AddDoubleLine(fortTyran, format("%s (%s%d)", SecondsToClock(affixInfo.durationSec, false), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), r, g, b, r, g, b)
							end
						end
					end

					DT.tooltip:AddLine(" ")
				end
			end
		end

		DT.tooltip:AddDoubleLine(L["Left-Click"], L["Toggle Mythic+ Page"], nil, nil, nil, 1, 1, 1)
		DT.tooltip:AddDoubleLine(L["Right-Click"], L["Toggle Great Vault"], nil, nil, nil, 1, 1, 1)
		--DT.tooltip:AddDoubleLine(L["Shift + Click"], L["Dungeon Teleport Menu"], nil, nil, nil, 1, 1, 1)
	else 
		DT.tooltip:AddLine(L["No Current Mythic+ Season"], 1, 1, 1)
	end

	DT.tooltip:Show()
end

local function OnEvent(self, event)
	if event == 'ELVUI_FORCE_UPDATE' then
		C_MythicPlus_RequestCurrentAffixes()
	end

	if #dungeons == 0 then
		GetKeystoneDungeonList()
	end

	local curerntSeason = C_MythicPlus_GetCurrentSeason()
	if not currentSeason then
		self.text:SetFormattedText(mpErrorString, L["No M+ Season"])
		return
	end

	local keystoneId, keystoneLevel = C_MythicPlus_GetOwnedKeystoneChallengeMapID(), C_MythicPlus_GetOwnedKeystoneLevel()
	if not keystoneId or dungeonNames[keystoneId] == nil then
		self.text:SetFormattedText(mpErrorString, L["No Keystone"])
		return
	end
	local instanceName = E.db.mplusdt.abbrevName == true and abbrevs[keystoneId] or dungeonNames[keystoneId]
	self.text:SetFormattedText(
		displayString,
		E.db.mplusdt.labelText == "none" and "" or strjoin("", labelText[E.db.mplusdt.labelText], ": "),
		format("%s%s", instanceName, E.db.mplusdt.includeLevel == true and format(" %d", keystoneLevel) or "")
	)
end

local interval = 5
local function OnUpdate(self, elapsed)
	if not self.lastUpdate then
		self.lastUpdate = 0
	end
	self.lastUpdate = self.lastUpdate + elapsed
	if self.lastUpdate > interval then
		OnEvent(self)
		self.lastUpdate = 0
	end
end

local function OnClick(self, button)
	--[[if IsShiftKeyDown() then
		DT.tooltip:Hide()
		ToggleDropDownMenu(1, nil, frame, self, 0, 0)
	else]]
	if button == "LeftButton" then
		if not PVEFrame then return end
		if PVEFrame:IsShown() then
			PVEFrameTab1:Click()
			ToggleLFDParentFrame()
		else
			ToggleLFDParentFrame()
			PVEFrameTab3:Click()
		end
	else
		-- load weekly rewards, if not loaded
		if not IsAddOnLoaded("Blizzard_WeeklyRewards") then
			LoadAddOn("Blizzard_WeeklyRewards")
		end

		if not WeeklyRewardsFrame then return end
		if WeeklyRewardsFrame:IsShown() then
			WeeklyRewardsFrame:Hide()
			tremove(UISpecialFrames, #UISpecialFrames)
		else
			WeeklyRewardsFrame:Show()
			tinsert(UISpecialFrames, "WeeklyRewardsFrame")
		end
	end
end

--[[
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...) 
	self.initialize = CreateMenu
	self.dispalyMode = "MENU"
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)
]]

local function GetClassColor(val)
	local class, _ = UnitClassBase("player")
	return RAID_CLASS_COLORS[class][val]
end

local function ValueColorUpdate(_, hex, r, g, b)
	displayString = strjoin("", "|cffffffff%s|r", hex, "%s|r")
	mpErrorString = strjoin("", hex, "%s|r")
	currentKeyString = strjoin("", hex, "%s|r |cffffffff%s|r")

	rgbColor.r = r
	rgbColor.g = g
	rgbColor.b = b
end

P["mplusdt"] = {
	["labelText"] = "key",
	["abbrevName"] = true,
	["includeLevel"] = true,
	["highlightKey"] = true,
	["highlightColor"] = {
		r = GetClassColor("r"),
		g = GetClassColor("g"),
		b = GetClassColor("b")
	}
}

local function InjectOptions()
	if not E.Options.args.Crackpotx then
		E.Options.args.Crackpotx = ACH:Group(L["Plugins by |cff0070deCrackpotx|r"])
	end
	if not E.Options.args.Crackpotx.args.thanks then
		E.Options.args.Crackpotx.args.thanks = ACH:Description(L["Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."], 1)
	end

	E.Options.args.Crackpotx.args.mplusdt = ACH:Group(L["Mythic+ Datatext"], nil, nil, nil, function(info) return E.db.mplusdt[info[#info]] end, function(info, value) E.db.mplusdt[info[#info]] = value; DT:ForceUpdate_DataText("Mythic+") end)
	E.Options.args.Crackpotx.args.mplusdt.args.labelText = ACH:Select(L["Datatext Label"], L["Choose how to label the datatext."], 1, { ["mPlus"] = L["M+"], ["mpKey"] = L["M+ Key"], ["mplusKey"] = L["Mythic+ Key"], ["mplusKeystone"] = L["Mythic+ Keystone"], ["keystone"] = L["Keystone"], ["key"] = L["Key"], ["none"] = L["None"] })
	E.Options.args.Crackpotx.args.mplusdt.args.abbrevName = ACH:Toggle(L["Abbreviate Instance Name"], L["Abbreviate instance name in the datatext."], 2)
	E.Options.args.Crackpotx.args.mplusdt.args.includeLevel = ACH:Toggle(L["Include Level"], L["Include your keystone's level in the datatext."], 3)
	E.Options.args.Crackpotx.args.mplusdt.args.highlightKey = ACH:Toggle(L["Highlight Your Key"], L["Highlight your key in the tooltip for the datatext."], 4)
	E.Options.args.Crackpotx.args.mplusdt.args.highlightColor = ACH:Color(L["Highlight Color"], L["Color to highlight your key."], 5, false, nil, function() return E.db.mplusdt.highlightColor.r, E.db.mplusdt.highlightColor.g, E.db.mplusdt.highlightColor.b end, function(_, r, g, b) E.db.mplusdt.highlightColor.r = r; E.db.mplusdt.highlightColor.g = g; E.db.mplusdt.highlightColor.b = b end, function() return not E.db.mplusdt.highlightKey end)
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("Mythic+", L["Plugins by |cff0070deCrackpotx|r"], {"PLAYER_ENTERING_WORLD", "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", "MYTHIC_PLUS_NEW_WEEKLY_RECORD"}, OnEvent, OnUpdate,  OnClick,  OnEnter, nil, L["Mythic+"], nil, ValueColorUpdate)

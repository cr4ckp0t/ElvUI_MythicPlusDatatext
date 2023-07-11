-------------------------------------------------------------------------------
-- ElvUI Mythic+ Datatext By Crackpotx
-------------------------------------------------------------------------------
local E, _, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local L = E.Libs.ACL:GetLocale("ElvUI_MythicPlusDatatext", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local select = select
local gmatch = gmatch
local format = format
local strjoin = strjoin
local strmatch = strmatch
local strupper = strupper
local strsub = strsub
local strfind = strfind
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

local CreateFrame = CreateFrame
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerNumSlots = GetContainerNumSlots
local IsAddOnLoaded = IsAddOnLoaded
local LoadAddOn = LoadAddOn
local ToggleLFDParentFrame = ToggleLFDParentFrame
local UnitAura = UnitAura

local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local SECONDS_PER_HOUR = SECONDS_PER_HOUR

local displayString = ""
local currentKeyString = ""
local mpErrorString = ""
local rgbColor = { r = 0, g = 0, b = 0 }

local dungeons = {}
local timerData = {
	[206] = { 1188, 1584, 1980 }, -- Neltharion's Lair
	[245] = { 1080, 1440, 1800 }, -- Freehold
	[251] = { 1080, 1440, 1800 }, -- The Underrot
	[403] = { 1260, 1680, 2100 }, -- Uldaman: Legacy of Tyr
	[404] = { 1188, 1584, 1980 }, -- Neltharus
	[405] = { 1260, 1680, 2100 }, -- Brackenhide Hollow
	[406] = { 1260, 1680, 2100 }, -- Halls of Infusion
	[438] = { 1080, 1440, 1800 }, -- The Vortex Pinnacle
}

local abbrevs = {
	[206] = L["NL"],
	[245] = L["FH"],
	[251] = L["UNDR"],
	[403] = L["ULD"],
	[404] = L["NELT"],
	[405] = L["BH"],
	[406] = L["HOI"],
	[438] = L["VP"],
}

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

--[[local function GetKeystoneDungeonAbbreviation(mapName)

	local abbrev = ""
	for match in gmatch(mapName, "%S+") do
		abbrev = format("%s%s", abbrev, (strfind(mapName, "of the") ~= nil and (match == "of" or match == "the")) and "" or strupper(strsub(match, 1, 1)))
	end

	return abbrev
end]]

local function GetKeystoneDungeonList()
	local maps = C_ChallengeMode_GetMapTable()
	for i = 1, #maps do
		local mapName, _, _, _ = C_ChallengeMode_GetMapUIInfo(maps[i])
		dungeons[maps[i]] = { id = maps[i], name = mapName, abbrev = abbrevs[maps[i]], timerData = timerData[maps[i]] }
	end
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

local function OnEnter(self)
	local keystoneId, keystoneLevel = C_MythicPlus_GetOwnedKeystoneChallengeMapID(), C_MythicPlus_GetOwnedKeystoneLevel()
	local currentAffixes = C_MythicPlus_GetCurrentAffixes()
	local currentScore = C_ChallengeMode_GetOverallDungeonScore()
	local color = C_ChallengeMode_GetDungeonScoreRarityColor(currentScore)
	if currentAffixes == nil or currentScore == nil then
		return
	end

	DT.tooltip:ClearLines()

	if keystoneId ~= nil then
		DT.tooltip:AddLine(L["Your Keystone"])
		DT.tooltip:AddDoubleLine(L["Dungeon"], dungeons[keystoneId].name, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
		DT.tooltip:AddDoubleLine(L["Level"], keystoneLevel, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
		DT.tooltip:AddLine(" ")
	end

	DT.tooltip:AddLine((L["Season %d"]):format(C_MythicPlus_GetCurrentSeason() - 8))
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

	DT.tooltip:Show()
end

local function OnEvent(self, event)
	if event == 'ELVUI_FORCE_UPDATE' then
		C_MythicPlus_RequestCurrentAffixes()
	end

	if #dungeons == 0 then
		GetKeystoneDungeonList()
	end

	local keystoneId, keystoneLevel = C_MythicPlus_GetOwnedKeystoneChallengeMapID(), C_MythicPlus_GetOwnedKeystoneLevel()
	if not keystoneId or dungeons[keystoneId] == nil then
		self.text:SetFormattedText(mpErrorString, L["No Keystone"])
		return
	end
	local instanceName = E.db.mplusdt.abbrevName == true and dungeons[keystoneId].abbrev or dungeons[keystoneId].name
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

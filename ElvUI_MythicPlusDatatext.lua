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

local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_AddOns_LoadAddOn = C_AddOns.LoadAddOn

local C_ChallengeMode_GetDungeonScoreRarityColor = C_ChallengeMode.GetDungeonScoreRarityColor
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_GetOverallDungeonScore = C_ChallengeMode.GetOverallDungeonScore

local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetCurrentSeason = C_MythicPlus.GetCurrentSeason
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local C_MythicPlus_GetRunHistory = C_MythicPlus.GetRunHistory
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_MythicPlus_GetSeasonBestForMap = C_MythicPlus.GetSeasonBestForMap
local C_MythicPlus_RequestCurrentAffixes = C_MythicPlus.RequestCurrentAffixes

local SecondsToClock = SecondsToClock

local CastSpellByID = CastSpellByID
local CreateFrame = CreateFrame
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellKnown = IsSpellKnown
local ToggleLFDParentFrame = ToggleLFDParentFrame

local SECONDS_PER_HOUR = SECONDS_PER_HOUR

local displayString = ""
local mpErrorString = ""
local rgbColor = { r = 0, g = 0, b = 0 }
local frame = CreateFrame("Frame", "ElvUI_MythicPlusDatatextMenu", E.UIParent, "UIDropDownMenuTemplate")

local dungeons = {}
local dungeonNames = {}
local timerData = {
	[247] = { 1188, 1584, 1980 }, -- The MOTHERLODE!!
	[370] = { 1152, 1536, 1920 }, -- Operation Mechagon: Workshop
	[382] = { 1224, 1632, 2040 }, -- Theater of Pain
	[499] = { 1170, 1560, 1950 }, -- Priory of the Sacred Flame
	[500] = { 1044, 1392, 1740 }, -- The Rookery
	[504] = { 1116, 1488, 1860 }, -- Darkflame Cleft
	[506] = { 1188, 1584, 1980 }, -- Cinderbrew Meadery
	[525] = { 1188, 1584, 1980 }, -- Operation: Floodgate
}

local abbrevs = {
	[247] = L["ML"],
	[370] = L["WORK"],
	[382] = L["TOP"],
	[499] = L["PSF"],
	[500] = L["ROOK"],
	[504] = L["DFC"],
	[506] = L["BREW"],
	[525] = L["FLOOD"],
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

	-- TWW Season 1
	[147] = L["Guile"],
	[148] = L["Ascendant"],
	[152] = L["Challenger's Peril"],
	[158] = L["Voidbound"],
	[159] = L["Oblivion"],
	[160] = L["Devour"],
	[162] = L["Pulsar"],
}

local function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
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

local function GetBestDungeonRun(affixScores, timerDataSeconds)
	tsort(affixScores, function(x, y) return x.durationSec < y.durationSec end)
	return ("%s%d %s"):format(GetPlusString(affixScores[1].durationSec, timerDataSeconds), affixScores[1].level, SecondsToClock(affixScores[1].durationSec, affixScores[1].durationSec >= SECONDS_PER_HOUR and true or false))
end

local function GetKeystoneDungeonList()
	if C_MythicPlus_GetCurrentSeason() == nil then return false end
	local maps = C_ChallengeMode_GetMapTable()
	if maps ~= nil then
		for i = 1, #maps do
			local mapName, _, _, texture = C_ChallengeMode_GetMapUIInfo(maps[i])
			local currentScore = C_ChallengeMode_GetOverallDungeonScore()
			local level, dungeonScore = 0, 0
			local durationText, plusString, overTime = "", "", false
			if currentScore ~= nil then
				local inTimeInfo, overTimeInfo = C_MythicPlus_GetSeasonBestForMap(maps[i])
				if inTimeInfo and overTimeInfo then
					local whichIsBetter = inTimeInfo.dungeonScore > overTimeInfo.dungeonScore
					level = whichIsBetter and inTimeInfo.level or overTimeInfo.level
					dungeonScore = whichIsBetter and inTimeInfo.dungeonScore or overTimeInfo.dungeonScore
				elseif inTimeInfo or overTimeInfo then
					level = inTimeInfo and inTimeInfo.level or overTimeInfo.level
					dungeonScore = inTimeInfo and inTimeInfo.dungeonScore or overTimeInfo.dungeonScore
				end

				-- get specific scores per affix
				local affixScores, _ = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(maps[i])
				if affixScores ~= nil then
					local fastestAffixScore = TableUtil.FindMin(affixScores, function(affixScore) return affixScore.durationSec end)
					if fastestAffixScore then
						local displayZeroHours = fastestAffixScore.durationSec >= SECONDS_PER_HOUR
						durationText = SecondsToClock(fastestAffixScore.durationSec, displayZeroHours)
						plusString = GetPlusString(fastestAffixScore.durationSec, timerData[maps[i]])
						overTime = fastestAffixScore.overTime
					end
				end
			end
			dungeons[i] = {
				id = maps[i],
				name = mapName,
				abbrev = abbrevs[maps[i]],
				timerData = timerData[maps[i]],
				texture = texture,
				level = level,
				dungeonScore = dungeonScore,
				durationText = durationText,
				overTime = overTime,
				plusString = plusString,
			}
			dungeonNames[maps[i]] = mapName
		end

		sort(dungeons, function(a, b)
			return a.dungeonScore > b.dungeonScore
		end)
	else 
		return false
	end
end

local function RGBtoHEX(r, g, b)
	return ("%02X%02X%02X"):format((r * 255), (g * 255), (b * 255))
end

local function GetFormattedDungeonString(map, overallScore)
	local dungeonString = "|cff%s%d|r |cff%s(%s%d %s)|r"
	local color = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(overallScore) or HIGHLIGHT_FONT_COLOR
	local timerColor = map.overTime and RGBtoHEX(.6, .6, .6) or "FFFFFF"
	return dungeonString:format(RGBtoHEX(color.r, color.g, color.b), map.dungeonScore, timerColor, map.plusString, map.level, map.durationText)
end

local function OnEnter(self)
	if not IsShiftKeyDown() then
		local keystoneId, keystoneLevel = C_MythicPlus_GetOwnedKeystoneChallengeMapID(), C_MythicPlus_GetOwnedKeystoneLevel()
		local currentAffixes = C_MythicPlus_GetCurrentAffixes()
		local currentScore = C_ChallengeMode_GetOverallDungeonScore()
		local currentSeason = C_MythicPlus_GetCurrentSeason()
		local color = C_ChallengeMode_GetDungeonScoreRarityColor(currentScore)

		DT.tooltip:ClearLines()

		if currentSeason ~= nil then
			if keystoneId ~= nil then
				DT.tooltip:AddLine(L["Your Keystone"])
				DT.tooltip:AddDoubleLine(L["Dungeon"], dungeonNames[keystoneId], 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
				DT.tooltip:AddDoubleLine(L["Level"], keystoneLevel, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)

				local runHistory = C_MythicPlus_GetRunHistory(false, true)
				local r, g, b = 1, 1, 1
				if #runHistory == 0 then
					r, g, b = 1, 0, 0
				elseif #runHistory > 1 and #runHistory < 8 then
					r, g, b = nil, nil, nil
				elseif #runHistory >= 8 then
					r, g, b = 0, 1, 0
				end
				DT.tooltip:AddDoubleLine(L["Runs This Week"], ("%d/%d"):format(#runHistory, #runHistory > 8 and #runHistory or 8), 1, 1, 1, r, g, b)

				DT.tooltip:AddLine(" ")
			end

			DT.tooltip:AddDoubleLine(L["The War Within"], (L["Season %d"]):format(currentSeason - 12), nil, nil, nil, 1, 1, 1)
			DT.tooltip:AddDoubleLine(L["Mythic+ Rating"], currentScore, 1, 1, 1, color.r, color.g, color.b)
			if #currentAffixes > 0 then
				DT.tooltip:AddDoubleLine(L["Affixes"], ("%s, %s, %s, %s"):format(affixes[currentAffixes[1].id], affixes[currentAffixes[2].id], affixes[currentAffixes[3].id], affixes[currentAffixes[4].id]), 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
			end
			DT.tooltip:AddLine(" ")

			if currentScore > 0 then
				DT.tooltip:AddLine(L["Best Runs by Dungeon"])
				for _, map in pairs(dungeons) do
					local _, overallScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(map.id)
					if E.db.mplusdt.highlightKey and map.id == keystoneId then
						DT.tooltip:AddDoubleLine(map.name, GetFormattedDungeonString(map, overallScore), E.db.mplusdt.highlightColor.r, E.db.mplusdt.highlightColor.g, E.db.mplusdt.highlightColor.b)
					else 
						DT.tooltip:AddDoubleLine(map.name, GetFormattedDungeonString(map, overallScore), 1, 1 ,1)
					end
				end
			end
		else 
			DT.tooltip:AddLine(L["No Current Mythic+ Season"], 1, 1, 1)
		end
		DT.tooltip:AddLine(" ")
	else
		local runHistory = C_MythicPlus_GetRunHistory(false, true)
		DT.tooltip:ClearLines()
		if #runHistory == 0 then
			DT.tooltip:AddLine(L["No Mythic+ runs this week."])
		else
			DT.tooltip:AddDoubleLine(L["Weekly Mythic+ Runs"], ("%d/%d"):format(#runHistory, #runHistory > 8 and #runHistory or 8), nil, nil, nil, 1, 1, 1)
			DT.tooltip:AddLine(" ")

			tsort(runHistory, function(a, b)
				if a.level == b.level then
					return a.mapChallengeModeID < b.mapChallengeModeID
				else
					return a.level > b.level
				end
			end)
			for i = 1, #runHistory do
				if runHistory[i] then
					local name = C_ChallengeMode_GetMapUIInfo(runHistory[i].mapChallengeModeID)
					local r, g, b = 1, 1, 1
					if runHistory[i].level == 3 or runHistory[i].level == 4 then
						-- uncommon (green)
						r, g, b = 0.12, 1, 0
					elseif runHistory[i].level == 5 or runHistory[i].level == 6 then
						-- rare (blue)
						r, g, b = 0, 0.44, 0.87
					elseif runHistory[i].level >= 7 and runHistory[i].level <= 9 then
						-- epic (purple)
						r, g, b = 0.64, 0.21, 0.93
					elseif runHistory[i].level >= 10 then
						-- legendary (orange)
						r, g, b = 1, 0.50, 0
					end

					-- DT.tooltip:AddLine(WEEKLY_REWARDS_MYTHIC_RUN_INFO:format(runHistory[i].level, name), r, g, b)
					DT.tooltip:AddDoubleLine(name, runHistory[i].level, 1, 1, 1, r, g, b)
				end
			end
		end
		DT.tooltip:AddLine(" ")
	end

	DT.tooltip:AddDoubleLine(L["Left-Click"], L["Toggle Mythic+ Page"], nil, nil, nil, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Right-Click"], L["Toggle Great Vault"], nil, nil, nil, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Mouseover"], L["Show M+ Dungeon Breakdown"], nil, nil, nil, 1, 1 ,1)
	DT.tooltip:AddDoubleLine(L["Shift + Mouseover"], L["Show Weekly M+ Runs"], nil, nil, nil, 1, 1, 1)
	DT.tooltip:Show()
end

local function OnEvent(self, event)
	if event == 'ELVUI_FORCE_UPDATE' then
		C_MythicPlus_RequestCurrentAffixes()
	end

	if #dungeons == 0 or event == "MYTHIC_PLUS_NEW_WEEKLY_RECORD" or event == "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE" or event == "ELVUI_FORCE_UPDATE" then
		GetKeystoneDungeonList()
	end

	local currentSeason = C_MythicPlus_GetCurrentSeason()
	if not currentSeason or currentSeason == 12 then
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
		if not C_AddOns_IsAddOnLoaded("Blizzard_WeeklyRewards") then
			C_AddOns_LoadAddOn("Blizzard_WeeklyRewards")
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

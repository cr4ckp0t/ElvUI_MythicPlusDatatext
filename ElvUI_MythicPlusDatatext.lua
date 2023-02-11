-------------------------------------------------------------------------------
-- ElvUI Mythic+ Datatext By Crackpotx
-------------------------------------------------------------------------------
--[[
      
MIT License

Copyright (c) 2022 Adam Koch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]
local E, _, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local L = LibStub("AceLocale-3.0"):GetLocale("ElvUI_MythicPlusDatatext", false)
local EP = LibStub("LibElvUIPlugin-1.0")

local C_ChallengeMode_GetDungeonScoreRarityColor = C_ChallengeMode.GetDungeonScoreRarityColor
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_GetOverallDungeonScore = C_ChallengeMode.GetOverallDungeonScore
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetCurrentSeason = C_MythicPlus.GetCurrentSeason
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_MythicPlus_GetSeasonBestForMap = C_MythicPlus.GetSeasonBestForMap
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local CreateFrame = _G["CreateFrame"]
local GetContainerItemInfo = _G["GetContainerItemInfo"]
local GetContainerNumSlots = _G["GetContainerNumSlots"]
local IsAddOnLoaded = _G["IsAddOnLoaded"]
local LoadAddOn = _G["LoadAddOn"]
local NUM_BAG_SLOTS = _G["NUM_BAG_SLOTS"]
local select = _G["select"]
local ToggleLFDParentFrame = _G["ToggleLFDParentFrame"]
local UnitAura = _G["UnitAura"]

local gmatch = string.gmatch
local join = string.join
local match = string.match
local sort = table.sort
local tinsert = _G["tinsert"]

local displayString = ""
local currentKeyString = ""
local mpErrorString = ""
local rgbColor = {
    ["r"] = 0,
    ["g"] = 0,
    ["b"] = 0
}
--local timewalkingActive

local dungeons = {}
local timerData = {
    [2] = { 1080, 1440, 1800 }, -- Temple of the Jade Serpent
    [165] = { 1188, 1584, 1980 }, -- Shadowmoon Buriel Grounds
    [200] = { 1368, 1824, 2280 }, -- Halls of Valor
    [210] = { 1080, 1440, 1800 }, -- Court of Stars
    [401] = { 1224, 1632, 2040 }, -- The Azure Vault
    [400] = { 1440, 1920, 2400 }, -- The Nokhud Offensive
    [402] = { 1152, 1536, 1920 }, -- Algeth'ar Academy
    [399] = { 1080, 1440, 1800 }, -- Ruby Life Pools
}
local labelText = {
    ["mpKey"] = L["M+ Key"],
    ["mplusKey"] = L["Mythic+ Key"],
    ["mplusKeystone"] = L["Mythic+ Keystone"],
    ["keystone"] = L["Keystone"],
    ["key"] = L["Key"],
    ["none"] = ""
}

local affixes = {
    [3] = L["Volcanic"],
    [4] = L["Necrotic"],
    [6] = L["Raging"],
    [7] = L["Bolstering"],
    [8] = L["Sanguine"],
    [9] = L["Tyrannical"],
    [10] = L["Fortified"],
    [11] = L["Bursting"],
    [12] = L["Grievous"],
    [13] = L["Explosive"],
    [14] = L["Quaking"],
    [122] = L["Inspiring"],
    [123] = L["Spiteful"],
    [124] = L["Storming"],
    [128] = L["Tormented"],
    [129] = L["Infernal"],
    [130] = L["Encrypted"],
    [131] = L["Shrouded"],
    [132] = L["Thundering"],
}

--[[local function IsLegionTimewalkingActive()
    for i = 1, 40 do
        local buffId = select(10, UnitAura("player", i))
        if buffId == 359082 then
            return true
        end
    end
    return false
end


local function GetLegionTimewalkingKeystone()
    if not timewalkingActive or timewalkingActive == nil then return false, false end
    for bag = 0, NUM_BAG_SLOTS do
        local bagSlots = GetContainerNumSlots(bag)
        for slot = 1, bagSlots do
            local itemLink, _, _, itemId = select(7, GetContainerItemInfo(bag, slot))
            if itemId == 187786 then
                -- |cffa335ee|Hkeystone:158923:251:12:10:5:13:117|h[Keystone: The Underrot (12)]|h|r
                -- string.match("|cffa335ee|Hkeystone:158923:251:12:10:5:13:117|h[Keystone: The Underrot (12)]|h|r", "|cffa335ee|Hkeystone:%d+:%d+:%d+:%d+:%d+:%d+:%d+|h%[Keystone: (.+) %((%d+)%)%]|h|r")
                local dungeon, level = match(itemLink, "|cffa335ee|Hkeystone:%d+:%d+:%d+:%d+:%d+:%d+:%d+|h%[Keystone: (.+) %((%d+)%)%]|h|r")
                if dungeon and level then
                    return dungeon, level
                end
            end
        end
    end
    return false, false
end]]

local function GetKeystoneDungeonAbbreviation(mapName)
    local abbrev = ""
    for match in gmatch(mapName, "%S+") do
        abbrev = ("%s%s"):format(abbrev, (mapName:find("of the") ~= nil and (match == "of" or match == "the")) and "" or match:sub(1, 1):upper())
    end

    return abbrev
end

local function GetKeystoneDungeonList()
    local maps = C_ChallengeMode_GetMapTable()
    for i = 1, #maps do
        local mapName, _, _, _ = C_ChallengeMode_GetMapUIInfo(maps[i])
        dungeons[maps[i]] = { id = maps[i], name = mapName, abbrev = GetKeystoneDungeonAbbreviation(mapName), timerData = timerData[maps[i]] }
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

    DT:SetupTooltip(self)

    if keystoneId ~= nil then
        DT.tooltip:AddLine(L["Your Keystone"])
        DT.tooltip:AddDoubleLine(L["Dungeon"], dungeons[keystoneId].name, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
        DT.tooltip:AddDoubleLine(L["Level"], keystoneLevel, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
        DT.tooltip:AddLine(" ")
    end

    --[[if E.db.mplusdt.includeLegion and timewalkingActive then
        local legionKey, legionLevel = GetLegionTimewalkingKeystone()
        if legionKey ~= false and legionLevel ~= false then
            DT.tooltip:AddLine(L["Legion Timewalking Keystone"])
            DT.tooltip:AddDoubleLine(L["Dungeon"], legionKey, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
            DT.tooltip:AddDoubleLine(L["Level"], legionLevel, 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
            DT.tooltip:AddLine(" ")
        end
    end]]

    DT.tooltip:AddLine((L["Season %d"]):format(C_MythicPlus_GetCurrentSeason() - 8))
    DT.tooltip:AddDoubleLine(L["Mythic+ Rating"], currentScore, 1, 1, 1, color.r, color.g, color.b)
    DT.tooltip:AddDoubleLine(L["Affixes"], ("%s, %s, %s, %s"):format(affixes[currentAffixes[1].id], affixes[currentAffixes[2].id], affixes[currentAffixes[3].id], affixes[currentAffixes[4].id]), 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
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
                    for _, affixInfo in ipairs(affixScores) do
                        if affixInfo.overTime then
                            if affixInfo.durationSec >= SECONDS_PER_HOUR then
                                DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%s%d)"):format(SecondsToClock(affixInfo.durationSec, true), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b, LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b)
                            else
                                DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%s%d)"):format(SecondsToClock(affixInfo.durationSec, false), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b, LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b)
                            end
                        else
                            if affixInfo.durationSec >= SECONDS_PER_HOUR then
                                DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%s%d)"):format(SecondsToClock(affixInfo.durationSec, true), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), 1, 1, 1, 1, 1, 1)
                            else
                                DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%s%d)"):format(SecondsToClock(affixInfo.durationSec, false), GetPlusString(affixInfo.durationSec, map.timerData), affixInfo.level), 1, 1, 1, 1, 1, 1)
                            end
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

local function OnEvent(self)
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
        E.db.mplusdt.labelText == "none" and "" or join("", labelText[E.db.mplusdt.labelText], ": "),
        ("%s%s"):format(instanceName, E.db.mplusdt.includeLevel == true and (" %d"):format(keystoneLevel) or "")
    )

    --[[if timewalkingActive == nil then
        timewalkingActive = IsLegionTimewalkingActive()
    end]]
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

local function ValueColorUpdate(self, hex, r, g, b)
    displayString = join("", "|cffffffff%s|r", hex, "%s|r")
    mpErrorString = join("", hex, "%s|r")
    currentKeyString = join("", hex, "%s|r |cffffffff%s|r")

    rgbColor.r = r
    rgbColor.g = g
    rgbColor.b = b

    OnEvent(self)
end

P["mplusdt"] = {
    ["labelText"] = "key",
    ["abbrevName"] = true,
    ["includeLevel"] = true,
    --["includeLegion"] = true,
    ["highlightKey"] = true,
    ["highlightColor"] = {
        r = GetClassColor("r"),
        g = GetClassColor("g"),
        b = GetClassColor("b")
    }
}

local function InjectOptions()
    if not E.Options.args.Crackpotx then
        E.Options.args.Crackpotx = {
            type = "group",
            order = -2,
            name = L["Plugins by |cff0070deCrackpotx|r"],
            args = {
                thanks = {
                    type = "description",
                    order = 1,
                    name = L[
                        "Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."
                    ]
                }
            }
        }
    elseif not E.Options.args.Crackpotx.args.thanks then
        E.Options.args.Crackpotx.args.thanks = {
            type = "description",
            order = 1,
            name = L[
                "Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."
            ]
        }
    end

    E.Options.args.Crackpotx.args.mplusdt = {
        type = "group",
        name = L["Mythic+ Datatext"],
        get = function(info)
            return E.db.mplusdt[info[#info]]
        end,
        set = function(info, value)
            E.db.mplusdt[info[#info]] = value
            DT:LoadDataTexts()
        end,
        args = {
            labelText = {
                type = "select",
                order = 4,
                name = L["Datatext Label"],
                desc = L["Choose how to label the datatext."],
                values = {
                    ["mpKey"] = L["M+ Key"],
                    ["mplusKey"] = L["Mythic+ Key"],
                    ["mplusKeystone"] = L["Mythic+ Keystone"],
                    ["keystone"] = L["Keystone"],
                    ["key"] = L["Key"],
                    ["none"] = L["None"],
                }
            },
            abbrevName = {
                type = "toggle",
                order = 5,
                name = L["Abbreviate Instance Name"],
                desc = L["Abbreviate instance name in the datatext."]
            },
            includeLevel = {
                type = "toggle",
                order = 6,
                name = L["Include Level"],
                desc = L["Include your keystone's level in the datatext."]
            },
            --[[includeLegion = {
                type = "toggle",
                order = 7,
                name = L["Include Legion TW"],
                desc = L["Include Legion Timewalking key in the tooltip"],
                disabled = function() return not IsLegionTimewalkingActive() end,
            },]]
            highlightKey = {
                type = "toggle",
                order = 8,
                name = L["Highlight Your Key"],
                desc = L["Highlight your key in the tooltip for the datatext."],
            },
            highlightColor = {
                type = "color",
                order = 9,
                name = L["Highlight Color"],
                desc = L["Color to highlight your key."],
                hasAlpha = false,
                disabled = function() return not E.db.mplusdt.highlightKey end,
                get = function() return E.db.mplusdt.highlightColor.r, E.db.mplusdt.highlightColor.g, E.db.mplusdt.highlightColor.b end,
                set = function(_, r, g, b) E.db.mplusdt.highlightColor.r = r; E.db.mplusdt.highlightColor.g = g; E.db.mplusdt.highlightColor.b = b end,
            },
        }
    }
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("Mythic+", nil, {"PLAYER_ENTERING_WORLD", "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE", "MYTHIC_PLUS_NEW_WEEKLY_RECORD"}, OnEvent, OnUpdate,  OnClick,  OnEnter, nil, L["Mythic+"], nil, ValueColorUpdate)

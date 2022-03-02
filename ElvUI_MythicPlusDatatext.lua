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
local C_ChallengeMode_GetOverallDungeonScore = C_ChallengeMode.GetOverallDungeonScore
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local C_MythicPlus_GetCurrentSeason = C_MythicPlus.GetCurrentSeason
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_MythicPlus_GetSeasonBestForMap = C_MythicPlus.GetSeasonBestForMap
local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local CreateFrame = _G["CreateFrame"]
local IsAddOnLoaded = _G["IsAddOnLoaded"]
local LoadAddOn = _G["LoadAddOn"]
local ToggleLFDParentFrame = _G["ToggleLFDParentFrame"]

local join = string.join
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
local lastPanel

local labelText = {
    ["mpKey"] = L["M+ Key"],
    ["mplusKey"] = L["Mythic+ Key"],
    ["mplusKeystone"] = L["Mythic+ Keystone"],
    ["keystone"] = L["Keystone"],
    ["key"] = L["Key"],
    ["none"] = ""
}

local dungeons = {
    [375] = {id = 375, name = L["Mists of Tirna Scithe"], abbrev = L["MOTS"]},
    [376] = {id = 376, name = L["The Necrotic Wake"], abbrev = L["NW"]},
    [377] = {id = 377, name = L["De Other Side"], abbrev = L["DOS"]},
    [378] = {id = 378, name = L["Halls of Atonement"], abbrev = L["HOA"]},
    [379] = {id = 379, name = L["Plaguefall"], abbrev = L["PF"]},
    [380] = {id = 380, name = L["Sanguine Depths"], abbrev = L["SD"]},
    [381] = {id = 381, name = L["Spires of Ascension"], abbrev = L["SOA"]},
    [382] = {id = 382, name = L["Theater of Pain"], abbrev = L["TOP"]},
    [391] = {id = 391, name = L["Streets of Wonder"], abbrev = L["T:SOW"]},
    [392] = {id = 392, name = L["So'leah's Gambit"], abbrev = L["T:SG"]},
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
    [130] = L["Encrypted"],
}

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
    DT.tooltip:AddLine((L["Season %d"]):format(C_MythicPlus_GetCurrentSeason()))
    DT.tooltip:AddDoubleLine(L["Mythic+ Rating"], currentScore, 1, 1, 1, color.r, color.g, color.b)
    DT.tooltip:AddDoubleLine(L["Affixes"], ("%s, %s, %s, %s"):format(affixes[currentAffixes[1].id], affixes[currentAffixes[2].id], affixes[currentAffixes[3].id], affixes[currentAffixes[4].id]), 1, 1, 1, rgbColor.r, rgbColor.g, rgbColor.b)
    DT.tooltip:AddLine(" ")

    if currentScore > 0 then
        for _, map in pairs(dungeons) do
            local inTimeInfo, overTimeInfo = C_MythicPlus_GetSeasonBestForMap(map.id)
            local affixScores, overAllScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(map.id)

            if overAllScore and inTimeInfo or overTimeInfo then
                local dungeonColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(overAllScore)
                if not dungeonColor then
                    dungeonColor = HIGHLIGHT_FONT_COLOR
                end
                DT.tooltip:AddDoubleLine(map.name, overAllScore, nil, nil, nil, dungeonColor.r, dungeonColor.g, dungeonColor.b)
            else
                DT.tooltip:AddLine(map.name)
            end
        
            if affixScores and #affixScores > 0 then
                for _, affixInfo in ipairs(affixScores) do
                    if affixInfo.overTime then
                        if affixInfo.durationSec >= SECONDS_PER_HOUR then
                            DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%d)"):format(SecondsToClock(affixInfo.durationSec, true), affixInfo.level), LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b, LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b)
                        else
                            DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%d)"):format(SecondsToClock(affixInfo.durationSec, false), affixInfo.level), LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b, LIGHTGRAY_FONT_COLOR.r, LIGHTGRAY_FONT_COLOR.g, LIGHTGRAY_FONT_COLOR.b)
                        end
                    else
                        if affixInfo.durationSec >= SECONDS_PER_HOUR then
                            DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%d)"):format(SecondsToClock(affixInfo.durationSec, true), affixInfo.level), 1, 1, 1, 1, 1, 1)
                        else
                            DT.tooltip:AddDoubleLine(affixInfo.name, ("%s (%d)"):format(SecondsToClock(affixInfo.durationSec, false), affixInfo.level), 1, 1, 1, 1, 1, 1)
                        end
                    end
                end
            end
            DT.tooltip:AddLine(" ")
        end
    end

    DT.tooltip:AddDoubleLine(L["Left-Click"], L["Toggle Mythic+ Page"], nil, nil, nil, 1, 1, 1)
    DT.tooltip:AddDoubleLine(L["Right-Click"], L["Toggle Great Vault"], nil, nil, nil, 1, 1, 1)
    
    DT.tooltip:Show()
end

local function OnEvent(self, event, ...)
    lastPanel = self

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

local function ValueColorUpdate(hex, r, g, b)
    displayString = join("", "|cffffffff%s|r", hex, "%s|r")
    mpErrorString = join("", hex, "%s|r")
    currentKeyString = join("", hex, "%s|r |cffffffff%s|r")

    rgbColor.r = r
    rgbColor.g = g
    rgbColor.b = b

    if lastPanel ~= nil then
        OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
    end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

P["mplusdt"] = {
    ["labelText"] = "key",
    ["abbrevName"] = true,
    ["includeLevel"] = true
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
            }
        }
    }
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext(
    "Mythic+",
    nil,
    {"PLAYER_ENTERING_WORLD", "MYTHIC_PLUS_NEW_SEASON_RECORD", "MYTHIC_PLUS_NEW_WEEKLY_RECORD"},
    OnEvent,
    OnUpdate,
    OnClick,
    OnEnter,
    nil,
    L["Mythic+"]
)

-------------------------------------------------------------------------------
-- ElvUI Mythic+ Datatext By Crackpotx
-------------------------------------------------------------------------------
--[[
      
MIT License

Copyright (c) 2021 Adam Koch

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

local C_MythicPlus_GetOwnedKeystoneChallengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID
local C_MythicPlus_GetOwnedKeystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel
local CreateFrame = _G["CreateFrame"]

local join = string.join

local displayString = ""
local mpErrorString = ""
local lastPanel

local dungeons = {
    [375] = {name = L["Mists of Tirna Scithe"], abbrev = L["MOTS"]},
    [376] = {name = L["The Necrotic Wake"], abbrev = L["NW"]},
    [377] = {name = L["De Other Side"], abbrev = L["DOS"]},
    [378] = {name = L["Halls of Atonement"], abbrev = L["HOA"]},
    [379] = {name = L["Plaguefall"], abbrev = L["PF"]},
    [380] = {name = L["Sanguine Depths"], abbrev = L["SD"]},
    [381] = {name = L["Spires of Ascension"], abbrev = L["SOA"]},
    [382] = {name = L["Theater of Pain"], abbrev = L["TOP"]}
}

local function OnEnter(self)
end

local function OnEvent(self, event, ...)
    lastPanel = self

    local keystoneId, keystoneLevel =
        C_MythicPlus_GetOwnedKeystoneChallengeMapID(),
        C_MythicPlus_GetOwnedKeystoneLevel()
    if not keystoneId or dungeons[keystoneId] == nil then
        self.text:SetFormattedText(mpErrorString, L["Invalid Keystone"])
        return
    end
    local instanceName = E.db.mplusdt.abbrevName == true and dungeons[keystoneId].abbrev or dungeons[keystoneId].name
    self.text:SetFormattedText(
        displayString,
        L["M+ Key"],
        ("%s%s"):format(instanceName, E.db.mplusdt.includeLevel == true and (" %d"):format(keystoneLevel) or "")
    )
end

local interval = 15
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
end

local function ValueColorUpdate(hex, r, g, b)
    displayString = join("", "|cffffffff%s:|r", " ", hex, "%s|r")
    mpErrorString = join("", hex, "%s|r")

    if lastPanel ~= nil then
        OnEvent(lastPanel, "ELVUI_COLOR_UPDATE")
    end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

P["mplusdt"] = {
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
            abbrevName = {
                type = "toggle",
                order = 4,
                name = L["Abbreviate Instance Name"],
                desc = L["Abbreviate instance name in the datatext."]
            },
            includeLevel = {
                type = "toggle",
                order = 5,
                name = L["Include Level"],
                desc = L["Include your keystone's level in the datatext."]
            }
        }
    }
end

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

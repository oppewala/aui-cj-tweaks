---@class CrackedJarTweaks : AceAddon, AceEvent-3.0, AceHook-3.0, AceConsole-3.0
local CJ = LibStub("AceAddon-3.0"):NewAddon("CrackedJarTweaks", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")

_G["CrackedJarTweaks"] = CJ

local optionsFrame
function CJ:OnInitialize()
    local defaults = {
        global = {
            profiles = {
                atrocityUI = "AtrocityUI",
                atrocityUIColor = "AtrocityUI [C]",
                atrocityUIHealer = "AtrocityUI Healer",
                atrocityUIHealerColor = "AtrocityUI Healer [C]"
            }
        },
    }

    self.db = LibStub("AceDB-3.0"):New("CrackedJarTweaksDB", defaults)

    local options = {
        name = "CrackedJarTweaks",
        handler = CJ,
        type = "group",
        args = {
            general = {
                order = 1,
                name = "General Tweaks",
                type = "group",
                args = {
                    apply = {
                        order = 1000,
                        name = "Apply Tweaks",
                        desc = "Use this button to apply any the tweaks you have enabled.",
                        type = "execute",
                        func = function () return CJ:ApplyAtrocityTweaks() end
                    }
                }
            }
        }
    }

    AceConfig:RegisterOptionsTable("CrackedJarTweaks", options)
    optionsFrame = AceConfigDialog:AddToBlizOptions("CrackedJarTweaks", "CrackedJarTweaks")

    self:RegisterChatCommand("cj", "ChatCommand")
end

function CJ:OnEnable()
end

function CJ:OnDisable()
end

function CJ:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(optionsFrame)
        return
    end

    if input:trim() == "apply" then
        CJ:ApplyAtrocityTweaks()
        return
    end
    
    AceConfigCmd.HandleCommand(CJ, "cj", "CrackedJarTweaks", input)
end
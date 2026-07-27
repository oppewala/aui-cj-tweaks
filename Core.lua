---@class CrackedJarTweaks : AceAddon, AceEvent-3.0, AceHook-3.0, AceConsole-3.0
local CJ = LibStub("AceAddon-3.0"):NewAddon("CrackedJarTweaks", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")

_G["CrackedJarTweaks"] = CJ

local optionsFrame
function CJ:OnInitialize()
    local sw = GetScreenWidth() * UIParent:GetEffectiveScale()
    local sh = GetScreenHeight() * UIParent:GetEffectiveScale()
    local aspectRatio = sw / sh
    local defaults = {
        global = {
            profiles = {
                atrocityUI = "atrocityUI",
                atrocityUIColor = "atrocityUI [C]",
                atrocityUIHealer = "atrocityUI Healer",
                atrocityUIHealerColor = "atrocityUI Healer [C]"
            },
            elvUi = {
                disableBags = true,
                primaryActionBars = true,
                secondaryActionBars = true,
                panels = true,
                -- If aspect ratio is greater than 2.3, assume ultrawide, else standard. Set to true by default for ultrawide.
                unitFrames = (aspectRatio > 2.3)
            }
        },
        profile = {
        }
    }

    self.db = LibStub("AceDB-3.0"):New("CrackedJarTweaksDB", defaults)

    local options = {
        name = "CrackedJarTweaks",
        handler = CJ,
        type = "group",
        args = {
            apply = {
                order = 1000,
                name = "Apply Tweaks",
                desc = "Use this button to apply any the tweaks you have enabled.",
                type = "execute",
                func = function () return CJ:ApplyTweaks() end
            },
            elvUi = {
                order = 1,
                name = "ElvUI Tweaks",
                type = "group",
                args = {
                    primaryActionBars = {
                        name = "Primary Action Bars",
                        desc = "Show primary action bars and move them to the center bottom of the screen.",
                        type = "toggle",
                        get = function() return self.db.global.elvUi.primaryActionBars end,
                        set = function(_, val) self.db.global.elvUi.primaryActionBars = val end
                    },
                    secondaryActionBars = {
                        name = "Secondary Action Bars",
                        desc = "Show secondary action bars and move them to the bottom left of the screen.",
                        type = "toggle",
                        get = function() return self.db.global.elvUi.secondaryActionBars end,
                        set = function(_, val) self.db.global.elvUi.secondaryActionBars = val end
                    },
                    panels = {
                        name = "Panels",
                        desc = "Increase the size of the left and right panels.",
                        type = "toggle",
                        get = function() return self.db.global.elvUi.panels end,
                        set = function(_, val) self.db.global.elvUi.panels = val end
                    },
                    disableBags = {
                        name = "Disable Bags",
                        desc = "Disable ElvUI bag management so you can use another bag addon.",
                        type = "toggle",
                        get = function() return self.db.global.elvUi.disableBags end,
                        set = function(_, val) self.db.global.elvUi.disableBags = val end
                    },
                    unitFrames = {
                        name = "Unit Frames",
                        desc = "Tweak unit frames positions for ultrawide displays.",
                        type = "toggle",
                        get = function() return self.db.global.elvUi.unitFrames end,
                        set = function(_, val) self.db.global.elvUi.unitFrames = val end
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
        Settings.OpenToCategory(optionsFrame.name)
        return
    end

    if input:trim() == "apply" then
        CJ:ApplyTweaks()
        return
    end
    
    AceConfigCmd.HandleCommand(CJ, "cj", "CrackedJarTweaks", input)
end

function CJ:ApplyTweaks()
    local opts = self.db.global

    CJ:ApplyElvUITweaks(opts)
    CJ:ApplyDetailsTweaks(opts)

    -- TODO
    -- Pop up message to move quest log in edit mode after applying tweaks
    -- Move falcon to top part of screen
    -- Better Cooldown Manager - Add and move Additional Custom for additional tracked auras

    -- ApplyWeakAurasTweaks(opts)
    -- ApplyOmniCDTweaks(opts)

    ReloadUI()
end
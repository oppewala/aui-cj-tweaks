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
            euiProfile = "atrocityUI",
            eui = {
                primaryActionBars = true,
                secondaryActionBars = true,
                raidFrames = true,
                damageMeters = true,
                -- If aspect ratio is greater than 2.3, assume ultrawide, else standard. Set to true by default for ultrawide.
                unitFrames = (aspectRatio > 2.3)
            },
            chat = {
                width = 500
            },
            -- Height of everything along the bottom of the screen.
            bottomStripHeight = 220,
            -- Damage + healing meter windows, combined. They sit edge to edge, so
            -- each window is half of this.
            meterWidth = 404
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
            eui = {
                order = 1,
                name = "EllesmereUI Tweaks",
                type = "group",
                args = {
                    euiProfile = {
                        order = 0,
                        name = "Profile",
                        desc = "The EllesmereUI profile to write tweaks into.",
                        type = "input",
                        get = function() return self.db.global.euiProfile end,
                        set = function(_, val) self.db.global.euiProfile = val end
                    },
                    primaryActionBars = {
                        name = "Primary Action Bars",
                        desc = "Stack Bar2 and Bar3 above the main bar, matching its settings.",
                        type = "toggle",
                        get = function() return self.db.global.eui.primaryActionBars end,
                        set = function(_, val) self.db.global.eui.primaryActionBars = val end
                    },
                    secondaryActionBars = {
                        name = "Secondary Action Bars",
                        desc = "Make Bar4 and Bar5 a 2x6 cluster beside the chat panel, and hang the pet bar off the damage meter.",
                        type = "toggle",
                        get = function() return self.db.global.eui.secondaryActionBars end,
                        set = function(_, val) self.db.global.eui.secondaryActionBars = val end
                    },
                    raidFrames = {
                        name = "Raid Frames",
                        desc = "Show role icons for tanks and healers only.",
                        type = "toggle",
                        get = function() return self.db.global.eui.raidFrames end,
                        set = function(_, val) self.db.global.eui.raidFrames = val end
                    },
                    unitFrames = {
                        name = "Unit Frames",
                        desc = "Tweak unit frame positions for ultrawide displays.",
                        type = "toggle",
                        get = function() return self.db.global.eui.unitFrames end,
                        set = function(_, val) self.db.global.eui.unitFrames = val end
                    },
                    damageMeters = {
                        name = "Damage Meters",
                        desc = "Size and position the damage meter windows.",
                        type = "toggle",
                        get = function() return self.db.global.eui.damageMeters end,
                        set = function(_, val) self.db.global.eui.damageMeters = val end
                    }
                }
            },
            chat = {
                order = 2,
                name = "Bottom Strip",
                type = "group",
                args = {
                    bottomStripHeight = {
                        order = 0,
                        name = "Height",
                        desc = "Height of the whole bottom strip: chat panel, Bar4/Bar5, pet bar and the damage meter windows. Button sizes are derived from it.",
                        type = "range",
                        min = 100, max = 400, step = 1, bigStep = 5,
                        get = function() return self.db.global.bottomStripHeight end,
                        set = function(_, val) self.db.global.bottomStripHeight = math.floor(val) end
                    },
                    meterWidth = {
                        order = 1,
                        name = "Meter Width (combined)",
                        desc = "Total width of the damage and healing meter windows together. They sit edge to edge, so each gets half.",
                        type = "range",
                        min = 200, max = 1200, step = 2, bigStep = 20,
                        get = function() return self.db.global.meterWidth end,
                        set = function(_, val) self.db.global.meterWidth = math.floor(val) end
                    },
                    width = {
                        order = 2,
                        name = "Chat Panel Width",
                        desc = "Width of the atrocityEssentials chat panel. Bar4 sits just right of it.",
                        type = "range",
                        min = 300, max = 900, step = 1, bigStep = 10,
                        get = function() return self.db.global.chat.width end,
                        set = function(_, val) self.db.global.chat.width = math.floor(val) end
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

    -- Before EllesmereUI: Bar4 is placed off the chat panel's right edge.
    CJ:ApplyAtrocityEssentialsTweaks(opts)

    if not CJ:ApplyEllesmereUITweaks(opts) then
        return
    end

    CJ:ApplyEditModeTweaks()

    -- TODO
    -- Pop up message to move quest log in edit mode after applying tweaks
    -- Move falcon to top part of screen
    -- Better Cooldown Manager - Add and move Additional Custom for additional tracked auras

    -- ApplyWeakAurasTweaks(opts)
    -- ApplyOmniCDTweaks(opts)

    -- The meter and action bar modules read their profile at login, so the
    -- writes above are invisible until this runs.
    ReloadUI()
end
---@class CrackedJarTweaks : AceAddon, AceEvent-3.0, AceHook-3.0, AceConsole-3.0
local CJ = LibStub("AceAddon-3.0"):NewAddon("CrackedJarTweaks", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")

_G["CrackedJarTweaks"] = CJ

local defaults = {
    global = {
        euiProfile = "atrocityUI",
        eui = {
            primaryActionBars = true,
            secondaryActionBars = true,
            raidFrames = true,
            damageMeters = true
        },
        debug = false
    }
}

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
            func = function() return CJ:ApplyTweaks() end
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
                    get = function() return CJ.db.global.euiProfile end,
                    set = function(_, val) CJ.db.global.euiProfile = val end
                },
                primaryActionBars = {
                    name = "Primary Action Bars",
                    desc = "Stack Bar2 and Bar3 above the main bar, matching its settings.",
                    type = "toggle",
                    get = function() return CJ.db.global.eui.primaryActionBars end,
                    set = function(_, val) CJ.db.global.eui.primaryActionBars = val end
                },
                secondaryActionBars = {
                    name = "Secondary Action Bars",
                    desc = "Show Bar4/Bar5 always with Bar5 beside Bar4, and match the pet bar height to the Damage Done window.",
                    type = "toggle",
                    get = function() return CJ.db.global.eui.secondaryActionBars end,
                    set = function(_, val) CJ.db.global.eui.secondaryActionBars = val end
                },
                raidFrames = {
                    name = "Raid Frames",
                    desc = "Show role icons for tanks and healers only.",
                    type = "toggle",
                    get = function() return CJ.db.global.eui.raidFrames end,
                    set = function(_, val) CJ.db.global.eui.raidFrames = val end
                },
                damageMeters = {
                    name = "Damage Meters",
                    desc = "Size and position the damage meter windows.",
                    type = "toggle",
                    get = function() return CJ.db.global.eui.damageMeters end,
                    set = function(_, val) CJ.db.global.eui.damageMeters = val end
                }
            }
        },
        debug = {
            order = 999,
            name = "Debug",
            desc = "Print the geometry each apply works out, and skip the reload at the end so the numbers stay on screen.",
            type = "toggle",
            get = function() return CJ.db.global.debug end,
            set = function(_, val) CJ.db.global.debug = val end
        }
    }
}

local optionsFrame
function CJ:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CrackedJarTweaksDB", defaults)

    AceConfig:RegisterOptionsTable("CrackedJarTweaks", options)
    optionsFrame = AceConfigDialog:AddToBlizOptions("CrackedJarTweaks", "CrackedJarTweaks")

    self:RegisterChatCommand("cj", "ChatCommand")
end

-- Geometry the layout math worked out, for hand-tuning the numbers against. Off
-- by default: these fire several times per apply, which is a lot of chat for
-- something only useful while tuning.
function CJ:Debug(fmt, ...)
    if not self.db.global.debug then return end
    self:Print(fmt:format(...))
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

    CJ:ApplyAtrocityEssentialsTweaks()

    if not CJ:ApplyEllesmereUITweaks(opts) then
        return
    end

    if opts.debug then
        CJ:Print("Debug mode: skipping the reload. /reload when you are done reading.")
        return
    end

    -- The meter and action bar modules read their profile at login, so the
    -- writes above are invisible until this runs.
    ReloadUI()
end

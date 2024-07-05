---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

local function ApplyWeakAurasTweaks(opts)
    WeakAurasSaved["displays"]["Missing Buffs"]["xOffset"] = -1716 -- -1276
    WeakAurasSaved["displays"]["Combat Ress"]["xOffset"] = -1658 -- -1218
    WeakAurasSaved["displays"]["Combat Time"]["xOffset"] = -1315 -- -877

    WeakAurasSaved["displays"]["Combat Ress"]["yOffset"] = -455 -- -466
    WeakAurasSaved["displays"]["Combat Time"]["yOffset"] = -455 -- -466
end

local function ApplyOmniCDTweaks(opts)
    local profile = OmniCDDB["profiles"][opts.profiles.atrocityUI]
    profile["Party"]["party"]["extraBars"]["raidBar1"]["manualPos"]["raidBar1"]["x"] = 514.9332700888335
    profile["Party"]["party"]["extraBars"]["raidBar1"]["manualPos"]["raidBar1"]["y"] = 434.4000392119051

    profile["Party"]["party"]["extraBars"]["raidBar2"]["manualPos"]["raidBar2"]["x"] = 514.9332700888335
    profile["Party"]["party"]["extraBars"]["raidBar2"]["manualPos"]["raidBar2"]["y"] = 311.7332822004973

    local healerProfile = OmniCDDB["profiles"][opts.profiles.atrocityUIHealer]
    healerProfile["Party"]["party"]["extraBars"]["raidBar1"]["manualPos"]["raidBar1"]["x"] = 1065.866798448551
end

local function ApplyDetailsTweaks(opts)
    for id, instance in Details:ListInstances() do
        instance.row_info.height = 24

        local position = instance:CreatePositionTable()

        -- Main damage window
        if id == 1 then
            position.h = 226 --217
        end

        -- Healing window
        if id == 2 then
            position.h = 132
        end

        -- Deaths window
        if id == 3 then
            position.h = 76
        end

        instance:RestorePositionFromPositionTable(position)
    end

    Details.tooltip.rounded_corner = false

    Details.tooltip.anchor_screen_pos = { 1194, -710 } -- 1144
    Details.tooltip.anchored_to = 2
    Details.tooltip.anchor_point = "bottomright"
    Details.tooltip.anchor_relative = "bottomright"
    Details.tooltip.anchor_offset = { 0, -6 }

    Details:SaveProfile()
    Details:ApplyProfile(opts.profiles.atrocityUI, false)
end

function CJ:ApplyAtrocityTweaks()
    local opts = self.db.global

    CJ:ApplyElvUITweaks(opts)

    ApplyWeakAurasTweaks(opts)
    ApplyOmniCDTweaks(opts)
    ApplyDetailsTweaks(opts)

    ReloadUI()
end


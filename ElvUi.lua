---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

local function DisableBags(elvPriv, elvPrivColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elvPriv["bags"] = elvPriv["bags"] or {}
        elvPriv["bags"]["enable"] = false
    end

    if (elvPrivColor ~= nil) then
        elvPrivColor["bags"] = elvPrivColor["bags"] or {}
        elvPrivColor["bags"]["enable"] = false
    end

    if (elvPrivHealer ~= nil) then
        elvPrivHealer["bags"] = elvPrivHealer["bags"] or {}
        elvPrivHealer["bags"]["enable"] = false
    end

    if (elvPrivHealerColor ~= nil) then
        elvPrivHealerColor["bags"] = elvPrivHealerColor["bags"] or {}
        elvPrivHealerColor["bags"]["enable"] = false
    end
end

local function ConfigurePrimaryActionBars(elv, elvColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elv["actionbar"]["bar1"]["heightMult"] = 3
        elv["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,68"
        elv["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,0,37"
        elv["actionbar"]["bar6"]["buttonSize"] = 30
        elv["actionbar"]["bar6"]["buttonsPerRow"] = 12
        elv["actionbar"]["bar6"]["backdrop"] = false
    end

    if (elvColor ~= nil) then
        elvColor["actionbar"]["bar1"]["heightMult"] = 3
        elvColor["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,68"
        elvColor["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,1,37"
        elvColor["actionbar"]["bar6"]["buttonSize"] = 30
        elvColor["actionbar"]["bar6"]["buttonsPerRow"] = 12
        elvColor["actionbar"]["bar6"]["backdrop"] = false
    end

    if (elvHealer ~= nil) then
        elvHealer["actionbar"]["bar1"]["heightMult"] = 3
        elvHealer["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,1,64"
        elvHealer["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,1,34"
        elvHealer["actionbar"]["bar6"]["buttonSize"] = 28
        elvHealer["actionbar"]["bar6"]["buttonsPerRow"] = 12
        elvHealer["actionbar"]["bar6"]["backdrop"] = false
    end

    if (elvHealerColor ~= nil) then
        elvHealerColor["actionbar"]["bar1"]["heightMult"] = 3
        elvHealerColor["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,1,64"
        elvHealerColor["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,1,34"
        elvHealerColor["actionbar"]["bar6"]["buttonSize"] = 28
        elvHealerColor["actionbar"]["bar6"]["buttonsPerRow"] = 12
        elvHealerColor["actionbar"]["bar6"]["backdrop"] = false
    end
end

local function ConfigureLeftActionBars(elv, elvColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elv["actionbar"]["bar3"]["mouseover"] = false
        elv["actionbar"]["bar3"]["buttons"] = 12
        elv["actionbar"]["bar3"]["buttonSpacing"] = 1
        elv["actionbar"]["bar3"]["buttonSize"] = 40
        elv["actionbar"]["bar3"]["widthMult"] = 2
        elv["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,489,5"
        elv["actionbar"]["bar4"]["buttonSize"] = 40
        elv["actionbar"]["bar4"]["buttonsPerRow"] = 2
        elv["actionbar"]["bar4"]["backdrop"] = false
    end

    if (elvColor ~= nil) then
        elvColor["actionbar"]["bar3"]["mouseover"] = false
        elvColor["actionbar"]["bar3"]["buttons"] = 12
        elvColor["actionbar"]["bar3"]["buttonSpacing"] = 1
        elvColor["actionbar"]["bar3"]["buttonSize"] = 40
        elvColor["actionbar"]["bar3"]["widthMult"] = 2
        elvColor["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,489,5"
        elvColor["actionbar"]["bar4"]["buttonSize"] = 40
        elvColor["actionbar"]["bar4"]["buttonsPerRow"] = 2
        elvColor["actionbar"]["bar4"]["backdrop"] = false
    end

    if (elvHealer ~= nil) then
        elvHealer["actionbar"]["bar3"]["mouseover"] = false
        elvHealer["actionbar"]["bar3"]["buttons"] = 12
        elvHealer["actionbar"]["bar3"]["buttonSpacing"] = 1
        elvHealer["actionbar"]["bar3"]["buttonSize"] = 40
        elvHealer["actionbar"]["bar3"]["widthMult"] = 2
        elvHealer["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,489,5"
        elvHealer["actionbar"]["bar4"]["buttonSize"] = 40
        elvHealer["actionbar"]["bar4"]["buttonsPerRow"] = 2
        elvHealer["actionbar"]["bar4"]["backdrop"] = false
    end

    if (elvHealerColor ~= nil) then
        elvHealerColor["actionbar"]["bar3"]["mouseover"] = false
        elvHealerColor["actionbar"]["bar3"]["buttons"] = 12
        elvHealerColor["actionbar"]["bar3"]["buttonSpacing"] = 1
        elvHealerColor["actionbar"]["bar3"]["buttonSize"] = 40
        elvHealerColor["actionbar"]["bar3"]["widthMult"] = 2
        elvHealerColor["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,489,5"
        elvHealerColor["actionbar"]["bar4"]["buttonSize"] = 40
        elvHealerColor["actionbar"]["bar4"]["buttonsPerRow"] = 2
        elvHealerColor["actionbar"]["bar4"]["backdrop"] = false
    end

    if (elv ~= nil and elv["actionbar"]["bar4"]["professionQuality"] ~= nil) then
        elv["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    end
    if (elvColor ~= nil and elvColor["actionbar"]["bar4"]["professionQuality"] ~= nil) then
        elvColor["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    end
    if (elvHealer ~= nil and elvHealer["actionbar"]["bar4"]["professionQuality"] ~= nil) then
        elvHealer["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    end
    if (elvHealerColor ~= nil and elvHealerColor["actionbar"]["bar4"]["professionQuality"] ~= nil) then
        elvHealerColor["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    end
end

local function ConfigurePetBars(elv, elvColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elv["actionbar"]["barPet"]["mouseover"] = false
        elv["actionbar"]["barPet"]["buttons"] = 12
        elv["actionbar"]["barPet"]["buttonSpacing"] = 1
        elv["actionbar"]["barPet"]["buttonSize"] = 40
    end

    if (elvColor ~= nil) then
        elvColor["actionbar"]["barPet"]["mouseover"] = false
        elvColor["actionbar"]["barPet"]["buttons"] = 12
        elvColor["actionbar"]["barPet"]["buttonSpacing"] = 1
        elvColor["actionbar"]["barPet"]["buttonSize"] = 40
    end

    if (elvHealer ~= nil) then
        elvHealer["actionbar"]["barPet"]["mouseover"] = false
        elvHealer["actionbar"]["barPet"]["buttons"] = 12
        elvHealer["actionbar"]["barPet"]["buttonSpacing"] = 1
        elvHealer["actionbar"]["barPet"]["buttonSize"] = 40
    end

    if (elvHealerColor ~= nil) then
        elvHealerColor["actionbar"]["barPet"]["mouseover"] = false
        elvHealerColor["actionbar"]["barPet"]["buttons"] = 12
        elvHealerColor["actionbar"]["barPet"]["buttonSpacing"] = 1
        elvHealerColor["actionbar"]["barPet"]["buttonSize"] = 40
    end
end

local function ConfigurePanels(elv, elvColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elv["chat"]["panelHeight"] = 249
        elv["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
        elv["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    end

    if (elvColor ~= nil) then
        elvColor["chat"]["panelHeight"] = 249
        elvColor["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
        elvColor["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    end

    if (elvHealer ~= nil) then
        elvHealer["chat"]["panelHeight"] = 249
        elvHealer["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
        elvHealer["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    end

    if (elvHealerColor ~= nil) then
        elvHealerColor["chat"]["panelHeight"] = 249
        elvHealerColor["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
        elvHealerColor["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    end
end

local function ConfigureRaidFrames(elv, elvColor, elvHealer, elvHealerColor)
    if (elv ~= nil) then
        elv["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
        elv["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
        elv["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
    end

    if (elvColor ~= nil) then
        elvColor["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
        elvColor["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
        elvColor["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
    end

    -- Enable Role Icons for raid
    if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
        elv["unitframe"]["units"]["raid1"]["roleIcon"] = elv["unitframe"]["units"]["raid1"]["roleIcon"] or {}
        elvColor["unitframe"]["units"]["raid1"]["roleIcon"] = elvColor["unitframe"]["units"]["raid1"]["roleIcon"] or {}
        elvHealer["unitframe"]["units"]["raid1"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid1"]["roleIcon"] or {}
        elvHealerColor["unitframe"]["units"]["raid1"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid1"]
        ["roleIcon"] or {}

        elv["unitframe"]["units"]["raid2"]["roleIcon"] = elv["unitframe"]["units"]["raid2"]["roleIcon"] or {}
        elvColor["unitframe"]["units"]["raid2"]["roleIcon"] = elvColor["unitframe"]["units"]["raid2"]["roleIcon"] or {}
        elvHealer["unitframe"]["units"]["raid2"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid2"]["roleIcon"] or {}
        elvHealerColor["unitframe"]["units"]["raid2"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid2"]
        ["roleIcon"] or {}

        elv["unitframe"]["units"]["raid3"]["roleIcon"] = elv["unitframe"]["units"]["raid3"]["roleIcon"] or {}
        elvColor["unitframe"]["units"]["raid3"]["roleIcon"] = elvColor["unitframe"]["units"]["raid3"]["roleIcon"] or {}
        elvHealer["unitframe"]["units"]["raid3"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid3"]["roleIcon"] or {}
        elvHealerColor["unitframe"]["units"]["raid3"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid3"]
        ["roleIcon"] or {}

        elv["unitframe"]["units"]["raid1"]["roleIcon"]["enable"] = true
        elv["unitframe"]["units"]["raid1"]["roleIcon"]["damager"] = false
        elvColor["unitframe"]["units"]["raid1"]["roleIcon"]["enable"] = true
        elvColor["unitframe"]["units"]["raid1"]["roleIcon"]["damager"] = false
        elvHealer["unitframe"]["units"]["raid1"]["roleIcon"]["enable"] = true
        elvHealer["unitframe"]["units"]["raid1"]["roleIcon"]["damager"] = false
        elvHealerColor["unitframe"]["units"]["raid1"]["roleIcon"]["enable"] = true
        elvHealerColor["unitframe"]["units"]["raid1"]["roleIcon"]["damager"] = false

        elv["unitframe"]["units"]["raid2"]["roleIcon"]["enable"] = true
        elv["unitframe"]["units"]["raid2"]["roleIcon"]["damager"] = false
        elvColor["unitframe"]["units"]["raid2"]["roleIcon"]["enable"] = true
        elvColor["unitframe"]["units"]["raid2"]["roleIcon"]["damager"] = false
        elvHealer["unitframe"]["units"]["raid2"]["roleIcon"]["enable"] = true
        elvHealer["unitframe"]["units"]["raid2"]["roleIcon"]["damager"] = false
        elvHealerColor["unitframe"]["units"]["raid2"]["roleIcon"]["enable"] = true
        elvHealerColor["unitframe"]["units"]["raid2"]["roleIcon"]["damager"] = false

        elv["unitframe"]["units"]["raid3"]["roleIcon"]["enable"] = true
        elv["unitframe"]["units"]["raid3"]["roleIcon"]["damager"] = false
        elvColor["unitframe"]["units"]["raid3"]["roleIcon"]["enable"] = true
        elvColor["unitframe"]["units"]["raid3"]["roleIcon"]["damager"] = false
        elvHealer["unitframe"]["units"]["raid3"]["roleIcon"]["enable"] = true
        elvHealer["unitframe"]["units"]["raid3"]["roleIcon"]["damager"] = false
        elvHealerColor["unitframe"]["units"]["raid3"]["roleIcon"]["enable"] = true
        elvHealerColor["unitframe"]["units"]["raid3"]["roleIcon"]["damager"] = false
    end
end

local function ConfigureUnitFrames(elv, elvColor, elvHealer, elvHealerColor)
    elv["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    elv["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"
    elv["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,965,535"
    
    -- elvColor["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    -- elvColor["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,965,535"
    -- elvColor["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"

    -- elvHealer["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    -- elvHealerColor["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"

    -- elvHealer["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"
    -- elvHealerColor["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"

end

local function ConfigureMiscMovers(elv, elvColor, elvHealer, elvHealerColor)
    elv["movers"]["AltPowerBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,101"
    -- elvColor["movers"]["AltPowerBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,101"
    -- elvHealer["movers"]["AltPowerBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,101"
    -- elvHealerColor["movers"]["AltPowerBarMover"] = "BOTTOM,ElvUIParent,BOTTOM,0,101"
end

function CJ:ApplyElvUITweaks(opts)
    local E = select(1, unpack(ElvUI))

    local elv = ElvDB["profiles"][opts.profiles.atrocityUI]
    local elvColor = ElvDB["profiles"][opts.profiles.atrocityUIColor]
    local elvHealer = ElvDB["profiles"][opts.profiles.atrocityUIHealer]
    local elvHealerColor = ElvDB["profiles"][opts.profiles.atrocityUIHealerColor]

    local elvPriv = ElvPrivateDB["profiles"][opts.profiles.atrocityUI]
    local elvPrivColor = ElvPrivateDB["profiles"][opts.profiles.atrocityUIColor]
    local elvPrivHealer = ElvPrivateDB["profiles"][opts.profiles.atrocityUIHealer]
    local elvPrivHealerColor = ElvPrivateDB["profiles"][opts.profiles.atrocityUIHealerColor]

    -- TODO
    -- GM Ticket Frame ElvUi Frame (move right a few pixels out of action bar 4)

    DisableBags(elvPriv, elvPrivColor, elvPrivHealer, elvPrivHealerColor)
    ConfigurePrimaryActionBars(elv, elvColor, elvHealer, elvHealerColor)
    ConfigureLeftActionBars(elv, elvColor, elvHealer, elvHealerColor)
    ConfigurePetBars(elv, elvColor, elvHealer, elvHealerColor)
    ConfigurePanels(elv, elvColor, elvHealer, elvHealerColor)
    ConfigureRaidFrames(elv, elvColor, elvHealer, elvHealerColor)
    ConfigureUnitFrames(elv, elvColor, elvHealer, elvHealerColor)
    ConfigureMiscMovers(elv, elvColor, elvHealer, elvHealerColor)
end

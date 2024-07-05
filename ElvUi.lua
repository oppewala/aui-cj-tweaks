---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

local function DisableBags(elvPriv, elvPrivColor, elvPrivHealer, elvPrivHealerColor)
    elvPriv["bags"] = elvPriv["bags"] or {}
    elvPrivColor["bags"] = elvPrivColor["bags"] or {}
    elvPrivHealer["bags"] = elvPrivHealer["bags"] or {}
    elvPrivHealerColor["bags"] = elvPrivHealerColor["bags"] or {}

    elvPriv["bags"]["enable"] = false
    elvPrivColor["bags"]["enable"] = false
    elvPrivHealer["bags"]["enable"] = false
    elvPrivHealerColor["bags"]["enable"] = false
end

local function ConfigurePrimaryActionBars(elv, elvColor, elvHealer, elvHealerColor)
    elv["actionbar"]["bar1"]["heightMult"] = 3
    elvColor["actionbar"]["bar1"]["heightMult"] = 3
    elvHealer["actionbar"]["bar1"]["heightMult"] = 3
    elvHealerColor["actionbar"]["bar1"]["heightMult"] = 3
    
    elv["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,67"
    elvColor["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,67"
    -- elvHealer["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,34"
    -- elvHealerColor["movers"]["ElvAB_5"] = "BOTTOM,ElvUIParent,BOTTOM,0,34"
    
    elv["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,0,36"
    elvColor["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,0,36"
    -- elvHealer["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,0,34"
    -- elvHealerColor["movers"]["ElvAB_6"] = "BOTTOM,ElvUIParent,BOTTOM,0,34"

    elv["actionbar"]["bar6"]["buttonSize"] = 30
    elvColor["actionbar"]["bar6"]["buttonSize"] = 30
    -- elvHealer["actionbar"]["bar6"]["buttonSize"] = 28
    -- elvHealerColor["actionbar"]["bar6"]["buttonSize"] = 28

    elv["actionbar"]["bar6"]["buttonsPerRow"] = 12
    elvColor["actionbar"]["bar6"]["buttonsPerRow"] = 12
    elvHealer["actionbar"]["bar6"]["buttonsPerRow"] = 12
    elvHealerColor["actionbar"]["bar6"]["buttonsPerRow"] = 12

    elv["actionbar"]["bar6"]["backdrop"] = false
    elvColor["actionbar"]["bar6"]["backdrop"] = false
    elvHealer["actionbar"]["bar6"]["backdrop"] = false
    elvHealerColor["actionbar"]["bar6"]["backdrop"] = false
end

local function ConfigureLeftActionBars(elv, elvColor, elvHealer, elvHealerColor)
    elv["actionbar"]["bar3"]["mouseover"] = false
    elvColor["actionbar"]["bar3"]["mouseover"] = false
    elvHealer["actionbar"]["bar3"]["mouseover"] = false
    elvHealerColor["actionbar"]["bar3"]["mouseover"] = false
    
    elv["actionbar"]["bar3"]["buttons"] = 12
    elvColor["actionbar"]["bar3"]["buttons"] = 12
    elvHealer["actionbar"]["bar3"]["buttons"] = 12
    elvHealerColor["actionbar"]["bar3"]["buttons"] = 12
    
    elv["actionbar"]["bar3"]["buttonSpacing"] = 1
    elvColor["actionbar"]["bar3"]["buttonSpacing"] = 1
    elvHealer["actionbar"]["bar3"]["buttonSpacing"] = 1
    elvHealerColor["actionbar"]["bar3"]["buttonSpacing"] = 1
    
    elv["actionbar"]["bar3"]["buttonSize"] = 40
    elvColor["actionbar"]["bar3"]["buttonSize"] = 40
    elvHealer["actionbar"]["bar3"]["buttonSize"] = 40
    elvHealerColor["actionbar"]["bar3"]["buttonSize"] = 40

    elv["actionbar"]["bar3"]["widthMult"] = 2
    elvColor["actionbar"]["bar3"]["widthMult"] = 2
    elvHealer["actionbar"]["bar3"]["widthMult"] = 2
    elvHealerColor["actionbar"]["bar3"]["widthMult"] = 2

    elv["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,538,5"
    elvColor["movers"]["ElvAB_4"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,538,5"
    elvHealer["movers"]["ElvAB_4"] =  "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,538,5"
    elvHealerColor["movers"]["ElvAB_4"] =  "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,538,5"

    elv["actionbar"]["bar4"]["buttonSize"] = 40
    elvColor["actionbar"]["bar4"]["buttonSize"] = 40
    elvHealer["actionbar"]["bar4"]["buttonSize"] = 40
    elvHealerColor["actionbar"]["bar4"]["buttonSize"] = 40

    elv["actionbar"]["bar4"]["buttonsPerRow"] = 2
    elvColor["actionbar"]["bar4"]["buttonsPerRow"] = 2
    elvHealer["actionbar"]["bar4"]["buttonsPerRow"] = 2
    elvHealerColor["actionbar"]["bar4"]["buttonsPerRow"] = 2

    elv["actionbar"]["bar4"]["backdrop"] = false
    elvColor["actionbar"]["bar4"]["backdrop"] = false
    elvHealer["actionbar"]["bar4"]["backdrop"] = false
    elvHealerColor["actionbar"]["bar4"]["backdrop"] = false

    elv["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    elvColor["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    elvHealer["actionbar"]["bar4"]["professionQuality"]["enable"] = true
    elvHealerColor["actionbar"]["bar4"]["professionQuality"]["enable"] = true
end

local function ConfigurePetBars(elv, elvColor, elvHealer, elvHealerColor)
    elv["actionbar"]["barPet"]["mouseover"] = false
    elvColor["actionbar"]["barPet"]["mouseover"] = false
    elvHealer["actionbar"]["barPet"]["mouseover"] = false
    elvHealerColor["actionbar"]["barPet"]["mouseover"] = false
    
    elv["actionbar"]["barPet"]["buttons"] = 12
    elvColor["actionbar"]["barPet"]["buttons"] = 12
    elvHealer["actionbar"]["barPet"]["buttons"] = 12
    elvHealerColor["actionbar"]["barPet"]["buttons"] = 12
    
    elv["actionbar"]["barPet"]["buttonSpacing"] = 1
    elvColor["actionbar"]["barPet"]["buttonSpacing"] = 1
    elvHealer["actionbar"]["barPet"]["buttonSpacing"] = 1
    elvHealerColor["actionbar"]["barPet"]["buttonSpacing"] = 1
    
    elv["actionbar"]["barPet"]["buttonSize"] = 40
    elvColor["actionbar"]["barPet"]["buttonSize"] = 40
    elvHealer["actionbar"]["barPet"]["buttonSize"] = 40
    elvHealerColor["actionbar"]["barPet"]["buttonSize"] = 40
end

local function ConfigurePanels(elv, elvColor, elvHealer, elvHealerColor)
    elv["chat"]["panelHeight"] = 249
    elvColor["chat"]["panelHeight"] = 249
    elvHealer["chat"]["panelHeight"] = 249
    elvHealerColor["chat"]["panelHeight"] = 249

    elv["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
    elvColor["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
    elvHealer["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"
    elvHealerColor["movers"]["VehicleLeaveButton"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-421,254"

    elv["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    elvColor["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    elvHealer["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
    elvHealerColor["movers"]["TooltipMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-2,254"
end

local function ConfigureRaidFrames(elv, elvColor, elvHealer, elvHealerColor)
    elv["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
    elvColor["movers"]["ElvUF_Raid1Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"

    elv["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
    elvColor["movers"]["ElvUF_Raid2Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"

    elv["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"
    elvColor["movers"]["ElvUF_Raid3Mover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,3,280"

    -- Enable Role Icons for raid
    elv["unitframe"]["units"]["raid1"]["roleIcon"] = elv["unitframe"]["units"]["raid1"]["roleIcon"] or {}
    elvColor["unitframe"]["units"]["raid1"]["roleIcon"] = elvColor["unitframe"]["units"]["raid1"]["roleIcon"] or {}
    elvHealer["unitframe"]["units"]["raid1"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid1"]["roleIcon"] or {}
    elvHealerColor["unitframe"]["units"]["raid1"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid1"]["roleIcon"] or {}

    elv["unitframe"]["units"]["raid2"]["roleIcon"] = elv["unitframe"]["units"]["raid2"]["roleIcon"] or {}
    elvColor["unitframe"]["units"]["raid2"]["roleIcon"] = elvColor["unitframe"]["units"]["raid2"]["roleIcon"] or {}
    elvHealer["unitframe"]["units"]["raid2"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid2"]["roleIcon"] or {}
    elvHealerColor["unitframe"]["units"]["raid2"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid2"]["roleIcon"] or {}

    elv["unitframe"]["units"]["raid3"]["roleIcon"] = elv["unitframe"]["units"]["raid3"]["roleIcon"] or {}
    elvColor["unitframe"]["units"]["raid3"]["roleIcon"] = elvColor["unitframe"]["units"]["raid3"]["roleIcon"] or {}
    elvHealer["unitframe"]["units"]["raid3"]["roleIcon"] = elvHealer["unitframe"]["units"]["raid3"]["roleIcon"] or {}
    elvHealerColor["unitframe"]["units"]["raid3"]["roleIcon"] = elvHealerColor["unitframe"]["units"]["raid3"]["roleIcon"] or {}

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

local function ConfigureUnitFrames(elv, elvColor, elvHealer, elvHealerColor)
    elv["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    elvColor["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    elvHealer["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"
    elvHealerColor["movers"]["BossHeaderMover"] = "TOPRIGHT,ElvUIParent,TOPRIGHT,-700,-300"

    elv["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"
    elvColor["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"
    elvHealer["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"
    elvHealerColor["movers"]["ElvUF_FocusMover"] = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-800,550"

    elv["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,965,535"
    elvColor["movers"]["ElvUF_PartyMover"] = "BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,965,535"
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
end
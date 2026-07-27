---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- ponytail: one profile. ElvUI needed four (base/[C]/Healer/Healer[C]); EllesmereUI
-- expresses those variations with specOverrides inside a single profile, so the
-- four-way fan-out this file used to carry is gone. Add specOverrides here if a
-- healer-only difference actually shows up.

local function AddonDB(profile, addon)
    profile.addons = profile.addons or {}
    profile.addons[addon] = profile.addons[addon] or {}
    return profile.addons[addon]
end

local function Bar(bars, name)
    bars[name] = bars[name] or {}
    return bars[name]
end

-- Every SetPos call below is seeded from the working EllesmereUI layout, NOT
-- converted from ElvUI. ElvUI stored corner-anchored offset strings
-- ("BOTTOM,ElvUIParent,BOTTOM,1,71") in its own scaled coordinate space; these are
-- CENTER-relative x/y in EllesmereUI's, which tracks EllesmereUIDB.ppUIScale.
-- Converting between them needs ElvUI's UIScale, and ElvUI is uninstalled -- its
-- SavedVariables are gone. So these are the numbers to hand-tune, not derived ones.
local function SetPos(positions, name, x, y)
    positions[name] = { point = "CENTER", relPoint = "CENTER", x = x, y = y }
end

-- EllesmereUI's cross-module relative anchoring, the same table unlock mode writes.
-- Works across addons: an action bar can hang off a damage meter window. side is
-- the side OF target the element sits on, so side = "LEFT" puts key left of target.
-- An anchored element's own saved position goes inert -- the anchor wins.
local function SetAnchor(profile, key, target, side, offsetX, offsetY)
    profile.unlockLayout = profile.unlockLayout or {}
    profile.unlockLayout.anchors = profile.unlockLayout.anchors or {}
    profile.unlockLayout.anchors[key] = {
        target = target,
        side = side,
        offsetX = offsetX or 0,
        offsetY = offsetY or 0,
    }
end

-- These functions set only what the old ElvUI code set. Anything a bar is missing
-- below, ElvUI left alone too. Two ElvUI settings have no EllesmereUI counterpart
-- and are dropped: heightMult/widthMult (backdrop-size multipliers that let one
-- bar's backdrop swallow its neighbours -- EllesmereUI only has bgPadX/bgPadY
-- padding) and bar4's professionQuality.
--
-- ElvUI visibility "" and "[petbattle] hide; show" both become "always":
-- EllesmereUI hides bars in pet battles through its own petbattleui state driver,
-- so the pet-battle clause is already covered.

-- MainBar / Bar5 / Bar6: the bottom-center stack.
local function ConfigurePrimaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}
    eab.barPositions = eab.barPositions or {}

    local main = Bar(eab.bars, "MainBar")
    main.barVisibility = "always"
    main.alwaysHidden = false

    local bar5 = Bar(eab.bars, "Bar5")
    bar5.barVisibility = "always"
    bar5.alwaysHidden = false

    local bar6 = Bar(eab.bars, "Bar6")
    bar6.barVisibility = "always"
    bar6.alwaysHidden = false
    bar6.buttonWidth = 33
    bar6.buttonHeight = 33
    bar6.overrideNumIcons = 12
    bar6.overrideNumRows = 1
    bar6.bgEnabled = false

    SetPos(eab.barPositions, "MainBar", -0.5, -704)
    SetPos(eab.barPositions, "Bar5", -279.5, -688.5)
    -- Bar6 was hidden and parked mid-screen. ElvUI showed it just above the main
    -- bar, so this is a guess -- check it in game.
    SetPos(eab.barPositions, "Bar6", 0.5, -23.5)
end

-- Bar3 / Bar4 / PetBar: the bottom-left cluster and the pet bar opposite it.
local function ConfigureSecondaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}
    eab.barPositions = eab.barPositions or {}

    local bar3 = Bar(eab.bars, "Bar3")
    bar3.barVisibility = "always"
    bar3.mouseoverEnabled = false
    bar3.overrideNumIcons = 12
    bar3.overrideNumRows = 1
    bar3.buttonPadding = 1
    bar3.buttonWidth = 40
    bar3.buttonHeight = 40
    bar3.bgEnabled = true

    -- ElvUI's buttonsPerRow = 2 on a vertical bar. EllesmereUI spells the same
    -- shape as overrideNumRows on an orientation = "vertical" bar.
    local bar4 = Bar(eab.bars, "Bar4")
    bar4.barVisibility = "always"
    bar4.buttonWidth = 40
    bar4.buttonHeight = 40
    bar4.overrideNumRows = 2
    bar4.bgEnabled = false

    local pet = Bar(eab.bars, "PetBar")
    pet.mouseoverEnabled = false
    pet.buttonPadding = 1
    pet.buttonWidth = 40
    pet.buttonHeight = 40
    -- ponytail: ElvUI asked for 12 here, but a pet bar only ever has 10 slots and
    -- ElvUI clamped it. 10 is what actually rendered.
    pet.overrideNumIcons = 10

    SetPos(eab.barPositions, "Bar4", -833.5, -617.5)

    -- Pet bar rides the left edge of the Damage Done window, so the meters and the
    -- pet bar move as one strip off the bottom-right corner. Cross-module anchor:
    -- if EllesmereUIDamageMeters is ever disabled this target goes missing and the
    -- pet bar falls back to its stale barPositions entry.
    SetAnchor(profile, "PetBar", "EDM_Win2", "LEFT")
end

-- ElvUI's raid1/2/3 roleIcon.enable + roleIcon.damager = false. EllesmereUI has a
-- single raid frame config rather than three raid group profiles, and expresses
-- "enabled" as any roleIconStyle other than "none".
local function ConfigureRaidFrames(profile)
    local erf = AddonDB(profile, "EllesmereUIRaidFrames")
    if (erf.roleIconStyle or "modern") == "none" then
        erf.roleIconStyle = "modern"
    end
    erf.showRoleForDPS = false
end

-- Ultrawide pull-in. ElvUI used absolute corner-anchored mover strings; these are
-- CENTER-relative offsets, so the ultrawide/standard split is just the numbers.
local function ConfigureUnitFrames(profile)
    local euf = AddonDB(profile, "EllesmereUIUnitFrames")
    euf.positions = euf.positions or {}

    -- SetPos(euf.positions, "player", -408, -300.5)
    -- SetPos(euf.positions, "target", 408, -301)
    -- SetPos(euf.positions, "targettarget", 595, -278)
    -- SetPos(euf.positions, "focus", 674.5, -170.5)
    -- SetPos(euf.positions, "focustarget", 625, -198)
    SetPos(euf.positions, "boss", 684, -12)

    -- profile.tooltipFixedPos = { centerX = 1291.333435058594, centerY = -386.4999237060547 }
end

-- Replaces the old Details tweaks. EllesmereUI ships its own meter, so there is no
-- profile to apply/save around the edit -- windows is a plain array indexed 1..windowCount.
local function ConfigureDamageMeters(profile)
    local edm = AddonDB(profile, "EllesmereUIDamageMeters")
    edm.dm = edm.dm or {}
    local dm = edm.dm

    dm.barHeight = 24
    dm.windowCount = 2
    dm.windows = dm.windows or {}

    -- Window 1 is Healing Done (curDMType 2), window 2 is Damage Done (curDMType 0).
    -- Details' third (deaths) window has no counterpart here.
    local WIDTH, HEIGHT, EDGE = 202, 204, 1

    for i = 1, dm.windowCount do
        local w = dm.windows[i] or {}
        w.width = WIDTH
        w.height = HEIGHT
        w.locked = true
        w.hideTimer = true
        dm.windows[i] = w
    end

    -- Healing Done is the only fixed window: hard into the bottom-right corner.
    dm.windows[1].position =
        { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -EDGE, y = EDGE }

    -- Damage Done hangs off its left edge. Its own position is inert once anchored,
    -- but zero it so a stale coordinate can't show through if the anchor is dropped.
    dm.windows[2].position = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
    SetAnchor(profile, "EDM_Win2", "EDM_Win1", "LEFT")
end

function CJ:ApplyEllesmereUITweaks(opts)
    if type(EllesmereUIDB) ~= "table" or type(EllesmereUIDB.profiles) ~= "table" then
        CJ:Print("EllesmereUI not loaded, skipping its tweaks.")
        return false
    end

    local profile = EllesmereUIDB.profiles[opts.euiProfile]
    if not profile then
        CJ:Print(("EllesmereUI profile '%s' not found, skipping its tweaks."):format(opts.euiProfile))
        return false
    end

    -- TODO
    -- --== EllesmereUI ==--
    -- Raid Frames are floating instead of anchored to the top left of the screen for Tank / DPS
    -- Minimap is floating instead of anchored to the top right of the screen for Tank / DPS
    -- Action Bars to match old layout
    -- - Main Bar is ok
    -- - Bar 3 should be anchored to top of bar 2
    -- - Bar 2 should be anchored to top of bar 1
    -- - Bar 2 should be 12 wide
    -- - Encounter bar should be moved up
    -- Damage Meters and Pet Bar need to be anchored to the right side of the screen for Healer
    -- Swap to class colours

    -- --== EditMode ==--
    -- Move the quest log to the right side of the screen for Tank / DPS
    -- Move buffs/debuffs to the right side of the screen (next to minimap) for Tank / DPS

    --if opts.eui.primaryActionBars then ConfigurePrimaryActionBars(profile) end
    --if opts.eui.secondaryActionBars then ConfigureSecondaryActionBars(profile) end
    --if opts.eui.raidFrames then ConfigureRaidFrames(profile) end
    --if opts.eui.unitFrames then ConfigureUnitFrames(profile) end
    if opts.eui.damageMeters then ConfigureDamageMeters(profile) end

    return true
end

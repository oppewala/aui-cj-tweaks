---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- ponytail: one profile. ElvUI needed four (base/[C]/Healer/Healer[C]); EllesmereUI
-- expresses those variations with specOverrides inside a single profile, so the
-- four-way fan-out this file used to carry is gone. Add specOverrides here if a
-- healer-only difference actually shows up.

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, sub in pairs(v) do t[k] = DeepCopy(sub) end
    return t
end

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

-- Gap between two elements that sit edge to edge. Matches the profile's
-- buttonPadding, so a bar stack reads as one grid.
local PAD = 1

-- EllesmereUI's cross-module relative anchoring, the same table unlock mode writes.
-- Works across addons: an action bar can hang off a damage meter window. side is
-- the side OF target the element sits on, so side = "LEFT" puts key left of target.
-- An anchored element's own saved position goes inert -- the anchor wins.
--
-- offsets are edge-to-edge: for TOP/BOTTOM, offsetY is the gap and offsetX slides
-- along the shared edge; for LEFT/RIGHT it is the other way round, and LEFT counts
-- leftward so its gap is negative.
--
-- Two stores, both mandatory. unlockLayout is what a profile load restores into
-- EllesmereUIDB.unlockAnchors; baselineLayout is what the spec-override layer
-- flush wipes and refills that same table from. Writing only the first means the
-- first flush after login reverts us.
local function SetAnchor(profile, key, target, side, offsetX, offsetY)
    profile.unlockLayout = profile.unlockLayout or {}
    local base = profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout
    for _, store in ipairs({ profile.unlockLayout, base or profile.unlockLayout }) do
        store.anchors = store.anchors or {}
        store.anchors[key] = {
            target = target,
            side = side,
            offsetX = offsetX or 0,
            offsetY = offsetY or 0,
        }
    end
end

-- barPositions carry the same convention as SetPos -- x/y are offsets from
-- UIParent's CENTER, and point names which edge of the bar frame is pinned there.
-- Same two-store problem as anchors: the layer flush refills barPositions from
-- baselineLayout.abPos.
local function SetBarPos(profile, eab, key, x, y)
    eab.barPositions = eab.barPositions or {}
    local old = eab.barPositions[key]
    SetPos(eab.barPositions, key, x, y)
    local base = profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout
    if base then
        base.abPos = base.abPos or {}
        SetPos(base.abPos, key, x, y)
    end

    local uiW, uiH = UIParent:GetSize()
    CJ:Print(("SetBarPos %s: %s -> CENTER %.1f,%.1f | UIParent %.1fx%.1f | baseline abPos %s")
        :format(key,
            old and ("%s %.1f,%.1f"):format(old.point or "?", old.x or 0, old.y or 0) or "unset",
            x, y, uiW, uiH, base and "written" or "MISSING"))
end

-- Chat is not a registered unlock element, so there is nothing to anchor a bar
-- to -- read the panel's width and place the bar beside it instead.
-- EllesmereUIChat stopped persisting chatWidth ("We no longer apply saved
-- width/height"), so the live frame is the only source. Runs at /cj apply time,
-- with the UI up, so it is there to read.
local CHAT_WIDTH_FALLBACK = 400

local function ChatPanelWidth()
    local w = ChatFrame1 and ChatFrame1:GetWidth()
    if not w or w <= 1 then
        CJ:Print(("ChatPanelWidth: ChatFrame1 width %s, using fallback %d")
            :format(tostring(w), CHAT_WIDTH_FALLBACK))
        return CHAT_WIDTH_FALLBACK
    end

    local cS, uiS = ChatFrame1:GetEffectiveScale(), UIParent:GetEffectiveScale()
    local scaled = w * cS / uiS
    -- Left edge too: if the chat panel is not actually flush with the screen edge,
    -- its width is the wrong number to offset by and this is what will show it.
    local left = ChatFrame1:GetLeft()
    CJ:Print(("ChatPanelWidth: raw %.1f, scale %.3f/%.3f -> %.1f | ChatFrame1 left %s, right %s")
        :format(w, cS, uiS, scaled,
            left and ("%.1f"):format(left * cS / uiS) or "nil",
            ChatFrame1:GetRight() and ("%.1f"):format(ChatFrame1:GetRight() * cS / uiS) or "nil"))
    return scaled
end

-- Same wipe-and-refill problem for grow directions: baselineLayout.abGrow is
-- re-applied over bars[key].growDirection on every layer flush. Mirror whatever
-- the bar settings now say rather than tracking which keys we touched.
local function SyncGrowToBaseline(profile, eab)
    local base = profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout
    local abGrow = base and base.abGrow
    if not abGrow then return end
    for key, cfg in pairs(eab.bars or {}) do
        if type(cfg) == "table" and cfg.growDirection then abGrow[key] = cfg.growDirection end
    end
end

-- Main Stack (bottom to top): MainBar, Bar2, Bar3
--   Bar2/Bar3 should inherit all settings from the main bar, and be anchored to the top of the bar below it
--   MainBar keeps its own position; the stack hangs off it.
local function ConfigurePrimaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}

    -- Clone, not merge. "Inherit all settings" has to also clear what the two
    -- carried on their own -- Bar2's 6x2 grid, Bar3's rightward growth -- and a
    -- merge would leave exactly those behind. The 12-wide single row Bar2 needs
    -- comes with the clone, MainBar already is one.
    local main = Bar(eab.bars, "MainBar")
    eab.bars.Bar2 = DeepCopy(main)
    eab.bars.Bar3 = DeepCopy(main)

    SetAnchor(profile, "Bar2", "MainBar", "TOP", 0, PAD)
    SetAnchor(profile, "Bar3", "Bar2", "TOP", 0, PAD)
end

-- Left Cluster (left to right): Bar4, Bar5
--   Each bar should be 2 icons wide (2x6 = 12 icons total)
--   Bar5 should be anchored to the right of Bar4
--   Bar4 sits in the bottom-left corner, 1px up and one chat-panel-width in
-- Right Cluster: Pet Bar (anchored to the left of the Damage Done window, ideally with 1 pixel padding)
local function ConfigureSecondaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}

    local bar4 = Bar(eab.bars, "Bar4")
    local bar5 = Bar(eab.bars, "Bar5")

    -- The two sit edge to edge as one block, so their buttons have to be the
    -- same size.
    bar5.buttonWidth, bar5.buttonHeight = bar4.buttonWidth, bar4.buttonHeight
    bar5.buttonPadding = bar4.buttonPadding

    for _, bar in ipairs({ bar4, bar5 }) do
        bar.orientation = "vertical"
        bar.overrideNumIcons = 12
        -- On a vertical bar overrideNumRows is the COLUMN count (see the layout
        -- loop's isVertical branch), so 2 is the 2-wide x 6-tall block.
        bar.overrideNumRows = 2
        -- Width-match padding left over from Bar5's old 10-column shape. It adds
        -- a pixel to the leading columns, which would leave the two bars
        -- different widths now that they are the same grid.
        bar._matchExtraPixels = nil

        -- Always visible. Bar4 was on mouseover, which parks mouseoverAlpha at 0
        -- and stashes the real alpha in _savedBarAlpha -- clearing the mode alone
        -- would leave the bar shown but fully transparent, so undo the stash too
        -- (VisibilityCompat.ApplyMode does the same on a mode change).
        bar.barVisibility = "always"
        bar.alwaysHidden = false
        bar.mouseoverEnabled = false
        bar.mouseoverAlpha = bar._savedBarAlpha or 1
        bar._savedBarAlpha = nil
    end

    -- Bar4 into the bottom-left corner, clear of the chat panel; Bar5 rides along
    -- via its anchor. growDirection is "center", so the stored point is the bar's
    -- centre and the corner has to be converted to one -- derive the frame size
    -- from the 2x6 grid set above rather than reading the live frame, which has
    -- not been re-laid-out yet. Re-run /cj apply after a button size change.
    local btnW = (bar4.buttonWidth or 0) > 0 and bar4.buttonWidth or 45
    local btnH = (bar4.buttonHeight or 0) > 0 and bar4.buttonHeight or 45
    local pad = bar4.buttonPadding or 2
    local barW, barH = 2 * btnW + pad, 6 * btnH + 5 * pad
    local uiW, uiH = UIParent:GetSize()
    -- The third term in the sum, and the one SetBarPos cannot see.
    CJ:Print(("Bar4 grid: btn %.1fx%.1f pad %.1f -> frame %.1fx%.1f")
        :format(btnW, btnH, pad, barW, barH))
    SetBarPos(profile, eab, "Bar4",
        -uiW / 2 + ChatPanelWidth() + PAD + barW / 2,
        -uiH / 2 + PAD + barH / 2)

    SetAnchor(profile, "Bar5", "Bar4", "RIGHT", PAD, 0)

    -- Pet bar rides the left edge of the Damage Done window, so the meters and the
    -- pet bar move as one strip off the bottom-right corner. Cross-module anchor:
    -- if EllesmereUIDamageMeters is ever disabled this target goes missing and the
    -- pet bar falls back to its stale barPositions entry.
    SetAnchor(profile, "PetBar", "EDM_Win2", "LEFT", -PAD, 0)
end

-- Container's TOPLEFT 1px in from UIParent's. RF reads unlockPos through
-- _RFPosTopLeft, which honours any point/relPoint pair (its own first-install
-- default is LEFT/LEFT), so this needs no CENTER conversion. Neither growth is
-- LEFT or UP, so _RFGrowthCorner pins TOPLEFT and every size tier stays put.
local RAID_TOPLEFT = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 1, y = -1 }

-- Overwrite only the geometry of an existing layer entry; w/h stay whatever the
-- layer harvested. Missing key = the layer never carried this element, so leave
-- it missing (that reads as "follow baseline").
local function SetElemPos(layer, key, pos)
    local e = layer and layer.elems and layer.elems[key]
    if not e then return end
    e.point, e.relPoint, e.x, e.y = pos.point, pos.relPoint, pos.x, pos.y
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

    -- Two writes for one position: unlockPos is the live module store, but a
    -- spec layer's elems entry is re-applied over it on every layer flush. Set
    -- the baseline entry too and MatchSpecLayoutsToBase pushes it into the
    -- non-healer forks (healer keeps its centred raid frames).
    erf.unlockPos = DeepCopy(RAID_TOPLEFT)
    SetElemPos(profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout,
        "RF_RaidFrames", RAID_TOPLEFT)
end

-- Minimap 1px in from the top right. Same shape as unlockPos and read the same
-- way (SetPoint straight onto UIParent), and TOPRIGHT is already the module's own
-- no-position fallback, so no CENTER conversion here either.
local MINIMAP_TOPRIGHT = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -1, y = -1 }

local function ConfigureMinimap(profile)
    local emm = AddonDB(profile, "EllesmereUIMinimap")
    emm.minimap = emm.minimap or {}
    emm.minimap.position = DeepCopy(MINIMAP_TOPRIGHT)
    SetElemPos(profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout,
        "EBS_Minimap", MINIMAP_TOPRIGHT)
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
    -- SetPos(euf.positions, "boss", 684, -12)

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

-- A spec override group owns a COMPLETE fork of the unlock layout
-- (profile.specUnlockOverrides.layouts[groupId]), not a diff -- so each group
-- keeps its elements wherever they were last dragged while it was live,
-- ignoring every base-profile change. Copy the listed elements' layout entries
-- out of the shared baselineLayout so the forks match base again.
--
-- EllesmereUI applies a layer wipe-and-refill per sub-store, so "the baseline
-- has no entry" has to be written as nil into the fork, not left behind.
--
-- Allowlists, so leaving a fork alone is the default: a key listed here is
-- forced back to base, anything unlisted stays whatever the fork holds.
local BASE_MATCHED_KEYS = {
    "EDM_Win1", "EDM_Win2", "PetBar", "EBS_Minimap",
    -- The action bar layout is the same in every spec, and a fork holding the
    -- pre-stack anchors would quietly keep the old arrangement on that spec.
    "MainBar", "Bar2", "Bar3", "Bar4", "Bar5",
}
-- Healer deliberately centres its raid/party frames over the action bars; every
-- other group wants the base profile's top-left placement.
local BASE_MATCHED_KEYS_NON_HEALER = { "RF_RaidFrames", "RF_PartyFrames" }

local function CopyLayoutKey(src, dst, store, key)
    local v = src[store] and src[store][key]
    if v == nil then
        if dst[store] then dst[store][key] = nil end
        return
    end
    dst[store] = dst[store] or {}
    dst[store][key] = DeepCopy(v)
end

local function MatchKeys(base, layer, keys)
    for _, key in ipairs(keys) do
        CopyLayoutKey(base, layer, "anchors", key)
        CopyLayoutKey(base, layer, "elems", key)
        CopyLayoutKey(base, layer, "abPos", key)
        CopyLayoutKey(base, layer, "abGrow", key)
    end
end

-- The healer group is matched on its role icon, not its name: the name is
-- user-editable, the icon is picked from a fixed set.
local function HealerGroupId(profile)
    for _, g in ipairs(profile.specOverrideGroups or {}) do
        if g.icon and g.icon.kind == "role" and g.icon.key == "HEALER" then return g.id end
    end
end

-- Self-skips when the profile has no forks.
local function MatchSpecLayoutsToBase(profile)
    local store = profile.specUnlockOverrides
    local base = store and store.baselineLayout
    if not base or not store.layouts then return end

    local healer = HealerGroupId(profile)
    for gid, layer in pairs(store.layouts) do
        MatchKeys(base, layer, BASE_MATCHED_KEYS)
        if gid ~= healer then MatchKeys(base, layer, BASE_MATCHED_KEYS_NON_HEALER) end
    end

    -- We just rewrote the layer store from outside EllesmereUI, but LIVE still
    -- holds the old geometry -- and the reload's logout harvest banks live back
    -- into whichever layer is active, erasing the edit. This is EllesmereUI's
    -- own flag for exactly that situation (set on profile import): it skips the
    -- bank, then the next login's apply force-converges live to the store and
    -- clears the flag. Costs any unsaved live drag made since the last boundary.
    profile._importEstablishPending = true
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
    -- Damage and Healing Meters can be wider
    -- Swap to class colours
    -- Role Icons to be 'modern light'
    -- Bar4 slightly too far to the left, hieght doesn't match chat panel

    -- --== EditMode ==--
    -- Encounter bar ~10px above Action Bar 3. Not doable from here: EAB's
    --   SetupBlizzardMovableFrames explicitly no-ops for EncounterBar ("let
    --   Blizzard own position entirely"), so it has no barPositions entry and no
    --   unlock key. Edit Mode is the only handle.
    -- Move the quest log to the right side of the screen for Tank / DPS
    -- Move buffs/debuffs to the right side of the screen (next to minimap) for Tank / DPS
    -- Increase the height/width of the chat panel

    local eab = AddonDB(profile, "EllesmereUIActionBars")
    if opts.eui.primaryActionBars then ConfigurePrimaryActionBars(profile) end
    if opts.eui.secondaryActionBars then ConfigureSecondaryActionBars(profile) end
    SyncGrowToBaseline(profile, eab)
    if opts.eui.raidFrames then ConfigureRaidFrames(profile) end
    -- ponytail: no opts.eui.minimap toggle -- nobody asked for one. Add it to
    -- Core.lua's options table if turning this off ever matters.
    ConfigureMinimap(profile)
    --if opts.eui.unitFrames then ConfigureUnitFrames(profile) end
    if opts.eui.damageMeters then ConfigureDamageMeters(profile) end
    MatchSpecLayoutsToBase(profile)

    return true
end

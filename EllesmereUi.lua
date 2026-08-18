---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, sub in pairs(v) do t[k] = DeepCopy(sub) end
    return t
end

-- Every layout write has to land twice: in the live store a profile load
-- restores into EllesmereUIDB, and in the baseline the spec-override layer flush
-- wipes and refills that same store from. Write only the live one and the first
-- flush after login reverts us.
local function Baseline(profile)
    return profile.specUnlockOverrides and profile.specUnlockOverrides.baselineLayout
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
local function SetAnchor(profile, key, target, side, offsetX, offsetY)
    profile.unlockLayout = profile.unlockLayout or {}
    local anchor = {
        target = target,
        side = side,
        offsetX = offsetX or 0,
        offsetY = offsetY or 0,
    }
    for _, store in ipairs({ profile.unlockLayout, Baseline(profile) }) do
        store.anchors = store.anchors or {}
        store.anchors[key] = DeepCopy(anchor)
    end
end

-- A bar's own position, for the bars no anchor owns. Two stores again, but not
-- the same two: the live copy is the module's barPositions, and a layer flush
-- refills that from baselineLayout.abPos (MatchSpecLayoutsToBase carries it into
-- the spec forks from there).
--
-- point/relPoint are applied verbatim by RestoreBarPositions, so a screen corner
-- works even though EllesmereUI's own saved-edge format only ever uses
-- LEFT/RIGHT/TOP/BOTTOM against CENTER. Side effect of being off that format:
-- LayoutBar only re-points a bar whose relPoint is CENTER, so a corner-pointed
-- frame keeps growing away from its corner on every resize -- which is what we
-- want -- but the module's X/Y position sliders now read corner-relative.
local function SetBarPos(profile, key, pos)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.barPositions = eab.barPositions or {}
    eab.barPositions[key] = DeepCopy(pos)

    local base = Baseline(profile)
    if base then
        base.abPos = base.abPos or {}
        base.abPos[key] = DeepCopy(pos)
    end
end

-- Square buttons that fill the strip: rows of them plus the gaps between. The
-- alternative -- stretching icons to hit the height -- is visible on every
-- single button, so the height drives the button size instead.
--
-- This is EllesmereUI's own match-height math (EUI_ActionBars_Options.lua's
-- setHeight handler), and it has to be, because rows almost never divide a
-- height evenly. LayoutBar locks button size and padding to whole PHYSICAL
-- pixels, so asking for 39.1667 gets you 39 and a block two pixels short -- the
-- step the chat panel showed against the bars. Floor to a whole pixel and give
-- the remainder to _matchExtraPixelsH, which LayoutBar adds back into the frame
-- height, and the block lands exactly on the target.
--
-- ponytail: no buttonShape handling (the option's own version expands/crops the
-- button first). These bars are shape "none"; if one ever isn't, copy that arm.
local function MatchBarHeight(bar, height, rows)
    local onePx = (EllesmereUI and EllesmereUI.PP and EllesmereUI.PP.mult) or 1
    local physTarget = math.floor(height / onePx + 0.5)
    local physPad = math.floor((bar.buttonPadding or 2) / onePx + 0.5)
    local physBtn = math.floor((physTarget - (rows - 1) * physPad) / rows)
    if physBtn < 8 then physBtn = 8 end

    bar.buttonWidth = physBtn * onePx
    bar.buttonHeight = bar.buttonWidth

    -- One spare pixel per row is all LayoutBar will distribute; more than that
    -- means the height is unreachable and the block stays a little short.
    local extra = physTarget - (rows * physBtn + (rows - 1) * physPad)
    bar._matchExtraPixelsH = (extra > 0 and extra <= rows) and extra or nil
    return bar.buttonWidth, bar._matchExtraPixelsH or 0
end

-- How many rows the bar will actually stack into its height -- ComputeBarLayout's
-- own math (EllesmereUIActionBars.lua), which has three traps worth copying
-- rather than eyeballing:
--   * the icon count is a three-step fallback, and cap is a hard ceiling. The
--     shared bar defaults carry numIcons = 12 while the pet bar's own cap is 10,
--     so trusting the stored number gives a 2x6 grid for a bar that lays out 2x5.
--   * stride, not the stored row count, is what stacks on a vertical bar (the
--     stored number is the COLUMN count there).
--   * an uneven split collapses: 10 icons in 3 columns is stride 4, which is
--     really 3 columns of 4-4-2, so the height is 4 rows and not 3.
local function BarRows(s, cap)
    local icons = s.overrideNumIcons or s.numIcons or cap
    if icons < 1 or icons > cap then icons = cap end
    local rows = s.overrideNumRows or s.numRows or 1
    if rows < 1 then rows = 1 end
    local stride = math.ceil(icons / rows)
    if s.orientation == "vertical" then return stride, icons end
    return math.ceil(icons / stride), icons
end

-- Grow directions have no setter of their own, so mirror whatever the bar
-- settings now say rather than tracking which keys we touched.
local function SyncGrowToBaseline(profile, eab)
    local base = Baseline(profile)
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
--   EllesmereUI's ultrawide support sizes Bar4 itself, so Bar5 is cloned off it
--   -- same grid, same button size -- and hung off its right edge.
--
-- Bar4 owns the bottom-left end of the strip, so pin it to that screen CORNER.
-- The imported position is CENTER-relative, which means every element of the
-- strip shifts by half the resolution delta on a swap; the corner does not move.
-- Bar5 rides along on its anchor.
--
-- x clears the chat window, which sits in the corner itself. Chat is owned by
-- Blizzard's Edit Mode -- unlock mode shows it as a read-only overlay, so there
-- is nothing to anchor to -- so this is a measured constant: retune it if the
-- chat is ever resized.
local BAR4_CORNER = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 502, y = 1 }
-- Right Cluster: Pet Bar (anchored to the left of the Damage Done window, ideally with 1 pixel padding)
-- Height of the window the pet bar hangs off. The unlock layer's elems entry
-- wins whenever it exists -- every flush pushes its w/h back through the
-- window's setWidth/setHeight, overwriting dm.windows[i] -- so read that first
-- and fall back to the meter module's own store.
local function MeterHeight(profile, key, index)
    local elems = profile.unlockLayout and profile.unlockLayout.elems
    local e = elems and elems[key]
    if e and e.h then return e.h end
    local edm = profile.addons and profile.addons.EllesmereUIDamageMeters
    local win = edm and edm.dm and edm.dm.windows and edm.dm.windows[index]
    return win and win.height
end

local function ConfigureSecondaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}

    local bar4 = Bar(eab.bars, "Bar4")
    eab.bars.Bar5 = DeepCopy(bar4)

    for _, bar in ipairs({ bar4, eab.bars.Bar5 }) do
        -- Always visible. Mouseover mode parks mouseoverAlpha at 0 and stashes
        -- the real alpha in _savedBarAlpha, so clearing the mode alone would
        -- leave the bar shown but fully transparent -- undo the stash too
        -- (VisibilityCompat.ApplyMode does the same on a mode change).
        bar.barVisibility = "always"
        bar.alwaysHidden = false
        bar.mouseoverEnabled = false
        bar.mouseoverAlpha = bar._savedBarAlpha or 1
        bar._savedBarAlpha = nil
    end

    SetBarPos(profile, "Bar4", BAR4_CORNER)
    SetAnchor(profile, "Bar5", "Bar4", "RIGHT", PAD, 0)

    -- Pet bar rides the left edge of the Damage Done window, so the meters and the
    -- pet bar move as one strip off the bottom-right corner. Cross-module anchor:
    -- if EllesmereUIDamageMeters is ever disabled this target goes missing and the
    -- pet bar falls back to its stale barPositions entry.
    SetAnchor(profile, "PetBar", "EDM_Win2", "LEFT", -PAD, 0)

    -- ...and matches its height, so the two read as one block. No height stored
    -- for the window means it has never been sized or dragged; leave the pet bar
    -- alone rather than guessing.
    local meterH = MeterHeight(profile, "EDM_Win2", 2)
    if not meterH then
        CJ:Print("No stored height for the Damage Done window, leaving the pet bar height alone.")
        return
    end

    local pet = Bar(eab.bars, "PetBar")
    local petRows, petIcons = BarRows(pet, NUM_PET_ACTION_SLOTS or 10)
    local petBtn, petExtra = MatchBarHeight(pet, meterH, petRows)
    CJ:Debug("PetBar: %d icons in %d rows, pad %.1f -> btn %.1f +%d spare px (EDM_Win2 %.1f tall)",
        petIcons, petRows, pet.buttonPadding or PAD, petBtn, petExtra, meterH)
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

-- ...and the size, for the elements whose owning module does NOT get the last
-- word on it. An elems entry carries w/h alongside x/y, and the unlock layer
-- pushes both back through the element's setWidth/setHeight on every flush --
-- which for the damage meter windows overwrites dm.windows[i].width/height with
-- whatever was last harvested.
local function SetElemSize(profile, key, w, h)
    for _, store in ipairs({ profile.unlockLayout or {}, Baseline(profile) or {} }) do
        local e = store.elems and store.elems[key]
        if e then
            CJ:Debug("SetElemSize %s: %.1fx%.1f -> %.1fx%.1f", key, e.w or 0, e.h or 0, w, h)
            e.w, e.h = w, h
        end
    end
end

-- Role icons for tanks and healers only. "Enabled" is expressed as any
-- roleIconStyle other than "none".
local function ConfigureRaidFrames(profile)
    local erf = AddonDB(profile, "EllesmereUIRaidFrames")
    -- "Modern Light" in the UI; the stored key stayed blizzLight for back-compat.
    erf.roleIconStyle = "blizzLight"
    erf.showRoleForDPS = false

    -- unlockPos is the live store here. Writing the baseline too lets
    -- MatchSpecLayoutsToBase push the position into the non-healer forks; healer
    -- keeps its centred raid frames.
    erf.unlockPos = DeepCopy(RAID_TOPLEFT)
    SetElemPos(Baseline(profile), "RF_RaidFrames", RAID_TOPLEFT)
end

-- Minimap's TOPRIGHT 1px in from UIParent's, for the same reason as Bar4: the
-- imported position is CENTER-relative, so a smaller screen drags the minimap off
-- its corner -- and the Edit Mode aura offsets, which are derived from the
-- minimap's size and this same 1px inset, drift with it. mapSize is a profile
-- setting, so once the corner is fixed the whole top-right block is.
--
-- minimap.position is the live store (ApplyMinimap reads it on first activation
-- and honours any point/relPoint pair); the layer copy is the baseline elems
-- entry, which owns positioning from then on. EBS_Minimap is already base-matched
-- into the spec forks.
local MINIMAP_TOPRIGHT = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -1, y = -1 }

local function ConfigureMinimap(profile)
    local ebs = AddonDB(profile, "EllesmereUIMinimap")
    ebs.minimap = ebs.minimap or {}
    ebs.minimap.position = DeepCopy(MINIMAP_TOPRIGHT)
    SetElemPos(Baseline(profile), "EBS_Minimap", MINIMAP_TOPRIGHT)
end

-- Dark Mode is not one stored flag: each module keeps its own in its own shape
-- (UF darkTheme, RB secondary.darkTheme, RF healthColorMode == "dark"), and
-- EllesmereUI's master checkbox only flips the LIVE module DBs. We edit a profile
-- table that may not even be loaded, so write the three directly -- same values
-- each provider's setOn(false) writes.
--
-- healthClassColored takes priority over the per-unit customFillColor, so setting
-- it leaves any custom colour parked in the profile rather than deleting it.
-- boss is excluded: it never class-colours (no player class on a boss).
local CLASS_COLOURED_UNITS = { "player", "target", "pet", "focus", "focustarget", "targettarget" }

local function ConfigureClassColours(profile)
    local euf = AddonDB(profile, "EllesmereUIUnitFrames")
    euf.darkTheme = false
    for _, unit in ipairs(CLASS_COLOURED_UNITS) do
        euf[unit] = euf[unit] or {}
        euf[unit].healthClassColored = true
    end

    local erb = AddonDB(profile, "EllesmereUIResourceBars")
    erb.secondary = erb.secondary or {}
    erb.secondary.darkTheme = false

    -- _darkPrev* is where the module stashed the pre-dark mode; prefer it, then
    -- clear it exactly as setOn(false) does.
    local erf = AddonDB(profile, "EllesmereUIRaidFrames")
    if erf.healthColorMode == "dark" then
        erf.healthColorMode = erf._darkPrevHealthColorMode or "class"
    end
    if erf.party_healthColorMode == "dark" then
        erf.party_healthColorMode = erf._darkPrevPartyHealthColorMode or "class"
    end
    erf._darkPrevHealthColorMode, erf._darkPrevPartyHealthColorMode = nil, nil
end

local METER_WIDTH, METER_HEIGHT = 250, 263

-- windows is a plain array indexed 1..windowCount -- no profile to apply/save
-- around the edit.
local function ConfigureDamageMeters(profile)
    local edm = AddonDB(profile, "EllesmereUIDamageMeters")
    edm.dm = edm.dm or {}
    local dm = edm.dm

    dm.barHeight = 24
    dm.windowCount = 2
    dm.windows = dm.windows or {}

    -- Window 1 is Healing Done (curDMType 2), window 2 is Damage Done (curDMType 0).
    local EDGE = 1

    for i = 1, dm.windowCount do
        local w = dm.windows[i] or {}
        w.width = METER_WIDTH
        w.height = METER_HEIGHT
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

    -- The size above is only half the job -- the unlock layer holds its own copy
    -- and wins. MatchSpecLayoutsToBase carries both keys into the spec forks.
    SetElemSize(profile, "EDM_Win1", METER_WIDTH, METER_HEIGHT)
    SetElemSize(profile, "EDM_Win2", METER_WIDTH, METER_HEIGHT)
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
    -- The action bar layout is the same in every spec, so a fork holding its own
    -- copy would quietly keep a stale arrangement on that spec.
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
    local base = Baseline(profile)
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

    local eab = AddonDB(profile, "EllesmereUIActionBars")
    if opts.eui.primaryActionBars then ConfigurePrimaryActionBars(profile) end
    -- Before the pet bar, which sizes itself off the meter window's height.
    if opts.eui.damageMeters then ConfigureDamageMeters(profile) end
    if opts.eui.secondaryActionBars then ConfigureSecondaryActionBars(profile) end
    SyncGrowToBaseline(profile, eab)
    if opts.eui.raidFrames then ConfigureRaidFrames(profile) end
    -- Before the Edit Mode pass in ApplyTweaks: the aura offsets are measured
    -- against the corner this pins the minimap to.
    -- ConfigureMinimap(profile)
    ConfigureClassColours(profile)
    MatchSpecLayoutsToBase(profile)

    return true
end

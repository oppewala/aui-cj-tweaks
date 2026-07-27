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

-- CENTER-relative x/y in EllesmereUI's coordinate space, which tracks
-- EllesmereUIDB.ppUIScale. Every call below is seeded from a working layout and
-- hand-tuned from there -- there is nothing to derive these from.
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

-- barPositions carry the same convention as SetPos -- x/y are offsets from
-- UIParent's CENTER, and point names which edge of the bar frame is pinned there.
-- The baseline's copy lives under abPos rather than alongside the anchors.
local function SetBarPos(profile, eab, key, x, y)
    eab.barPositions = eab.barPositions or {}
    local old = eab.barPositions[key]
    SetPos(eab.barPositions, key, x, y)
    local base = Baseline(profile)
    if base then
        base.abPos = base.abPos or {}
        SetPos(base.abPos, key, x, y)
    end

    local uiW, uiH = UIParent:GetSize()
    CJ:Debug("SetBarPos %s: %s -> CENTER %.1f,%.1f | UIParent %.1fx%.1f | baseline abPos %s",
        key,
        old and ("%s %.1f,%.1f"):format(old.point or "?", old.x or 0, old.y or 0) or "unset",
        x, y, uiW, uiH, base and "written" or "MISSING")
end

-- Everything along the bottom of the screen is opts.bottomStripHeight tall: the
-- chat panel (sized in AtrocityEssentials.lua), Bar4/Bar5, the meter windows and
-- the pet bar. It is a user option, so it arrives as a parameter rather than a
-- constant -- the height is threaded through to every one of them below.

-- Bar4 wants a touch more air off the chat panel than the 1px the bar grid uses.
local CHAT_GAP = PAD + 1

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
--   Each bar should be 2 icons wide (2x6 = 12 icons total)
--   Bar5 should be anchored to the right of Bar4
--   Bar4 sits in the bottom-left corner, 1px up and one chat-panel-width in
-- Right Cluster: Pet Bar (anchored to the left of the Damage Done window, ideally with 1 pixel padding)
local function ConfigureSecondaryActionBars(profile, chatWidth, stripHeight)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}

    local bar4 = Bar(eab.bars, "Bar4")
    local bar5 = Bar(eab.bars, "Bar5")

    -- The two sit edge to edge as one block, so their buttons have to be the
    -- same size -- and that size is whatever makes 6 rows fill the strip. Same
    -- padding and row count in, so both come back with the same button size.
    local pad = bar4.buttonPadding or PAD

    for _, bar in ipairs({ bar4, bar5 }) do
        bar.buttonPadding = pad
        MatchBarHeight(bar, stripHeight, 6)
        bar.orientation = "vertical"
        bar.overrideNumIcons = 12
        -- On a vertical bar overrideNumRows is the COLUMN count (see the layout
        -- loop's isVertical branch), so 2 is the 2-wide x 6-tall block.
        bar.overrideNumRows = 2
        -- The WIDTH-match spare, which adds a pixel to the leading columns. Both
        -- bars have to come out the same width, so neither may carry it.
        bar._matchExtraPixels = nil

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

    -- Bar4 into the bottom-left corner, clear of the chat panel; Bar5 rides along
    -- via its anchor. growDirection is "center", so the stored point is the bar's
    -- centre and the corner has to be converted to one -- derive the frame size
    -- from the 2x6 grid set above rather than reading the live frame, which has
    -- not been re-laid-out yet.
    local btn, extra = bar4.buttonWidth, bar4._matchExtraPixelsH or 0
    local barW, barH = 2 * btn + pad, stripHeight
    local uiW, uiH = UIParent:GetSize()
    -- The third term in the sum, and the one SetBarPos cannot see.
    CJ:Debug("Bar4/Bar5: 6 rows pad %.1f -> btn %.1f +%d spare px, frame %.1fx%.1f",
        pad, btn, extra, barW, barH)
    SetBarPos(profile, eab, "Bar4",
        -uiW / 2 + CJ:ChatPanelRight(chatWidth) + CHAT_GAP + barW / 2,
        -uiH / 2 + PAD + barH / 2)

    SetAnchor(profile, "Bar5", "Bar4", "RIGHT", PAD, 0)

    -- Pet bar rides the left edge of the Damage Done window, so the meters and the
    -- pet bar move as one strip off the bottom-right corner. Cross-module anchor:
    -- if EllesmereUIDamageMeters is ever disabled this target goes missing and the
    -- pet bar falls back to its stale barPositions entry.
    SetAnchor(profile, "PetBar", "EDM_Win2", "LEFT", -PAD, 0)

    -- Same block height as the chat panel and the meters, so the whole bottom
    -- strip reads as one band.
    local pet = Bar(eab.bars, "PetBar")
    -- On a vertical bar overrideNumRows is the COLUMN count (same quirk as Bar4
    -- above), so the row count is icons over columns.
    local petRows = (pet.orientation == "vertical")
        and math.ceil((pet.overrideNumIcons or 10) / (pet.overrideNumRows or 2))
        or (pet.overrideNumRows or 1)
    local petBtn, petExtra = MatchBarHeight(pet, stripHeight, petRows)
    CJ:Debug("PetBar: %d rows pad %.1f -> btn %.1f +%d spare px (strip %d tall)",
        petRows, pet.buttonPadding or PAD, petBtn, petExtra, stripHeight)
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

-- Minimap 1px in from the top right. Same shape as unlockPos and read the same
-- way (SetPoint straight onto UIParent), and TOPRIGHT is already the module's own
-- no-position fallback, so no CENTER conversion here either.
local MINIMAP_TOPRIGHT = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -1, y = -1 }

local function ConfigureMinimap(profile)
    local emm = AddonDB(profile, "EllesmereUIMinimap")
    emm.minimap = emm.minimap or {}
    emm.minimap.position = DeepCopy(MINIMAP_TOPRIGHT)
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

-- windows is a plain array indexed 1..windowCount -- no profile to apply/save
-- around the edit.
local function ConfigureDamageMeters(profile, stripHeight, combinedWidth)
    local edm = AddonDB(profile, "EllesmereUIDamageMeters")
    edm.dm = edm.dm or {}
    local dm = edm.dm

    dm.barHeight = 24
    dm.windowCount = 2
    dm.windows = dm.windows or {}

    -- Window 1 is Healing Done (curDMType 2), window 2 is Damage Done (curDMType 0).
    -- Height matches the chat panel so the bottom strip lines up across the screen.
    -- The two windows sit edge to edge (EDM_Win2's LEFT anchor has no offset), so
    -- the combined width is just split in half.
    local WIDTH, EDGE = math.floor(combinedWidth / 2), 1

    for i = 1, dm.windowCount do
        local w = dm.windows[i] or {}
        w.width = WIDTH
        w.height = stripHeight
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
    SetElemSize(profile, "EDM_Win1", WIDTH, stripHeight)
    SetElemSize(profile, "EDM_Win2", WIDTH, stripHeight)
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
    if opts.eui.secondaryActionBars then
        ConfigureSecondaryActionBars(profile, opts.chat.width, opts.bottomStripHeight)
    end
    SyncGrowToBaseline(profile, eab)
    if opts.eui.raidFrames then ConfigureRaidFrames(profile) end
    -- ponytail: no opts.eui.minimap toggle -- nobody asked for one. Add it to
    -- Core.lua's options table if turning this off ever matters.
    ConfigureMinimap(profile)
    ConfigureClassColours(profile)
    if opts.eui.damageMeters then
        ConfigureDamageMeters(profile, opts.bottomStripHeight, opts.meterWidth)
    end
    MatchSpecLayoutsToBase(profile)

    return true
end

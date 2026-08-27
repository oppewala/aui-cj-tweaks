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
-- Bar4's own placement is atrocityUI's now: it anchors Bar4 to AES_ChatPanel,
-- the chat panel atrocityEssentials registers as a real unlock element, and
-- re-seeds that anchor once per revision (its Core.lua chat-anchor-seed). So
-- the bottom-left end of the strip follows the chat at any resolution and the
-- measured corner offset this used to carry is gone. Bar5 rides along.

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

-- Height of the panel Bar4 hangs off, so the left end of the strip lines up the
-- same way the pet bar does against the meter. Read atrocityEssentials' live
-- store rather than a second copy of the number: CJ:ApplyAtrocityEssentialsTweaks
-- has already written it by the time this runs, and it stays right if the height
-- is ever changed from AE's own options page instead.
local function ChatHeight()
    local AE = _G.atrocityEssentials
    local chat = AE and AE.GetModule and AE:GetModule("Chat", true)
    local db = chat and chat.db
    if not (db and db.Enabled) then return nil end
    return db.Height
end

local function ConfigureSecondaryActionBars(profile)
    local eab = AddonDB(profile, "EllesmereUIActionBars")
    eab.bars = eab.bars or {}

    local bar4 = Bar(eab.bars, "Bar4")
    eab.bars.Bar5 = DeepCopy(bar4)

    local chatH = ChatHeight()
    if not chatH then
        CJ:Print("No chat panel height available, leaving Bar4/Bar5 button sizes alone.")
    end

    for _, bar in ipairs({ bar4, eab.bars.Bar5 }) do
        -- Full 12 buttons. atrocityUI ships these two as 2x5 verticals, which
        -- leaves two slots per bar unreachable; 2x6 is the same two columns.
        bar.overrideNumIcons = 12

        -- Always visible. Mouseover mode parks mouseoverAlpha at 0 and stashes
        -- the real alpha in _savedBarAlpha, so clearing the mode alone would
        -- leave the bar shown but fully transparent -- undo the stash too
        -- (VisibilityCompat.ApplyMode does the same on a mode change).
        bar.barVisibility = "always"
        bar.alwaysHidden = false
        bar.mouseoverEnabled = false
        bar.mouseoverAlpha = bar._savedBarAlpha or 1
        bar._savedBarAlpha = nil

        -- Vertical, so BarRows hands back the STRIDE -- 12 icons in the stored 2
        -- columns is 6 rows, not 2.
        if chatH then
            local rows, icons = BarRows(bar, NUM_ACTIONBAR_BUTTONS or 12)
            local btn, extra = MatchBarHeight(bar, chatH, rows)
            CJ:Debug("Bar4/5: %d icons in %d rows, pad %.1f -> btn %.1f +%d spare px (chat %.1f tall)",
                icons, rows, bar.buttonPadding or PAD, btn, extra, chatH)
        end
    end

    SetAnchor(profile, "Bar5", "Bar4", "RIGHT", PAD, 0)

    -- The pet bar already rides the left edge of the Damage Done window in the
    -- imported profile, so only its HEIGHT is ours: match the window's and the
    -- two read as one block. No height stored for the window means it has never
    -- been sized or dragged; leave the pet bar alone rather than guessing.
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

-- Size, for the elements whose owning module does NOT get the last
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
--
-- Position is not ours any more: the imported profile already places the raid
-- frames against UIParent's TOPLEFT, as it now does for the minimap and the
-- meters, so a swap between aspect ratios keeps them on their corner.
local function ConfigureRaidFrames(profile)
    local erf = AddonDB(profile, "EllesmereUIRaidFrames")
    -- "Modern Light" in the UI; the stored key stayed blizzLight for back-compat.
    erf.roleIconStyle = "blizzLight"
    erf.showRoleForDPS = false
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

local METER_WIDTH, METER_HEIGHT = CJ.METER_WIDTH, CJ.METER_HEIGHT

-- windows is a plain array indexed 1..windowCount -- no profile to apply/save
-- around the edit.
--
-- Only the SIZE is ours now. The imported profile pins Healing Done to
-- UIParent's BOTTOMRIGHT and hangs Damage Done off its left edge, which is what
-- the hand-written corner position and EDM_Win2 anchor used to do here.
local function ConfigureDamageMeters(profile)
    local edm = AddonDB(profile, "EllesmereUIDamageMeters")
    edm.dm = edm.dm or {}
    local dm = edm.dm

    dm.barHeight = 24
    dm.windowCount = 2
    dm.windows = dm.windows or {}

    -- Window 1 is Healing Done (curDMType 2), window 2 is Damage Done (curDMType 0).
    for i = 1, dm.windowCount do
        local w = dm.windows[i] or {}
        w.width = METER_WIDTH
        w.height = METER_HEIGHT
        w.locked = true
        w.hideTimer = true
        dm.windows[i] = w
    end

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

-- Self-skips when the profile has no forks.
--
-- The raid/party frames used to be forced back to base on every non-healer
-- fork. Gone with the fork count: the profile now carries one layout override
-- (Healer Mode), which is the one group that deliberately keeps its own centred
-- raid frames -- so there is nothing left to force.
local function MatchSpecLayoutsToBase(profile)
    local store = profile.specUnlockOverrides
    local base = Baseline(profile)
    if not base or not store.layouts then return end

    for _, layer in pairs(store.layouts) do
        MatchKeys(base, layer, BASE_MATCHED_KEYS)
    end

    -- We just rewrote the layer store from outside EllesmereUI, but LIVE still
    -- holds the old geometry -- and the reload's logout harvest banks live back
    -- into whichever layer is active, erasing the edit. This is EllesmereUI's
    -- own flag for exactly that situation (set on profile import): it skips the
    -- bank, then the next login's apply force-converges live to the store and
    -- clears the flag. Costs any unsaved live drag made since the last boundary.
    profile._importEstablishPending = true
end

-- Quickdraw palette 1: the eight raid target markers, then /tm 0 (clear) in the
-- ninth slot. Only palette 1 is ours -- anything the user adds beyond it stays.
--
-- The ring's own key is NOT a profile key: EUI_RADIAL1 is a Blizzard binding
-- (EllesmereUIQuickdraw/Bindings.xml), so it has to be set and saved through
-- the binding API, and saved before ApplyTweaks reloads out from under it.
local function ConfigureQuickdraw(profile)
    local qd = AddonDB(profile, "EllesmereUIQuickdraw")
    qd.enabled = true

    local slots = {}
    for i = 1, 8 do slots[i] = { kind = "raidtarget", id = i } end
    slots[9] = { kind = "raidtarget", id = 0 }

    qd.palettes = qd.palettes or {}
    qd.palettes[1] = { name = "Target Markers", slots = slots }

    if InCombatLockdown() then
        CJ:Print("In combat: leaving the ALT-R binding alone.")
        return
    end
    SetBinding("ALT-R", "EUI_RADIAL1")
    SaveBindings(GetCurrentBindingSet())
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
    ConfigureClassColours(profile)
    ConfigureQuickdraw(profile)
    MatchSpecLayoutsToBase(profile)

    return true
end

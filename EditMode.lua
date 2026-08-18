---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- Elements Blizzard owns outright -- EllesmereUI has no unlock key or profile
-- entry for the aura frames (unlock mode only draws a read-only "move via Blizz
-- Edit Mode" overlay on them), so the Edit Mode layout is the only handle. We
-- never SetPoint these frames ourselves: that taints them. Mutate the layout
-- table Blizzard hands us, save it, and let Blizzard's own code apply it.

local PAD = 1

-- ponytail: BUFF_BLOCK_HEIGHT is a constant because the live BuffFrame height
-- tracks how many buffs you currently have, so reading it at /cj apply time
-- gives a different answer every run. Tune it to the tallest buff row count you
-- actually see; if debuffs ever need to be exact, the upgrade is reading the
-- layout's IconLimitCount + IconSize settings and computing the block.
local BUFF_BLOCK_HEIGHT = 145

-- The minimap sits flush in the top-right corner (see ConfigureMinimap), but its
-- SIZE is EllesmereUIMinimap's and it varies with border style and the info rows
-- the profile turns on -- so read the live frame rather than assuming a size.
-- Fallback assumes the profile's own 1px inset and its 270px map.
local MINIMAP_SIZE_FALLBACK = 270

-- Left, top and bottom edges, in UIParent coordinates.
--
-- Size read live, corner NOT read live -- derived from the same PAD inset
-- ConfigureMinimap pins the minimap with. Two reasons the live edges are the
-- wrong thing to measure:
--   * Minimap, not MinimapCluster, is the frame you can see: EllesmereUIMinimap
--     reparents Minimap straight to UIParent and leaves the cluster behind at
--     alpha 0 (its ApplyMinimap). The ghost cluster keeps whatever size and
--     position Blizzard's Edit Mode gave it, which differs per resolution --
--     measuring it is what slid the auras under the minimap after a swap.
--   * even reading the right frame, /cj apply runs BEFORE the reload that moves
--     the minimap, so on the first apply after a resolution change the live
--     edges are the OUTGOING ones and every offset derived from them is stale.
-- The size survives the reload, so that is the only part worth reading.
local function MinimapCorner()
    local mm = Minimap or MinimapCluster
    local w, h = mm and mm:GetWidth(), mm and mm:GetHeight()
    if w and h and w > 1 and h > 1 then
        local s = mm:GetEffectiveScale() / UIParent:GetEffectiveScale()
        w, h = w * s, h * s
    else
        CJ:Print(("MinimapCorner: no live minimap, using fallback %d"):format(MINIMAP_SIZE_FALLBACK))
        w, h = MINIMAP_SIZE_FALLBACK, MINIMAP_SIZE_FALLBACK
    end
    local top = UIParent:GetTop() - PAD
    CJ:Debug("MinimapCorner: %s %.1fx%.1f -> left %.1f top %.1f bottom %.1f (UIParent %.1fx%.1f)",
        (mm and mm:GetName()) or "?", w, h, UIParent:GetRight() - PAD - w, top, top - h,
        UIParent:GetRight(), UIParent:GetTop())
    return UIParent:GetRight() - PAD - w, top, top - h
end

-- Gap between an aura frame's right edge and where its icons actually end, in
-- UIParent units. BuffFrame carries the collapse/expand arrow next to its
-- AuraContainer and DebuffFrame does not, so anchoring the two frames flush
-- leaves the icon columns misaligned by the width of that button. Measured, not
-- assumed: a sign flip or a future bit of chrome on either frame comes out in
-- the wash. Relative, so it holds regardless of where the frames sit right now.
local function IconInset(frame)
    local c = frame and frame.AuraContainer
    local fr, cr = frame and frame:GetRight(), c and c:GetRight()
    if not (fr and cr) then return 0 end
    return (fr * frame:GetEffectiveScale() - cr * c:GetEffectiveScale())
        / UIParent:GetEffectiveScale()
end

-- Read system/systemIndex off the live frame rather than naming Enum members --
-- the frame is the same thing Edit Mode registered, so it cannot drift.
local function FindSystem(layout, frame, name)
    if not frame or frame.system == nil then
        CJ:Print(("EditMode: %s is not an Edit Mode system, skipping."):format(name))
        return nil
    end
    for _, sys in ipairs(layout.systems or {}) do
        if sys.system == frame.system and sys.systemIndex == frame.systemIndex then
            return sys
        end
    end
    CJ:Print(("EditMode: %s has no entry in the active layout, skipping."):format(name))
    return nil
end

-- Returns true only on an actual change: an unconditional SaveLayouts would
-- demand a reload on every /cj apply.
local function SetPos(layout, frame, name, point, relPoint, x, y)
    local sys = FindSystem(layout, frame, name)
    if not sys then return false end

    local a = sys.anchorInfo or {}
    sys.anchorInfo = a
    if a.point == point and a.relativePoint == relPoint
        and a.relativeTo == "UIParent"
        and a.offsetX == x and a.offsetY == y
        and sys.isInDefaultPosition == false then
        return false
    end
    CJ:Debug("EditMode %s: %s %.1f,%.1f -> %s %.1f,%.1f",
        name, a.point or "unset", a.offsetX or 0, a.offsetY or 0, point, x, y)
    a.point, a.relativeTo, a.relativePoint = point, "UIParent", relPoint
    a.offsetX, a.offsetY = x, y
    -- Left true, Blizzard re-snaps the frame to its preset spot and throws the
    -- offsets away.
    sys.isInDefaultPosition = false
    return true
end

-- Buffs' TOPRIGHT onto the minimap's TOPLEFT, so the block runs leftward off the
-- minimap with their top edges flush; debuffs keep that right edge and sit under
-- them. Blizzard's own default for these is already the top-right corner, so the
-- leftward/downward growth that comes with the layout suits this placement as-is.
--
-- Anchored to UIParent's TOPRIGHT, not to the minimap frame: Edit Mode resolves
-- relativeTo by global name, and the minimap it would find is Blizzard's, whose
-- position EllesmereUIMinimap overrides afterwards. Corner-relative offsets also
-- survive a resolution swap, which is the whole point. Reading the live corner
-- keeps the numbers honest -- re-run /cj apply after a minimap resize.
local function ConfigureAuras(layout)
    local left, top = MinimapCorner()
    -- Where the ICON columns should end, converted to a frame-edge offset per
    -- frame by its own inset.
    local x = left - PAD - UIParent:GetRight()
    local y = top - UIParent:GetTop()

    local buffInset, debuffInset = IconInset(BuffFrame), IconInset(DebuffFrame)
    CJ:Debug("Aura icon insets: buffs %.1f, debuffs %.1f", buffInset, debuffInset)

    local changed = SetPos(layout, BuffFrame, "Buffs", "TOPRIGHT", "TOPRIGHT",
        x + buffInset, y - PAD)
    -- OR, not "or" -- both calls have to run.
    changed = SetPos(layout, DebuffFrame, "Debuffs", "TOPRIGHT", "TOPRIGHT",
        x + debuffInset, y - BUFF_BLOCK_HEIGHT - PAD * 2) or changed
    return changed
end

-- Tracker's TOPRIGHT to the screen's, dropped below the minimap. It grows
-- downward from its anchor, so the top edge is the one that matters -- and the
-- gap has to clear the debuff block, which is why it hangs off the minimap's
-- bottom rather than the corner.
local QUEST_GAP = 50

local function ConfigureQuestTracker(layout)
    local _, _, bottom = MinimapCorner()
    return SetPos(layout, ObjectiveTrackerFrame, "Quest tracker", "TOPRIGHT", "TOPRIGHT",
        -PAD, bottom - QUEST_GAP - UIParent:GetTop())
end

function CJ:ApplyEditModeTweaks()
    if InCombatLockdown() then
        CJ:Print("In combat, skipping Edit Mode tweaks.")
        return false
    end
    if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return false end

    local ok, info = pcall(C_EditMode.GetLayouts)
    if not ok or type(info) ~= "table" or type(info.layouts) ~= "table" then return false end

    -- activeLayout indexes presets first, then saved layouts, but GetLayouts
    -- returns only the saved half -- so the index is meaningless until the
    -- presets are prepended, and guessing would edit somebody else's layout.
    local presets = EditModePresetLayoutManager
        and EditModePresetLayoutManager:GetCopyOfPresetLayouts()
    if type(presets) ~= "table" then
        CJ:Print("Edit Mode preset list unavailable, skipping Edit Mode tweaks.")
        return false
    end
    local numPresets = #presets
    tAppendAll(presets, info.layouts)
    info.layouts = presets

    -- Presets are read-only: SaveLayouts drops the edit silently, so we would
    -- re-apply and re-prompt for a reload forever.
    if type(info.activeLayout) ~= "number" or info.activeLayout <= numPresets then
        CJ:Print("Active Edit Mode layout is a Blizzard preset (read-only). Copy it, then re-run /cj apply.")
        return false
    end

    local layout = info.layouts[info.activeLayout]
    if not layout or type(layout.systems) ~= "table" then return false end

    -- OR, not "or" -- both have to run.
    local changed = ConfigureAuras(layout)
    changed = ConfigureQuestTracker(layout) or changed
    if not changed then return false end

    C_EditMode.SaveLayouts(info)
    CJ:Print("Edit Mode layout updated: buffs, debuffs and the quest tracker pinned to the right edge.")
    return true
end

---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- The chat panel and the damage meter windows are the two ends of the same
-- bottom strip, so the strip height is the meter height.
local CHAT_HEIGHT = CJ.METER_HEIGHT

-- I want to watch cinematics and talking heads. Both keys are read live from
-- AUTO.db, and ApplySettings re-registers the cinematic events, so no reload.
--
-- Via the module, not the addon object: atrocityEssentials keeps its AceDB on the
-- PRIVATE namespace table (`select(2, ...)`) and only the AceAddon object is
-- global, so _G.atrocityEssentials.db does not exist. A module caches the same
-- profile table as its own .db and re-caches it on a profile change, so writing
-- through it writes the live profile.
function CJ:ApplyAtrocityEssentialsTweaks()
    local AE = _G.atrocityEssentials
    if not (AE and AE.GetModule) then return end

    local auto = AE:GetModule("Automation", true)
    if auto and auto.db then
        auto.db.SkipCinematics, auto.db.HideTalkingHead = false, false
        pcall(auto.ApplySettings, auto)
    end

    -- Taller chat, so it matches the meter block at the other end of the strip.
    -- The panel is a real unlock element (AES_ChatPanel, what Bar4 anchors to)
    -- but registered noResize -- its size is this module's alone, so this is the
    -- only lever, and unlock mode will not push a stale size back over it.
    local chat = AE:GetModule("Chat", true)
    if chat and chat.db then
        chat.db.Height = CHAT_HEIGHT
        pcall(chat.UpdatePanel, chat)
    end

    -- The backdrop behind the meters. It deliberately does not track them --
    -- it is a plain rectangle placed by hand -- so it has to be cut to the same
    -- block: two windows wide plus the seam between them, one window tall.
    local mp = AE:GetModule("MeterPanel", true)
    if mp and mp.db then
        mp.db.Enabled = true
        mp.db.Width = CJ.METER_WIDTH * 2 + CJ.METER_SEAM
        mp.db.Height = CJ.METER_HEIGHT
        pcall(mp.ApplySettings, mp)
    end

    -- Cursor circle with the integrated GCD ring, class-coloured, combat only.
    local cc = AE:GetModule("CursorCircle", true)
    if cc and cc.db then
        cc.db.Enabled, cc.db.ColorMode, cc.db.HideOutOfCombat = true, "class", true
        cc.db.Size = 36
        cc.db.GCD.Mode, cc.db.GCD.Size = "integrated", 45
        cc.db.GCD.RingColor = { 0.529, 0.584, 1, 1 }
        cc.db.GCD.SwipeColor = { 0, 0, 0, 0.453 }
        pcall(cc.ApplySettings, cc)
    end

    -- World markers on ALT-T, clear on ALT-SHIFT-T. These keys live in the
    -- profile rather than as Blizzard bindings -- the module turns them into
    -- override bindings itself -- so writing them here is the whole job.
    local wm = AE:GetModule("WorldMarkers", true)
    if wm and wm.db then
        wm.db.Enabled = true
        wm.db.PlaceKey, wm.db.PlaceModifier = "T", "ALT-"
        wm.db.ClearKey, wm.db.ClearModifier = "T", "ALT-SHIFT-"
        pcall(wm.ApplySettings, wm)
    end
end

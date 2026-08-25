---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- Matches METER_HEIGHT in EllesmereUi.lua -- the chat panel and the damage
-- meter windows are the two ends of the same bottom strip.
local CHAT_HEIGHT = 263

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
end

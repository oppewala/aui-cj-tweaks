---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

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
    local auto = AE and AE.GetModule and AE:GetModule("Automation", true)
    if not (auto and auto.db) then return end
    auto.db.SkipCinematics, auto.db.HideTalkingHead = false, false
    pcall(auto.ApplySettings, auto)
end

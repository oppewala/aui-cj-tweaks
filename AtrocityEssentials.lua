---@class CrackedJarTweaks
local CJ = LibStub("AceAddon-3.0"):GetAddon("CrackedJarTweaks")

-- atrocityEssentials owns the chat panel: AE_ChatPanel, with ChatFrame1 living
-- INSIDE it. Reading the Blizzard frame gave the wrong edge and Edit Mode's chat
-- width/height settings do nothing, so size it here -- then Bar4 can be placed
-- off the same numbers instead of measuring anything.

-- Via the module, not the addon object: atrocityEssentials keeps its AceDB on the
-- PRIVATE namespace table (`select(2, ...)`) and only the AceAddon object is
-- global, so _G.atrocityEssentials.db does not exist. The Chat module caches the
-- same profile table as CHAT.db (UI/Chat.lua CHAT:UpdateDB), and re-caches it on
-- a profile change, so writing through it writes the live profile.
local function ChatModule()
    local AE = _G.atrocityEssentials
    return AE and AE.GetModule and AE:GetModule("Chat", true)
end

local function ChatDB()
    local mod = ChatModule()
    return mod and mod.db
end

-- Where the panel's right edge lands, in UIParent coordinates. The panel is
-- anchored BOTTOMLEFT by default, so its offset counts; any other anchor and the
-- offset is measured from somewhere else, so ignore it and use the bare width.
function CJ:ChatPanelRight(width)
    local pos = (ChatDB() or {}).Position
    local from = pos and pos.AnchorFrom or ""
    if from:find("LEFT") and pos.AnchorTo == from then
        return (pos.XOffset or 0) + width
    end
    CJ:Print(("ChatPanelRight: panel anchored %s, ignoring its offset."):format(from ~= "" and from or "?"))
    return width
end

-- The panel is one segment of the bottom strip, so its height is the strip's --
-- the bars, meters and pet bar beside it all get sized off the same number.
function CJ:ApplyAtrocityEssentialsTweaks(opts)
    local chat = ChatDB()
    if not chat then
        CJ:Print("atrocityEssentials Chat not loaded, skipping chat panel size.")
        return false
    end

    CJ:Print(("Chat panel: %.0fx%.0f -> %dx%d")
        :format(chat.Width or 0, chat.Height or 0, opts.chat.width, opts.bottomStripHeight))
    chat.Width, chat.Height = opts.chat.width, opts.bottomStripHeight

    -- Resizes the live panel and re-anchors the chat frames inside it. Only does
    -- anything once the module has built its panel, hence the pcall -- the write
    -- above is what survives the reload either way.
    local mod = ChatModule()
    if mod and mod.UpdatePanel then pcall(mod.UpdatePanel, mod) end
    return true
end

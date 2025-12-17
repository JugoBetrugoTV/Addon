--[[
    EpicDamageMeter - Healing Module
    Healing tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Healing = {}
local Healing = EDM.Modules.Healing

-- Initialize
function Healing:Initialize()
    -- Healing module initialization
end

-- Get total healing for segment
function Healing:GetTotal(segment)
    return segment and segment.totalHealing or 0
end

-- Get HPS for actor
function Healing:GetHPS(actor, duration)
    if not actor or not duration or duration == 0 then return 0 end
    return actor.healing / duration
end

-- Get effective healing (excluding overhealing)
function Healing:GetEffective(actor)
    if not actor then return 0 end
    return actor.healing
end

-- Get overhealing
function Healing:GetOverhealing(actor)
    if not actor then return 0 end
    return actor.overhealing
end

-- Format healing output
function Healing:Format(value)
    return EDM.Utils.FormatNumber(value)
end

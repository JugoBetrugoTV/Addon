--[[
    EpicDamageMeter - Damage Module
    Damage tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Damage = {}
local Damage = EDM.Modules.Damage

-- Initialize
function Damage:Initialize()
    -- Damage module initialization
end

-- Get total damage for segment
function Damage:GetTotal(segment)
    return segment and segment.totalDamage or 0
end

-- Get DPS for actor
function Damage:GetDPS(actor, duration)
    if not actor or not duration or duration == 0 then return 0 end
    return actor.damage / duration
end

-- Format damage output
function Damage:Format(value)
    return EDM.Utils.FormatNumber(value)
end

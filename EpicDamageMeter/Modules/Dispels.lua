--[[
    EpicDamageMeter - Dispels Module
    Dispel tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Dispels = {}
local Dispels = EDM.Modules.Dispels

-- Initialize
function Dispels:Initialize()
    -- Dispels module initialization
end

-- Get total dispels for segment
function Dispels:GetTotal(segment)
    if not segment then return 0 end
    local total = 0
    for _, actor in pairs(segment.actors) do
        total = total + (actor.dispels or 0)
    end
    return total
end

-- Get dispels for actor
function Dispels:GetActorDispels(actor)
    if not actor then return 0 end
    return actor.dispels or 0
end

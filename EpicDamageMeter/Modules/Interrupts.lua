--[[
    EpicDamageMeter - Interrupts Module
    Interrupt tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Interrupts = {}
local Interrupts = EDM.Modules.Interrupts

-- Initialize
function Interrupts:Initialize()
    -- Interrupts module initialization
end

-- Get total interrupts for segment
function Interrupts:GetTotal(segment)
    if not segment then return 0 end
    local total = 0
    for _, actor in pairs(segment.actors) do
        total = total + (actor.interrupts or 0)
    end
    return total
end

-- Get interrupts for actor
function Interrupts:GetActorInterrupts(actor)
    if not actor then return 0 end
    return actor.interrupts or 0
end

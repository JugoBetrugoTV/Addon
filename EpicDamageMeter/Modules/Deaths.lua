--[[
    EpicDamageMeter - Deaths Module
    Death tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Deaths = {}
local Deaths = EDM.Modules.Deaths

-- Initialize
function Deaths:Initialize()
    -- Deaths module initialization
end

-- Get total deaths for segment
function Deaths:GetTotal(segment)
    if not segment or not segment.deaths then return 0 end
    return #segment.deaths
end

-- Get deaths for actor
function Deaths:GetActorDeaths(actor)
    if not actor then return 0 end
    return actor.deaths
end

-- Get death log for actor
function Deaths:GetDeathLog(actor)
    if not actor then return {} end
    return actor.deathLog or {}
end

-- Format death info
function Deaths:FormatDeath(death)
    if not death then return "" end
    local time = date("%H:%M:%S", death.timestamp)
    return string.format("[%s] %s died to %s (%s)",
        time,
        death.victimName or "Unknown",
        death.spellName or "Unknown",
        EDM.Utils.FormatNumber(death.damage or 0)
    )
end

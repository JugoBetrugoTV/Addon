--[[
    EpicDamageMeter - Threat Module
    Threat tracking functionality
]]

local ADDON_NAME, EDM = ...

EDM.Modules = EDM.Modules or {}
EDM.Modules.Threat = {}
local Threat = EDM.Modules.Threat

-- Initialize
function Threat:Initialize()
    -- Threat module initialization
end

-- Get threat for unit
function Threat:GetUnitThreat(unit)
    if not unit or not UnitExists(unit) then return 0 end

    local _, _, threatPct, _, threatValue = UnitDetailedThreatSituation("player", unit)
    return threatValue or 0
end

-- Get threat status
function Threat:GetThreatStatus(unit)
    if not unit or not UnitExists(unit) then return 0 end

    local status = UnitThreatSituation("player", unit)
    return status or 0
end

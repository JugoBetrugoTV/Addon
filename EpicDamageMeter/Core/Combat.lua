--[[
    EpicDamageMeter - Combat
    Combat tracking and encounter management
]]

local ADDON_NAME, EDM = ...

EDM.Combat = {}
local Combat = EDM.Combat
local C = EDM.Constants
local Utils = EDM.Utils
local DB = EDM.Database

-- Combat state
Combat.inCombat = false
Combat.combatStartTime = nil
Combat.lastDamageTime = nil
Combat.currentEncounter = nil

-- Encounter tracking
Combat.encounters = {}

-- Boss detection patterns
local bossNPCs = {
    -- These would be filled with actual boss NPC IDs
    -- Format: [npcID] = "Boss Name"
}

-- Initialize combat tracking
function Combat:Initialize()
    self.inCombat = false
    self.combatStartTime = nil
    self.currentEncounter = nil
end

-- Start combat
function Combat:StartCombat()
    if self.inCombat then return end

    self.inCombat = true
    self.combatStartTime = GetTime()
    self.lastDamageTime = GetTime()

    Utils.Debug("Combat started")
end

-- End combat
function Combat:EndCombat()
    if not self.inCombat then return end

    self.inCombat = false
    local duration = GetTime() - (self.combatStartTime or GetTime())
    self.combatStartTime = nil

    Utils.Debug("Combat ended, duration:", duration)

    return duration
end

-- Check if we should auto-end combat (no activity)
function Combat:CheckCombatTimeout(timeout)
    timeout = timeout or 3 -- 3 seconds of no activity

    if self.inCombat and self.lastDamageTime then
        if GetTime() - self.lastDamageTime > timeout then
            return true
        end
    end

    return false
end

-- Update last activity time
function Combat:UpdateActivity()
    self.lastDamageTime = GetTime()
end

-- Get combat duration
function Combat:GetDuration()
    if not self.combatStartTime then return 0 end

    if self.inCombat then
        return GetTime() - self.combatStartTime
    else
        return 0
    end
end

-- Start encounter
function Combat:StartEncounter(encounterID, encounterName, difficultyID, groupSize)
    self.currentEncounter = {
        id = encounterID,
        name = encounterName,
        difficultyId = difficultyID,
        groupSize = groupSize,
        startTime = GetTime(),
        endTime = nil,
        success = nil,
    }

    table.insert(self.encounters, self.currentEncounter)

    Utils.Debug("Encounter started:", encounterName)
end

-- End encounter
function Combat:EndEncounter(success)
    if not self.currentEncounter then return end

    self.currentEncounter.endTime = GetTime()
    self.currentEncounter.success = success
    self.currentEncounter.duration = self.currentEncounter.endTime - self.currentEncounter.startTime

    local encounter = self.currentEncounter
    self.currentEncounter = nil

    Utils.Debug("Encounter ended:", encounter.name, "Success:", success, "Duration:", encounter.duration)

    return encounter
end

-- Get current encounter
function Combat:GetCurrentEncounter()
    return self.currentEncounter
end

-- Check if in boss fight
function Combat:IsInBossFight()
    return self.currentEncounter ~= nil
end

-- Get encounter by ID
function Combat:GetEncounter(encounterID)
    for _, encounter in ipairs(self.encounters) do
        if encounter.id == encounterID then
            return encounter
        end
    end
    return nil
end

-- Calculate DPS for an actor
function Combat:CalculateDPS(actor, duration)
    if not actor or not duration or duration == 0 then return 0 end
    return actor.damage / duration
end

-- Calculate HPS for an actor
function Combat:CalculateHPS(actor, duration)
    if not actor or not duration or duration == 0 then return 0 end
    return actor.healing / duration
end

-- Calculate effective DPS (using active time)
function Combat:CalculateEffectiveDPS(actor)
    if not actor then return 0 end

    local activeTime = actor.activeTime
    if activeTime == 0 then
        -- Estimate active time from segment duration
        local segment = DB.Data.currentSegment
        if segment then
            activeTime = segment.duration
        end
    end

    if activeTime == 0 then return 0 end
    return actor.damage / activeTime
end

-- Calculate effective HPS (using active time)
function Combat:CalculateEffectiveHPS(actor)
    if not actor then return 0 end

    local activeTime = actor.activeTime
    if activeTime == 0 then
        local segment = DB.Data.currentSegment
        if segment then
            activeTime = segment.duration
        end
    end

    if activeTime == 0 then return 0 end
    return actor.healing / activeTime
end

-- Get difficulty name
function Combat:GetDifficultyName(difficultyId)
    local difficultyInfo = difficultyId and C_ChallengeMode and C_ChallengeMode.GetDifficultyInfo and C_ChallengeMode.GetDifficultyInfo(difficultyId)
    if difficultyInfo then
        return difficultyInfo
    end

    -- Fallback mapping
    local difficulties = {
        [1] = "Normal",
        [2] = "Heroic",
        [3] = "10 Player",
        [4] = "25 Player",
        [5] = "10 Player (Heroic)",
        [6] = "25 Player (Heroic)",
        [7] = "Looking For Raid",
        [8] = "Mythic Keystone",
        [9] = "40 Player",
        [14] = "Normal",
        [15] = "Heroic",
        [16] = "Mythic",
        [17] = "Looking For Raid",
        [23] = "Mythic",
        [24] = "Timewalking",
    }

    return difficulties[difficultyId] or "Unknown"
end

-- Generate combat report
function Combat:GenerateReport(segment, mode, numLines)
    if not segment then return {} end

    numLines = numLines or 5
    mode = mode or C.DISPLAY_MODE.DAMAGE_DONE

    local actors = DB:GetSortedActors(segment, mode)
    local duration = DB:GetSegmentDuration(segment)
    local report = {}

    local header = ""
    if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
        header = "Damage Done"
    elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
        header = "Healing Done"
    else
        header = C.DISPLAY_MODE_NAMES[mode] or "Data"
    end

    table.insert(report, string.format("%s - %s (%s)", C.ADDON_NAME, header, Utils.FormatTime(duration)))

    for i = 1, math.min(numLines, #actors) do
        local actor = actors[i]
        local value = 0
        local perSecond = 0

        if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
            value = actor.damage
            perSecond = duration > 0 and (actor.damage / duration) or 0
        elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
            value = actor.healing
            perSecond = duration > 0 and (actor.healing / duration) or 0
        elseif mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
            value = actor.damageTaken
        elseif mode == C.DISPLAY_MODE.DEATHS then
            value = actor.deaths
        elseif mode == C.DISPLAY_MODE.INTERRUPTS then
            value = actor.interrupts
        elseif mode == C.DISPLAY_MODE.DISPELS then
            value = actor.dispels
        end

        local line
        if mode == C.DISPLAY_MODE.DPS or mode == C.DISPLAY_MODE.HPS then
            line = string.format("%d. %s: %s (%s/s)",
                i, actor.name,
                Utils.FormatNumber(value),
                Utils.FormatNumber(perSecond))
        else
            line = string.format("%d. %s: %s",
                i, actor.name,
                Utils.FormatNumber(value))
        end

        table.insert(report, line)
    end

    return report
end

-- Report to chat
function Combat:ReportToChat(channel, segment, mode, numLines)
    local report = self:GenerateReport(segment, mode, numLines)

    for _, line in ipairs(report) do
        if channel == "SELF" then
            print(line)
        elseif channel == "SAY" then
            SendChatMessage(line, "SAY")
        elseif channel == "PARTY" then
            SendChatMessage(line, "PARTY")
        elseif channel == "RAID" then
            SendChatMessage(line, "RAID")
        elseif channel == "GUILD" then
            SendChatMessage(line, "GUILD")
        elseif channel == "WHISPER" then
            -- Would need target
        end
    end
end

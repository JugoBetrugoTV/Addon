--[[
    EpicDamageMeter - Database
    Data structures and storage
]]

local ADDON_NAME, EDM = ...

EDM.Database = {}
local DB = EDM.Database
local C = EDM.Constants
local Utils = EDM.Utils

-- Localize frequently used globals for performance
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local tonumber = tonumber
local math_floor = math.floor
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local wipe = wipe
local GetTime = GetTime

-- Reusable tables to reduce garbage collection
local sortedActorsCache = {}
local tempSortTable = {}

-- Sort result caching for performance
local sortCache = {
    data = nil,
    timestamp = 0,
    segmentId = nil,
    displayMode = nil,
    ttl = 0.15, -- Cache for 150ms
}

-- Session statistics
local sessionStats = {
    totalCombatTime = 0,
    totalFights = 0,
    totalDeaths = 0,
    totalDamage = 0,
    totalHealing = 0,
    bossKills = 0,
    bossWipes = 0,
    sessionStart = 0,
    lastCombatEnd = 0,
}

-- Data Templates

-- Player/Actor data structure
function DB.CreateActorData(guid, name, class, flags)
    return {
        guid = guid,
        name = name,
        class = class or "UNKNOWN",
        flags = flags,

        -- Totals
        damage = 0,
        healing = 0,
        absorbs = 0,            -- Absorbs done by this actor
        absorbsReceived = 0,    -- Absorbs received by this actor
        overhealing = 0,
        damageTaken = 0,
        healingTaken = 0,
        friendlyFire = 0,       -- Damage done to friendly targets

        -- Counts
        deaths = 0,
        kills = 0,
        interrupts = 0,
        dispels = 0,
        ccBreaks = 0,           -- CC broken by this actor
        resurrects = 0,         -- Resurrects cast by this actor

        -- Activity tracking (for Activity tab)
        interruptSpells = {}, -- spellId -> {name, count}
        dispelSpells = {},    -- spellId -> {name, count, removedSpell}

        -- Time tracking
        activeTime = 0,
        lastActivity = 0,

        -- Detailed breakdown
        abilities = {}, -- spellId -> ability data
        targets = {}, -- guid -> target data
        sources = {}, -- guid -> source data (for damage taken)

        -- Death log
        deathLog = {},

        -- Timeline data for graphs
        timeline = {
            damage = {},
            healing = {},
        },

        -- Pet tracking (if this actor has pets)
        pets = {},
        owner = nil, -- GUID of owner if this is a pet
    }
end

-- Ability data structure
function DB.CreateAbilityData(spellId, spellName, spellIcon)
    return {
        spellId = spellId,
        name = spellName or "Unknown",
        icon = spellIcon,

        -- Damage
        damage = 0,
        damageHits = 0,
        damageCrits = 0,
        damageMin = 0,
        damageMax = 0,

        -- Healing
        healing = 0,
        healingHits = 0,
        healingCrits = 0,
        overhealing = 0,

        -- Absorbs
        absorbs = 0,
        absorbCount = 0,

        -- Miss tracking
        misses = {
            MISS = 0,
            DODGE = 0,
            PARRY = 0,
            BLOCK = 0,
            RESIST = 0,
            ABSORB = 0,
            IMMUNE = 0,
            DEFLECT = 0,
            EVADE = 0,
            REFLECT = 0,
        },

        -- Targets
        targets = {},
    }
end

-- Target data structure
function DB.CreateTargetData(guid, name)
    return {
        guid = guid,
        name = name,
        damage = 0,
        healing = 0,
        hits = 0,
    }
end

-- Segment data structure
function DB.CreateSegment(segmentType, name)
    return {
        type = segmentType or C.SEGMENT_TYPE.CURRENT,
        name = name or "Segment",

        -- Timing
        startTime = GetTime(),
        endTime = nil,
        duration = 0,

        -- Combat state
        inCombat = false,

        -- Boss info (if applicable)
        bossName = nil,
        bossId = nil,
        difficultyId = nil,
        success = nil, -- nil = ongoing, true = kill, false = wipe

        -- Instance info
        instanceName = nil,
        instanceType = nil,

        -- Actors
        actors = {}, -- guid -> actor data

        -- Totals for quick access
        totalDamage = 0,
        totalHealing = 0,
        totalAbsorbs = 0,

        -- Timeline (for overall graph)
        timeline = {
            timestamps = {},
            damage = {},
            healing = {},
        },

        -- Deaths
        deaths = {},
    }
end

-- Death log entry
function DB.CreateDeathLogEntry(timestamp, victimGuid, victimName, killerName, spellId, spellName, damage, overkill, healthBefore)
    return {
        timestamp = timestamp,
        victimGuid = victimGuid,
        victimName = victimName,
        killerName = killerName,
        spellId = spellId,
        spellName = spellName or "Unknown",
        damage = damage or 0,
        overkill = overkill or 0,
        healthBefore = healthBefore or 0,
        lastHits = {}, -- Recent damage events before death
    }
end

-- Main data storage
DB.Data = {
    segments = {},
    currentSegment = nil,
    overallSegment = nil,
}

-- Initialize database
function DB:Initialize()
    -- Create overall segment
    self.Data.overallSegment = DB.CreateSegment(C.SEGMENT_TYPE.OVERALL, "Overall")

    -- Create current segment
    self:NewSegment()

    -- Initialize session statistics
    self:InitSessionStats()
end

-- Create new segment
function DB:NewSegment(name, segmentType, bossInfo)
    local segment = DB.CreateSegment(segmentType or C.SEGMENT_TYPE.CURRENT, name or "Current")

    if bossInfo then
        segment.bossName = bossInfo.name
        segment.bossId = bossInfo.id
        segment.difficultyId = bossInfo.difficultyId
        segment.type = C.SEGMENT_TYPE.BOSS
    end

    -- Get instance info
    local instance = Utils.GetInstanceInfo()
    segment.instanceName = instance.name
    segment.instanceType = instance.type

    -- Set as current
    self.Data.currentSegment = segment

    -- Add to segment list (at beginning)
    table.insert(self.Data.segments, 1, segment)

    -- Trim old segments
    local maxSegments = EDM.db and EDM.db.profile.combat.maxSegments or C.MAX_SEGMENTS
    while #self.Data.segments > maxSegments do
        table.remove(self.Data.segments)
    end

    return segment
end

-- End current segment
function DB:EndSegment(success)
    local segment = self.Data.currentSegment
    if not segment then return end

    segment.endTime = GetTime()
    segment.duration = segment.endTime - segment.startTime
    segment.inCombat = false
    segment.success = success

    -- Calculate final totals
    self:CalculateSegmentTotals(segment)
end

-- Calculate segment totals
function DB:CalculateSegmentTotals(segment)
    segment.totalDamage = 0
    segment.totalHealing = 0
    segment.totalAbsorbs = 0

    for _, actor in pairs(segment.actors) do
        segment.totalDamage = segment.totalDamage + actor.damage
        segment.totalHealing = segment.totalHealing + actor.healing
        segment.totalAbsorbs = segment.totalAbsorbs + actor.absorbs
    end
end

-- Get or create actor in segment
function DB:GetActor(segment, guid, name, class, flags)
    if not segment or not guid then return nil end

    if not segment.actors[guid] then
        segment.actors[guid] = DB.CreateActorData(guid, name, class, flags)
    end

    local actor = segment.actors[guid]

    -- Update name/class if provided
    if name and actor.name ~= name then
        actor.name = name
    end
    if class and class ~= "UNKNOWN" and actor.class == "UNKNOWN" then
        actor.class = class
    end
    if flags then
        actor.flags = flags
    end

    return actor
end

-- Get or create ability for actor
function DB:GetAbility(actor, spellId, spellName, spellIcon)
    if not actor or not spellId then return nil end

    if not actor.abilities[spellId] then
        actor.abilities[spellId] = DB.CreateAbilityData(spellId, spellName, spellIcon)
    end

    return actor.abilities[spellId]
end

-- Record damage
function DB:RecordDamage(segment, sourceGuid, sourceName, sourceClass, sourceFlags,
                         destGuid, destName, destFlags,
                         spellId, spellName, spellIcon, amount, overkill, school, critical)
    if not segment then return end

    -- Get or create source actor
    local actor = self:GetActor(segment, sourceGuid, sourceName, sourceClass, sourceFlags)
    if not actor then return end

    -- Update totals
    actor.damage = actor.damage + amount
    actor.lastActivity = GetTime()
    segment.totalDamage = segment.totalDamage + amount

    -- Also update overall
    if self.Data.overallSegment then
        local overallActor = self:GetActor(self.Data.overallSegment, sourceGuid, sourceName, sourceClass, sourceFlags)
        if overallActor then
            overallActor.damage = overallActor.damage + amount
            overallActor.lastActivity = GetTime()
        end
        self.Data.overallSegment.totalDamage = self.Data.overallSegment.totalDamage + amount
    end

    -- Record ability
    if EDM.db and EDM.db.profile.advanced.recordAbilities then
        local ability = self:GetAbility(actor, spellId, spellName, spellIcon)
        if ability then
            ability.damage = ability.damage + amount
            ability.damageHits = ability.damageHits + 1
            if critical then
                ability.damageCrits = ability.damageCrits + 1
            end
            if amount > ability.damageMax then
                ability.damageMax = amount
            end
            if ability.damageMin == 0 or amount < ability.damageMin then
                ability.damageMin = amount
            end

            -- Record target
            if not ability.targets[destGuid] then
                ability.targets[destGuid] = DB.CreateTargetData(destGuid, destName)
            end
            ability.targets[destGuid].damage = ability.targets[destGuid].damage + amount
            ability.targets[destGuid].hits = ability.targets[destGuid].hits + 1
        end
    end

    -- Record target for actor
    if EDM.db and EDM.db.profile.advanced.recordTargets then
        if not actor.targets[destGuid] then
            actor.targets[destGuid] = DB.CreateTargetData(destGuid, destName)
        end
        actor.targets[destGuid].damage = actor.targets[destGuid].damage + amount
        actor.targets[destGuid].hits = actor.targets[destGuid].hits + 1
    end
end

-- Record healing
function DB:RecordHealing(segment, sourceGuid, sourceName, sourceClass, sourceFlags,
                          destGuid, destName, destFlags,
                          spellId, spellName, spellIcon, amount, overhealing, critical)
    if not segment then return end

    local actor = self:GetActor(segment, sourceGuid, sourceName, sourceClass, sourceFlags)
    if not actor then return end

    local effectiveHeal = amount - (overhealing or 0)

    -- Update totals
    actor.healing = actor.healing + effectiveHeal
    actor.overhealing = actor.overhealing + (overhealing or 0)
    actor.lastActivity = GetTime()
    segment.totalHealing = segment.totalHealing + effectiveHeal

    -- Also update overall
    if self.Data.overallSegment then
        local overallActor = self:GetActor(self.Data.overallSegment, sourceGuid, sourceName, sourceClass, sourceFlags)
        if overallActor then
            overallActor.healing = overallActor.healing + effectiveHeal
            overallActor.overhealing = overallActor.overhealing + (overhealing or 0)
            overallActor.lastActivity = GetTime()
        end
        self.Data.overallSegment.totalHealing = self.Data.overallSegment.totalHealing + effectiveHeal
    end

    -- Record ability
    if EDM.db and EDM.db.profile.advanced.recordAbilities then
        local ability = self:GetAbility(actor, spellId, spellName, spellIcon)
        if ability then
            ability.healing = ability.healing + effectiveHeal
            ability.overhealing = ability.overhealing + (overhealing or 0)
            ability.healingHits = ability.healingHits + 1
            if critical then
                ability.healingCrits = ability.healingCrits + 1
            end
        end
    end

    -- Record healing received
    local destActor = self:GetActor(segment, destGuid, destName, nil, destFlags)
    if destActor then
        destActor.healingTaken = destActor.healingTaken + effectiveHeal
    end
end

-- Record death
function DB:RecordDeath(segment, timestamp, victimGuid, victimName, killerName, spellId, spellName, damage, overkill)
    if not segment then return end

    local actor = segment.actors[victimGuid]
    if actor then
        actor.deaths = actor.deaths + 1

        -- Create death log entry
        local deathEntry = DB.CreateDeathLogEntry(
            timestamp, victimGuid, victimName, killerName,
            spellId, spellName, damage, overkill
        )

        -- Add recent damage as last hits
        -- (This would need to be tracked separately, simplified here)

        table.insert(actor.deathLog, 1, deathEntry)

        -- Limit death log size
        while #actor.deathLog > C.MAX_DEATH_LOG_ENTRIES do
            table.remove(actor.deathLog)
        end
    end

    -- Add to segment deaths
    table.insert(segment.deaths, {
        timestamp = timestamp,
        victimGuid = victimGuid,
        victimName = victimName,
        killerName = killerName,
    })
end

-- Record interrupt
function DB:RecordInterrupt(segment, sourceGuid, sourceName, sourceClass, sourceFlags, spellId, spellName, extraSpellId, extraSpellName)
    if not segment then return end

    local actor = self:GetActor(segment, sourceGuid, sourceName, sourceClass, sourceFlags)
    if actor then
        actor.interrupts = actor.interrupts + 1
        -- Track the interrupt spell used
        if spellId then
            if not actor.interruptSpells then actor.interruptSpells = {} end
            if not actor.interruptSpells[spellId] then
                local spellInfo = EDM.Utils.GetSpellInfo(spellId)
                actor.interruptSpells[spellId] = {
                    name = spellName or (spellInfo and spellInfo.name) or "Unknown",
                    count = 0,
                    icon = spellInfo and spellInfo.icon,
                    interruptedSpell = extraSpellName or "Unknown"
                }
            end
            actor.interruptSpells[spellId].count = actor.interruptSpells[spellId].count + 1
        end
    end

    -- Overall
    if self.Data.overallSegment then
        local overallActor = self:GetActor(self.Data.overallSegment, sourceGuid, sourceName, sourceClass, sourceFlags)
        if overallActor then
            overallActor.interrupts = overallActor.interrupts + 1
            if spellId then
                if not overallActor.interruptSpells then overallActor.interruptSpells = {} end
                if not overallActor.interruptSpells[spellId] then
                    local spellInfo = EDM.Utils.GetSpellInfo(spellId)
                    overallActor.interruptSpells[spellId] = {
                        name = spellName or (spellInfo and spellInfo.name) or "Unknown",
                        count = 0,
                        icon = spellInfo and spellInfo.icon,
                        interruptedSpell = extraSpellName or "Unknown"
                    }
                end
                overallActor.interruptSpells[spellId].count = overallActor.interruptSpells[spellId].count + 1
            end
        end
    end
end

-- Record dispel
function DB:RecordDispel(segment, sourceGuid, sourceName, sourceClass, sourceFlags, spellId, spellName, extraSpellId, extraSpellName)
    if not segment then return end

    local actor = self:GetActor(segment, sourceGuid, sourceName, sourceClass, sourceFlags)
    if actor then
        actor.dispels = actor.dispels + 1
        -- Track the dispel spell used
        if spellId then
            if not actor.dispelSpells then actor.dispelSpells = {} end
            if not actor.dispelSpells[spellId] then
                local spellInfo = EDM.Utils.GetSpellInfo(spellId)
                actor.dispelSpells[spellId] = {
                    name = spellName or (spellInfo and spellInfo.name) or "Unknown",
                    count = 0,
                    icon = spellInfo and spellInfo.icon,
                    removedSpell = extraSpellName or "Unknown"
                }
            end
            actor.dispelSpells[spellId].count = actor.dispelSpells[spellId].count + 1
        end
    end

    -- Overall
    if self.Data.overallSegment then
        local overallActor = self:GetActor(self.Data.overallSegment, sourceGuid, sourceName, sourceClass, sourceFlags)
        if overallActor then
            overallActor.dispels = overallActor.dispels + 1
            if spellId then
                if not overallActor.dispelSpells then overallActor.dispelSpells = {} end
                if not overallActor.dispelSpells[spellId] then
                    local spellInfo = EDM.Utils.GetSpellInfo(spellId)
                    overallActor.dispelSpells[spellId] = {
                        name = spellName or (spellInfo and spellInfo.name) or "Unknown",
                        count = 0,
                        icon = spellInfo and spellInfo.icon,
                        removedSpell = extraSpellName or "Unknown"
                    }
                end
                overallActor.dispelSpells[spellId].count = overallActor.dispelSpells[spellId].count + 1
            end
        end
    end
end

-- Add timeline data point
function DB:AddTimelinePoint(segment, timestamp, damage, healing)
    if not segment or not EDM.db or not EDM.db.profile.advanced.recordTimeline then return end

    local timeline = segment.timeline
    table.insert(timeline.timestamps, timestamp)
    table.insert(timeline.damage, damage)
    table.insert(timeline.healing, healing)

    -- Limit data points
    while #timeline.timestamps > C.MAX_GRAPH_POINTS do
        table.remove(timeline.timestamps, 1)
        table.remove(timeline.damage, 1)
        table.remove(timeline.healing, 1)
    end
end

-- Get sorted actors for display (optimized with caching and table reuse)
function DB:GetSortedActors(segment, mode)
    if not segment then return tempSortTable end

    -- Check cache validity
    local now = GetTime()
    local segmentId = tostring(segment)
    if sortCache.data and
       sortCache.segmentId == segmentId and
       sortCache.displayMode == mode and
       (now - sortCache.timestamp) < sortCache.ttl then
        return sortCache.data
    end

    -- Reuse temp table to avoid GC
    wipe(tempSortTable)
    local actors = tempSortTable

    for guid, actor in pairs(segment.actors) do
        -- Include all tracked actors (already filtered by Parser)
        -- Only skip if actor has zero relevant value for the mode
        local hasValue = false
        if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
            hasValue = (actor.damage or 0) > 0
        elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
            hasValue = (actor.healing or 0) > 0
        elseif mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
            hasValue = (actor.damageTaken or 0) > 0
        elseif mode == C.DISPLAY_MODE.HEALING_TAKEN then
            hasValue = (actor.healingTaken or 0) > 0
        elseif mode == C.DISPLAY_MODE.DEATHS then
            hasValue = (actor.deaths or 0) > 0
        elseif mode == C.DISPLAY_MODE.INTERRUPTS then
            hasValue = (actor.interrupts or 0) > 0
        elseif mode == C.DISPLAY_MODE.DISPELS then
            hasValue = (actor.dispels or 0) > 0
        elseif mode == C.DISPLAY_MODE.ABSORBS then
            hasValue = (actor.absorbs or 0) > 0
        elseif mode == C.DISPLAY_MODE.ABSORBS_DONE then
            hasValue = (actor.absorbsReceived or 0) > 0
        elseif mode == C.DISPLAY_MODE.OVERHEALING then
            hasValue = (actor.overhealing or 0) > 0
        elseif mode == C.DISPLAY_MODE.FRIENDLY_FIRE then
            hasValue = (actor.friendlyFire or 0) > 0
        elseif mode == C.DISPLAY_MODE.CC_BREAKS then
            hasValue = (actor.ccBreaks or 0) > 0
        elseif mode == C.DISPLAY_MODE.RESURRECTS then
            hasValue = (actor.resurrects or 0) > 0
        else
            hasValue = (actor.damage or 0) > 0 or (actor.healing or 0) > 0
        end

        if hasValue then
            table.insert(actors, actor)
        end
    end

    -- Sort based on mode
    local sortKey
    if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
        sortKey = "damage"
    elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
        sortKey = "healing"
    elseif mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        sortKey = "damageTaken"
    elseif mode == C.DISPLAY_MODE.HEALING_TAKEN then
        sortKey = "healingTaken"
    elseif mode == C.DISPLAY_MODE.DEATHS then
        sortKey = "deaths"
    elseif mode == C.DISPLAY_MODE.INTERRUPTS then
        sortKey = "interrupts"
    elseif mode == C.DISPLAY_MODE.DISPELS then
        sortKey = "dispels"
    elseif mode == C.DISPLAY_MODE.ABSORBS then
        sortKey = "absorbs"
    elseif mode == C.DISPLAY_MODE.ABSORBS_DONE then
        sortKey = "absorbsReceived"
    elseif mode == C.DISPLAY_MODE.OVERHEALING then
        sortKey = "overhealing"
    elseif mode == C.DISPLAY_MODE.FRIENDLY_FIRE then
        sortKey = "friendlyFire"
    elseif mode == C.DISPLAY_MODE.CC_BREAKS then
        sortKey = "ccBreaks"
    elseif mode == C.DISPLAY_MODE.RESURRECTS then
        sortKey = "resurrects"
    else
        sortKey = "damage"
    end

    table.sort(actors, function(a, b)
        return (a[sortKey] or 0) > (b[sortKey] or 0)
    end)

    -- Update cache
    sortCache.data = actors
    sortCache.timestamp = now
    sortCache.segmentId = segmentId
    sortCache.displayMode = mode

    return actors
end

-- Get segment duration
function DB:GetSegmentDuration(segment)
    if not segment then return 0 end
    if segment.endTime then
        return segment.duration
    else
        return GetTime() - segment.startTime
    end
end

-- Reset all data (clears BOTH current AND overall - user triggered)
function DB:Reset()
    self.Data.segments = {}
    self.Data.overallSegment = DB.CreateSegment(C.SEGMENT_TYPE.OVERALL, "Overall")
    self:NewSegment()

    if EDM.UI then
        EDM.UI:Refresh()
    end
end

-- Start new current segment (clears current only, keeps overall - combat triggered)
function DB:StartNewCurrentSegment()
    -- Create fresh current segment
    local segment = DB.CreateSegment(C.SEGMENT_TYPE.CURRENT, "Current Combat")

    -- Get instance info
    local instance = Utils.GetInstanceInfo()
    segment.instanceName = instance.name
    segment.instanceType = instance.type

    -- Set as current (don't touch overall)
    self.Data.currentSegment = segment

    -- Add to segment list
    table.insert(self.Data.segments, 1, segment)

    -- Trim old segments
    local maxSegments = EDM.db and EDM.db.profile.combat.maxSegments or C.MAX_SEGMENTS
    while #self.Data.segments > maxSegments do
        table.remove(self.Data.segments)
    end

    return segment
end

-- Get segment by index (1 = current, 2 = previous, etc.)
function DB:GetSegment(index)
    if index == 0 then
        return self.Data.overallSegment
    else
        return self.Data.segments[index]
    end
end

-- Clear all segments (but keep current and overall)
function DB:ClearAllSegments()
    -- Keep only the current segment
    local current = self.Data.currentSegment
    self.Data.segments = {}
    if current then
        table.insert(self.Data.segments, current)
    end
    -- Reset overall
    self.Data.overallSegment = DB.CreateSegment(C.SEGMENT_TYPE.OVERALL, "Overall")
end

-- Get all segments for display
function DB:GetSegments()
    return self.Data.segments or {}
end

-- Format number for display
function DB:FormatNumber(value)
    if not value or value == 0 then return "0" end

    local format = EDM.db and EDM.db.profile.display.numberFormat or "SHORT"

    if format == "FULL" then
        return tostring(math.floor(value))
    elseif format == "COMMA" then
        local str = tostring(math.floor(value))
        local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        return formatted:gsub("^,", "")
    else -- SHORT
        if value >= 1e9 then
            return string.format("%.1fB", value / 1e9)
        elseif value >= 1e6 then
            return string.format("%.1fM", value / 1e6)
        elseif value >= 1e3 then
            return string.format("%.1fK", value / 1e3)
        else
            return tostring(math.floor(value))
        end
    end
end

-- ============================================================
-- Session Statistics
-- ============================================================

-- Initialize session stats
function DB:InitSessionStats()
    sessionStats.sessionStart = GetTime()
    sessionStats.totalCombatTime = 0
    sessionStats.totalFights = 0
    sessionStats.totalDeaths = 0
    sessionStats.totalDamage = 0
    sessionStats.totalHealing = 0
    sessionStats.bossKills = 0
    sessionStats.bossWipes = 0
end

-- Update session stats when combat ends
function DB:UpdateSessionStats(segment)
    if not segment then return end

    sessionStats.totalFights = sessionStats.totalFights + 1
    sessionStats.totalCombatTime = sessionStats.totalCombatTime + (segment.duration or 0)
    sessionStats.totalDamage = sessionStats.totalDamage + (segment.totalDamage or 0)
    sessionStats.totalHealing = sessionStats.totalHealing + (segment.totalHealing or 0)
    sessionStats.lastCombatEnd = GetTime()

    -- Count deaths
    for _, actor in pairs(segment.actors) do
        sessionStats.totalDeaths = sessionStats.totalDeaths + (actor.deaths or 0)
    end

    -- Boss tracking
    if segment.bossName then
        if segment.success then
            sessionStats.bossKills = sessionStats.bossKills + 1
        else
            sessionStats.bossWipes = sessionStats.bossWipes + 1
        end
    end
end

-- Get session statistics
function DB:GetSessionStats()
    local now = GetTime()
    local sessionDuration = now - sessionStats.sessionStart

    return {
        sessionDuration = sessionDuration,
        totalCombatTime = sessionStats.totalCombatTime,
        combatTimePercent = sessionDuration > 0 and (sessionStats.totalCombatTime / sessionDuration * 100) or 0,
        totalFights = sessionStats.totalFights,
        totalDeaths = sessionStats.totalDeaths,
        deathsPerFight = sessionStats.totalFights > 0 and (sessionStats.totalDeaths / sessionStats.totalFights) or 0,
        totalDamage = sessionStats.totalDamage,
        totalHealing = sessionStats.totalHealing,
        avgDPS = sessionStats.totalCombatTime > 0 and (sessionStats.totalDamage / sessionStats.totalCombatTime) or 0,
        avgHPS = sessionStats.totalCombatTime > 0 and (sessionStats.totalHealing / sessionStats.totalCombatTime) or 0,
        bossKills = sessionStats.bossKills,
        bossWipes = sessionStats.bossWipes,
        bossSuccessRate = (sessionStats.bossKills + sessionStats.bossWipes) > 0
            and (sessionStats.bossKills / (sessionStats.bossKills + sessionStats.bossWipes) * 100) or 0,
    }
end

-- ============================================================
-- Spell School Tracking
-- ============================================================

-- Record damage with spell school
function DB:RecordDamageWithSchool(segment, sourceGuid, sourceName, sourceClass, sourceFlags,
                                    destGuid, destName, destFlags,
                                    spellId, spellName, spellIcon, amount, overkill, school, critical)
    -- Call original record function
    self:RecordDamage(segment, sourceGuid, sourceName, sourceClass, sourceFlags,
                      destGuid, destName, destFlags,
                      spellId, spellName, spellIcon, amount, overkill, school, critical)

    -- Track spell school breakdown
    local actor = segment.actors[sourceGuid]
    if actor then
        if not actor.spellSchools then
            actor.spellSchools = {}
        end
        school = school or 1 -- Physical default
        actor.spellSchools[school] = (actor.spellSchools[school] or 0) + amount
    end
end

-- Get spell school breakdown for an actor
function DB:GetSpellSchoolBreakdown(actor)
    if not actor or not actor.spellSchools then return {} end

    local breakdown = {}
    local total = actor.damage or 0

    for school, damage in pairs(actor.spellSchools) do
        local percent = total > 0 and (damage / total * 100) or 0
        table_insert(breakdown, {
            school = school,
            damage = damage,
            percent = percent,
        })
    end

    -- Sort by damage
    table_sort(breakdown, function(a, b) return a.damage > b.damage end)

    return breakdown
end

-- ============================================================
-- Death Recap / Damage History
-- ============================================================

-- Damage history buffer for death recap (per actor)
local damageHistory = {} -- guid -> circular buffer of recent damage events
local DAMAGE_HISTORY_SIZE = 15
local DAMAGE_HISTORY_WINDOW = 10 -- seconds

-- Record damage event to history (for death recap)
function DB:RecordDamageHistory(destGuid, timestamp, sourceName, spellName, spellSchool, amount, overkill)
    if not damageHistory[destGuid] then
        damageHistory[destGuid] = {}
    end

    local history = damageHistory[destGuid]

    -- Add new entry
    table_insert(history, 1, {
        timestamp = timestamp,
        sourceName = sourceName or "Unknown",
        spellName = spellName or "Melee",
        spellSchool = spellSchool or 1,
        amount = amount or 0,
        overkill = overkill or 0,
    })

    -- Trim to max size
    while #history > DAMAGE_HISTORY_SIZE do
        table_remove(history)
    end

    -- Remove old entries outside time window
    local now = GetTime()
    for i = #history, 1, -1 do
        if (now - history[i].timestamp) > DAMAGE_HISTORY_WINDOW then
            table_remove(history, i)
        end
    end
end

-- Get damage history for death recap
function DB:GetDamageHistory(guid)
    return damageHistory[guid] or {}
end

-- Clear damage history for an actor (on combat reset)
function DB:ClearDamageHistory(guid)
    if guid then
        damageHistory[guid] = nil
    else
        wipe(damageHistory)
    end
end

-- Get enhanced death info with damage sequence
function DB:GetDeathRecap(actor)
    if not actor or #actor.deathLog == 0 then return nil end

    local lastDeath = actor.deathLog[1]
    local history = self:GetDamageHistory(actor.guid) or {}

    return {
        timestamp = lastDeath.timestamp,
        killerName = lastDeath.killerName,
        killingBlow = {
            spellName = lastDeath.spellName,
            damage = lastDeath.damage,
            overkill = lastDeath.overkill,
        },
        damageSequence = history,
        totalDamage = 0, -- Will be calculated by UI
    }
end

-- ============================================================
-- Performance Metrics
-- ============================================================

-- Invalidate sort cache (call when data changes significantly)
function DB:InvalidateSortCache()
    sortCache.data = nil
    sortCache.timestamp = 0
end

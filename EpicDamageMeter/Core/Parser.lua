--[[
    EpicDamageMeter - Parser
    Combat Log parsing and data extraction
]]

local ADDON_NAME, EDM = ...

EDM.Parser = {}
local Parser = EDM.Parser
local C = EDM.Constants
local Utils = EDM.Utils
local DB = EDM.Database

-- Player GUID cache
local playerGUID = nil
local groupGUIDs = {}

-- Initialize parser
function Parser:Initialize()
    playerGUID = UnitGUID("player")
    self:UpdateGroupGUIDs()
end

-- Update group GUIDs
function Parser:UpdateGroupGUIDs()
    wipe(groupGUIDs)

    -- Add player
    local pGUID = UnitGUID("player")
    if pGUID then
        groupGUIDs[pGUID] = true
    end

    -- Add party/raid members
    local inRaid = IsInRaid()
    local prefix = inRaid and "raid" or "party"
    local maxMembers = inRaid and 40 or 4

    for i = 1, maxMembers do
        local unit = prefix .. i
        local guid = UnitGUID(unit)
        if guid then
            groupGUIDs[guid] = true
        end

        -- Add pets
        local petUnit = prefix .. "pet" .. i
        local petGUID = UnitGUID(petUnit)
        if petGUID then
            groupGUIDs[petGUID] = true
        end
    end

    -- Add player's pet
    local playerPetGUID = UnitGUID("pet")
    if playerPetGUID then
        groupGUIDs[playerPetGUID] = true
    end
end

-- Check if GUID is in our group
function Parser:IsInGroup(guid)
    return groupGUIDs[guid] or false
end

-- Get class for GUID
function Parser:GetClass(guid)
    if not guid then return "UNKNOWN" end

    local info = Utils.GetPlayerInfo(guid)
    if info and info.class then
        return info.class
    end

    return "UNKNOWN"
end

-- Main combat log event handler
function Parser:OnCombatLogEvent()
    local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

    -- Skip events from sources not in our group (for damage/healing)
    -- But keep events targeting us (for damage taken)
    local sourceInGroup = sourceGUID and self:IsInGroup(sourceGUID)
    local destInGroup = destGUID and self:IsInGroup(destGUID)

    -- Get current segment
    local segment = DB.Data.currentSegment
    if not segment then return end

    -- Process based on event type
    if C.DAMAGE_EVENTS[subEvent] then
        self:ProcessDamage(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                          destGUID, destName, destFlags)

    elseif C.HEAL_EVENTS[subEvent] then
        self:ProcessHealing(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                           destGUID, destName, destFlags)

    elseif C.MISS_EVENTS[subEvent] then
        self:ProcessMiss(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                        destGUID, destName, destFlags)

    elseif C.DEATH_EVENTS[subEvent] then
        self:ProcessDeath(segment, timestamp, subEvent, destGUID, destName, destFlags)

    elseif C.INTERRUPT_EVENTS[subEvent] then
        self:ProcessInterrupt(segment, timestamp, sourceGUID, sourceName, sourceFlags)

    elseif C.DISPEL_EVENTS[subEvent] then
        self:ProcessDispel(segment, timestamp, sourceGUID, sourceName, sourceFlags)

    elseif C.ABSORB_EVENTS[subEvent] then
        self:ProcessAbsorb(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                          destGUID, destName, destFlags)
    end
end

-- Process damage event
function Parser:ProcessDamage(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                              destGUID, destName, destFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    local _, _, _, _, _, _, _, _, _, _, _, spellId, spellName, spellSchool
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing

    if subEvent == "SWING_DAMAGE" then
        amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            select(12, CombatLogGetCurrentEventInfo())
        spellId = 6603 -- Melee
        spellName = "Melee"
        spellSchool = 1
    elseif subEvent == "ENVIRONMENTAL_DAMAGE" then
        local envType
        envType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            select(12, CombatLogGetCurrentEventInfo())
        spellId = 0
        spellName = envType or "Environment"
        spellSchool = school or 1
    else
        spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing =
            select(12, CombatLogGetCurrentEventInfo())
    end

    if not amount or amount == 0 then return end

    -- Get spell icon
    local spellInfo = Utils.GetSpellInfo(spellId)
    local spellIcon = spellInfo and spellInfo.icon

    -- Get source class
    local sourceClass = self:GetClass(sourceGUID)

    -- Record damage
    DB:RecordDamage(segment, sourceGUID, sourceName, sourceClass, sourceFlags,
                    destGUID, destName, destFlags,
                    spellId, spellName, spellIcon, amount, overkill, spellSchool, critical)

    -- Also record damage taken for dest if in group
    if self:IsInGroup(destGUID) then
        local destActor = DB:GetActor(segment, destGUID, destName, self:GetClass(destGUID), destFlags)
        if destActor then
            destActor.damageTaken = destActor.damageTaken + amount

            -- Record in sources
            if not destActor.sources[sourceGUID] then
                destActor.sources[sourceGUID] = DB.CreateTargetData(sourceGUID, sourceName)
            end
            destActor.sources[sourceGUID].damage = destActor.sources[sourceGUID].damage + amount
        end
    end
end

-- Process healing event
function Parser:ProcessHealing(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                               destGUID, destName, destFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical =
        select(12, CombatLogGetCurrentEventInfo())

    if not amount or amount == 0 then return end

    -- Get spell icon
    local spellInfo = Utils.GetSpellInfo(spellId)
    local spellIcon = spellInfo and spellInfo.icon

    -- Get source class
    local sourceClass = self:GetClass(sourceGUID)

    -- Record healing
    DB:RecordHealing(segment, sourceGUID, sourceName, sourceClass, sourceFlags,
                     destGUID, destName, destFlags,
                     spellId, spellName, spellIcon, amount, overhealing, critical)
end

-- Process miss event
function Parser:ProcessMiss(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                            destGUID, destName, destFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    local spellId, spellName, spellSchool, missType, isOffHand, amountMissed, critical

    if subEvent == "SWING_MISSED" then
        missType, isOffHand, amountMissed, critical = select(12, CombatLogGetCurrentEventInfo())
        spellId = 6603
        spellName = "Melee"
    else
        spellId, spellName, spellSchool, missType, isOffHand, amountMissed, critical =
            select(12, CombatLogGetCurrentEventInfo())
    end

    -- Get source class
    local sourceClass = self:GetClass(sourceGUID)

    -- Get or create actor
    local actor = DB:GetActor(segment, sourceGUID, sourceName, sourceClass, sourceFlags)
    if not actor then return end

    -- Get or create ability
    local ability = DB:GetAbility(actor, spellId, spellName)
    if ability and missType then
        ability.misses[missType] = (ability.misses[missType] or 0) + 1
    end
end

-- Process death event
function Parser:ProcessDeath(segment, timestamp, subEvent, destGUID, destName, destFlags)
    -- Check if dest is in our group
    if not self:IsInGroup(destGUID) then return end

    -- Find last damage source
    local lastSource = nil
    local lastSpell = nil
    local lastDamage = 0

    -- Record death (simplified - in real addon you'd track last hits)
    DB:RecordDeath(segment, timestamp, destGUID, destName, lastSource, nil, lastSpell, lastDamage, 0)

    Utils.Debug("Death recorded for:", destName)
end

-- Process interrupt event
function Parser:ProcessInterrupt(segment, timestamp, sourceGUID, sourceName, sourceFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    local spellId, spellName, spellSchool, extraSpellId, extraSpellName =
        select(12, CombatLogGetCurrentEventInfo())

    -- Get source class
    local sourceClass = self:GetClass(sourceGUID)

    -- Record interrupt
    DB:RecordInterrupt(segment, sourceGUID, sourceName, sourceClass, sourceFlags, spellId)

    Utils.Debug("Interrupt recorded for:", sourceName, "->", extraSpellName)
end

-- Process dispel event
function Parser:ProcessDispel(segment, timestamp, sourceGUID, sourceName, sourceFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    local spellId, spellName, spellSchool, extraSpellId, extraSpellName =
        select(12, CombatLogGetCurrentEventInfo())

    -- Get source class
    local sourceClass = self:GetClass(sourceGUID)

    -- Record dispel
    DB:RecordDispel(segment, sourceGUID, sourceName, sourceClass, sourceFlags, spellId)

    Utils.Debug("Dispel recorded for:", sourceName, "->", extraSpellName)
end

-- Process absorb event
function Parser:ProcessAbsorb(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                              destGUID, destName, destFlags)
    -- SPELL_ABSORBED has complex parameters
    local args = {select(12, CombatLogGetCurrentEventInfo())}

    local casterGUID, casterName, casterFlags, casterRaidFlags
    local absorbSpellId, absorbSpellName, absorbSpellSchool
    local amount

    -- Parse based on event structure
    if type(args[4]) == "string" then
        -- Source spell was named (caster info at start)
        casterGUID, casterName, casterFlags, casterRaidFlags = args[1], args[2], args[3], args[4]
        absorbSpellId, absorbSpellName, absorbSpellSchool = args[5], args[6], args[7]
        amount = args[8]
    else
        -- No source spell
        casterGUID, casterName, casterFlags, casterRaidFlags = args[1], args[2], args[3], args[4]
        absorbSpellId, absorbSpellName, absorbSpellSchool = args[5], args[6], args[7]
        amount = args[8]
    end

    if not casterGUID or not self:IsInGroup(casterGUID) then return end
    if not amount or amount == 0 then return end

    -- Get caster class
    local casterClass = self:GetClass(casterGUID)

    -- Record absorb as healing
    local actor = DB:GetActor(segment, casterGUID, casterName, casterClass, casterFlags)
    if actor then
        actor.absorbs = actor.absorbs + amount
        actor.healing = actor.healing + amount
        segment.totalAbsorbs = segment.totalAbsorbs + amount
        segment.totalHealing = segment.totalHealing + amount
    end

    -- Also update overall
    if DB.Data.overallSegment then
        local overallActor = DB:GetActor(DB.Data.overallSegment, casterGUID, casterName, casterClass, casterFlags)
        if overallActor then
            overallActor.absorbs = overallActor.absorbs + amount
            overallActor.healing = overallActor.healing + amount
        end
        DB.Data.overallSegment.totalAbsorbs = DB.Data.overallSegment.totalAbsorbs + amount
        DB.Data.overallSegment.totalHealing = DB.Data.overallSegment.totalHealing + amount
    end
end

-- Pet to owner mapping
local petOwners = {}

-- Get pet owner
function Parser:GetPetOwner(petGUID)
    if petOwners[petGUID] then
        return petOwners[petGUID]
    end

    -- Try to find owner through tooltip scanning or other methods
    -- This is simplified - real addon would use more sophisticated tracking
    return nil
end

-- Set pet owner
function Parser:SetPetOwner(petGUID, ownerGUID)
    petOwners[petGUID] = ownerGUID
end

-- Initialize on load
Parser:Initialize()

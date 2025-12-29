--[[
    EpicDamageMeter - Parser (Enhanced)
    Combat Log parsing with improved group/raid tracking
]]

local ADDON_NAME, EDM = ...

EDM.Parser = {}
local Parser = EDM.Parser
local C = EDM.Constants
local Utils = EDM.Utils
local DB = EDM.Database

-- Localize frequently used globals for performance
local pairs = pairs
local ipairs = ipairs
local type = type
local select = select
local strsplit = strsplit
local wipe = wipe
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitClass = UnitClass
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

-- Player GUID cache
local playerGUID = nil
local playerName = nil
local groupGUIDs = {}
local petOwners = {}
local ownerPets = {}

-- GUID type cache for fast lookups
local guidTypeCache = {}

-- Reusable table to avoid garbage collection
local eventArgs = {}

-- Initialize parser
function Parser:Initialize()
    playerGUID = UnitGUID("player")
    playerName = UnitName("player")

    self:UpdateGroupGUIDs()
    self:RegisterEvents()
end

-- Register events for dynamic tracking
function Parser:RegisterEvents()
    local frame = CreateFrame("Frame")

    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ARENA_OPPONENT_UPDATE")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            Parser:UpdateGroupGUIDs()
        elseif event == "UNIT_PET" then
            Parser:UpdatePetMapping(...)
        elseif event == "ARENA_OPPONENT_UPDATE" then
            Parser:UpdateGroupGUIDs()
        end
    end)
end

-- Update group GUIDs with comprehensive tracking
function Parser:UpdateGroupGUIDs()
    wipe(groupGUIDs)
    wipe(guidTypeCache)

    -- Add player - always get fresh values
    local pGUID = UnitGUID("player")
    local pName = UnitName("player")

    -- Update cached values if available
    if pGUID then playerGUID = pGUID end
    if pName then playerName = pName end

    if pGUID and playerName then
        groupGUIDs[pGUID] = { name = playerName, type = "player", owner = nil }
        guidTypeCache[pGUID] = "player"
    end

    -- Add player's pet (unit is "pet" for player's pet)
    self:AddPetForUnit("pet", pGUID)

    -- Determine group type
    local inRaid = IsInRaid()
    local inParty = IsInGroup() and not inRaid
    local inArena = IsActiveBattlefieldArena and IsActiveBattlefieldArena()
    local inBattleground = UnitInBattleground("player") ~= nil

    if inRaid then
        self:ScanRaid()
    elseif inParty then
        self:ScanParty()
    end

    -- Add arena teammates/opponents if in arena
    if inArena then
        self:ScanArena()
    end

    Utils.Debug("Group GUIDs updated:", self:GetGroupCount())
end

-- Scan raid members
function Parser:ScanRaid()
    for i = 1, 40 do
        local unit = "raid" .. i
        local guid = UnitGUID(unit)
        if guid then
            local name, realm = UnitName(unit)
            if name then
                groupGUIDs[guid] = { name = name, type = "player", owner = nil }
                guidTypeCache[guid] = "player"
                self:AddPetForUnit(unit .. "pet", guid)
            end
        end
    end
end

-- Scan party members
function Parser:ScanParty()
    for i = 1, 4 do
        local unit = "party" .. i
        local guid = UnitGUID(unit)
        if guid then
            local name, realm = UnitName(unit)
            if name then
                groupGUIDs[guid] = { name = name, type = "player", owner = nil }
                guidTypeCache[guid] = "player"
                self:AddPetForUnit(unit .. "pet", guid)
            end
        end
    end
end

-- Scan arena units
function Parser:ScanArena()
    for i = 1, 5 do
        -- Teammates
        local unit = "arena" .. i
        local guid = UnitGUID(unit)
        if guid then
            local name = UnitName(unit)
            if name then
                groupGUIDs[guid] = { name = name, type = "player", owner = nil }
                guidTypeCache[guid] = "player"
            end
        end

        -- Arena pet
        local petUnit = "arenapet" .. i
        local petGUID = UnitGUID(petUnit)
        if petGUID then
            self:AddPetForUnit(petUnit, guid)
        end
    end
end

-- Add pet for a unit
function Parser:AddPetForUnit(petUnit, ownerGUID)
    local petGUID = UnitGUID(petUnit)
    if petGUID then
        local petName = UnitName(petUnit)
        groupGUIDs[petGUID] = { name = petName or "Pet", type = "pet", owner = ownerGUID }
        guidTypeCache[petGUID] = "pet"

        -- Store pet-owner mapping
        petOwners[petGUID] = ownerGUID
        ownerPets[ownerGUID] = ownerPets[ownerGUID] or {}
        ownerPets[ownerGUID][petGUID] = true
    end
end

-- Update pet mapping when UNIT_PET fires
function Parser:UpdatePetMapping(unit)
    if not unit then return end

    local ownerGUID = UnitGUID(unit)
    if not ownerGUID then return end

    local petUnit = unit .. "pet"
    local petGUID = UnitGUID(petUnit)

    if petGUID then
        local petName = UnitName(petUnit)
        groupGUIDs[petGUID] = { name = petName or "Pet", type = "pet", owner = ownerGUID }
        guidTypeCache[petGUID] = "pet"
        petOwners[petGUID] = ownerGUID
        ownerPets[ownerGUID] = ownerPets[ownerGUID] or {}
        ownerPets[ownerGUID][petGUID] = true
    end
end

-- Get group member count
function Parser:GetGroupCount()
    local count = 0
    for _ in pairs(groupGUIDs) do
        count = count + 1
    end
    return count
end

-- Check if GUID is in our group (simplified - like Recount/Details)
-- Only tracks: player, party members, raid members, and their pets
function Parser:IsInGroup(guid)
    if not guid then return false end

    -- Check cache first (fast path)
    if groupGUIDs[guid] then
        return true
    end

    -- Check GUID type
    local guidType = self:GetGUIDType(guid)

    -- Dynamic pet discovery from combat log
    if guidType == "Pet" or guidType == "Creature" then
        -- Try to find owner via GUID parsing
        local ownerGUID = self:FindPetOwner(guid)
        if ownerGUID and groupGUIDs[ownerGUID] then
            -- Add pet to tracking
            local name = self:GetNameFromGUID(guid)
            groupGUIDs[guid] = { name = name or "Pet", type = "pet", owner = ownerGUID }
            guidTypeCache[guid] = "pet"
            petOwners[guid] = ownerGUID
            return true
        end
    end

    return false
end

-- Get GUID type (Player, Pet, Creature, etc)
function Parser:GetGUIDType(guid)
    if not guid then return nil end

    if guidTypeCache[guid] then
        return guidTypeCache[guid]
    end

    -- Parse GUID to determine type
    local guidType = strsplit("-", guid)
    guidTypeCache[guid] = guidType
    return guidType
end

-- Find pet owner through various methods
function Parser:FindPetOwner(petGUID)
    -- Check cache first
    if petOwners[petGUID] then
        return petOwners[petGUID]
    end

    -- Try tooltip scanning
    local ownerGUID = self:ScanTooltipForOwner(petGUID)
    if ownerGUID then
        petOwners[petGUID] = ownerGUID
        return ownerGUID
    end

    return nil
end

-- Scan tooltip for pet owner (uses scanning tooltip)
function Parser:ScanTooltipForOwner(petGUID)
    -- This is a simplified version - real implementation would use tooltip scanning
    -- For now, we rely on unit-based pet tracking
    return nil
end

-- Get name from GUID
function Parser:GetNameFromGUID(guid)
    if groupGUIDs[guid] then
        return groupGUIDs[guid].name
    end
    return nil
end

-- Get class for GUID
function Parser:GetClass(guid)
    if not guid then return "UNKNOWN" end

    local info = Utils.GetPlayerInfo(guid)
    if info and info.class then
        return info.class
    end

    -- Check if it's a pet
    if guidTypeCache[guid] == "pet" or (groupGUIDs[guid] and groupGUIDs[guid].type == "pet") then
        -- Try to get owner class
        local ownerGUID = petOwners[guid]
        if ownerGUID then
            local ownerInfo = Utils.GetPlayerInfo(ownerGUID)
            if ownerInfo and ownerInfo.class then
                return ownerInfo.class
            end
        end
    end

    return "UNKNOWN"
end

-- Get pet owner (public API)
function Parser:GetPetOwner(petGUID)
    return petOwners[petGUID]
end

-- Set pet owner (public API)
function Parser:SetPetOwner(petGUID, ownerGUID)
    petOwners[petGUID] = ownerGUID
    if ownerGUID then
        ownerPets[ownerGUID] = ownerPets[ownerGUID] or {}
        ownerPets[ownerGUID][petGUID] = true
    end
end

-- Check if actor should be merged with owner
function Parser:ShouldMergePetDamage()
    return EDM.db and EDM.db.profile.general and EDM.db.profile.general.mergePets
end

-- Get effective source (pet -> owner if merging)
function Parser:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)
    if self:ShouldMergePetDamage() then
        local ownerGUID = petOwners[sourceGUID]
        if ownerGUID and groupGUIDs[ownerGUID] then
            local ownerInfo = groupGUIDs[ownerGUID]
            return ownerGUID, ownerInfo.name, sourceFlags
        end
    end
    return sourceGUID, sourceName, sourceFlags
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

    -- Handle summon events for pet tracking
    elseif subEvent == "SPELL_SUMMON" then
        self:ProcessSummon(sourceGUID, sourceName, destGUID, destName)
    end
end

-- Process summon event for pet tracking
function Parser:ProcessSummon(ownerGUID, ownerName, petGUID, petName)
    if not ownerGUID or not petGUID then return end
    if not self:IsInGroup(ownerGUID) then return end

    -- Add pet to tracking
    groupGUIDs[petGUID] = { name = petName or "Pet", type = "pet", owner = ownerGUID }
    guidTypeCache[petGUID] = "pet"
    petOwners[petGUID] = ownerGUID
    ownerPets[ownerGUID] = ownerPets[ownerGUID] or {}
    ownerPets[ownerGUID][petGUID] = true

    Utils.Debug("Pet summoned:", petName, "by", ownerName)
end

-- Process damage event
function Parser:ProcessDamage(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                              destGUID, destName, destFlags)
    -- Check if either source or dest is in our group
    local sourceInGroup = self:IsInGroup(sourceGUID)
    local destInGroup = self:IsInGroup(destGUID)

    -- Skip if neither source nor dest is in our group
    if not sourceInGroup and not destInGroup then return end

    -- Parse combat log data
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

    -- Record damage DONE if source is in our group
    if sourceInGroup then
        local effSourceGUID, effSourceName, effSourceFlags = self:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)
        local sourceClass = self:GetClass(effSourceGUID)

        DB:RecordDamage(segment, effSourceGUID, effSourceName, sourceClass, effSourceFlags,
                        destGUID, destName, destFlags,
                        spellId, spellName, spellIcon, amount, overkill, spellSchool, critical)
    end

    -- Record damage TAKEN if dest is in our group (from any source, including enemies!)
    if destInGroup then
        local destClass = self:GetClass(destGUID)
        local destActor = DB:GetActor(segment, destGUID, destName, destClass, destFlags)
        if destActor then
            destActor.damageTaken = destActor.damageTaken + amount

            -- Record in sources (who hit us)
            if not destActor.sources[sourceGUID] then
                destActor.sources[sourceGUID] = DB.CreateTargetData(sourceGUID, sourceName)
            end
            destActor.sources[sourceGUID].damage = destActor.sources[sourceGUID].damage + amount
        end

        -- Also update overall segment
        if DB.Data.overallSegment then
            local overallActor = DB:GetActor(DB.Data.overallSegment, destGUID, destName, destClass, destFlags)
            if overallActor then
                overallActor.damageTaken = overallActor.damageTaken + amount
            end
        end
    end
end

-- Process healing event
function Parser:ProcessHealing(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                               destGUID, destName, destFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    -- Get effective source (handles pet merging)
    local effSourceGUID, effSourceName, effSourceFlags = self:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)

    local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical =
        select(12, CombatLogGetCurrentEventInfo())

    if not amount or amount == 0 then return end

    -- Get spell icon
    local spellInfo = Utils.GetSpellInfo(spellId)
    local spellIcon = spellInfo and spellInfo.icon

    -- Get source class
    local sourceClass = self:GetClass(effSourceGUID)

    -- Record healing
    DB:RecordHealing(segment, effSourceGUID, effSourceName, sourceClass, effSourceFlags,
                     destGUID, destName, destFlags,
                     spellId, spellName, spellIcon, amount, overhealing, critical)
end

-- Process miss event
function Parser:ProcessMiss(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                            destGUID, destName, destFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    -- Get effective source
    local effSourceGUID, effSourceName, effSourceFlags = self:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)

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
    local sourceClass = self:GetClass(effSourceGUID)

    -- Get or create actor
    local actor = DB:GetActor(segment, effSourceGUID, effSourceName, sourceClass, effSourceFlags)
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

    -- Get effective source
    local effSourceGUID, effSourceName, effSourceFlags = self:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)

    local spellId, spellName, spellSchool, extraSpellId, extraSpellName =
        select(12, CombatLogGetCurrentEventInfo())

    -- Get source class
    local sourceClass = self:GetClass(effSourceGUID)

    -- Record interrupt with spell info
    DB:RecordInterrupt(segment, effSourceGUID, effSourceName, sourceClass, effSourceFlags, spellId, spellName, extraSpellId, extraSpellName)

    Utils.Debug("Interrupt recorded for:", effSourceName, "->", extraSpellName)
end

-- Process dispel event
function Parser:ProcessDispel(segment, timestamp, sourceGUID, sourceName, sourceFlags)
    -- Check if source is in our group
    if not self:IsInGroup(sourceGUID) then return end

    -- Get effective source
    local effSourceGUID, effSourceName, effSourceFlags = self:GetEffectiveSource(sourceGUID, sourceName, sourceFlags)

    local spellId, spellName, spellSchool, extraSpellId, extraSpellName =
        select(12, CombatLogGetCurrentEventInfo())

    -- Get source class
    local sourceClass = self:GetClass(effSourceGUID)

    -- Record dispel with spell info
    DB:RecordDispel(segment, effSourceGUID, effSourceName, sourceClass, effSourceFlags, spellId, spellName, extraSpellId, extraSpellName)

    Utils.Debug("Dispel recorded for:", effSourceName, "->", extraSpellName)
end

-- Process absorb event
function Parser:ProcessAbsorb(segment, timestamp, subEvent, sourceGUID, sourceName, sourceFlags,
                              destGUID, destName, destFlags)
    -- SPELL_ABSORBED has complex parameters - use select directly to avoid table creation
    local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 = select(12, CombatLogGetCurrentEventInfo())

    local casterGUID, casterName, casterFlags, casterRaidFlags
    local absorbSpellId, absorbSpellName, absorbSpellSchool
    local amount

    -- Parse absorb event args directly
    casterGUID, casterName, casterFlags, casterRaidFlags = arg1, arg2, arg3, arg4
    absorbSpellId, absorbSpellName, absorbSpellSchool = arg5, arg6, arg7
    amount = arg8

    if not casterGUID or not self:IsInGroup(casterGUID) then return end
    if not amount or amount == 0 then return end

    -- Get effective source
    local effCasterGUID, effCasterName = self:GetEffectiveSource(casterGUID, casterName, casterFlags)

    -- Get caster class
    local casterClass = self:GetClass(effCasterGUID)

    -- Record absorb as absorbs (NOT as healing - they are separate!)
    local actor = DB:GetActor(segment, effCasterGUID, effCasterName, casterClass, casterFlags)
    if actor then
        actor.absorbs = actor.absorbs + amount
        segment.totalAbsorbs = segment.totalAbsorbs + amount
    end

    -- Also update overall
    if DB.Data.overallSegment then
        local overallActor = DB:GetActor(DB.Data.overallSegment, effCasterGUID, effCasterName, casterClass, casterFlags)
        if overallActor then
            overallActor.absorbs = overallActor.absorbs + amount
        end
        DB.Data.overallSegment.totalAbsorbs = DB.Data.overallSegment.totalAbsorbs + amount
    end
end

-- Force refresh group GUIDs (public API)
function Parser:RefreshGroup()
    self:UpdateGroupGUIDs()
end

-- Get all group members (public API for debugging)
function Parser:GetGroupMembers()
    local members = {}
    for guid, info in pairs(groupGUIDs) do
        table.insert(members, {
            guid = guid,
            name = info.name,
            type = info.type,
            owner = info.owner
        })
    end
    return members
end

-- Note: Parser:Initialize() is called from Core:OnEnable() after player is loaded
-- Do NOT initialize here as playerGUID/playerName won't be available yet

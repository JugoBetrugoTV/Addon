--[[
    EpicDamageMeter - Core
    Main addon initialization and lifecycle management
]]

local ADDON_NAME, EDM = ...

-- Ace3 Libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- Create main addon object
local Core = AceAddon:NewAddon(ADDON_NAME, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceHook-3.0")
EDM.Core = Core

-- Local references
local C = EDM.Constants
local Utils = EDM.Utils
local DB = EDM.Database

-- Localization
local L = EpicDamageMeter_Locale or {}

-- Addon state
Core.initialized = false
Core.inCombat = false
Core.combatStartTime = nil
Core.updateTimer = nil
Core.graphTimer = nil

-- Data Broker object for minimap icon
local dataBroker = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = C.ADDON_SHORT,
    icon = "Interface\\AddOns\\EpicDamageMeter\\Textures\\icon",
    OnClick = function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                Core:ToggleLock()
            else
                Core:ToggleWindow()
            end
        elseif button == "RightButton" then
            Core:OpenConfig()
        elseif button == "MiddleButton" then
            Core:Reset()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cff00ff00Epic|r|cffff6600Damage|r|cffff0000Meter|r")
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffffffffLeft-Click:|r Toggle Window", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cffffffffShift+Left-Click:|r Lock/Unlock", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cffffffffRight-Click:|r Options", 0.8, 0.8, 0.8)
        tooltip:AddLine("|cffffffffMiddle-Click:|r Reset Data", 0.8, 0.8, 0.8)
    end,
})

-- Addon initialization
function Core:OnInitialize()
    -- Initialize database
    self.db = AceDB:New("EpicDamageMeterDB", C.DEFAULT_SETTINGS, true)
    EDM.db = self.db

    -- Setup profile callbacks
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

    -- Initialize database structures
    DB:Initialize()

    -- Register minimap icon
    LDBIcon:Register(ADDON_NAME, dataBroker, self.db.profile.minimap)

    -- Register slash commands
    self:RegisterChatCommand("edm", "SlashCommand")
    self:RegisterChatCommand("epicdm", "SlashCommand")
    self:RegisterChatCommand("epicdamagemeter", "SlashCommand")

    Utils.Debug("Core initialized")
end

-- Addon enable
function Core:OnEnable()
    -- Register events
    self:RegisterEvents()

    -- Create UI
    if EDM.UI then
        EDM.UI:Initialize()
    end

    -- Start update timer
    self:StartUpdateTimer()

    -- Print load message
    self:Print(L["ADDON_LOADED"] or "EpicDamageMeter loaded. Type /edm for options.")

    self.initialized = true
    Utils.Debug("Core enabled")
end

-- Addon disable
function Core:OnDisable()
    self:UnregisterAllEvents()
    self:CancelAllTimers()

    Utils.Debug("Core disabled")
end

-- Profile changed callback
function Core:OnProfileChanged()
    -- Update minimap icon
    LDBIcon:Refresh(ADDON_NAME, self.db.profile.minimap)

    -- Update UI
    if EDM.UI then
        EDM.UI:ApplySettings()
        EDM.UI:Refresh()
    end

    Utils.Debug("Profile changed")
end

-- Register all events
function Core:RegisterEvents()
    -- Combat events
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")

    -- Combat log
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent")

    -- Encounter events
    self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
    self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")

    -- Zone events
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    -- Group events
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")

    -- Pet events
    self:RegisterEvent("UNIT_PET", "OnUnitPet")

    Utils.Debug("Events registered")
end

-- Start update timer
function Core:StartUpdateTimer()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
    end

    local interval = self.db.profile.display.refreshRate or C.UPDATE_INTERVAL
    self.updateTimer = self:ScheduleRepeatingTimer("OnUpdateTimer", interval)

    Utils.Debug("Update timer started with interval:", interval)
end

-- Update timer callback
function Core:OnUpdateTimer()
    if not self.initialized then return end

    -- Update combat time
    if self.inCombat and DB.Data.currentSegment then
        DB.Data.currentSegment.duration = GetTime() - DB.Data.currentSegment.startTime
    end

    -- Update UI
    if EDM.UI and EDM.UI.mainFrame and EDM.UI.mainFrame:IsShown() then
        EDM.UI:UpdateBars()
    end
end

-- Combat start
function Core:OnCombatStart()
    self.inCombat = true
    self.combatStartTime = GetTime()

    local segment = DB.Data.currentSegment
    if segment then
        segment.inCombat = true
        segment.startTime = self.combatStartTime
    end

    -- Play sound
    if self.db.profile.sounds.combatStart then
        self:PlaySound("Combat Start")
    end

    Utils.Debug("Combat started")
end

-- Combat end
function Core:OnCombatEnd()
    if not self.inCombat then return end

    self.inCombat = false
    local combatDuration = GetTime() - (self.combatStartTime or GetTime())
    self.combatStartTime = nil

    local segment = DB.Data.currentSegment
    if segment then
        segment.inCombat = false
        segment.endTime = GetTime()
        segment.duration = combatDuration
    end

    -- Check minimum combat time
    local minTime = self.db.profile.combat.minCombatTime or 5
    if combatDuration >= minTime then
        -- Auto-create new segment if configured
        if self.db.profile.combat.autoReset then
            -- Only create new segment if there was meaningful data
            if segment and segment.totalDamage > 0 then
                -- Rename current segment based on context
                if segment.bossName then
                    segment.name = segment.bossName
                else
                    segment.name = Utils.FormatTime(segment.duration)
                end

                -- Create new segment
                DB:NewSegment()
            end
        end
    end

    -- Play sound
    if self.db.profile.sounds.combatEnd then
        self:PlaySound("Combat End")
    end

    -- Update UI
    if EDM.UI then
        EDM.UI:Refresh()
    end

    Utils.Debug("Combat ended, duration:", combatDuration)
end

-- Encounter start
function Core:OnEncounterStart(event, encounterID, encounterName, difficultyID, groupSize)
    Utils.Debug("Encounter started:", encounterName, "Difficulty:", difficultyID)

    -- Create a boss segment
    local bossInfo = {
        id = encounterID,
        name = encounterName,
        difficultyId = difficultyID,
        groupSize = groupSize,
    }

    DB:NewSegment(encounterName, C.SEGMENT_TYPE.BOSS, bossInfo)
end

-- Encounter end
function Core:OnEncounterEnd(event, encounterID, encounterName, difficultyID, groupSize, success)
    Utils.Debug("Encounter ended:", encounterName, "Success:", success)

    local segment = DB.Data.currentSegment
    if segment then
        segment.success = success == 1
        DB:EndSegment(success == 1)
    end

    -- Create new segment for next combat
    DB:NewSegment()
end

-- Zone changed
function Core:OnZoneChanged()
    local instance = Utils.GetInstanceInfo()
    Utils.Debug("Zone changed:", instance.name, "Type:", instance.type)
end

-- Player entering world
function Core:OnPlayerEnteringWorld(event, isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        Utils.Debug("Player entering world")

        -- Refresh UI
        if EDM.UI then
            C_Timer.After(1, function()
                EDM.UI:Refresh()
            end)
        end
    end
end

-- Group roster update
function Core:OnGroupRosterUpdate()
    Utils.Debug("Group roster updated")
end

-- Unit pet changed
function Core:OnUnitPet(event, unit)
    -- Track pet ownership changes
    Utils.Debug("Pet changed for unit:", unit)
end

-- Combat log event handler
function Core:OnCombatLogEvent(event)
    if not self.initialized then return end

    -- Parse the combat log event
    if EDM.Parser then
        EDM.Parser:OnCombatLogEvent()
    end
end

-- Slash command handler
function Core:SlashCommand(input)
    input = input and input:trim():lower() or ""

    if input == "" or input == "show" then
        self:ShowWindow()
    elseif input == "hide" then
        self:HideWindow()
    elseif input == "toggle" then
        self:ToggleWindow()
    elseif input == "reset" then
        self:Reset()
    elseif input == "config" or input == "options" then
        self:OpenConfig()
    elseif input == "lock" then
        self:ToggleLock()
    elseif input == "graph" then
        self:ToggleGraph()
    elseif input == "minimap" then
        self:ToggleMinimap()
    elseif input == "debug" then
        self.db.profile.advanced.debugMode = not self.db.profile.advanced.debugMode
        self:Print("Debug mode:", self.db.profile.advanced.debugMode and "ON" or "OFF")
    elseif input == "report" or input:match("^report%s") then
        self:ReportToChat(input)
    elseif input == "newwindow" or input == "new" then
        self:CreateNewWindow()
    elseif input == "help" then
        self:PrintHelp()
    else
        self:Print("Unknown command: " .. input)
        self:PrintHelp()
    end
end

-- Print help
function Core:PrintHelp()
    self:Print("Commands:")
    self:Print("  /edm - Show main window")
    self:Print("  /edm show - Show main window")
    self:Print("  /edm hide - Hide main window")
    self:Print("  /edm toggle - Toggle main window")
    self:Print("  /edm reset - Reset all data")
    self:Print("  /edm config - Open configuration")
    self:Print("  /edm lock - Toggle window lock")
    self:Print("  /edm graph - Toggle graph window")
    self:Print("  /edm minimap - Toggle minimap icon")
    self:Print("  /edm new - Create new meter window")
    self:Print("  /edm report [channel] - Report to chat (say/party/raid/guild)")
    self:Print("  /edm help - Show this help")
end

-- Create new window
function Core:CreateNewWindow()
    if EDM.UI then
        local instance = EDM.UI:CreateNewInstance()
        if instance then
            self:Print("Created new window #" .. instance.id)
        end
    end
end

-- Report to chat
function Core:ReportToChat(input)
    -- Parse channel from input
    local channel = "SAY"
    local args = input:match("^report%s+(.+)$")
    if args then
        args = args:upper()
        if args == "PARTY" or args == "P" then
            channel = "PARTY"
        elseif args == "RAID" or args == "R" then
            channel = "RAID"
        elseif args == "GUILD" or args == "G" then
            channel = "GUILD"
        elseif args == "INSTANCE" or args == "I" then
            channel = "INSTANCE_CHAT"
        elseif args == "WHISPER" or args == "W" then
            channel = "WHISPER"
        end
    end

    -- Get current segment data
    local segment = DB.Data.currentSegment
    if not segment then
        self:Print("No data to report")
        return
    end

    -- Get sorted actors for damage
    local actors = DB:GetSortedActors(segment, C.DISPLAY_MODE.DAMAGE_DONE)
    if not actors or #actors == 0 then
        self:Print("No damage data to report")
        return
    end

    -- Get duration
    local duration = DB:GetSegmentDuration(segment)

    -- Build report
    local maxReport = math.min(5, #actors)

    SendChatMessage("--- EpicDamageMeter Report ---", channel)

    for i = 1, maxReport do
        local actor = actors[i]
        local dps = duration > 0 and (actor.damage / duration) or 0
        local msg = string.format("%d. %s - %s (%s DPS)",
            i,
            actor.name or "Unknown",
            Utils.FormatNumber(actor.damage),
            Utils.FormatNumber(dps)
        )
        SendChatMessage(msg, channel)
    end

    -- Total line
    local totalDPS = duration > 0 and (segment.totalDamage / duration) or 0
    SendChatMessage(string.format("Total: %s damage in %s (%s DPS)",
        Utils.FormatNumber(segment.totalDamage),
        Utils.FormatTime(duration),
        Utils.FormatNumber(totalDPS)
    ), channel)
end

-- Show window
function Core:ShowWindow()
    if EDM.UI and EDM.UI.mainFrame then
        EDM.UI.mainFrame:Show()
        EDM.UI:Refresh()
    end
end

-- Hide window
function Core:HideWindow()
    if EDM.UI and EDM.UI.mainFrame then
        EDM.UI.mainFrame:Hide()
    end
end

-- Toggle window
function Core:ToggleWindow()
    if EDM.UI and EDM.UI.mainFrame then
        if EDM.UI.mainFrame:IsShown() then
            EDM.UI.mainFrame:Hide()
        else
            EDM.UI.mainFrame:Show()
            EDM.UI:Refresh()
        end
    end
end

-- Toggle lock
function Core:ToggleLock()
    self.db.profile.locked = not self.db.profile.locked

    if EDM.UI then
        EDM.UI:SetLocked(self.db.profile.locked)
    end

    self:Print("Window " .. (self.db.profile.locked and "locked" or "unlocked"))
end

-- Toggle graph
function Core:ToggleGraph()
    if EDM.UI and EDM.UI.graphFrame then
        if EDM.UI.graphFrame:IsShown() then
            EDM.UI.graphFrame:Hide()
        else
            EDM.UI.graphFrame:Show()
        end
    end
end

-- Toggle minimap
function Core:ToggleMinimap()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide

    if self.db.profile.minimap.hide then
        LDBIcon:Hide(ADDON_NAME)
    else
        LDBIcon:Show(ADDON_NAME)
    end
end

-- Open config
function Core:OpenConfig()
    if EDM.Config then
        EDM.Config:Open()
    end
end

-- Reset data
function Core:Reset()
    DB:Reset()
    self:Print("Data reset")
end

-- Play sound
function Core:PlaySound(soundName)
    local soundFile = LSM:Fetch("sound", soundName)
    if soundFile and soundFile ~= "" then
        PlaySoundFile(soundFile, "Master")
    end
end

-- Get current display mode name
function Core:GetDisplayModeName()
    local mode = self.db.profile.display.mode
    return C.DISPLAY_MODE_NAMES[mode] or "Damage Done"
end

-- Set display mode
function Core:SetDisplayMode(mode)
    if C.DISPLAY_MODE_NAMES[mode] then
        self.db.profile.display.mode = mode
        if EDM.UI then
            EDM.UI:Refresh()
        end
    end
end

-- Cycle display mode
function Core:CycleDisplayMode()
    local currentMode = self.db.profile.display.mode
    local nextMode = currentMode + 1

    -- Find next valid mode
    while not C.DISPLAY_MODE_NAMES[nextMode] do
        nextMode = nextMode + 1
        if nextMode > 12 then
            nextMode = 1
        end
        if nextMode == currentMode then
            break
        end
    end

    self:SetDisplayMode(nextMode)
end

-- Get data for current display
function Core:GetDisplayData()
    local segmentIndex = self.db.profile.display.segment
    local segment

    if segmentIndex == C.SEGMENT_TYPE.OVERALL then
        segment = DB.Data.overallSegment
    else
        segment = DB.Data.currentSegment
    end

    if not segment then return {} end

    local mode = self.db.profile.display.mode
    return DB:GetSortedActors(segment, mode)
end

-- Addon compartment click handler (for addon list button)
function EpicDamageMeter_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "LeftButton" then
        Core:ToggleWindow()
    elseif buttonName == "RightButton" then
        Core:OpenConfig()
    end
end

-- Make Core globally accessible
_G.EpicDamageMeterCore = Core

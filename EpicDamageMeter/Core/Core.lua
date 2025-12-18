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

    -- Update combat time for current segment
    if DB.Data.currentSegment then
        if self.inCombat then
            DB.Data.currentSegment.duration = GetTime() - DB.Data.currentSegment.startTime
        elseif not DB.Data.currentSegment.endTime then
            -- Keep updating duration even out of combat until segment ends
            DB.Data.currentSegment.duration = GetTime() - DB.Data.currentSegment.startTime
        end
    end

    -- Update all UI instances (multi-window support)
    if EDM.UI then
        EDM.UI:UpdateAll()
    end

    -- Update graph if visible
    if EDM.Graph and EDM.Graph.frame and EDM.Graph.frame:IsShown() then
        EDM.Graph:Update()
    end

    -- Update detail window if visible
    if EDM.DetailWindow and EDM.DetailWindow.frame and EDM.DetailWindow.frame:IsShown() then
        EDM.DetailWindow:Update()
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
        segment.duration = combatDuration
        segment.endTime = GetTime()

        -- Save current segment data to overall before potentially clearing
        -- Overall keeps accumulating until manual reset or group change
        -- Current segment data persists but shows last combat
    end

    -- Play sound
    if self.db.profile.sounds.combatEnd then
        self:PlaySound("Combat End")
    end

    -- Update UI (data stays visible after combat)
    if EDM.UI then
        EDM.UI:Refresh()
    end

    Utils.Debug("Combat ended, duration:", combatDuration)
end

-- Check if group/instance changed (should reset overall)
function Core:CheckGroupChange()
    local currentInstance = Utils.GetInstanceInfo()
    local currentGroupType = self:GetGroupType()

    -- Check if we're in a new instance/group
    local shouldReset = false

    if self.lastInstanceName and self.lastInstanceName ~= currentInstance.name then
        if currentInstance.type ~= "none" then
            shouldReset = true
            Utils.Debug("Instance changed from", self.lastInstanceName, "to", currentInstance.name)
        end
    end

    if self.lastGroupType and self.lastGroupType ~= currentGroupType then
        if currentGroupType ~= "solo" then
            shouldReset = true
            Utils.Debug("Group changed from", self.lastGroupType, "to", currentGroupType)
        end
    end

    -- Store current state
    self.lastInstanceName = currentInstance.name
    self.lastGroupType = currentGroupType

    if shouldReset then
        self:Print("New group/instance detected. Resetting data.")
        DB:Reset()
    end
end

-- Get current group type
function Core:GetGroupType()
    if IsInRaid() then
        return "raid"
    elseif IsInGroup() then
        local instanceType = select(2, IsInInstance())
        if instanceType == "pvp" then
            return "battleground"
        elseif instanceType == "arena" then
            return "arena"
        else
            return "party"
        end
    end
    return "solo"
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

    -- Check if we should auto-reset for new instance
    C_Timer.After(1, function()
        self:CheckGroupChange()
    end)
end

-- Player entering world
function Core:OnPlayerEnteringWorld(event, isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        Utils.Debug("Player entering world")

        -- Initialize tracking state
        local instance = Utils.GetInstanceInfo()
        self.lastInstanceName = instance.name
        self.lastGroupType = self:GetGroupType()

        -- Refresh UI
        if EDM.UI then
            C_Timer.After(1, function()
                EDM.UI:Refresh()
            end)
        end
    else
        -- Zone change (not login/reload)
        C_Timer.After(1, function()
            self:CheckGroupChange()
        end)
    end
end

-- Group roster update
function Core:OnGroupRosterUpdate()
    Utils.Debug("Group roster updated")

    -- Check for group changes
    C_Timer.After(0.5, function()
        self:CheckGroupChange()
    end)
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

-- Report to chat with enhanced options
function Core:ReportToChat(input)
    -- Parse channel and mode from input
    -- Format: /edm report [channel] [mode] [count]
    -- Examples: /edm report party damage 5
    --           /edm report raid healing
    --           /edm report guild own
    local channel = "SAY"
    local reportMode = "damage" -- damage, healing, own
    local reportCount = 5
    local whisperTarget = nil

    local args = input:match("^report%s*(.*)$")
    if args and args ~= "" then
        local parts = {}
        for part in args:gmatch("%S+") do
            table.insert(parts, part:lower())
        end

        -- Parse channel
        if parts[1] then
            local ch = parts[1]:upper()
            if ch == "PARTY" or ch == "P" then
                channel = "PARTY"
            elseif ch == "RAID" or ch == "R" then
                channel = "RAID"
            elseif ch == "GUILD" or ch == "G" then
                channel = "GUILD"
            elseif ch == "INSTANCE" or ch == "I" then
                channel = "INSTANCE_CHAT"
            elseif ch == "SAY" or ch == "S" then
                channel = "SAY"
            elseif ch == "YELL" or ch == "Y" then
                channel = "YELL"
            elseif ch:match("^W:") then
                channel = "WHISPER"
                whisperTarget = ch:match("^W:(.+)$")
            end
        end

        -- Parse mode
        if parts[2] then
            local mode = parts[2]
            if mode == "damage" or mode == "dps" or mode == "d" then
                reportMode = "damage"
            elseif mode == "healing" or mode == "hps" or mode == "h" then
                reportMode = "healing"
            elseif mode == "own" or mode == "self" or mode == "me" then
                reportMode = "own"
            end
        end

        -- Parse count
        if parts[3] then
            reportCount = tonumber(parts[3]) or 5
            reportCount = math.min(math.max(reportCount, 1), 15)
        end
    end

    -- Get segment data
    local segment = DB.Data.currentSegment
    if not segment then
        self:Print("No data to report")
        return
    end

    local duration = DB:GetSegmentDuration(segment)
    if duration == 0 then duration = 1 end

    -- Helper function to send message
    local function SendMsg(msg)
        if channel == "WHISPER" and whisperTarget then
            SendChatMessage(msg, channel, nil, whisperTarget)
        else
            SendChatMessage(msg, channel)
        end
    end

    -- Report own data
    if reportMode == "own" then
        local playerGuid = UnitGUID("player")
        local playerActor = segment.actors[playerGuid]

        if not playerActor then
            self:Print("No personal data to report")
            return
        end

        local dps = playerActor.damage / duration
        local hps = playerActor.healing / duration

        SendMsg(string.format("--- My Stats (%s) ---", Utils.FormatTime(duration)))
        SendMsg(string.format("Damage: %s (%s DPS) | Healing: %s (%s HPS)",
            Utils.FormatNumber(playerActor.damage),
            Utils.FormatNumber(dps),
            Utils.FormatNumber(playerActor.healing),
            Utils.FormatNumber(hps)
        ))

        -- Top abilities
        if playerActor.abilities and next(playerActor.abilities) then
            local sortedAbilities = {}
            for _, ability in pairs(playerActor.abilities) do
                if ability.damage > 0 then
                    table.insert(sortedAbilities, ability)
                end
            end
            table.sort(sortedAbilities, function(a, b) return a.damage > b.damage end)

            if #sortedAbilities > 0 then
                local topAbilities = {}
                for i = 1, math.min(3, #sortedAbilities) do
                    table.insert(topAbilities, string.format("%s: %s", sortedAbilities[i].name, Utils.FormatNumber(sortedAbilities[i].damage)))
                end
                SendMsg("Top: " .. table.concat(topAbilities, " | "))
            end
        end
        return
    end

    -- Report group data
    local displayMode = reportMode == "healing" and C.DISPLAY_MODE.HEALING_DONE or C.DISPLAY_MODE.DAMAGE_DONE
    local actors = DB:GetSortedActors(segment, displayMode)

    if not actors or #actors == 0 then
        self:Print("No " .. reportMode .. " data to report")
        return
    end

    local maxReport = math.min(reportCount, #actors)
    local modeLabel = reportMode == "healing" and "Healing" or "Damage"
    local psLabel = reportMode == "healing" and "HPS" or "DPS"

    SendMsg(string.format("--- EpicDM %s Report (%s) ---", modeLabel, Utils.FormatTime(duration)))

    local total = 0
    for i = 1, maxReport do
        local actor = actors[i]
        local value = reportMode == "healing" and actor.healing or actor.damage
        local perSecond = value / duration
        total = total + value

        local msg = string.format("%d. %s - %s (%s %s)",
            i,
            actor.name or "Unknown",
            Utils.FormatNumber(value),
            Utils.FormatNumber(perSecond),
            psLabel
        )
        SendMsg(msg)
    end

    -- Total line
    local segmentTotal = reportMode == "healing" and segment.totalHealing or segment.totalDamage
    local totalPS = segmentTotal / duration
    SendMsg(string.format("Total: %s %s (%s %s)",
        Utils.FormatNumber(segmentTotal),
        modeLabel:lower(),
        Utils.FormatNumber(totalPS),
        psLabel
    ))
end

-- Show chat report menu (for UI button)
function Core:ShowReportMenu(parentFrame)
    if not self.reportDropdown then
        self.reportDropdown = CreateFrame("Frame", "EDMReportDropdown", UIParent, "UIDropDownMenuTemplate")
    end

    local function InitializeMenu(frame, level)
        level = level or 1
        local info = UIDropDownMenu_CreateInfo()

        if level == 1 then
            -- Header
            info.text = "|cff00ff00Report to Chat|r"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            info.isTitle = false
            info.disabled = false

            -- Report damage
            info.text = "Damage (Party)"
            info.notCheckable = true
            info.func = function() Core:ReportToChat("report party damage 5") end
            UIDropDownMenu_AddButton(info, level)

            info.text = "Damage (Raid)"
            info.func = function() Core:ReportToChat("report raid damage 5") end
            UIDropDownMenu_AddButton(info, level)

            info.text = "Damage (Instance)"
            info.func = function() Core:ReportToChat("report instance damage 5") end
            UIDropDownMenu_AddButton(info, level)

            -- Separator
            info.text = ""
            info.disabled = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            info.disabled = false

            -- Report healing
            info.text = "Healing (Party)"
            info.func = function() Core:ReportToChat("report party healing 5") end
            UIDropDownMenu_AddButton(info, level)

            info.text = "Healing (Raid)"
            info.func = function() Core:ReportToChat("report raid healing 5") end
            UIDropDownMenu_AddButton(info, level)

            -- Separator
            info.text = ""
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            info.disabled = false

            -- Report own stats
            info.text = "|cff6699ffMy Stats (Party)|r"
            info.func = function() Core:ReportToChat("report party own") end
            UIDropDownMenu_AddButton(info, level)

            info.text = "|cff6699ffMy Stats (Guild)|r"
            info.func = function() Core:ReportToChat("report guild own") end
            UIDropDownMenu_AddButton(info, level)

            -- Separator
            info.text = ""
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            info.disabled = false

            -- Cancel
            info.text = "Cancel"
            info.func = function() CloseDropDownMenus() end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(self.reportDropdown, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, self.reportDropdown, parentFrame or "cursor", 0, 0)
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
    -- Try LSM first
    local soundFile = LSM:Fetch("sound", soundName)
    if soundFile and soundFile ~= "" and soundFile ~= "None" then
        PlaySoundFile(soundFile, "Master")
        return
    end

    -- Fallback to built-in WoW sounds
    local builtInSounds = {
        ["Combat Start"] = SOUNDKIT.READY_CHECK,
        ["Combat End"] = SOUNDKIT.UI_RAID_BOSS_DEFEATED,
        ["New Record"] = SOUNDKIT.UI_PERSONAL_BEST_BANNER_CHEER,
        ["Alert"] = SOUNDKIT.ALARM_CLOCK_WARNING_2,
    }

    local soundID = builtInSounds[soundName]
    if soundID then
        PlaySound(soundID, "Master")
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

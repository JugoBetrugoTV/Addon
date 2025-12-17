--[[
    EpicDamageMeter - Events
    Event handling and callbacks
]]

local ADDON_NAME, EDM = ...

EDM.Events = {}
local Events = EDM.Events
local C = EDM.Constants
local Utils = EDM.Utils

-- Event registry
Events.callbacks = {}

-- Register callback for an event
function Events:RegisterCallback(event, callback, owner)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end

    table.insert(self.callbacks[event], {
        callback = callback,
        owner = owner,
    })
end

-- Unregister callback
function Events:UnregisterCallback(event, callback)
    if not self.callbacks[event] then return end

    for i, cb in ipairs(self.callbacks[event]) do
        if cb.callback == callback then
            table.remove(self.callbacks[event], i)
            return
        end
    end
end

-- Fire event
function Events:Fire(event, ...)
    if not self.callbacks[event] then return end

    for _, cb in ipairs(self.callbacks[event]) do
        local success, err = pcall(cb.callback, cb.owner, ...)
        if not success then
            Utils.Debug("Event callback error:", event, err)
        end
    end
end

-- Combat events
Events.COMBAT_START = "COMBAT_START"
Events.COMBAT_END = "COMBAT_END"
Events.SEGMENT_START = "SEGMENT_START"
Events.SEGMENT_END = "SEGMENT_END"
Events.DATA_UPDATED = "DATA_UPDATED"
Events.DISPLAY_MODE_CHANGED = "DISPLAY_MODE_CHANGED"
Events.SETTINGS_CHANGED = "SETTINGS_CHANGED"

-- Encounter events
Events.ENCOUNTER_START = "ENCOUNTER_START"
Events.ENCOUNTER_END = "ENCOUNTER_END"

-- Unit events
Events.UNIT_DIED = "UNIT_DIED"
Events.PLAYER_DAMAGE = "PLAYER_DAMAGE"
Events.PLAYER_HEAL = "PLAYER_HEAL"

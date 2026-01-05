--[[ AceEvent-3.0-EDM - ISOLATED Event handling library for EpicDamageMeter ]]
local MAJOR, MINOR = "AceEvent-3.0-EDM", 1
local AceEvent

-- Create isolated version
if LibStub.libs["AceEvent-3.0-EDM"] then
    AceEvent = LibStub.libs["AceEvent-3.0-EDM"]
else
    AceEvent = {}
    LibStub.libs["AceEvent-3.0-EDM"] = AceEvent
    LibStub.minors["AceEvent-3.0-EDM"] = 1
end

AceEvent.frame = AceEvent.frame or CreateFrame("Frame", "AceEvent30EDMFrame")
AceEvent.embeds = AceEvent.embeds or {}
AceEvent.eventCallbacks = AceEvent.eventCallbacks or {}
AceEvent.messageCallbacks = AceEvent.messageCallbacks or {}

-- Safe error handler that works without BugSack
local function safeErrorHandler(err)
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        handler(err)
    else
        -- Fallback to print if no error handler is available
        print("|cffff0000Error:|r " .. tostring(err))
    end
end

-- Direct event registration (no CallbackHandler dependency)
local function RegisterEventImpl(self, event, method)
    if type(event) ~= "string" then return end
    method = method or event

    if not AceEvent.eventCallbacks[event] then
        AceEvent.eventCallbacks[event] = {}
        AceEvent.frame:RegisterEvent(event)
    end
    AceEvent.eventCallbacks[event][self] = method
end

local function UnregisterEventImpl(self, event)
    if not event or not AceEvent.eventCallbacks[event] then return end
    AceEvent.eventCallbacks[event][self] = nil

    if not next(AceEvent.eventCallbacks[event]) then
        AceEvent.frame:UnregisterEvent(event)
        AceEvent.eventCallbacks[event] = nil
    end
end

local function UnregisterAllEventsImpl(self)
    for event in pairs(AceEvent.eventCallbacks) do
        if AceEvent.eventCallbacks[event][self] then
            AceEvent.eventCallbacks[event][self] = nil
            if not next(AceEvent.eventCallbacks[event]) then
                AceEvent.frame:UnregisterEvent(event)
                AceEvent.eventCallbacks[event] = nil
            end
        end
    end
end

local function RegisterMessageImpl(self, message, method)
    if type(message) ~= "string" then return end
    method = method or message

    if not AceEvent.messageCallbacks[message] then
        AceEvent.messageCallbacks[message] = {}
    end
    AceEvent.messageCallbacks[message][self] = method
end

local function UnregisterMessageImpl(self, message)
    if not message or not AceEvent.messageCallbacks[message] then return end
    AceEvent.messageCallbacks[message][self] = nil
end

local function UnregisterAllMessagesImpl(self)
    for message in pairs(AceEvent.messageCallbacks) do
        if AceEvent.messageCallbacks[message][self] then
            AceEvent.messageCallbacks[message][self] = nil
        end
    end
end

local function SendMessageImpl(self, message, ...)
    if not message or not AceEvent.messageCallbacks[message] then return end
    for target, method in pairs(AceEvent.messageCallbacks[message]) do
        local func = type(method) == "string" and target[method] or method
        if func then
            local success, err = pcall(func, target, message, ...)
            if not success then
                safeErrorHandler(err)
            end
        end
    end
end

-- Event dispatcher
AceEvent.frame:SetScript("OnEvent", function(frame, event, ...)
    local callbacks = AceEvent.eventCallbacks[event]
    if not callbacks then return end

    for target, method in pairs(callbacks) do
        local func = type(method) == "string" and target[method] or method
        if func then
            local success, err = pcall(func, target, event, ...)
            if not success then
                safeErrorHandler(err)
            end
        end
    end
end)

-- Embed into target addon
function AceEvent:Embed(target)
    target.RegisterEvent = RegisterEventImpl
    target.UnregisterEvent = UnregisterEventImpl
    target.UnregisterAllEvents = UnregisterAllEventsImpl
    target.RegisterMessage = RegisterMessageImpl
    target.UnregisterMessage = UnregisterMessageImpl
    target.UnregisterAllMessages = UnregisterAllMessagesImpl
    target.SendMessage = SendMessageImpl

    self.embeds[target] = true
    return target
end

-- Re-embed on library upgrade
for addon in pairs(AceEvent.embeds) do
    AceEvent:Embed(addon)
end

--[[ AceEvent-3.0 - Event handling library ]]
local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end

AceEvent.frame = AceEvent.frame or CreateFrame("Frame")
AceEvent.embeds = AceEvent.embeds or {}

local CallbackHandler = LibStub("CallbackHandler-1.0")

-- Create separate callback handler objects for events and messages
-- Each gets its own Fire function and events storage
if not AceEvent.eventHandler then
    local handler, events, registry = CallbackHandler:New({}, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")
    AceEvent.eventHandler = handler

    -- Copy methods to AceEvent for embedding
    if handler then
        AceEvent.RegisterEvent = handler.RegisterEvent
        AceEvent.UnregisterEvent = handler.UnregisterEvent
        AceEvent.UnregisterAllEvents = handler.UnregisterAllEvents
    end

    -- When an event is first registered, register the frame for that event
    -- Safety check: registry might be nil if CallbackHandler version differs
    if registry then
        registry.OnUsed = function(self, usedTarget, eventname)
            AceEvent.frame:RegisterEvent(eventname)
        end
        -- When no more handlers exist for an event, unregister the frame
        registry.OnUnused = function(self, usedTarget, eventname)
            AceEvent.frame:UnregisterEvent(eventname)
        end
    end
end

if not AceEvent.messageHandler then
    local handler, messages, registry = CallbackHandler:New({}, "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages")
    AceEvent.messageHandler = handler

    -- Copy methods to AceEvent for embedding
    if handler then
        AceEvent.RegisterMessage = handler.RegisterMessage
        AceEvent.UnregisterMessage = handler.UnregisterMessage
        AceEvent.UnregisterAllMessages = handler.UnregisterAllMessages
    end
end

AceEvent.frame:SetScript("OnEvent", function(self, event, ...)
    AceEvent.eventHandler:Fire(event, ...)
end)

local function SendMessage(self, message, ...)
    AceEvent.messageHandler:Fire(message, ...)
end

local mixins = {
    "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents",
    "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages",
    "SendMessage"
}

function AceEvent:Embed(target)
    for k, v in pairs(mixins) do
        if v == "SendMessage" then
            target[v] = SendMessage
        else
            target[v] = self[v]
        end
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceEvent.embeds) do
    AceEvent:Embed(addon)
end

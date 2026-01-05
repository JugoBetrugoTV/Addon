--[[ AceEvent-3.0 - Event handling library ]]
local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end

AceEvent.frame = AceEvent.frame or CreateFrame("Frame")
AceEvent.embeds = AceEvent.embeds or {}

local CallbackHandler = LibStub("CallbackHandler-1.0")
AceEvent.events = AceEvent.events or CallbackHandler:New(AceEvent.frame, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents")
AceEvent.messages = AceEvent.messages or CallbackHandler:New(AceEvent.frame, "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages")

function AceEvent.events:OnUsed(target, eventname)
    target:RegisterEvent(eventname)
end

function AceEvent.events:OnUnused(target, eventname)
    target:UnregisterEvent(eventname)
end

AceEvent.frame:SetScript("OnEvent", function(self, event, ...)
    AceEvent.events:Fire(event, ...)
end)

local function SendMessage(self, message, ...)
    AceEvent.messages:Fire(message, ...)
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
            target[v] = self[v] or self.events[v] or self.messages[v]
        end
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceEvent.embeds) do
    AceEvent:Embed(addon)
end

--[[ AceConsole-3.0 - Console command library ]]
local MAJOR, MINOR = "AceConsole-3.0", 7
local AceConsole = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConsole then return end

AceConsole.embeds = AceConsole.embeds or {}
AceConsole.commands = AceConsole.commands or {}

local print, type, pairs, tinsert, tconcat = print, type, pairs, table.insert, table.concat

local function Print(self, frame, ...)
    frame = frame or DEFAULT_CHAT_FRAME
    local text = ""
    local n = select("#", ...)
    for i = 1, n do
        local v = select(i, ...)
        text = text .. (i > 1 and " " or "") .. tostring(v)
    end
    frame:AddMessage(text)
end

local mixins = {
    "Print", "Printf", "RegisterChatCommand", "UnregisterChatCommand"
}

function AceConsole:Print(...)
    local name = self.moduleName or self.name or "Addon"
    return Print(self, DEFAULT_CHAT_FRAME, "|cff33ff99" .. name .. "|r:", ...)
end

function AceConsole:Printf(...)
    local name = self.moduleName or self.name or "Addon"
    return Print(self, DEFAULT_CHAT_FRAME, "|cff33ff99" .. name .. "|r:", format(...))
end

function AceConsole:RegisterChatCommand(command, func, persist)
    if type(command) ~= "string" then
        error("Usage: RegisterChatCommand(command, func): 'command' - string expected.", 2)
    end

    if func == nil then
        func = "ChatCommand"
    end

    if type(func) == "string" then
        if type(self[func]) ~= "function" then
            error(("Usage: RegisterChatCommand(command, func): 'func' - method '%s' not found."):format(func), 2)
        end
    elseif type(func) ~= "function" then
        error("Usage: RegisterChatCommand(command, func): 'func' - function or method name expected.", 2)
    end

    command = command:lower()

    local function handler(msg, editbox)
        local callback = func
        if type(callback) == "string" then
            callback = self[func]
        end
        callback(self, msg, editbox)
    end

    SlashCmdList[command:upper()] = handler
    _G["SLASH_" .. command:upper() .. "1"] = "/" .. command

    AceConsole.commands[command] = command:upper()

    return command
end

function AceConsole:UnregisterChatCommand(command)
    command = command:lower()
    if AceConsole.commands[command] then
        SlashCmdList[AceConsole.commands[command]] = nil
        _G["SLASH_" .. AceConsole.commands[command] .. "1"] = nil
        AceConsole.commands[command] = nil
    end
end

function AceConsole:Embed(target)
    for k, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceConsole.embeds) do
    AceConsole:Embed(addon)
end

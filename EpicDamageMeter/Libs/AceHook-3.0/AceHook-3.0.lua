--[[ AceHook-3.0 - Hook library ]]
local MAJOR, MINOR = "AceHook-3.0", 8
local AceHook = LibStub:NewLibrary(MAJOR, MINOR)

if not AceHook then return end

AceHook.embeds = AceHook.embeds or {}
AceHook.hooks = AceHook.hooks or {}

local function donothing() end

local function hook(self, obj, method, handler, script, secure)
    local uid
    if obj then
        uid = tostring(obj)..tostring(method)
    else
        uid = tostring(method)
    end

    self.hooks = self.hooks or {}

    if self.hooks[uid] then
        return
    end

    local orig
    if script then
        orig = obj:GetScript(method) or donothing
    elseif obj then
        orig = obj[method]
    else
        orig = _G[method]
    end

    self.hooks[uid] = orig

    local hookFunc = function(...)
        local handlerFunc = handler
        if type(handler) == "string" then
            handlerFunc = self[handler]
        end
        return handlerFunc(self, ...)
    end

    if script then
        if secure then
            obj:HookScript(method, hookFunc)
        else
            obj:SetScript(method, hookFunc)
        end
    elseif obj then
        if secure then
            hooksecurefunc(obj, method, hookFunc)
        else
            obj[method] = hookFunc
        end
    else
        if secure then
            hooksecurefunc(method, hookFunc)
        else
            _G[method] = hookFunc
        end
    end
end

local mixins = {
    "Hook", "SecureHook", "HookScript", "SecureHookScript",
    "Unhook", "UnhookAll", "IsHooked", "RawHook", "RawHookScript"
}

function AceHook:Hook(obj, method, handler)
    if type(obj) == "string" then
        handler = method
        method = obj
        obj = nil
    end
    handler = handler or method
    hook(self, obj, method, handler, false, false)
end

function AceHook:SecureHook(obj, method, handler)
    if type(obj) == "string" then
        handler = method
        method = obj
        obj = nil
    end
    handler = handler or method
    hook(self, obj, method, handler, false, true)
end

function AceHook:HookScript(obj, method, handler)
    handler = handler or method
    hook(self, obj, method, handler, true, false)
end

function AceHook:SecureHookScript(obj, method, handler)
    handler = handler or method
    hook(self, obj, method, handler, true, true)
end

function AceHook:RawHook(obj, method, handler)
    self:Hook(obj, method, handler)
end

function AceHook:RawHookScript(obj, method, handler)
    self:HookScript(obj, method, handler)
end

function AceHook:Unhook(obj, method)
    if type(obj) == "string" then
        method = obj
        obj = nil
    end

    local uid
    if obj then
        uid = tostring(obj)..tostring(method)
    else
        uid = tostring(method)
    end

    if self.hooks and self.hooks[uid] then
        self.hooks[uid] = nil
    end
end

function AceHook:UnhookAll()
    if self.hooks then
        wipe(self.hooks)
    end
end

function AceHook:IsHooked(obj, method)
    if type(obj) == "string" then
        method = obj
        obj = nil
    end

    local uid
    if obj then
        uid = tostring(obj)..tostring(method)
    else
        uid = tostring(method)
    end

    return self.hooks and self.hooks[uid] ~= nil
end

function AceHook:Embed(target)
    for k, v in pairs(mixins) do
        target[v] = self[v]
    end
    target.hooks = target.hooks or {}
    self.embeds[target] = true
    return target
end

for addon in pairs(AceHook.embeds) do
    AceHook:Embed(addon)
end

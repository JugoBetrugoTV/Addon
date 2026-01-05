--[[ CallbackHandler-1.0-EDM - Callback system for EpicDamageMeter ]]
-- Also registers as CallbackHandler-1.0 for compatibility with LibDataBroker, LibDBIcon, etc.
local MAJOR, MINOR = "CallbackHandler-1.0-EDM", 8
local CallbackHandler

-- Create isolated version
if LibStub.libs["CallbackHandler-1.0-EDM"] then
    CallbackHandler = LibStub.libs["CallbackHandler-1.0-EDM"]
else
    CallbackHandler = {}
    LibStub.libs["CallbackHandler-1.0-EDM"] = CallbackHandler
    LibStub.minors["CallbackHandler-1.0-EDM"] = MINOR
end

-- ALSO register as standard CallbackHandler-1.0 if not already present (for LibDataBroker, LibDBIcon compatibility)
if not LibStub.libs["CallbackHandler-1.0"] then
    LibStub.libs["CallbackHandler-1.0"] = CallbackHandler
    LibStub.minors["CallbackHandler-1.0"] = MINOR
end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

-- Safe error handler that works without BugSack
local function safeErrorHandler(err)
    local handler = geterrorhandler and geterrorhandler()
    if handler then
        return handler(err)
    else
        -- Fallback to print if no error handler is available
        print("|cffff0000Error:|r " .. tostring(err))
    end
end

function CallbackHandler.New(self, target, RegisterName, UnregisterName, UnregisterAllName)
    RegisterName = RegisterName or "RegisterCallback"
    UnregisterName = UnregisterName or "UnregisterCallback"
    UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

    local events = setmetatable({}, meta)
    local registry = {recurse=0, insertQueue={}}

    target = target or {}

    local function fire(self, eventname, ...)
        if not rawget(events, eventname) or not next(events[eventname]) then return end
        local oldrecurse = registry.recurse
        registry.recurse = oldrecurse + 1

        for target, method in pairs(events[eventname]) do
            local func = method
            if type(method) == "string" then
                func = target[method]
            end
            xpcall(func, safeErrorHandler, target, ...)
        end

        registry.recurse = oldrecurse
        if registry.recurse == 0 and next(registry.insertQueue) then
            for eventname, callbacks in pairs(registry.insertQueue) do
                for target, method in pairs(callbacks) do
                    events[eventname][target] = method
                end
            end
            wipe(registry.insertQueue)
        end
    end

    target[RegisterName] = function(self, eventname, method, ...)
        if type(eventname) ~= "string" then
            error("Usage: "..RegisterName.."(eventname, method): 'eventname' - string expected.", 2)
        end

        method = method or eventname

        local first = not rawget(events, eventname) or not next(events[eventname])

        if registry.recurse > 0 then
            registry.insertQueue[eventname] = registry.insertQueue[eventname] or {}
            registry.insertQueue[eventname][self] = method
        else
            events[eventname][self] = method
        end

        if registry.OnUsed and first then
            registry.OnUsed(registry, target, eventname)
        end
    end

    target[UnregisterName] = function(self, eventname)
        if not self or not eventname then return end
        if rawget(events, eventname) then
            events[eventname][self] = nil
        end
        if registry.OnUnused and rawget(events, eventname) and not next(events[eventname]) then
            registry.OnUnused(registry, target, eventname)
        end
    end

    target[UnregisterAllName] = function(self)
        if not self then return end
        for eventname in pairs(events) do
            events[eventname][self] = nil
            if registry.OnUnused and not next(events[eventname]) then
                registry.OnUnused(registry, target, eventname)
            end
        end
    end

    target.Fire = fire

    return target, events, registry
end

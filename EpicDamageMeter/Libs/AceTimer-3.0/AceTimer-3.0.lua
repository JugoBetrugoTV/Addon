--[[ AceTimer-3.0-EDM - ISOLATED Timer library for EpicDamageMeter ]]
local MAJOR, MINOR = "AceTimer-3.0-EDM", 1
local AceTimer

-- Create isolated version
if LibStub.libs["AceTimer-3.0-EDM"] then
    AceTimer = LibStub.libs["AceTimer-3.0-EDM"]
else
    AceTimer = {}
    LibStub.libs["AceTimer-3.0-EDM"] = AceTimer
    LibStub.minors["AceTimer-3.0-EDM"] = 1
end

-- C_Timer polyfill for older WoW versions (MoP, Cata, etc.) that don't have C_Timer
if not C_Timer then
    C_Timer = {}

    local timerFrame = CreateFrame("Frame")
    local timers = {}
    local timerID = 0

    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        for id, timer in pairs(timers) do
            if now >= timer.endTime then
                timers[id] = nil
                local success, err = pcall(timer.callback)
                if not success then
                    print("|cffff0000Timer Error:|r " .. tostring(err))
                end
            end
        end
    end)

    function C_Timer.After(delay, callback)
        timerID = timerID + 1
        timers[timerID] = {
            endTime = GetTime() + delay,
            callback = callback
        }
    end

    function C_Timer.NewTimer(delay, callback)
        local timer = { cancelled = false }
        timerID = timerID + 1
        local id = timerID
        timers[id] = {
            endTime = GetTime() + delay,
            callback = function()
                if not timer.cancelled then
                    callback()
                end
            end
        }
        function timer:Cancel()
            self.cancelled = true
            timers[id] = nil
        end
        return timer
    end

    function C_Timer.NewTicker(interval, callback, iterations)
        local ticker = { cancelled = false, count = 0 }
        local function tick()
            if ticker.cancelled then return end
            ticker.count = ticker.count + 1
            callback(ticker)
            if not iterations or ticker.count < iterations then
                C_Timer.After(interval, tick)
            end
        end
        C_Timer.After(interval, tick)
        function ticker:Cancel()
            self.cancelled = true
        end
        return ticker
    end
end

AceTimer.embeds = AceTimer.embeds or {}
AceTimer.activeTimers = AceTimer.activeTimers or {}

local function new(self, callback, delay, arg, rep)
    local timer = {
        object = self,
        callback = callback,
        delay = delay,
        arg = arg,
        rep = rep,
    }

    timer.handle = C_Timer.NewTicker(delay, function()
        local cb = timer.callback
        if type(cb) == "string" then
            cb = timer.object[cb]
        end

        if timer.arg ~= nil then
            cb(timer.object, timer.arg)
        else
            cb(timer.object)
        end

        if not timer.rep then
            AceTimer.activeTimers[timer] = nil
        end
    end, rep and nil or 1)

    AceTimer.activeTimers[timer] = true

    return timer
end

local function cancel(timer)
    if timer and timer.handle then
        timer.handle:Cancel()
    end
    if timer then
        AceTimer.activeTimers[timer] = nil
    end
end

local mixins = {
    "ScheduleTimer", "ScheduleRepeatingTimer", "CancelTimer", "CancelAllTimers", "TimeLeft"
}

function AceTimer:ScheduleTimer(callback, delay, arg)
    return new(self, callback, delay, arg, false)
end

function AceTimer:ScheduleRepeatingTimer(callback, delay, arg)
    return new(self, callback, delay, arg, true)
end

function AceTimer:CancelTimer(timer)
    cancel(timer)
end

function AceTimer:CancelAllTimers()
    for timer in pairs(AceTimer.activeTimers) do
        if timer.object == self then
            cancel(timer)
        end
    end
end

function AceTimer:TimeLeft(timer)
    if not timer or not timer.handle then return 0 end
    return 0 -- C_Timer doesn't expose time left
end

function AceTimer:Embed(target)
    for k, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

for addon in pairs(AceTimer.embeds) do
    AceTimer:Embed(addon)
end

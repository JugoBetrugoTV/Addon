--[[
    EpicDamageMeter - Utilities
    Helper functions and utilities
]]

local ADDON_NAME, EDM = ...

-- C_Timer polyfill for older WoW versions (MoP, etc.) that don't have C_Timer
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

EDM.Utils = {}
local Utils = EDM.Utils
local C = EDM.Constants

-- Number formatting
function Utils.FormatNumber(number, format)
    if not number or number == 0 then return "0" end

    format = format or "SHORT"

    if format == "FULL" then
        return string.format("%.0f", number)
    elseif format == "COMMA" then
        local formatted = string.format("%.0f", number)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then break end
        end
        return formatted
    else -- SHORT
        for _, abbr in ipairs(C.NUMBER_ABBREVIATIONS) do
            if math.abs(number) >= abbr.threshold then
                return string.format("%.1f%s", number / abbr.threshold, abbr.suffix)
            end
        end
        return string.format("%.0f", number)
    end
end

-- Time formatting
function Utils.FormatTime(seconds)
    if not seconds or seconds <= 0 then return "0:00" end

    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%d:%02d", mins, secs)
    end
end

-- Percentage formatting
function Utils.FormatPercent(value, total)
    if not total or total == 0 then return "0%" end
    local percent = (value / total) * 100
    if percent < 1 then
        return string.format("%.1f%%", percent)
    else
        return string.format("%.0f%%", percent)
    end
end

-- Get class color
function Utils.GetClassColor(class)
    local color = C.CLASS_COLORS[class] or C.CLASS_COLORS.UNKNOWN
    return color.r, color.g, color.b
end

-- Get class color as hex
function Utils.GetClassColorHex(class)
    local r, g, b = Utils.GetClassColor(class)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- Color text with class color
function Utils.ClassColorText(text, class)
    local hex = Utils.GetClassColorHex(class)
    return "|cff" .. hex .. text .. "|r"
end

-- Get school color
function Utils.GetSchoolColor(school)
    school = school or 1
    local color = C.SCHOOL_COLORS[school]
    if not color then
        -- Handle combined schools by finding the primary
        for _, schoolId in ipairs({64, 32, 16, 8, 4, 2, 1}) do
            if bit.band(school, schoolId) > 0 then
                color = C.SCHOOL_COLORS[schoolId]
                break
            end
        end
    end
    return color or C.SCHOOL_COLORS[1]
end

-- Check if unit is player controlled
function Utils.IsPlayerControlled(flags)
    if not flags then return false end
    return bit.band(flags, C.UNIT_FLAGS.CONTROL_PLAYER) > 0
end

-- Check if unit is friendly
function Utils.IsFriendly(flags)
    if not flags then return false end
    return bit.band(flags, C.UNIT_FLAGS.REACTION_FRIENDLY) > 0
end

-- Check if unit is in our group (party/raid)
function Utils.IsInGroup(flags)
    if not flags then return false end
    local mask = bit.bor(
        C.UNIT_FLAGS.AFFILIATION_MINE,
        C.UNIT_FLAGS.AFFILIATION_PARTY,
        C.UNIT_FLAGS.AFFILIATION_RAID
    )
    return bit.band(flags, mask) > 0
end

-- Check if unit is a pet/guardian
function Utils.IsPet(flags)
    if not flags then return false end
    local mask = bit.bor(C.UNIT_FLAGS.TYPE_PET, C.UNIT_FLAGS.TYPE_GUARDIAN)
    return bit.band(flags, mask) > 0
end

-- Check if unit is an NPC
function Utils.IsNPC(flags)
    if not flags then return false end
    return bit.band(flags, C.UNIT_FLAGS.TYPE_NPC) > 0
end

-- Get unit type string
function Utils.GetUnitType(flags)
    if Utils.IsPet(flags) then
        return "PET"
    elseif bit.band(flags, C.UNIT_FLAGS.TYPE_PLAYER) > 0 then
        return "PLAYER"
    elseif Utils.IsNPC(flags) then
        return "NPC"
    else
        return "UNKNOWN"
    end
end

-- GUID parsing
function Utils.ParseGUID(guid)
    if not guid then return nil end

    local unitType, _, serverID, instanceID, zoneUID, npcID, spawnUID = strsplit("-", guid)

    return {
        type = unitType,
        serverID = serverID,
        instanceID = instanceID,
        zoneUID = zoneUID,
        npcID = npcID and tonumber(npcID),
        spawnUID = spawnUID,
    }
end

-- Get player info from GUID
function Utils.GetPlayerInfo(guid)
    if not guid then return nil end

    local _, class, _, race, sex, name, realm = GetPlayerInfoByGUID(guid)

    return {
        class = class,
        race = race,
        sex = sex,
        name = name,
        realm = realm,
    }
end

-- Table utilities
function Utils.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils.TableMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            Utils.TableMerge(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

function Utils.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Utils.TableKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

-- Sort table by value
function Utils.SortByValue(tbl, key, descending)
    local sorted = {}
    for k, v in pairs(tbl) do
        table.insert(sorted, { key = k, value = v })
    end

    table.sort(sorted, function(a, b)
        local aVal = key and a.value[key] or a.value
        local bVal = key and b.value[key] or b.value
        if descending then
            return aVal > bVal
        else
            return aVal < bVal
        end
    end)

    return sorted
end

-- Color utilities
function Utils.HexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
           tonumber("0x" .. hex:sub(3, 4)) / 255,
           tonumber("0x" .. hex:sub(5, 6)) / 255
end

function Utils.RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Utils.ColorGradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select('#', ...) - 2, ...)
        return r, g, b
    elseif perc <= 0 then
        local r, g, b = ...
        return r, g, b
    end

    local num = select('#', ...) / 3
    local segment, relperc = math.modf(perc * (num - 1))
    local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)

    return r1 + (r2 - r1) * relperc,
           g1 + (g2 - g1) * relperc,
           b1 + (b2 - b1) * relperc
end

-- Create color from percent (green -> yellow -> red)
function Utils.GetPercentColor(percent)
    return Utils.ColorGradient(percent,
        0, 1, 0,      -- Green
        1, 1, 0,      -- Yellow
        1, 0, 0       -- Red
    )
end

-- String utilities
function Utils.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

function Utils.Split(str, sep)
    local parts = {}
    for part in str:gmatch("[^" .. sep .. "]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Animation easing functions
function Utils.EaseOutQuad(t)
    return t * (2 - t)
end

function Utils.EaseInOutQuad(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2)^2 / 2
end

function Utils.EaseOutElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return 2^(-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

-- Debug print
function Utils.Debug(...)
    if EDM.db and EDM.db.profile.advanced.debugMode then
        print("|cff00ff00[EDM Debug]|r", ...)
    end
end

-- Error handling wrapper
function Utils.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Utils.Debug("Error:", result)
    end
    return success, result
end

-- Get spell info with caching
local spellCache = {}
function Utils.GetSpellInfo(spellId)
    if not spellId then return nil end

    if not spellCache[spellId] then
        local info = C_Spell and C_Spell.GetSpellInfo(spellId) or nil
        if info then
            spellCache[spellId] = {
                name = info.name,
                icon = info.iconID,
                castTime = info.castTime,
                minRange = info.minRange,
                maxRange = info.maxRange,
            }
        else
            -- Fallback for older API
            local name, _, icon = GetSpellInfo(spellId)
            if name then
                spellCache[spellId] = {
                    name = name,
                    icon = icon,
                }
            end
        end
    end

    return spellCache[spellId]
end

-- Get current instance info
function Utils.GetInstanceInfo()
    local name, instanceType, difficultyID, difficultyName, maxPlayers,
          dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()

    return {
        name = name,
        type = instanceType,
        difficultyID = difficultyID,
        difficultyName = difficultyName,
        maxPlayers = maxPlayers,
        instanceID = instanceID,
        isRaid = instanceType == "raid",
        isDungeon = instanceType == "party",
        isPvP = instanceType == "pvp" or instanceType == "arena",
    }
end

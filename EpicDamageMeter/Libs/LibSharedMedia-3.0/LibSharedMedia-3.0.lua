--[[ LibSharedMedia-3.0 - Shared media library ]]
local MAJOR, MINOR = "LibSharedMedia-3.0", 8
local LibSharedMedia = LibStub:NewLibrary(MAJOR, MINOR)

if not LibSharedMedia then return end

LibSharedMedia.MediaTable = LibSharedMedia.MediaTable or {}
LibSharedMedia.MediaList = LibSharedMedia.MediaList or {}
LibSharedMedia.DefaultMedia = LibSharedMedia.DefaultMedia or {}

local MediaTable = LibSharedMedia.MediaTable
local MediaList = LibSharedMedia.MediaList
local DefaultMedia = LibSharedMedia.DefaultMedia

-- Media types
LibSharedMedia.MediaType = LibSharedMedia.MediaType or {}
local MediaType = LibSharedMedia.MediaType

MediaType.STATUSBAR = "statusbar"
MediaType.FONT = "font"
MediaType.SOUND = "sound"
MediaType.BORDER = "border"
MediaType.BACKGROUND = "background"

-- Initialize tables
for _, v in pairs(MediaType) do
    MediaTable[v] = MediaTable[v] or {}
    MediaList[v] = MediaList[v] or {}
end

-- Default media
DefaultMedia.statusbar = "Blizzard"
DefaultMedia.font = "Friz Quadrata TT"
DefaultMedia.sound = "None"
DefaultMedia.border = "Blizzard Tooltip"
DefaultMedia.background = "Blizzard Tooltip"

function LibSharedMedia:Register(mediatype, key, data, langmask)
    if type(mediatype) ~= "string" then
        error("Usage: LibSharedMedia:Register(mediatype, key, data): 'mediatype' - string expected, got " .. type(mediatype), 2)
    end
    if type(key) ~= "string" then
        error("Usage: LibSharedMedia:Register(mediatype, key, data): 'key' - string expected, got " .. type(key), 2)
    end

    mediatype = mediatype:lower()
    if not MediaTable[mediatype] then
        MediaTable[mediatype] = {}
        MediaList[mediatype] = {}
    end

    MediaTable[mediatype][key] = data

    -- Update list
    for i, v in pairs(MediaList[mediatype]) do
        if v == key then
            return
        end
    end
    table.insert(MediaList[mediatype], key)
    table.sort(MediaList[mediatype])
end

function LibSharedMedia:Fetch(mediatype, key, noDefault)
    mediatype = mediatype:lower()
    local mtable = MediaTable[mediatype]
    if mtable then
        if mtable[key] then
            return mtable[key]
        end
        if not noDefault and DefaultMedia[mediatype] and mtable[DefaultMedia[mediatype]] then
            return mtable[DefaultMedia[mediatype]]
        end
    end
    return nil
end

function LibSharedMedia:IsValid(mediatype, key)
    mediatype = mediatype:lower()
    return MediaTable[mediatype] and MediaTable[mediatype][key] ~= nil
end

function LibSharedMedia:HashTable(mediatype)
    return MediaTable[mediatype:lower()]
end

function LibSharedMedia:List(mediatype)
    return MediaList[mediatype:lower()]
end

function LibSharedMedia:GetGlobal(mediatype)
    return DefaultMedia[mediatype:lower()]
end

function LibSharedMedia:SetGlobal(mediatype, key)
    if MediaTable[mediatype:lower()] and MediaTable[mediatype:lower()][key] then
        DefaultMedia[mediatype:lower()] = key
        return true
    end
    return false
end

function LibSharedMedia:GetDefault(mediatype)
    return DefaultMedia[mediatype:lower()]
end

-- Register default media

-- Status Bars
LibSharedMedia:Register("statusbar", "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar")
LibSharedMedia:Register("statusbar", "Blizzard Character Skills Bar", "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
LibSharedMedia:Register("statusbar", "Blizzard Raid Bar", "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
LibSharedMedia:Register("statusbar", "Solid", "Interface\\Buttons\\WHITE8X8")
LibSharedMedia:Register("statusbar", "Smooth", "Interface\\AddOns\\EpicDamageMeter\\Textures\\statusbar_smooth")
LibSharedMedia:Register("statusbar", "Gradient", "Interface\\AddOns\\EpicDamageMeter\\Textures\\statusbar_gradient")
LibSharedMedia:Register("statusbar", "Glossy", "Interface\\AddOns\\EpicDamageMeter\\Textures\\statusbar_glossy")
LibSharedMedia:Register("statusbar", "Modern", "Interface\\AddOns\\EpicDamageMeter\\Textures\\statusbar_modern")
LibSharedMedia:Register("statusbar", "Flat", "Interface\\AddOns\\EpicDamageMeter\\Textures\\statusbar_flat")

-- Fonts (All standard WoW fonts)
LibSharedMedia:Register("font", "Friz Quadrata TT", "Fonts\\FRIZQT__.TTF")
LibSharedMedia:Register("font", "Arial Narrow", "Fonts\\ARIALN.TTF")
LibSharedMedia:Register("font", "Morpheus", "Fonts\\MORPHEUS.TTF")
LibSharedMedia:Register("font", "Skurri", "Fonts\\SKURRI.TTF")
LibSharedMedia:Register("font", "2002", "Fonts\\2002.TTF")
LibSharedMedia:Register("font", "2002 Bold", "Fonts\\2002B.TTF")
LibSharedMedia:Register("font", "Expressway", "Fonts\\EXPRESSA.TTF")
LibSharedMedia:Register("font", "Nimrod MT", "Fonts\\NIM_____.TTF")
LibSharedMedia:Register("font", "Adventure", "Fonts\\ADVENTURE.TTF")
LibSharedMedia:Register("font", "Porky's", "Fonts\\PORKYS_.TTF")
LibSharedMedia:Register("font", "Friends", "Fonts\\FRIENDS.TTF")

-- Sounds
LibSharedMedia:Register("sound", "None", "")
LibSharedMedia:Register("sound", "Alarm Clock", "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\AlarmClockWarning3.ogg")
LibSharedMedia:Register("sound", "Ding", "Interface\\AddOns\\EpicDamageMeter\\Sounds\\ding.ogg")
LibSharedMedia:Register("sound", "Combat Start", "Interface\\AddOns\\EpicDamageMeter\\Sounds\\combat_start.ogg")
LibSharedMedia:Register("sound", "Combat End", "Interface\\AddOns\\EpicDamageMeter\\Sounds\\combat_end.ogg")
LibSharedMedia:Register("sound", "Level Up", "Interface\\AddOns\\EpicDamageMeter\\Sounds\\level_up.ogg")

-- Borders
LibSharedMedia:Register("border", "Blizzard Tooltip", "Interface\\Tooltips\\UI-Tooltip-Border")
LibSharedMedia:Register("border", "Blizzard Dialog", "Interface\\DialogFrame\\UI-DialogBox-Border")
LibSharedMedia:Register("border", "None", "")
LibSharedMedia:Register("border", "Simple", "Interface\\AddOns\\EpicDamageMeter\\Textures\\border_simple")

-- Backgrounds
LibSharedMedia:Register("background", "Blizzard Tooltip", "Interface\\Tooltips\\UI-Tooltip-Background")
LibSharedMedia:Register("background", "Blizzard Dialog", "Interface\\DialogFrame\\UI-DialogBox-Background")
LibSharedMedia:Register("background", "Solid", "Interface\\Buttons\\WHITE8X8")
LibSharedMedia:Register("background", "None", "")

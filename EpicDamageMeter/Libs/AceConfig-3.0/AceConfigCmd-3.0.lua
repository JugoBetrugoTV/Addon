--[[ AceConfigCmd-3.0-EDM - ISOLATED Configuration command line for EpicDamageMeter ]]
local MAJOR, MINOR = "AceConfigCmd-3.0-EDM", 1
local AceConfigCmd

-- Create isolated version
if LibStub.libs["AceConfigCmd-3.0-EDM"] then
    AceConfigCmd = LibStub.libs["AceConfigCmd-3.0-EDM"]
else
    AceConfigCmd = {}
    LibStub.libs["AceConfigCmd-3.0-EDM"] = AceConfigCmd
    LibStub.minors["AceConfigCmd-3.0-EDM"] = 1
end

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0-EDM")
local AceConsole = LibStub("AceConsole-3.0-EDM")

AceConfigCmd.commands = AceConfigCmd.commands or {}

local function traverseOptions(options, path)
    local current = options
    for _, key in ipairs(path) do
        if current.args and current.args[key] then
            current = current.args[key]
        else
            return nil
        end
    end
    return current
end

local function printHelp(options, prefix, handler)
    prefix = prefix or ""
    if not options or not options.args then return end

    for key, opt in pairs(options.args) do
        if opt.type == "group" then
            print(prefix .. key .. " - " .. (opt.name or key))
            printHelp(opt, prefix .. "  ", handler)
        else
            local desc = opt.desc or opt.name or key
            print(prefix .. key .. " - " .. desc)
        end
    end
end

function AceConfigCmd:CreateChatCommand(slashcmd, appName)
    if type(slashcmd) ~= "string" then
        error(("Usage: CreateChatCommand(slashcmd, appName): 'slashcmd' - string expected, got %s"):format(type(slashcmd)), 2)
    end
    if type(appName) ~= "string" then
        error(("Usage: CreateChatCommand(slashcmd, appName): 'appName' - string expected, got %s"):format(type(appName)), 2)
    end

    local handler = self.commands[appName]
    if not handler then
        handler = {}
        self.commands[appName] = handler
    end

    slashcmd = slashcmd:lower()

    local function chatCommand(input)
        local options = AceConfigRegistry:GetOptionsTable(appName, "cmd", slashcmd)
        if not options then
            print("No options found for " .. appName)
            return
        end

        if not input or input == "" or input == "help" then
            print("Commands for " .. appName .. ":")
            printHelp(options, "  ", handler)
            return
        end

        -- Parse input
        local args = {}
        for word in input:gmatch("%S+") do
            table.insert(args, word)
        end

        local option = traverseOptions(options, args)
        if option then
            if option.type == "toggle" then
                local get = option.get
                if type(get) == "function" then
                    local current = get()
                    if option.set then
                        option.set(not current)
                    end
                    print(option.name .. ": " .. (current and "Disabled" or "Enabled"))
                end
            elseif option.type == "execute" then
                if option.func then
                    option.func()
                end
            else
                print("Option: " .. (option.name or args[#args]))
            end
        else
            print("Unknown command. Type /" .. slashcmd .. " help for available commands.")
        end
    end

    SlashCmdList[slashcmd:upper()] = chatCommand
    _G["SLASH_" .. slashcmd:upper() .. "1"] = "/" .. slashcmd
end

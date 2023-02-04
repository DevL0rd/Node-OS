local termUtils = require("/lib/termUtils")
local sha256 = require("/lib/sha256")
local args = { ... }
local command = args[1]


function printHelp()
    termUtils.print("Usage: settings <command> <arguments>")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  list - List all settings.")
    termUtils.print("  set <setting> <value> - Set a setting.")
    termUtils.print("  get <setting> - Get a setting.")
end
if command == "set" then
    local setting = string.lower(args[2])
    local value = args[3]
    if setting == "name" then
        os.setComputerLabel(value)
    elseif setting == "password" then
        termUtils.print("You can also input no password to disable it.")
        termUtils.print("Please enter a new password:")
        local newPassword = read("*")
        if newPassword == "" then
            sets.settings.password = ""
            settings.saveSettings()
        else
            termUtils.print("Please enter the password again:")
            local pass2 = read("*")
            if pass2 ~= newPassword then
                sets.settings.password = ""
                termUtils.print("Passwords do not match.", "red")
            else
                sets.settings.password = sha256(newPassword)
                settings.saveSettings()
            end
        end
    elseif setting == "pin" then
        sets.settings.pin = value
        termUtils.print("Pin set! A reboot is required for network to get changes.", "yellow")
        settings.saveSettings()
    elseif setting == "master" then
        sets.settings.master = value
        termUtils.print("Master ID set! A reboot is required for network to get changes.", "yellow")
        settings.saveSettings()
    elseif setting == "consoleonly" then
        if value == "true" then
            sets.settings.consoleOnly = true
            termUtils.print("Console only set! A reboot is required to switch to console only mode.", "yellow")
            settings.saveSettings()
        elseif value == "false" then
            sets.settings.consoleOnly = false
            termUtils.print("Console only set! A reboot is required to switch to console only mode.", "yellow")
            settings.saveSettings()
        else
            termUtils.print("Invalid value!", "red")
        end
    else
        termUtils.print("Unknown setting!", "red")
    end
elseif command == "get" then
    local setting = string.lower(args[2])
    if setting == "name" then
        termUtils.print(os.getComputerLabel())
    elseif setting == "password" then
        termUtils.print("The password is unreadable after set.", "yellow")
    elseif setting == "pin" then
        termUtils.print(sets.settings.pin)
    elseif setting == "master" then
        termUtils.print(sets.settings.master)
    elseif setting == "consoleonly" then
        if sets.settings.consoleOnly then
            termUtils.print("true")
        else
            termUtils.print("false")
        end
    else
        termUtils.print("Unknown setting!", "red")
    end
elseif command == "list" then
    termUtils.print("name: " .. os.getComputerLabel())
    if sets.settings.password == "" then
        termUtils.print("password: none")
    else
        termUtils.print("password: set")
    end
    if sets.settings.pin == "" then
        termUtils.print("pin: none")
    else
        termUtils.print("pin: set")
    end
    if sets.settings.consoleOnly then
        termUtils.print("consoleOnly: true")
    else
        termUtils.print("consoleOnly: false")
    end
    termUtils.print("master: " .. sets.settings.master)
else
    printHelp()
end
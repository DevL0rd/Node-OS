local sha256 = require("/lib/sha256")
local args = { ... }
local command = args[1]


function printHelp()
    nodeos.graphics.print("Usage: settings <command> <arguments>")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  list - List all settings.")
    nodeos.graphics.print("  set <setting> <value> - Set a setting.")
    nodeos.graphics.print("  get <setting> - Get a setting.")
end

if command == "set" then
    local setting = string.lower(args[2])
    local value = args[3]
    if setting == "name" then
        os.setComputerLabel(value)
    elseif setting == "password" then
        nodeos.graphics.print("You can also input no password to disable it.")
        nodeos.graphics.print("Please enter a new password:")
        local newPassword = read("*")
        if newPassword == "" then
            nodeos.settings.settings.password = ""
            settings.saveSettings()
        else
            nodeos.graphics.print("Please enter the password again:")
            local pass2 = read("*")
            if pass2 ~= newPassword then
                nodeos.settings.settings.password = ""
                nodeos.graphics.print("Passwords do not match.", "red")
            else
                nodeos.settings.settings.password = sha256(newPassword)
                settings.saveSettings()
            end
        end
    elseif setting == "pin" then
        nodeos.settings.settings.pin = value
        nodeos.graphics.print("Pin set! A reboot is required for network to get changes.", "yellow")
        settings.saveSettings()
    elseif setting == "master" then
        nodeos.settings.settings.master = value
        nodeos.graphics.print("Master ID set! A reboot is required for network to get changes.", "yellow")
        settings.saveSettings()
    elseif setting == "consoleonly" then
        if value == "true" then
            nodeos.settings.settings.consoleOnly = true
            nodeos.graphics.print("Console only set! A reboot is required to switch to console only mode.", "yellow")
            settings.saveSettings()
        elseif value == "false" then
            nodeos.settings.settings.consoleOnly = false
            nodeos.graphics.print("Console only set! A reboot is required to switch to console only mode.", "yellow")
            settings.saveSettings()
        else
            nodeos.graphics.print("Invalid value!", "red")
        end
    else
        nodeos.graphics.print("Unknown setting!", "red")
    end
elseif command == "get" then
    local setting = string.lower(args[2])
    if setting == "name" then
        nodeos.graphics.print(os.getComputerLabel())
    elseif setting == "password" then
        nodeos.graphics.print("The password is unreadable after set.", "yellow")
    elseif setting == "pin" then
        nodeos.graphics.print(nodeos.settings.settings.pin)
    elseif setting == "master" then
        nodeos.graphics.print(nodeos.settings.settings.master)
    elseif setting == "consoleonly" then
        if nodeos.settings.settings.consoleOnly then
            nodeos.graphics.print("true")
        else
            nodeos.graphics.print("false")
        end
    else
        nodeos.graphics.print("Unknown setting!", "red")
    end
elseif command == "list" then
    nodeos.graphics.print("name: " .. os.getComputerLabel())
    if nodeos.settings.settings.password == "" then
        nodeos.graphics.print("password: none")
    else
        nodeos.graphics.print("password: set")
    end
    if nodeos.settings.settings.pin == "" then
        nodeos.graphics.print("pin: none")
    else
        nodeos.graphics.print("pin: set")
    end
    if nodeos.settings.settings.consoleOnly then
        nodeos.graphics.print("consoleOnly: true")
    else
        nodeos.graphics.print("consoleOnly: false")
    end
    nodeos.graphics.print("master: " .. nodeos.settings.settings.master)
else
    printHelp()
end

local settings = require("/lib/settings")
local termUtils = require("/lib/termUtils")
local sha256 = require("/lib/sha256")
local args = { ... }
local command = args[1]


function printHelp()
    termUtils.print("settings help")
    termUtils.print("settings set <setting> <value>")
    termUtils.print("settings get <setting>")
    termUtils.print("settings addgroup <group>")
    termUtils.print("settings delgroup <group>")
    termUtils.print("settings listgroups")
end

if command == "set" then
    local setting = args[2]
    local value = args[3]
    if setting == "name" then
        os.setComputerLabel(value)
    elseif setting == "password" then
        termUtils.print("You can also input no password to disable it.")
        termUtils.print("Please enter a new password:")
        local newPassword = read("*")
        if newPassword == "" then
            settings.password = ""
        else
            termUtils.print("Please enter the password again:")
            local pass2 = read("*")
            if pass2 ~= newPassword then
                settings.settings.password = ""
                termUtils.print("Passwords do not match.", "red")
            else
                settings.settings.password = sha256(newPassword)
            end
        end
    elseif setting == "pin" then
        settings.settings.pin = value
        termUtils.print("Pin set! A reboot is required for network to get changes.", "yellow")
    elseif setting == "master" then
        settings.settings.master = value
        termUtils.print("Master ID set! A reboot is required for network to get changes.", "yellow")
    else
        termUtils.print("Unknown setting!", "red")
    end
    settings.saveSettings(settings.settings)
elseif command == "get" then
    local setting = args[2]
    if setting == "name" then
        termUtils.print(os.getComputerLabel())
    elseif setting == "password" then
        termUtils.print("The password is unreadable after set.", "yellow")
    elseif setting == "pin" then
        termUtils.print(settings.settings.pin)
    elseif setting == "master" then
        termUtils.print(settings.settings.master)
    else
        termUtils.print("Unknown setting!", "red")
    end
elseif command == "addgroup" then
    local group = args[2]
    if not group then
        termUtils.print("You must specify a group.", "red")
        return
    end
    if not settings.settings.groups then
        settings.settings.groups = {}
    end
    if not settings.settings.groups[group] then
        table.insert(settings.settings.groups, group)
        settings.saveSettings(settings.settings)
        termUtils.print("Group '" .. group .. "' added! A reboot is required for network to get changes.", "yellow")
    else
        termUtils.print("Group '" .. group .. "' already exists.", "yellow")
    end
elseif command == "delgroup" then
    local group = args[2]
    if not group then
        termUtils.print("You must specify a group.", "red")
        return
    end
    if settings.settings.groups[group] then
        settings.settings.groups[group] = nil
        settings.saveSettings(settings.settings)
        termUtils.print("Group '" .. group .. "' deleted. A reboot is required for network to get changes.", "yellow")
    else
        termUtils.print("Group '" .. group .. "' does not exist.", "red")
    end
elseif command == "listgroups" then
    for i, group in ipairs(settings.settings.groups) do
        termUtils.print(group)
    end
else
    printHelp()
end
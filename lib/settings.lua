local util = require("/lib/util")
local file = util.loadModule("file")
local settingsPath = "etc/settings.cfg"

--Load system settings
local settings = {
    settings = {
        password = nil,
        pin = nil,
        master = 0,
        groups = {
            "all"
        },
        consoleOnly = nil
    }
}

function settings.getSettings()
    local s = file.readTable(settingsPath)
    if not s then
        settings.saveSettings(settings.settings)
        return settings.settings
    end
    settings.settings = s
    return settings.settings
end

function settings.saveSettings()
    file.writeTable(settingsPath, settings.settings)
end

settings.getSettings()
return settings
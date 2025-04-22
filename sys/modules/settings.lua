local module = {}
require("/sys/lua_extensions")

function module.init(nodeos, native, termWidth, termHeight)
    local settingsPath = "etc/settings.cfg"

    -- Check if logging is available before using it
    local function log(level, message)
        if nodeos.logging then
            nodeos.logging[level]("Settings", message)
        end
    end

    log("info", "Settings module initialization started")

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
        log("debug", "Loading settings from " .. settingsPath)
        local s = loadTable(settingsPath)
        if not s then
            log("warn", "Settings file not found or invalid, creating default settings")
            settings.saveSettings(settings.settings)
            return settings.settings
        end
        log("debug", "Settings loaded successfully")
        settings.settings = s
        return settings.settings
    end

    function settings.saveSettings()
        log("debug", "Saving settings to " .. settingsPath)
        local success = saveTable(settingsPath, settings.settings)
        if success then
            log("info", "Settings saved successfully")
        else
            log("error", "Failed to save settings")
        end
    end

    settings.getSettings()
    nodeos.settings = settings
    log("info", "Settings module initialization completed")
end

return module

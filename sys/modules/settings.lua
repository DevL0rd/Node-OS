local module = {}
require("/sys/lua_extensions")

function module.init(nodeos, native, termWidth, termHeight)
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
        local s = loadTable(settingsPath)
        if not s then
            settings.saveSettings(settings.settings)
            return settings.settings
        end
        settings.settings = s
        return settings.settings
    end

    function settings.saveSettings()
        saveTable(settingsPath, settings.settings)
    end

    settings.getSettings()
    nodeos.settings = settings
end

return module

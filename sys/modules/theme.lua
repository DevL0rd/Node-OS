-- nodeos Theme Management
-- Handles theme loading and access

local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    -- Load theme
    nodeos.getTheme = function()
        local themePath = loadTable("/etc/theme.cfg").currentTheme
        nodeos.theme = loadTable(themePath)
        return nodeos.theme
    end

    -- Initialize theme
    nodeos.getTheme()
end

return module

local netstone_settings_path = "etc/netstone.cfg"
local util = require("/lib/util")
local file = util.loadModule("file")
local netstone = {}
netstone.settings = {
    actuationRange = 10,
    rangeunlock = false,
    rangelock = false,
    actuationSound = true,
    redstone = {
        ranged = false,
        side = "top",
        state = false,
        onInRange = "on",
        onLeaveRange = "off"
    }
}
netstone.inRangeClients = {}
function netstone.getSettings()
    local ns = file.readTable(netstone_settings_path)
    if not ns then
        netstone.saveSettings(netstone.settings)
        return netstone.settings
    end
    netstone.settings = ns
    return ns
end

function netstone.saveSettings(ns)
    file.writeTable(netstone_settings_path, ns)
end

function netstone.on()
    netstone.settings.redstone.state = true
    redstone.setOutput(netstone.settings.redstone.side, netstone.settings.redstone.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.off()
    netstone.settings.redstone.state = false
    redstone.setOutput(netstone.settings.redstone.side, netstone.settings.redstone.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.toggle()
    if netstone.settings.redstone.state then
        netstone.settings.redstone.state = false
    else
        netstone.settings.redstone.state = true
    end
    redstone.setOutput(netstone.settings.redstone.side, netstone.settings.redstone.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.pulse(secs)
    netstone.toggle()
    os.sleep(tonumber(secs))
    netstone.toggle()
end

return netstone
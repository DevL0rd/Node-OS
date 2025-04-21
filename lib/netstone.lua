local netstone_settings_path = "etc/netstone.cfg"
local netstone = {}
netstone.settings = {
    actuationRange = 10,
    rangeunlock = false,
    rangelock = false,
    actuationSound = true,
    enabled = false,
    side = "top",
    state = false,
    onInRange = "on",
    onLeaveRange = "off"
}
netstone.inRangeClients = {}
function netstone.getSettings()
    local ns = loadTable(netstone_settings_path)
    if not ns then
        netstone.saveSettings(netstone.settings)
        return netstone.settings
    end
    netstone.settings = ns
    return ns
end

function netstone.saveSettings(ns)
    saveTable(netstone_settings_path, ns)
end

function netstone.on()
    netstone.settings.state = true
    redstone.setOutput(netstone.settings.side, netstone.settings.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.off()
    netstone.settings.state = false
    redstone.setOutput(netstone.settings.side, netstone.settings.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.toggle()
    if netstone.settings.state then
        netstone.settings.state = false
    else
        netstone.settings.state = true
    end
    redstone.setOutput(netstone.settings.side, netstone.settings.state)
    netstone.saveSettings(netstone.settings)
end

function netstone.pulse(secs)
    netstone.toggle()
    os.sleep(tonumber(secs))
    netstone.toggle()
end

return netstone

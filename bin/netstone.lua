local termUtils = require("/lib/termUtils")
local gps = require("/lib/gps")
local netstone = require("/lib/netstone")
netstone.getSettings()
local args = { ... }
--usage
-- netstone [open | close | toggle | on | off | pulse <seconds>]
local usage = "netstone [open | close | toggle | on | off | pulse <seconds> | setin <on,off,toggle,pulse <seconds>> | setout <on,off,toggle,pulse <seconds>> | side [side] | rangesound | rangeunlock]"
if args[1] == "open" then
    netstone.on()
elseif args[1] == "close" then
    netstone.off()
elseif args[1] == "toggle" then
    netstone.toggle()
elseif args[1] == "on" then
    netstone.on()
elseif args[1] == "off" then
    netstone.off()
elseif args[1] == "pulse" then
    netstone.pulse(args[2])
elseif args[1] == "setin" then
    if args[2] == "on" or args[2] == "off" or args[2] == "toggle" or args[2] == "pulse" then
        if args[3] then
            netstone.settings.redstone.onInRange = args[2] .. " " .. args[3]
        else
            netstone.settings.redstone.onInRange = args[2]
        end
        netstone.inRangeClients = {}
        termUtils.print("In range action set to " .. netstone.settings.redstone.onInRange .. ".", "green")
        netstone.saveSettings(netstone.settings)
    else
        termUtils.print("Usage: setin <on,off,toggle,pulse <seconds>>", "red")
    end
elseif args[1] == "setout" then
    if args[2] == "on" or args[2] == "off" or args[2] == "toggle" or args[2] == "pulse" then
        if args[3] then
            netstone.settings.redstone.onLeaveRange = args[2] .. " " .. args[3]
        else
            netstone.settings.redstone.onLeaveRange = args[2]
        end
        netstone.inRangeClients = {}
        termUtils.print("Out of range action set to " .. netstone.settings.redstone.onLeaveRange .. ".", "green")
        netstone.saveSettings(netstone.settings)
    else
        termUtils.print("Usage: setout <on,off,toggle,pulse <seconds>>", "red")
    end
elseif args[1] == "side" then
    if args[2] == "top" or args[2] == "bottom" or args[2] == "back" or args[2] == "front" or
        args[2] == "left" or args[2] == "right" then
        netstone.settings.redstone.side = args[2]
        netstone.inRangeClients = {}
        termUtils.print("Redstone side set to " .. netstone.settings.redstone.side .. ".", "green")
        netstone.saveSettings(netstone.settings)
    else
        termUtils.print("Redstone side is '" .. netstone.settings.redstone.side .. "'.")
    end
elseif args[1] == "rangesound" then
    netstone.settings.redstone.rangeSound = not netstone.settings.redstone.rangeSound
    netstone.inRangeClients = {}
    termUtils.print("Range sound is " .. (netstone.settings.redstone.rangeSound and "on" or "off") .. ".", "green")
    netstone.saveSettings(netstone.settings)
elseif args[1] == "rangeunlock" then
    netstone.settings.redstone.rangeUnlock = not netstone.settings.redstone.rangeUnlock
    netstone.inRangeClients = {}
    termUtils.print("Range unlock is " .. (netstone.settings.redstone.rangeUnlock and "on" or "off") .. ".", "green")
    netstone.saveSettings(netstone.settings)
elseif args[1] == "ranged" then
    netstone.settings.redstone.ranged = not netstone.settings.redstone.ranged
    netstone.inRangeClients = {}
    termUtils.print("Range set to " .. (netstone.settings.redstone.ranged and "on" or "off") .. ".", "green")
    netstone.saveSettings(netstone.settings)
elseif args[1] == "range" then
    if args[2] then
        netstone.settings.actuationRange = tonumber(args[2])
        netstone.inRangeClients = {}
        termUtils.print("Range set to " .. netstone.settings.actuationRange .. ".", "green")
        netstone.saveSettings(netstone.settings)
    else
        termUtils.print("Range is " .. netstone.settings.actuationRange .. ".", "green")
    end
else
    termUtils.print(usage, "red")
end
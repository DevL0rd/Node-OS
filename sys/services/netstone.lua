local netstone = require("/lib/netstone")
local net = require("/lib/net")
local gps = require("/lib/gps")
require("/lib/misc")
local function scanInRange_thread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            netstone.getSettings()
            if netstone.settings.redstone.ranged then
                local pairedClients = net.getPairedClients()
                for id, isPaired in pairs(pairedClients) do
                    local localComputers = gps.getLocalComputers()
                    if localComputers[id] then
                        if localComputers[id].pos then
                            local dist = gps.getDistance(gpsPos, localComputers[id].pos)
                            if netstone.inRangeClients[id] then
                                if dist > netstone.settings.actuationRange then
                                    netstone.inRangeClients[id] = nil
                                    local clientsStillInRange = #netstone.inRangeClients > 0
                                    if not clientsStillInRange then
                                        -- if netstone.settings.rangelock and settings.password ~= "" then
                                        --     isLocked = true
                                        --     clear()
                                        --     newLine()
                                        -- end
                                        local params = getWords(netstone.settings.redstone.onLeaveRange)
                                        local command = table.remove(params, 1)
                                        if netstone.settings.redstone.onLeaveRange == "on" then
                                            netstone.on()
                                        elseif netstone.settings.redstone.onLeaveRange == "off" then
                                            netstone.off()
                                        elseif netstone.settings.redstone.onLeaveRange == "toggle" then
                                            netstone.toggle()
                                        elseif command == "pulse" then
                                            netstone.pulse(tonumber(params[1]))
                                        end
                                    end
                                end
                            else
                                if dist <= netstone.settings.actuationRange then
                                    local clientsStillInRange = #netstone.inRangeClients > 0
                                    netstone.inRangeClients[id] = true
                                    if not clientsStillInRange then
                                        -- if netstone.settings.rangeunlock and settings.password ~= "" then
                                        --     isLocked = false
                                        --     clear()
                                        --     newLine()
                                        -- end
                                        local params = getWords(netstone.settings.redstone.onInRange)
                                        local command = table.remove(params, 1)
                                        if netstone.settings.redstone.onInRange == "on" then
                                            netstone.on()
                                        elseif netstone.settings.redstone.onInRange == "off" then
                                            netstone.off()
                                        elseif netstone.settings.redstone.onInRange == "toggle" then
                                            netstone.toggle()
                                        elseif command == "pulse" then
                                            netstone.pulse(tonumber(params[1]))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        os.sleep(0.3)
    end
end

parallel.addOSThread(scanInRange_thread)

local settings = netstone.getSettings()
if settings.redstone.state then
    netstone.on()
else
    netstone.off()
end
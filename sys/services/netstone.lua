local netstone = require("/lib/netstone")
require("/lib/misc")
local function scanInRange_thread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            netstone.getSettings()
            if netstone.settings.enabled then
                local pairedClients = net.getPairedClients()
                for id, isPaired in pairs(pairedClients) do
                    local computer = gps.getComputer(id)
                    if computer then
                        if computer.pos then
                            local dist = gps.getDistance(gpsPos, computer.pos)
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
                                        local params = getWords(netstone.settings.onLeaveRange)
                                        local command = table.remove(params, 1)
                                        if netstone.settings.onLeaveRange == "on" then
                                            netstone.on()
                                        elseif netstone.settings.onLeaveRange == "off" then
                                            netstone.off()
                                        elseif netstone.settings.onLeaveRange == "toggle" then
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
                                        local params = getWords(netstone.settings.onInRange)
                                        local command = table.remove(params, 1)
                                        if netstone.settings.onInRange == "on" then
                                            netstone.on()
                                        elseif netstone.settings.onInRange == "off" then
                                            netstone.off()
                                        elseif netstone.settings.onInRange == "toggle" then
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

pm.createProcess(scanInRange_thread, { isService = true, title = "scanInRange_thread" })

function listen_netStoneCommand()
    while true do
        local cid, msg = rednet.receive("NodeOS_netstoneCommand")
        if net.isClientPaired(cid) then
            local data = msg.data
            if data.command == "open" then
                netstone.on()
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Open."
                })
            elseif data.command == "close" then
                netstone.off()
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Closed."
                })
            elseif data.command == "toggle" then
                netstone.toggle()
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Toggled."
                })
            elseif data.command == "on" then
                netstone.on()
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": On."
                })
            elseif data.command == "off" then
                netstone.off()
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Off."
                })
            elseif data.command == "pulse" then
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() ..
                        "@" .. os.getComputerID() .. ": Pulsed for " .. data.params[1] .. " seconds."
                })
                netstone.pulse(data.params[1])
            elseif data.command == "setin" then
                if data.params[1] == "on" or data.params[1] == "off" or data.params[1] == "toggle" or
                    data.params[1] == "pulse" then
                    if data.params[1] == "pulse" and data.params[2] then
                        netstone.settings.onInRange = data.params[1] .. " " .. data.params[2]
                    else
                        netstone.settings.onInRange = data.params[1]
                    end
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" ..
                            os.getComputerID() ..
                            ": In range action set to " .. netstone.settings.onInRange .. "."
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid in range action."
                    })
                end
            elseif data.command == "setout" then
                if data.params[1] == "on" or data.params[1] == "off" or data.params[1] == "toggle" or
                    data.params[1] == "pulse" then
                    if data.params[1] == "pulse" and data.params[2] then
                        netstone.settings.onLeaveRange = data.params[1] .. " " .. data.params[2]
                    else
                        netstone.settings.onLeaveRange = data.params[1]
                    end
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" ..
                            os.getComputerID() ..
                            ": Out of range action set to " .. netstone.settings.onLeaveRange .. "."
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid out of range action."
                    })
                end
            elseif data.command == "setrange" then
                if data.params[1] then
                    netstone.settings.actuationRange = tonumber(data.params[1])
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. ": Range set to " .. netstone.settings.actuationRange .. "."
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid range."
                    })
                end
            elseif data.command == "setside" then
                if data.params[1] then
                    netstone.settings.side = data.params[1]
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. ": Side set to " .. netstone.settings.side .. "."
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid side."
                    })
                end
            elseif data.command == "enable" then
                netstone.settings.enabled = true
                netstone.saveSettings(netstone.settings)
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Enabled."
                })
            elseif data.command == "disable" then
                netstone.settings.enabled = false
                netstone.saveSettings(netstone.settings)
                net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Disabled."
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this device."
            })
        end
    end
end

pm.createProcess(listen_netStoneCommand, { isService = true, title = "listen_netStoneCommand" })

local settings = netstone.getSettings()
if settings.state then
    netstone.on()
else
    netstone.off()
end

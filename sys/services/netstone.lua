local netstone = require("/lib/netstone")

-- Add initialization log for NetStone service
nodeos.logging.info("NetStoneService", "Initializing NetStone service")

local function scanInRange_thread()
    nodeos.logging.debug("NetStoneService", "Starting proximity scan thread")
    while true do
        local gpsPos = nodeos.gps.getPosition()
        if gpsPos then
            netstone.getSettings()
            if netstone.settings.enabled then
                local pairedClients = nodeos.net.getPairedClients()
                for id, isPaired in pairs(pairedClients) do
                    local computer = nodeos.gps.getComputer(id)
                    if computer then
                        if computer.pos then
                            local dist = nodeos.gps.getDistance(gpsPos, computer.pos)
                            if netstone.inRangeClients[id] then
                                if dist > netstone.settings.actuationRange then
                                    nodeos.logging.debug("NetStoneService",
                                        "Computer #" .. id .. " left range (distance: " .. dist .. ")")
                                    netstone.inRangeClients[id] = nil
                                    local clientsStillInRange = #netstone.inRangeClients > 0
                                    if not clientsStillInRange then
                                        nodeos.logging.info("NetStoneService",
                                            "No computers in range, executing leave range action: " ..
                                            netstone.settings.onLeaveRange)
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
                                    nodeos.logging.debug("NetStoneService",
                                        "Computer #" .. id .. " entered range (distance: " .. dist .. ")")
                                    local clientsStillInRange = #netstone.inRangeClients > 0
                                    netstone.inRangeClients[id] = true
                                    if not clientsStillInRange then
                                        nodeos.logging.info("NetStoneService",
                                            "First computer in range, executing in range action: " ..
                                            netstone.settings.onInRange)
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
        else
            nodeos.logging.warn("NetStoneService", "No GPS position available for proximity scan")
        end
        os.sleep(0.3)
    end
end

nodeos.createProcess(scanInRange_thread, { isService = true, title = "scanInRange_thread" })

function listen_netStoneCommand()
    nodeos.logging.debug("NetStoneService", "Starting NetStone command listener")
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_netstoneCommand")

        -- Validate basic message structure
        if not msg or not msg.data then
            nodeos.logging.error("NetStoneService", "Received invalid NetStone command request from #" .. cid)
            nodeos.net.respond(cid, msg and msg.token, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        if not msg.data.command then
            nodeos.logging.error("NetStoneService", "Missing command parameter in NetStone request from #" .. cid)
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "Missing required parameter: command"
            })
            goto continue
        end

        -- Validate client pairing
        if not nodeos.net.isClientPaired(cid) then
            nodeos.logging.warn("NetStoneService", "Unpaired computer #" .. cid .. " attempted to send NetStone command")
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this device."
            })
            goto continue
        end

        local data = msg.data
        nodeos.logging.info("NetStoneService", "Received command '" .. data.command .. "' from computer #" .. cid)

        -- Simple commands that don't need parameter validation
        if data.command == "open" then
            netstone.on()
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Open."
            })
        elseif data.command == "close" then
            netstone.off()
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Closed."
            })
        elseif data.command == "toggle" then
            netstone.toggle()
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Toggled."
            })
        elseif data.command == "on" then
            netstone.on()
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": On."
            })
        elseif data.command == "off" then
            netstone.off()
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Off."
            })
        elseif data.command == "enable" then
            netstone.settings.enabled = true
            nodeos.logging.info("NetStoneService", "Service enabled")
            netstone.saveSettings(netstone.settings)
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Enabled."
            })
        elseif data.command == "disable" then
            netstone.settings.enabled = false
            nodeos.logging.info("NetStoneService", "Service disabled")
            netstone.saveSettings(netstone.settings)
            nodeos.net.respond(cid, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Disabled."
            })
            -- Commands requiring parameter validation
        elseif data.command == "pulse" then
            if not data.params or not data.params[1] then
                nodeos.logging.error("NetStoneService", "Missing pulse duration parameter from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameter: pulse duration"
                })
            else
                local duration = tonumber(data.params[1])
                if not duration or duration <= 0 then
                    nodeos.logging.error("NetStoneService",
                        "Invalid pulse duration from #" .. cid .. ": " .. data.params[1])
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Pulse duration must be a positive number"
                    })
                else
                    nodeos.logging.info("NetStoneService", "Pulsing for " .. duration .. " seconds")
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. ": Pulsed for " .. duration .. " seconds."
                    })
                    netstone.pulse(duration)
                end
            end
        elseif data.command == "setin" then
            if not data.params or not data.params[1] then
                nodeos.logging.error("NetStoneService", "Missing in-range action parameter from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameter: in-range action"
                })
            elseif data.params[1] == "on" or data.params[1] == "off" or data.params[1] == "toggle" or
                data.params[1] == "pulse" then
                if data.params[1] == "pulse" then
                    if not data.params[2] then
                        nodeos.logging.error("NetStoneService", "Missing pulse duration parameter from #" .. cid)
                        nodeos.net.respond(cid, msg.token, {
                            success = false,
                            message = "Pulse action requires a duration parameter"
                        })
                        goto continue
                    end

                    local duration = tonumber(data.params[2])
                    if not duration or duration <= 0 then
                        nodeos.logging.error("NetStoneService",
                            "Invalid pulse duration from #" .. cid .. ": " .. data.params[2])
                        nodeos.net.respond(cid, msg.token, {
                            success = false,
                            message = "Pulse duration must be a positive number"
                        })
                        goto continue
                    end

                    netstone.settings.onInRange = data.params[1] .. " " .. data.params[2]
                else
                    netstone.settings.onInRange = data.params[1]
                end

                nodeos.logging.info("NetStoneService", "In range action set to: " .. netstone.settings.onInRange)
                netstone.inRangeClients = {}

                netstone.saveSettings(netstone.settings)
                nodeos.net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() ..
                        "@" ..
                        os.getComputerID() ..
                        ": In range action set to " .. netstone.settings.onInRange .. "."
                })
            else
                nodeos.logging.warn("NetStoneService", "Invalid in range action: " .. data.params[1])
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid in range action."
                })
            end
        elseif data.command == "setout" then
            if not data.params or not data.params[1] then
                nodeos.logging.error("NetStoneService", "Missing out-of-range action parameter from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameter: out-of-range action"
                })
            elseif data.params[1] == "on" or data.params[1] == "off" or data.params[1] == "toggle" or
                data.params[1] == "pulse" then
                if data.params[1] == "pulse" then
                    if not data.params[2] then
                        nodeos.logging.error("NetStoneService", "Missing pulse duration parameter from #" .. cid)
                        nodeos.net.respond(cid, msg.token, {
                            success = false,
                            message = "Pulse action requires a duration parameter"
                        })
                        goto continue
                    end

                    local duration = tonumber(data.params[2])
                    if not duration or duration <= 0 then
                        nodeos.logging.error("NetStoneService",
                            "Invalid pulse duration from #" .. cid .. ": " .. data.params[2])
                        nodeos.net.respond(cid, msg.token, {
                            success = false,
                            message = "Pulse duration must be a positive number"
                        })
                        goto continue
                    end

                    netstone.settings.onLeaveRange = data.params[1] .. " " .. data.params[2]
                else
                    netstone.settings.onLeaveRange = data.params[1]
                end

                nodeos.logging.info("NetStoneService", "Out of range action set to: " .. netstone.settings.onLeaveRange)
                netstone.inRangeClients = {}

                netstone.saveSettings(netstone.settings)
                nodeos.net.respond(cid, msg.token, {
                    success = true,
                    message = os.getComputerLabel() ..
                        "@" .. os.getComputerID() ..
                        ": Out of range action set to " .. netstone.settings.onLeaveRange .. "."
                })
            else
                nodeos.logging.warn("NetStoneService", "Invalid out of range action: " .. data.params[1])
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = os.getComputerLabel() .. "@" .. os.getComputerID() .. ": Invalid out of range action."
                })
            end
        elseif data.command == "setrange" then
            if not data.params or not data.params[1] then
                nodeos.logging.error("NetStoneService", "Missing range parameter from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameter: range"
                })
            else
                local range = tonumber(data.params[1])
                if not range or range <= 0 then
                    nodeos.logging.error("NetStoneService",
                        "Invalid range parameter from #" .. cid .. ": " .. data.params[1])
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Range must be a positive number"
                    })
                else
                    netstone.settings.actuationRange = range
                    nodeos.logging.info("NetStoneService", "Actuation range set to: " .. netstone.settings
                        .actuationRange)
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. ": Range set to " .. netstone.settings.actuationRange .. "."
                    })
                end
            end
        elseif data.command == "setside" then
            if not data.params or not data.params[1] then
                nodeos.logging.error("NetStoneService", "Missing side parameter from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameter: side"
                })
            else
                local validSides = { top = true, bottom = true, left = true, right = true, front = true, back = true }
                if not validSides[data.params[1]] then
                    nodeos.logging.error("NetStoneService",
                        "Invalid side parameter from #" .. cid .. ": " .. data.params[1])
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Side must be one of: top, bottom, left, right, front, back"
                    })
                else
                    netstone.settings.side = data.params[1]
                    nodeos.logging.info("NetStoneService", "Side set to: " .. netstone.settings.side)
                    netstone.inRangeClients = {}

                    netstone.saveSettings(netstone.settings)
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. ": Side set to " .. netstone.settings.side .. "."
                    })
                end
            end
        else
            nodeos.logging.error("NetStoneService", "Unknown command from #" .. cid .. ": " .. data.command)
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "Unknown command: " .. data.command
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_netStoneCommand, { isService = true, title = "listen_netStoneCommand" })

local settings = netstone.getSettings()
if settings.state then
    nodeos.logging.info("NetStoneService", "Initial state set to ON")
    netstone.on()
else
    nodeos.logging.info("NetStoneService", "Initial state set to OFF")
    netstone.off()
end

nodeos.logging.info("NetStoneService", "NetStone service initialized")

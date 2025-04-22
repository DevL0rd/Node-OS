-- Add initialization log for Net service
nodeos.logging.info("NetService", "Initializing network service")

local negotiatingClients = {}
function listen_pair()
    nodeos.logging.debug("NetService", "Starting pair listener")
    while true do
        local cId, msg = nodeos.net.receive("NodeOS_pair")
        if not msg then
            nodeos.logging.error("NetService", "Received invalid pair request from #" .. cId)
            nodeos.net.respond(cId, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        if cId then
            if negotiatingClients[cId] then
                nodeos.logging.warn("NetService", "Rate limiting #" .. cId)
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Rate limited!"
                })
            else
                nodeos.logging.debug("NetService", "Pair req from #" .. cId)
                negotiatingClients[cId] = true
                local pin = msg.data

                if not pin or type(pin) ~= "string" then
                    nodeos.logging.error("NetService", "Missing or invalid pin from #" .. cId)
                    nodeos.net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin format"
                    })
                    negotiatingClients[cId] = nil
                    goto continue
                end

                sleep(math.random(1, 5))
                if pin == nodeos.settings.settings.pin then
                    nodeos.logging.info("NetService", "Computer #" .. cId .. " paired")
                    local pairedClients = nodeos.net.getPairedClients()
                    pairedClients[cId] = true
                    nodeos.net.savePairedClients(pairedClients)
                    nodeos.net.respond(cId, msg.token, {
                        success = true,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " paired successfully!"
                    })
                else
                    nodeos.logging.warn("NetService", "Invalid pin from #" .. cId)
                    nodeos.net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin!"
                    })
                end
                negotiatingClients[cId] = nil
            end
        end

        ::continue::
    end
end

nodeos.createProcess(listen_pair, { isService = true, title = "listen_pair" })

function listen_unpair()
    nodeos.logging.debug("NetService", "Starting unpair listener")
    while true do
        local cId, msg = nodeos.net.receive("NodeOS_unpair")
        if not msg then
            nodeos.logging.error("NetService", "Received invalid unpair request from #" .. cId)
            nodeos.net.respond(cId, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        nodeos.logging.info("NetService", "Unpaired #" .. cId)
        local pairedClients = nodeos.net.getPairedClients()
        pairedClients[cId] = nil
        nodeos.net.savePairedClients(pairedClients)
        nodeos.net.respond(cId, msg.token, {
            success = true,
            message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " unpaired successfully!"
        })

        ::continue::
    end
end

nodeos.createProcess(listen_unpair, { isService = true, title = "listen_unpair" })


function listen_ping()
    nodeos.logging.debug("NetService", "Starting ping listener")
    while true do
        local cId, msg = nodeos.net.receive("NodeOS_ping")
        if not msg then
            nodeos.logging.error("NetService", "Received invalid ping request from #" .. cId)
            goto continue
        end

        nodeos.net.respond(cId, msg.token, { success = true, message = "Pong!" })

        ::continue::
    end
end

nodeos.createProcess(listen_ping, { isService = true, title = "listen_ping" })


function net_status_mon()
    nodeos.logging.debug("NetService", "Starting network status monitor")
    if os.getComputerID() == nodeos.settings.settings.master then
        nodeos.net.isConnected = true
        return
    end
    while true do
        nodeos.net.ping(nodeos.settings.settings.master)
        sleep(2)
    end
end

nodeos.createProcess(net_status_mon, { isService = true, title = "net_status_mon" })

function listen_authenticate()
    nodeos.logging.debug("NetService", "Starting authentication listener")
    while true do
        local cId, msg = nodeos.net.receive("NodeOS_authenticate")
        if not msg then
            nodeos.logging.error("NetService", "Received invalid authentication request from #" .. cId)
            nodeos.net.respond(cId, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        if negotiatingClients[cId] then
            nodeos.logging.warn("NetService", "Rate limiting #" .. cId)
            nodeos.net.respond(cId, msg.token, {
                success = false,
                message = "Rate limited!"
            })
        else
            nodeos.logging.debug("NetService", "Auth req from #" .. cId)
            negotiatingClients[cId] = true

            local pin = msg.data
            if not pin or type(pin) ~= "string" then
                nodeos.logging.error("NetService", "Missing or invalid pin from #" .. cId)
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Invalid pin format"
                })
                negotiatingClients[cId] = nil
                goto continue
            end

            sleep(math.random(1, 5))
            if pin == nodeos.settings.settings.pin then
                nodeos.logging.info("NetService", "Authenticated #" .. cId)
                nodeos.net.respond(cId, msg.token, {
                    success = true,
                    message = os.getComputerLabel() ..
                        "@" .. os.getComputerID() .. " authenticated successfully!"
                })
            else
                nodeos.logging.warn("NetService", "Invalid pin from #" .. cId)
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Invalid pin!"
                })
            end
            negotiatingClients[cId] = nil
        end

        ::continue::
    end
end

nodeos.createProcess(listen_authenticate, { isService = true, title = "listen_authenticate" })

function listen_minecraftCommand()
    nodeos.logging.debug("NetService", "Starting Minecraft command listener")
    while true do
        local cId, msg = nodeos.net.receive("NodeOS_minecraftCommand")

        if not msg or not msg.data then
            nodeos.logging.error("NetService", "Received invalid Minecraft command request from #" .. cId)
            nodeos.net.respond(cId, msg and msg.token, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        if not msg.data.command then
            nodeos.logging.error("NetService", "Missing command parameter in Minecraft command request from #" .. cId)
            nodeos.net.respond(cId, msg.token, {
                success = false,
                message = "Missing required parameter: command"
            })
            goto continue
        end

        if not nodeos.net.isClientPaired(cId) then
            nodeos.logging.warn("NetService", "Unpaired #" .. cId .. " attempted command")
            nodeos.net.respond(cId, msg.token, {
                success = false,
                message = "Not paired!"
            })
        else
            local command = msg.data.command

            if type(command) ~= "string" or command == "" then
                nodeos.logging.error("NetService", "Invalid command from #" .. cId)
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Invalid command format"
                })
                goto continue
            end

            nodeos.logging.info("NetService", "Executing command from #" .. cId .. ": " .. command)
            local ok, result = commands.exec(command)
            if ok then
                nodeos.logging.debug("NetService", "Command success")
            else
                nodeos.logging.warn("NetService", "Command failed: " .. result[1])
            end
            nodeos.net.respond(cId, msg.token, {
                success = ok,
                message = result[1]
            })
        end

        ::continue::
    end
end

if os.getComputerID() == nodeos.settings.settings.master then
    nodeos.logging.info("NetService", "Starting Minecraft command listener (master only)")
    nodeos.createProcess(listen_minecraftCommand, { isService = true, title = "listen_minecraftCommand" })
end

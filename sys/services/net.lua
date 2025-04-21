local negotiatingClients = {}
function listen_pair()
    while true do
        local cId, msg = rednet.receive("NodeOS_pair")
        if cId then
            if negotiatingClients[cId] then
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Rate limited!"
                })
            else
                negotiatingClients[cId] = true
                local pin = msg.data
                sleep(math.random(1, 5))
                if pin == nodeos.settings.settings.pin then
                    local pairedClients = nodeos.net.getPairedClients()
                    pairedClients[cId] = true
                    nodeos.net.savePairedClients(pairedClients)
                    nodeos.net.respond(cId, msg.token, {
                        success = true,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " paired successfully!"
                    })
                else
                    nodeos.net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin!"
                    })
                end
                negotiatingClients[cId] = nil
            end
        end
    end
end

nodeos.createProcess(listen_pair, { isService = true, title = "listen_pair" })

function listen_unpair()
    while true do
        local cId, msg = rednet.receive("NodeOS_unpair")
        if cId then
            local pairedClients = nodeos.net.getPairedClients()
            pairedClients[cId] = nil
            nodeos.net.savePairedClients(pairedClients)
            nodeos.net.respond(cId, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " paired successfully!"
            })
        end
    end
end

nodeos.createProcess(listen_unpair, { isService = true, title = "listen_unpair" })


function listen_ping()
    while true do
        local cId, msg = rednet.receive("NodeOS_ping")
        nodeos.net.respond(cId, msg.token, { success = true, message = "Pong!" })
    end
end

nodeos.createProcess(listen_ping, { isService = true, title = "listen_ping" })


function net_status_mon()
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
    while true do
        local cId, msg = rednet.receive("NodeOS_authenticate")
        if cId then
            if negotiatingClients[cId] then
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Rate limited!"
                })
            else
                negotiatingClients[cId] = true
                local pin = msg.data
                sleep(math.random(1, 5))
                if pin == nodeos.settings.settings.pin then
                    nodeos.net.respond(cId, msg.token, {
                        success = true,
                        message = os.getComputerLabel() ..
                            "@" .. os.getComputerID() .. " authenticated successfully!"
                    })
                else
                    nodeos.net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin!"
                    })
                end
                negotiatingClients[cId] = nil
            end
        end
    end
end

nodeos.createProcess(listen_authenticate, { isService = true, title = "listen_authenticate" })

function listen_minecraftCommand()
    -- local ok, result = commands.exec(command)
    while true do
        local cId, msg = rednet.receive("NodeOS_minecraftCommand")
        if cId then
            if not nodeos.net.isClientPaired(cId) then
                nodeos.net.respond(cId, msg.token, {
                    success = false,
                    message = "Not paired!"
                })
            else
                local command = msg.data.command
                local ok, result = commands.exec(command)
                nodeos.net.respond(cId, msg.token, {
                    success = ok,
                    message = result[1]
                })
            end
        end
    end
end

if os.getComputerID() == nodeos.settings.settings.master then
    nodeos.createProcess(listen_minecraftCommand, { isService = true, title = "listen_minecraftCommand" })
end

local isConnected = false
local negotiatingClients = {}
function listen_pair()
    while true do
        local cId, msg = rednet.receive("NodeOS_pair")
        if cId then
            if negotiatingClients[cId] then
                net.respond(cId, msg.token, {
                    success = false,
                    message = "Rate limited!"
                })
            else
                negotiatingClients[cId] = true
                local pin = msg.data
                sleep(math.random(1, 5))
                if pin == sets.settings.pin then
                    local pairedClients = net.getPairedClients()
                    pairedClients[cId] = true
                    net.savePairedClients(pairedClients)
                    net.respond(cId, msg.token, {
                        success = true,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " paired successfully!"
                    })
                else
                    net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin!"
                    })
                end
                negotiatingClients[cId] = nil
            end
        end
    end
end

pm.createProcess(listen_pair, { isService = true, title = "listen_pair" })

function listen_unpair()
    while true do
        local cId, msg = rednet.receive("NodeOS_unpair")
        if cId then
            local pairedClients = net.getPairedClients()
            pairedClients[cId] = nil
            net.savePairedClients(pairedClients)
            net.respond(cId, msg.token, {
                success = true,
                message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " paired successfully!"
            })
        end
    end
end

pm.createProcess(listen_unpair, { isService = true, title = "listen_unpair" })


function listen_ping()
    while true do
        local cId, msg = rednet.receive("NodeOS_ping")
        net.respond(cId, msg.token, { success = true, message = "Pong!" })
    end
end

pm.createProcess(listen_ping, { isService = true, title = "listen_ping" })


function net_status_mon()
    if os.getComputerID() == sets.settings.master then
        net.isConnected = true
        return
    end
    while true do
        net.ping(sets.settings.master)
        sleep(2)
    end
end

pm.createProcess(net_status_mon, { isService = true, title = "net_status_mon" })

function listen_authenticate()
    while true do
        local cId, msg = rednet.receive("NodeOS_authenticate")
        if cId then
            if negotiatingClients[cId] then
                net.respond(cId, msg.token, {
                    success = false,
                    message = "Rate limited!"
                })
            else
                negotiatingClients[cId] = true
                local pin = msg.data
                sleep(math.random(1, 5))
                if pin == sets.settings.pin then
                    net.respond(cId, msg.token, {
                        success = true,
                        message = os.getComputerLabel() .. "@" .. os.getComputerID() .. " authenticated successfully!"
                    })
                else
                    net.respond(cId, msg.token, {
                        success = false,
                        message = "Invalid pin!"
                    })
                end
                negotiatingClients[cId] = nil
            end
        end
    end
end

pm.createProcess(listen_authenticate, { isService = true, title = "listen_authenticate" })

function listen_minecraftCommand()
    -- local ok, result = commands.exec(command)
    while true do
        local cId, msg = rednet.receive("NodeOS_minecraftCommand")
        if cId then
            if not net.isClientPaired(cId) then
                net.respond(cId, msg.token, {
                    success = false,
                    message = "Not paired!"
                })
            else
                local command = msg.data.command
                local ok, result = commands.exec(command)
                net.respond(cId, msg.token, {
                    success = ok,
                    message = result[1]
                })
            end
        end
    end
end

if os.getComputerID() == sets.settings.master then
    pm.createProcess(listen_minecraftCommand, { isService = true, title = "listen_minecraftCommand" })
end

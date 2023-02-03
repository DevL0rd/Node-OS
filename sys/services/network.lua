local net = require("/lib/net")
local settings = require("/lib/settings").settings


function listen_pair()
    while true do
        local cId, msg = rednet.receive("NodeOS_pair")
        if cId then
            local pin = msg.data
            if pin == settings.pin then
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
        end
    end
end

pm.createProcess(listen_pair, {isService=true, title="listen_pair"})

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

pm.createProcess(listen_unpair, {isService=true, title="listen_unpair"})


function listen_ping()
    while true do
        local cId, msg = rednet.receive("NodeOS_ping")
        net.respond(cId, msg.token, { success = true, message = "Pong!" })
    end
end

pm.createProcess(listen_ping, {isService=true, title="listen_ping"})
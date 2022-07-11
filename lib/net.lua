local util = require("/lib/util")
local file = util.loadModule("file")
local net = {}
local net_settings = {
    responseTimeout = 10
}
local pairedClientsPath = "etc/net/pairedClients.dat"
local pairedDevicesPath = "etc/net/pairedDevices.dat"
function net.getPairedClients()
    local clients = file.readTable(pairedClientsPath)
    if not clients then
        return {}
    end
    return clients
end

function net.getPairedDevices()
    local devices = file.readTable(pairedDevicesPath)
    if not devices then
        return {}
    end
    return devices
end

function net.savePairedClients(clients)
    file.writeTable(pairedClientsPath, clients)
end

function net.savePairedDevices(clients)
    file.writeTable(pairedDevicesPath, clients)
end

function net.emit(command, data, cId, IgnoreResponse)
    if not cId then
        rednet.broadcast({ data = data }, command)
        return
    end
    local token = math.random(1, 999999999)
    rednet.send(cId, { token = token, data = data }, command)
    if not IgnoreResponse then
        local r_cId, msg = rednet.receive("NodeOS_Response_" .. token, net_settings.responseTimeout)
        if r_cId ~= cId then
            return
        end
        return msg
    end
end

function net.respond(cid, token, data)
    rednet.send(cid, data, "NodeOS_Response_" .. token)
end

function net.unpair(cId)
    local res = net.emit("unpair", nil, cId)
    if res and res.success then
        local pairedDevices = net.getPairedDevices()
        pairedDevices[cId] = nil
        file.writeTable(pairedDevicesPath, pairedDevices)
    else
        return nil
    end
end

function net.pair(cId, pin)
    local res = net.emit("pair", pin, cId)
    if res and res.success then
        local pairedDevices = net.getPairedDevices()
        pairedDevices[cId] = pin
        file.writeTable(pairedDevicesPath, pairedDevices)
    else
        return nil
    end
end

function net.ping(cId, pin)
    local res = net.emit("NodeOS_ping", pin, cId)
    if res and res.success then
        return true
    else
        return false
    end
end

return net
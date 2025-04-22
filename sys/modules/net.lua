local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("Net", "Initializing network module")

    local net = {}
    net.isConnected = false
    local net_settings = {
        responseTimeout = 10
    }
    local pairedClientsPath = "etc/net/pairedClients.dat"
    local pairedDevicesPath = "etc/net/pairedDevices.dat"
    local clients = loadTable(pairedClientsPath)
    if not clients then
        nodeos.logging.debug("Net", "No paired clients found, creating empty list")
        clients = {}
    else
        nodeos.logging.debug("Net", "Loaded " .. #clients .. " paired clients")
    end

    function net.getPairedClients()
        return clients
    end

    local pairedDevices = loadTable(pairedDevicesPath)
    if not pairedDevices then
        nodeos.logging.debug("Net", "No paired devices found, creating empty list")
        pairedDevices = {}
    else
        nodeos.logging.debug("Net", "Loaded " .. #pairedDevices .. " paired devices")
    end

    function net.getPairedDevices()
        return pairedDevices
    end

    function net.savePairedClients(clients)
        nodeos.logging.debug("Net", "Saving " .. #clients .. " paired clients")
        saveTable(pairedClientsPath, clients)
    end

    function net.savePairedDevices(devices)
        nodeos.logging.debug("Net", "Saving " .. #devices .. " paired devices")
        saveTable(pairedDevicesPath, devices)
    end

    function net.receive(command, timeout)
        local r_cId, msg = rednet.receive(command, timeout)
        return r_cId, msg
    end

    function net.emit(command, data, cId, IgnoreResponse)
        local token = math.random(1, 999999999)
        if cId == nil or cId == false then
            rednet.broadcast({ data = data }, command)
            return
        end

        rednet.send(cId, { token = token, data = data }, command)

        if not IgnoreResponse then
            local r_cId, msg = rednet.receive("NodeOS_Response_" .. token, net_settings.responseTimeout)

            if r_cId ~= cId then
                nodeos.logging.warn("Net", "Received response from incorrect computer ID: " .. (r_cId or "timeout"))
                return
            end
            return msg
        end
    end

    function net.respond(cid, token, data)
        if not token then
            return
        end
        rednet.send(cid, data, "NodeOS_Response_" .. token)
    end

    function net.isClientPaired(cid)
        local clients = net.getPairedClients()
        if clients[cid] then
            return true
        end
        return false
    end

    function net.isDevicePaired(cid)
        local devices = net.getPairedDevices()
        if devices[cid] then
            return true
        end
        return false
    end

    function net.unpair(cId)
        nodeos.logging.info("Net", "Attempting to unpair from device " .. cId)
        local res = net.emit("unpair", nil, cId)
        if res and res.success then
            nodeos.logging.info("Net", "Successfully unpaired from device " .. cId)
            local pairedDevices = net.getPairedDevices()
            pairedDevices[cId] = nil
            saveTable(pairedDevicesPath, pairedDevices)
            return true
        else
            nodeos.logging.warn("Net", "Failed to unpair from device " .. cId)
            return nil
        end
    end

    function net.pair(cId, pin)
        nodeos.logging.info("Net", "Attempting to pair with device " .. cId)
        local res = net.emit("pair", pin, cId)
        if res and res.success then
            nodeos.logging.info("Net", "Successfully paired with device " .. cId)
            local pairedDevices = net.getPairedDevices()
            pairedDevices[cId] = pin
            saveTable(pairedDevicesPath, pairedDevices)
            return true
        else
            nodeos.logging.warn("Net", "Failed to pair with device " .. cId)
            return nil
        end
    end

    function net.ping(cId)
        local res = net.emit("NodeOS_ping", nil, cId)
        if res then
            net.isConnected = true
            return true
        else
            return false
        end
    end

    nodeos.net = net
    nodeos.logging.info("Net", "Network module initialization complete")
end

return module

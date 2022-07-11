local net = require("/lib/net")
local gps = require("/lib/gps")
local args = { ... }

--usage net pair <id> <pin>
--usage net unpair <id>
--usage net list
if args[1] == "pair" then
    if not args[2] or not args[3] then
        print("usage: pairing pair <id> <pin>")
        return
    end
    local cId = gps.getComputerID(args[2])
    if not cId then
        cId = tonumber(args[2])
    end
    local pin = args[3]
    local res = net.emit("NodeOS_pair", pin, cId)
    if res and res.success then
        print("Paired!")
        local pairedDevices = net.getPairedDevices()
        pairedDevices[cId] = true
        net.savePairedDevices(pairedDevices)
    else
        print("Failed to pair!")
    end
elseif args[1] == "unpair" then
    if not args[2] then
        print("usage: pairing unpair <id>")
        return
    end
    local cId = gps.getComputerID(args[2])
    if not cId then
        cId = tonumber(args[2])
    end
    local res = net.emit("NodeOS_unpair", nil, cId)
    if res and res.success then
        print("Unpaired!")
        local pairedDevices = net.getPairedDevices()
        pairedDevices[cId] = nil
        net.savePairedDevices(pairedDevices)
    else
        print("Failed to pair!")
    end
elseif args[1] == "list" then
    print("Devices: ")
    for cId, _ in pairs(net.getPairedDevices()) do
        local name = gps.getComputerName(cId)
        print("  " .. name .. "@" .. cId)
    end
    print("Clients: ")
    for cId, _ in pairs(net.getPairedClients()) do
        local name = gps.getComputerName(cId)
        print("  " .. name .. "@" .. cId)
    end
else
    print("usage: pairing <pair|unpair|list>")
end
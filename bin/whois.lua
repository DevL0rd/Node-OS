local args = { ... }

-- usage whois [range]
-- details Shows known computers.
nodeos.graphics.print("Computer List:", "purple")
local range = nil
if args[1] and isInt(tonumber(args[1])) then
    range = tonumber(args[1])
end

local localComputers = nodeos.gps.getLocalComputers()
for id, details in pairs(localComputers) do
    local dist = "?"
    local gpsPos = nodeos.gps.getPosition()
    if gpsPos and localComputers[id].pos then
        dist = math.floor(nodeos.gps.getDistance(gpsPos, localComputers[id].pos))
    end
    local pairdDevices = nodeos.net.getPairedDevices()
    if dist ~= "?" and range then
        if dist <= range then
            if (nodeos.net.ping(id)) then
                if pairdDevices[id] then
                    nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                else
                    nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                end
            else
                nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
            end
        end
    else
        if (nodeos.net.ping(id)) then
            if pairdDevices[id] then
                nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
            else
                nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
            end
        else
            nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
        end
    end
end

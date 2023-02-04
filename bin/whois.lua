local termUtils = require("/lib/termUtils")
local args = { ... }

-- usage whois [range]
-- details Shows known computers.
termUtils.print("Computer List:", "purple")
local range = nil
if args[1] and isInt(tonumber(args[1])) then
    range = tonumber(args[1])
end

local localComputers = gps.getLocalComputers()
for id, details in pairs(localComputers) do
    local dist = "?"
    local gpsPos = gps.getPosition()
    if gpsPos and localComputers[id].pos then
        dist = math.floor(gps.getDistance(gpsPos, localComputers[id].pos))
    end
    local pairdDevices = net.getPairedDevices()
    if dist ~= "?" and range then
        if dist <= range then
            if (net.ping(id)) then
                if pairdDevices[id] then
                    termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                else
                    termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                end
            else
                termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
            end
        end
    else
        if (net.ping(id)) then
            if pairdDevices[id] then
                termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
            else
                termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
            end
        else
            termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
        end
    end
end
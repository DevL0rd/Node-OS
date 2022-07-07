coms.whois = {
    usage = "whois [range]",
    details = "Shows known computers.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        local range = nil
        if params[1] and isInt(tonumber(params[1])) then
            range = tonumber(params[1])
        end
        nPrint("Computer List:", "purple")
        local offsetY = 9
        local tx,ty = term.getSize()
        local maxLines = ty - offsetY
        local scanHeight = 0
        for id, details in pairs(localComputers) do
            local dist = "?"
            local gpsPos = getPosition()
            if gpsPos and localComputers[id].pos then
                dist = math.floor(getDistance(gpsPos, localComputers[id].pos))
            end
            if dist ~= "?" and range then
                if dist <= range then
                    if (ping(id)) then
                        if pairedPCs[id] then
                            nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "green")
                        else
                            nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "orange")
                        end
                    else
                        nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "red")
                    end
                    scanHeight = scanHeight + 1
                    if scanHeight == maxLines then
                        nPrint("Enter for next page..")
                        read("")
                        scanHeight = 0
                    end
                    nPrint("       " .. details.message, "lightGray")
                    scanHeight = scanHeight + 1
                    if scanHeight == maxLines then
                        nPrint("Enter for next page..")
                        read("")
                        scanHeight = 0
                    end
                end
            else
                if (ping(id)) then
                    if pairedPCs[id] then
                        nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "green")
                    else
                        nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "orange")
                    end
                else
                    nPrint("   " .. details.name .. "(" .. id .. ") Dist: " .. dist, "red")
                end
                    scanHeight = scanHeight + 1
                    if scanHeight == maxLines then
                        nPrint("Enter for next page..")
                        read("")
                        scanHeight = 0
                    end
                nPrint("       " .. details.message, "lightGray")
                scanHeight = scanHeight + 1
                if scanHeight == maxLines then
                    nPrint("Enter for next page..")
                    read("")
                    scanHeight = 0
                end
            end
        end
    end
}
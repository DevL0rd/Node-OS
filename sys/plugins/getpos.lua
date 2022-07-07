coms.getpos = {
    usage = "getpos",
    details = "Shows the current position.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        local gpsPos = getPosition()
        if gpsPos then
            if senderID then
                rednet.send(senderID, {data = "X:" .. math.floor(gpsPos.x) .. " Y:" .. math.floor(gpsPos.y) .. " Z:" .. math.floor(gpsPos.z), responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("X:" .. math.floor(gpsPos.x) .. " Y:" .. math.floor(gpsPos.y) .. " Z:" .. math.floor(gpsPos.z))
        else
            if senderID then
                rednet.send(senderID, {data = "No GPS signal found!", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("No GPS signal found!", "red")
        end
    end
}
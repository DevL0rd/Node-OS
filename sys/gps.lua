gps_settings_path = "config/gps.dat" 
gps_settings = {
    pollRate = 0.001,
    offset = {
        x = 0,
        y = 0,
        z = 0
    }
}
if fs.exists(gps_settings_path) then
    gps_settings = load(gps_settings_path)
else
    save(gps_settings, gps_settings_path)
end




function getClosestPC()
    local gpsPos = getPosition()
    if gpsPos then
        local closestDist = nil
        local closestID = nil
        for id, details in pairs(localComputers) do
            if details.pos then
                local dist = getDistance(details.pos, gpsPos)
                if closestDist == nil or dist < closestDist then
                    closestDist = dist
                    closestID = id
                end
            end
        end
        return closestID
    end
    return nil
end
function emitComputerDetails(gpsPos)
    local cDetails = {
        id = os.getComputerID(),
        pos = gpsPos,
        name = settings.name,
        OU = settings.OU,
        message = settings.message,
        time = os.time()
    }
    broadcastNet("giveDetails", cDetails)
end
local failedgpscount = 0
local oldPos = nil
local lastPoll = 0
function getPosition()
    local gpsPos = nil
    timeDiff = os.time() - lastPoll
    if timeDiff < 0 then
        timeDiff = 0
    end
    if timeDiff >= gps_settings.pollRate then
        -- print(os.time())
        lastPoll = os.time() + gps_settings.pollRate
        local px, py, pz = gps.locate(5)
        if px and (not isNan(px)) then 
            px = px + gps_settings.offset.x
            py = py + gps_settings.offset.y
            pz = pz + gps_settings.offset.z
            oldPos = {x = px, y = py, z = pz}
            return oldPos
        else
            failedgpscount = failedgpscount + 1
            if failedgpscount > 5 then
                failedgpscount = 0
                oldPos = nil
            end
            return oldPos
        end
    else
        return oldPos
    end
end
function getDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt ( dx * dx + dy * dy + dz * dz)
end
coms.setoffset = {
    usage = "setoffset",
    details = "Set the offset of remote computer to your position.",
    isLocal = false,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        local px, py, pz = gps.locate(2)
        if localComputers[senderID] and px then
            if localComputers[senderID].pos then
                gps_settings.offset.x = localComputers[senderID].pos.x - px
                gps_settings.offset.y = localComputers[senderID].pos.y - py
                gps_settings.offset.z = localComputers[senderID].pos.z - pz
                inRangeClients = {}
                save(gps_settings, gps_settings_path)
            rednet.send(senderID, {data = "Offset set.", responseToken = responseToken}, "NodeOSCommandResponse")
            else
            rednet.send(senderID, {data = "Failed to set offset. Please check GPS and try again." , responseToken = responseToken}, "NodeOSCommandResponse")
            end
        else
            rednet.send(senderID, {data = "Failed to set offset. Please check GPS and try again." , responseToken = responseToken}, "NodeOSCommandResponse")
        end
    end
}

netcoms.giveDetails = {
    exec = function (senderID, responseToken, data)
        localComputers[senderID] = data
    end
}

gps_threads = {}
function gps_thread()
    while true do
        local gpsPos = getPosition()
        if gpsPos then
            emitComputerDetails(gpsPos)
            for k, v in pairs(gps_threads) do
                v(gpsPos)
            end
        end
        os.sleep(0.5)
    end
end
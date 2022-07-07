local netStack = {}
NetResponseStack = {
    NodeOSNetResponse = {},
    NodeOSCommandResponse = {}
}
netInUse = false
net_settings_path = "config/net.dat" 
net_settings = {
    retrys = 50, --TODO make this timeouttime, not retrys.
    pollRate = 0.1
}
if fs.exists(net_settings_path) then
    net_settings = load(net_settings_path)
else
    save(net_settings, net_settings_path)
end

pairedClientsPath = "config/net_pairedClients.dat" 
pairedClients = {}
pairedPCsPath = "config/net_pairedPCs.dat" 
pairedPCs = {}
localComputersPath = "config/net_localComputers.dat" 
localComputers = {}

if not fs.exists(pairedClientsPath) then
    pairedClients = {}
    save(pairedClients, pairedClientsPath)
else
    pairedClients = load(pairedClientsPath)
end
if not fs.exists(pairedPCsPath) then
    pairedPCs = {}
    save(pairedPCs, pairedPCsPath)
else
    pairedPCs = load(pairedPCsPath)
end
if not fs.exists(localComputersPath) then
    localComputers = {}
    save(localComputers, localComputersPath)
else
    localComputers = load(localComputersPath)
end
if not fs.exists("share") then
    fs.makeDir("share")
end
function pair(cId, pin)
    nPrint("Sending pair request...")
    local res = sendNet(cId, "pair", pin)
    if res then
        if res == "success" then
            nPrint("Successfully Paired!", "lime")
            pairedPCs[cId] = pin
            save(pairedPCs, pairedPCsPath)
        elseif res == "fail" then
            nPrint("Incorrect pin.", "red")
        end
    else
        nPrint("No response received.", "red")
    end
end

function unpair(cId)
    nPrint("Sending unpair command...")
    local res = sendNet(cId, "unpair", nil)
    if res then
        if res == "success" then
            nPrint("Successfully unpaired!", "lime")
            pairedPCs[cId] = nil
            save(pairedPCs, pairedPCsPath)
        end
    else
        nPrint("No response received.", "red")
    end
end

function trimLocalComputers()
    for id, details in pairs(localComputers) do
        if details.time then
            local timeElapsed = os.time() - details.time -- WHAT KIND OF TIME IS THIS!?!?
            if timeElapsed > 15 then
                localComputers[id] = nil --remove computer from list if it hasn't sent updates recently
            end
        else
            localComputers[id] = nil
        end
    end
    save(localComputers, localComputersPath)
end
table.insert(update_threads, trimLocalComputers)
function ping(cId)
    return sendNet(cId, "ping", "ping")
end

function resolveComputer(cString)
    local cID = nil
    if localComputers[tonumber(cString)] then
        cID = tonumber(cString)
    elseif localComputers[getComputerID(cString)] then
        cID = getComputerID(cString)
    elseif cString == "!" then
        local closestID = getClosestPC()
        if closestID then
            cID = closestID
        end
    end
    return cID
end

function sendCommand(cId, command, data, IgnoreResponse)
    local token = math.random(100000000,999999999)
    rednet.send(cId, {command=command, pin=pairedPCs[cId], responseToken = token, data=data}, "NodeOs-Command")
    if not IgnoreResponse then
        local loopTimes = net_settings.retrys
        while true do
            if NetResponseStack["NodeOSCommandResponse"][token] then
                local res = deepcopy(NetResponseStack["NodeOSCommandResponse"][token])
                NetResponseStack["NodeOSCommandResponse"][token] = nil
                return res
            end
            loopTimes = loopTimes - 1
            if loopTimes == 0 then
                return nil
            end
            sleep(net_settings.pollRate)
        end
    end
end

function sendNet(cId, command, data, IgnoreResponse)
    local token = math.random(100000000,999999999)
    rednet.send(cId, {command=command, pin=pairedPCs[cId], responseToken = token, data=data}, "NodeOs-Net")
    if not IgnoreResponse then
        local loopTimes = net_settings.retrys
        while true do
            if NetResponseStack["NodeOSNetResponse"][token] then
                local res = deepcopy(NetResponseStack["NodeOSNetResponse"][token])
                NetResponseStack["NodeOSNetResponse"][token] = nil
                return res
            end
            loopTimes = loopTimes - 1
            if loopTimes == 0 then
                nPrint("Network timeout!", "red")
                return nil
            end
            sleep(net_settings.pollRate)
        end
    end
end

function fetchFile(cId, filePath, fileTo, silent)
    local res = sendNet(cId, "fetch", filePath)
    if res and res.data then
        if res.fileFound then
            local file = fs.open(fileTo,"w")
            file.write(res.data)
            file.close()
            if not silent then
                nPrint("File '" .. fileTo .. "' received!", "green")
            end
            return res.data
        else
            if not silent then
                nPrint("File not found!", "red")
            end
            return false
        end
    else    
        if not silent then
            nPrint("No response received.", "red")
        end
        return false
    end
end
function sendFile(cid, filePath, silent)
    if not pairedPCs[cId] then
        nPrint("This PC is not paired!", "red")
        return
    end
    local file = fs.open(filePath,"r")
    local data = file.readAll()
    file.close()
    local res = sendNet(cid, "send", {filePath=filePath, data=data})
    if res then
        if res.fileSent then
            if not silent then
                nPrint("File '" .. filePath .. "' sent!", "green")
            end
            return true
        else
            if not silent then
                nPrint("File not sent!", "red")
            end
            return false
        end
    else
        if not silent then
            nPrint("No response received.", "red")
        end
        return false
    end
end
function broadcastNet(command, data)
    rednet.broadcast({command=command, data=data}, "NodeOs-Net")
end

function getComputerID(name)
    for id, details in pairs(localComputers) do
        if name == details.name then
            return id
        end
    end
end

function getComputerName(id)
    if localComputers[id] then
        return localComputers[id].name
    end
end

function getComputerDetails(id)
    if localComputers[id] then
        return localComputers[id]
    end
end

function netRx_thread()
    while true do
        if devicesConnected["modem"] then
            sid, data, protocol = rednet.receive()
            table.insert(netStack, {senderID = sid, data = data, protocol = protocol})
        else
            os.sleep(5)
        end
    end
end

function netExec_thread()
    while true do
        if netStack[1] then
            netInUse = true
            if not shellRunning then
                if not term_settings.currentRdSession then
                    drawStatusBar()
                end
            end
        end
        for key, rec in pairs(netStack) do
            if rec.senderID ~= os.getComputerID() then
                    local cName = "Unknown"
                    if localComputers[rec.senderID] and localComputers[rec.senderID].name then
                        cName = localComputers[rec.senderID].name
                    end
                if rec.protocol == "NodeOs-Net" then
                    if netcoms[rec.data.command] then
                        netcoms[rec.data.command].exec(rec.senderID, rec.data.responseToken, rec.data.data)
                    else
                        rednet.send(rec.senderID, {data = false, responseToken = rec.data.responseToken}, "NodeOSNetResponse")
                    end
                    if rec.data.command ~= "giveDetails" then
                    end
                elseif rec.protocol == "NodeOs-Command" then
                    if rec.data.pin == settings.pairPin then
                        if coms[rec.data.command] and coms[rec.data.command].isRemote then
                            coms[rec.data.command].exec(rec.data.data, rec.data.responseToken, rec.senderID)
                        else
                            rednet.send(rec.senderID, {data = "Invalid command!", responseToken = rec.data.responseToken}, "NodeOSCommandResponse")
                        end
                    else
                        rednet.send(rec.senderID, {data = "Incorrect pin!", responseToken = rec.data.responseToken}, "NodeOSCommandResponse")
                    end
                else
                    if NetResponseStack[rec.protocol] and rec.data.data ~= nil then
                        NetResponseStack[rec.protocol][rec.data.responseToken] = rec.data.data
                    else
                        nPrint("Invalid protocol '" .. rec.protocol .. "' received from computer '" .. rec.senderID .. "'!", "red")
                    end
                end
            end
            netStack[key] = nil
        end
        os.sleep(net_settings.pollRate)
        netInUse = false
    end
end
coms.pair = {
    usage = "pair <pin> [computer]",
    details = "Pairs to the closest computer by default, otherwise you can specify.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        local pin = "0000"
        if params[1] then
            pin = params[1]
        end
            if params[2] then
                local cId = nil
                if localComputers[tonumber(params[2])] then
                    cId = tonumber(params[2])
                else
                    cId = getComputerID(params[2])
                end
                if cId then
                    if pairedPCs[cId] then
                        nPrint("This PC is already paired!", "red")
                    else
                        pair(cId, pin)
                    end
                else
                    nPrint("Could not connect to PC.", "red")
                end
            else
                local closestID = getClosestPC()
                if closestID then
                    if pairedPCs[closestID] then
                        nPrint("This PC is already paired!", "red")
                    else
                        pair(closestID, pin)
                    end
                else
                    nPrint("PC not in range!", "red")
                end
            end
    end
}
coms.pairlist = {
    usage = "pairlist",
    details = "Lists all paired computers.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        nPrint("Paired List:", "purple")
        local offsetY = 9
        local tx,ty = term.getSize()
        local maxLines = ty - offsetY
        local scanHeight = 0
        for id, pin in pairs(pairedPCs) do
            local dist = "?"
            local gpsPos = getPosition()
            if gpsPos and localComputers[id] and localComputers[id].pos then
                dist = math.floor(getDistance(gpsPos, localComputers[id].pos))
            end
            if getComputerName(id) then
                if (ping(id)) then
                    nPrint("   " .. getComputerName(id) .. "(" .. id .. ") Dist: " .. dist, "green")
                else
                    nPrint("   " .. getComputerName(id) .. "(" .. id .. ") Dist: " .. dist, "red")
                end
                scanHeight = scanHeight + 1
                if scanHeight == maxLines then
                    nPrint("Enter for next page..")
                    read("")
                    scanHeight = 0
                end
                    nPrint("       " .. localComputers[id].message, "lightGray")
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
coms.unpair = {
    usage = "unpair [computer]",
    details = "unpairs the closest computer by default, otherwise you can specify.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
            if params[1] then
                local cId = nil
                if localComputers[tonumber(params[2])] then
                    cId = tonumber(params[2])
                else
                    cId = getComputerID(params[1])
                end
                if cId then
                    if pairedPCs[cId] then
                        unpair(cId)
                    else
                        nPrint("This PC is not paired!", "red")
                    end
                else
                    nPrint("Could not connect to PC.", "red")
                end
            else
                local closestID = getClosestPC()
                if closestID then
                    unpair(closestID)
                else
                    nPrint("No PC in range.", "red")
                end
            end
    end
}

netcoms = {
    pair = {
        exec = function (senderID, responseToken, pin)
            if settings.pairPin == pin then
                rednet.send(senderID, {data = "success", responseToken = responseToken}, "NodeOSNetResponse")
                pairedClients[senderID] = true
                save(pairedClients, pairedClientsPath)
            else
                rednet.send(senderID, {data = "fail", responseToken = responseToken}, "NodeOSNetResponse")
            end
        end
    },
    unpair = {
        exec = function (senderID, responseToken, pin)
                rednet.send(senderID, {data = "success", responseToken = responseToken}, "NodeOSNetResponse")
            pairedClients[senderID] = nil
            save(pairedClients, pairedClientsPath)
        end
    },
    ping = {
        exec = function (senderID, responseToken, data)
                rednet.send(senderID, {data = "pong", responseToken = responseToken}, "NodeOSNetResponse")
        end
    },
    msg = {
        exec = function (senderID, responseToken, data)
            rednet.send(senderID, {data = true, responseToken = responseToken}, "NodeOSNetResponse")
            nPrint(data.name .. ">> " .. data.msg, "blue")
            if devicesConnected["speaker"] and speaker_settings.actuationSound then
                peripherals[devicesConnected["speaker"]].peripheral.playNote("guitar", speaker_settings.volume, 1)
                sleep(0.2)
                peripherals[devicesConnected["speaker"]].peripheral.playNote("guitar", speaker_settings.volume, 9)
            end
        end
    },
    fetch = {
        exec = function (senderID, responseToken, filePath)
                local name = "Unknown"
                if getComputerName(senderID) then
                    name = getComputerName(senderID)
                else
                    name = senderID
                end
            filePath = "share/" .. filePath
            if fs.exists(filePath) then
                local file = fs.open(filePath,"r")
                local data = file.readAll()
                file.close()
                rednet.send(senderID, {data = {fileFound = true, filePath = filePath, data = data}, responseToken = responseToken}, "NodeOSNetResponse")
                nPrint(name .. "[FETCH]>> File '" .. filePath .. "' received!", "blue")
            else
                rednet.send(senderID, {data = {fileFound = false}, responseToken = responseToken}, "NodeOSNetResponse")
                nPrint(name .. "[FETCH]>> File '" .. filePath .. "' not found!", "purple")
            end          
        end
    },
    send = {
        exec = function (senderID, responseToken, data)
            local name = "Unknown"
            if getComputerName(senderID) then
                name = getComputerName(senderID)
            else
                name = senderID
            end
            if data.filePath then
                local file = fs.open(data.filePath,"w")
                file.write(data.data)
                file.close()
                rednet.send(senderID, {data = {fileSent = true, filePath = data.filePath}, responseToken = responseToken}, "NodeOSNetResponse")
                nPrint(name .. "[SEND]>> File '" .. data.filePath .. "' sent!", "blue")
            else
                rednet.send(senderID, {data = {fileSent = false}, responseToken = responseToken}, "NodeOSNetResponse")
                nPrint(name .. "[SEND]>> File not sent!", "purple")
            end
        end
    },
    fsExists = {
        exec = function (senderID, responseToken, path)
            rednet.send(senderID, {data = fs.exists(path), responseToken = responseToken}, "NodeOSNetResponse")
        end
    }
}
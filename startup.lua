----------
--CCEmuX--
if ccemux then
    ccemux.attach("left", "wireless_modem", {
    -- The range of this modem
    range = 64,

    -- Whether this is an ender modem
    interdimensional = false,

    -- The current world's name. Sending messages between worlds requires an interdimensional modem
    world = "main",

    -- The position of this wireless modem within the world
    posX = 0, posY = 0, posZ = 0,
    })
end

--------------
--INITIALIZE--
term.setCursorPos(1,1)
term.clear()
monSide = nil
monitor = nil
inRangeClients = {}
--Install to PC if inserted into disk drive.
if fs.exists("disk/startup.lua") then
    if fs.exists("startup.lua") then
        term.setTextColor(colors.red)
        print("NodeOS cannot be installed on this system. A Startup file already exists!")
        term.setTextColor(colors.lightGray)
        print("Press enter to reboot.")
        read("")
        peripheral.find( "drive", function( _, drive ) drive.ejectDisk( ) end )
        os.reboot()
    else
        fs.copy("disk/startup.lua", "startup.lua")
        term.setTextColor(colors.green)
        print("NodeOS succesfully installed from disk!")
        os.sleep(2)
        peripheral.find( "drive", function( _, drive ) drive.ejectDisk( ) end )
        os.reboot()
    end
end

---------------
--File System--

function save(table, filePath)
    local file = fs.open(filePath,"w")
    serializedTable = nil
    function serializeTable()
        serializedTable = textutils.serialize(table)
    end
    if pcall(serializeTable) then
        file.write(serializedTable)
    else
        -- print("Failure")
    end
    file.close()
end
function load(filePath)
    local file = fs.open(filePath,"r")
    local data = file.readAll()
    file.close()
    loadedTable = textutils.unserialize(data)
    if not loadedTable then
        loadedTable = {}
    end
    return loadedTable
end
settingsFolder = "settings"
settingsPath = settingsFolder .. "/settings.dat" 
if not fs.exists(settingsFolder) then
    fs.makeDir(settingsFolder)
end

--Load system settings
settings = {}
if not fs.exists(settingsPath) then
    settings = {
        isSetup = false,
        name = "UnNamed-PC",
        message = "This PC has not been setup yet.",
        password = "",
        OU = "",
        pairPin = "0000",
        NodeOSMasterID = 0,
        startupProgram = "",
        startupScripts = {},
        console = {
            fg = "lightGray",
            bg = "black",
            seperatorfg = "lightGray",
            seperatorbg = "black",
            header = {
                bg = "gray",
                fg = "blue"
            },
            statusBar = {
                bg = "blue",
                fg = "white"
            }
        },
        gps = {
            pollRate = 0.2,
            offset = {
                x = 0,
                y = 0,
                z = 0
            },
            actuationRange = 10,
            rangeunlock = false,
            rangelock = false
        },
        network = {
            retrys = 10,
            pollRate = 0.1
        },
        peripherals = {
            pollRate = 1
        },
        redstone = {
            ranged = false,
            side = "top",
            state = false,
            onInRange = "on",
            onLeaveRange = "off"
        },
        audio = {
            volume = 1,
            actuationSound = true
        }
    }
else
    settings = load(settingsPath)
end
--Generate system file structure
startupPath = settingsFolder .. "/startup.dat" 
startup = {}
if not fs.exists(startupPath) then
    save(startup, startupPath)
else
    startup = load(startupPath)
end
eventsPath = settingsFolder .. "/events.dat" 
events = {}
if not fs.exists(eventsPath) then
    save(events, eventsPath)
else
    events = load(eventsPath)
end
if not fs.exists("FileShare") then
    fs.makeDir("FileShare")
end
ver = 0
if fs.exists("settings/ver.txt") then
    local file = fs.open("settings/ver.txt","r")
    ver = file.readAll()
    file.close()
end







-----------------
--MISC Function--
local isLocked = true
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
function getWords(str)
    local words = {}
    for word in str:gmatch("%S+") do table.insert(words, word) end
    return words
end
function listToString(list)
    local str = nil
    for i, word in pairs(list) do 
        if str then
            str = str .. " " .. word
        else
            str = word
        end
    end
    return str
end
function isInt(n)
    return (type(n) == "number") and (math.floor(n) == n)
end
function isNan(n)
    return (tostring(n) == "nan")
end
function getCharOfLength(char, len)
    local nStr = ""
    while(len > 0) do
        nStr = nStr .. char
        len = len - 1
    end
    return nStr
end
function redstoneOn()
    settings.redstone.state = true
    redstone.setOutput(settings.redstone.side, settings.redstone.state)
    save(settings, settingsPath)
end
function redstoneOff()
    settings.redstone.state = false
    redstone.setOutput(settings.redstone.side, settings.redstone.state)
    save(settings, settingsPath)
end
function redstoneToggle()
    if settings.redstone.state then
        settings.redstone.state = false
    else
        settings.redstone.state = true
    end
    redstone.setOutput(settings.redstone.side, settings.redstone.state)
    save(settings, settingsPath)
end
function redstonePulse(secs)
    redstoneToggle()
    os.sleep(tonumber(secs))
    redstoneToggle()
end


---------------
--PERIPHERALS--
peripherals = {}
devicesConnected = {}
driverData = {}
drivers = {}
function scanPeripherals()
    local lstSides = {"left","right","top","bottom","front","back"};
    for i, side in pairs(lstSides) do
        if (peripheral.isPresent(side)) then
            --Perihperal found
            local type = peripheral.getType(side)
            if peripherals[side] then
                --Peripheral side exists
            else
                --New perihperal
                if drivers[type] then
                    if devicesConnected[type] == nil then
                        devicesConnected[type] = side
                    end
                    devicesConnected[type] = side
                    peripherals[side] = {type = type, peripheral = peripheral.wrap(side)};
                    drivers[type].init(side)
                    nPrint("Device '" .. type .. "' connected!", "green")
                else
                    nPrint("No driver found for device '" .. type .. "'!")
                end
                
            end
        else
            --Peripheral not found
            if peripherals[side] then
                local type = peripherals[side].type
                --But is registered
                if drivers[type] then
                    drivers[type].unInit(side)
                end
                peripherals[side] = nil
                devicesConnected[type] = nil
                nPrint("Device '" .. type .. "' disconnected.")
            end
        end
    end
end


--**NET**--
local localComputersPath = settingsFolder .. "/localComputers.dat" 
localComputers = {}
if not fs.exists(localComputersPath) then
    localComputers = {}
    save(localComputers, localComputersPath)
else
    localComputers = load(localComputersPath)
end
local pairedPCsPath = settingsFolder .. "/pairedPCs.dat" 
pairedPCs = {}
if not fs.exists(pairedPCsPath) then
    pairedPCs = {}
    save(pairedPCs, pairedPCsPath)
else
    pairedPCs = load(pairedPCsPath)
end
local pairedClientsPath = settingsFolder .. "/pairedClients.dat" 
pairedClients = {}
if not fs.exists(pairedClientsPath) then
    pairedClients = {}
    save(pairedClients, pairedClientsPath)
else
    pairedClients = load(pairedClientsPath)
end
netInUse = false
NetResponseStack = {
    NodeOSNetResponse = {},
    NodeOSCommandResponse = {}
}
function sendCommand(cId, command, data, IgnoreResponse)
    local token = math.random(100000000,999999999)
    rednet.send(cId, {command=command, pin=pairedPCs[cId], responseToken = token, data=data}, "NodeOs-Command")
    if not IgnoreResponse then
        local loopTimes = settings.network.retrys
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
            sleep(settings.network.pollRate)
        end
    end
end
function sendNet(cId, command, data, IgnoreResponse)
    local token = math.random(100000000,999999999)
    rednet.send(cId, {command=command, pin=pairedPCs[cId], responseToken = token, data=data}, "NodeOs-Net")
    if not IgnoreResponse then
        local loopTimes = settings.network.retrys
        while true do
            if NetResponseStack["NodeOSNetResponse"][token] then
                local res = deepcopy(NetResponseStack["NodeOSNetResponse"][token])
                NetResponseStack["NodeOSNetResponse"][token] = nil
                return res
            end
            loopTimes = loopTimes - 1
            if loopTimes == 0 then
                return nil
            end
            sleep(settings.network.pollRate)
        end
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
function ping(cId)
    return sendNet(cId, "ping", "ping")
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
function emitComputerDetails()
    local gpsPos = getPosition()
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
function trimLocalComputers()
    for id, details in pairs(localComputers) do
        if details.time then
            local timeElapsed = os.time() - details.time -- WHAT KIND OF TIME IS THIS!?!?
            if timeElapsed > 0.2 then
                localComputers[id] = nil --remove computer from list if it hasn't sent updates recently
            end
        else
            localComputers[id] = nil
        end
    end
end
function scanInRange()
    local gpsPos = getPosition()
        if gpsPos and settings.redstone.ranged then
            for id, isPaired in pairs(pairedClients) do
                if localComputers[id] then
                    if localComputers[id].pos then
                        local dist = getDistance(gpsPos, localComputers[id].pos)
                        if inRangeClients[id] then
                            if dist > settings.gps.actuationRange then
                                inRangeClients[id] = nil
                                if not next(inRangeClients) then
                                    if settings.gps.rangelock and settings.password ~= "" then
                                        isLocked = true
                                        clear()
                                        newLine()
                                    end
                                    if devicesConnected["speaker"] and settings.audio.actuationSound then
                                        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 9)
                                        os.sleep(0.2)
                                        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 1)
                                    end
                                    --table.insert(events, {name = localComputers[id].name, id = id, event = "leave", time = os.time()})
                                    --save(events, eventsPath)
                                    local params = getWords(settings.redstone.onLeaveRange)
                                    local command = table.remove(params, 1)
                                    if settings.redstone.onLeaveRange == "on" then
                                        redstoneOn()
                                    elseif settings.redstone.onLeaveRange == "off" then
                                        redstoneOff()
                                    elseif settings.redstone.onLeaveRange == "toggle" then
                                        redstoneToggle()
                                    elseif command == "pulse" then
                                        redstonePulse(tonumber(params[1]))
                                    end
                                end
                            end
                        else
                            if dist <= settings.gps.actuationRange then
                                local clientInRange = (next(inRangeClients))
                                inRangeClients[id] = true
                                if not clientInRange then
                                    if settings.gps.rangeunlock and settings.password ~= "" then
                                        isLocked = false
                                        clear()
                                        newLine()
                                    end
                                    if devicesConnected["speaker"] and settings.audio.actuationSound then
                                        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 1)
                                        os.sleep(0.2)
                                        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 9)
                                    end
                                    --table.insert(events, {name = localComputers[id].name, id = id, event = "enter", time = os.time()})
                                    --save(events, eventsPath)
                                    local params = getWords(settings.redstone.onInRange)
                                    local command = table.remove(params, 1)
                                    if settings.redstone.onInRange == "on" then
                                        redstoneOn()
                                    elseif settings.redstone.onInRange == "off" then
                                        redstoneOff()
                                    elseif settings.redstone.onInRange == "toggle" then
                                        redstoneToggle()
                                    elseif command == "pulse" then
                                        redstoneToggle(tonumber(params[1]))
                                    end
                                end
                            end
                        end
                    end
                end
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
-------
--GPS--
locations = {}
navigatingToBlock = false
navto = nil
navtoid = nil
navname = ""
locationsPath = settingsFolder .. "/locations.dat"
if not fs.exists(locationsPath) then
    save(locations, locationsPath)
else
    locations = load(locationsPath)
end
worldTilesPath = settingsFolder .. "/worldTiles.dat"
worldTiles = {}
if settings.NodeOSMasterID == os.getComputerID() then
    if not fs.exists(worldTilesPath) then
        worldTiles = {}
        save(worldTiles, worldTilesPath)
    else
        worldTiles = load(worldTilesPath)
    end
end
function getWorldTiles()
    local res = sendNet(settings.NodeOSMasterID, "getWorldTiles")
    if res then
        worldTiles = res
    end
end
function getPosition()
    local px, py, pz = gps.locate(5)
    if px and (not isNan(px)) then 
        px = px + settings.gps.offset.x
        py = py + settings.gps.offset.y
        pz = pz + settings.gps.offset.z
        return {x = px, y = py, z = pz}
    else
        return nil
    end
end
function getDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt ( dx * dx + dy * dy + dz * dz)
end
function update() 
    newLine()        
    nPrint("Updating...", "gray")
    fetchFile(settings.NodeOSMasterID, "NodeOS/startup.lua", "startup.lua", true)
    newLine()
    nPrint("Update complete!", "green")
    os.sleep(1)
    --table.insert(events, {name = settings.name, id = os.getComputerID(), event = "Update To Ver: " .. nVer, time = os.time()})
    --save(events, eventsPath)
    os.reboot()
end
function checkForUpdate()
    local nVer = fetchFile(settings.NodeOSMasterID, "NodeOS/ver.txt", "settings/ver.txt", true)
    if nVer then
        if nVer ~= ver then
            return true
        else
            return false
        end
    end
end


------------
--GRAPHICS--
waitingForInput = false
shellRunning = false
function clear()
    
    if settings.rdID then
        sendNet(settings.rdID, "rdclear", "", true)
    end
    term.clear()
    term.setCursorPos(1,7)
    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,7)
    end
    if not settings.currentRdSession then
        drawStatusBar()
        drawHeader()
    end
end
function setCursorPos(x, y)
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    if not x then
        x = cx
    end
    if not y then
        y = cy
    end
    if settings.rdID then
        sendNet(settings.rdID, "rdsetCursorPos", {x = x, y = y}, true)
    end
    term.setCursorPos(x, y)
    if monitor then
        monitor.setCursorPos(x, y)
    end
end
function newLine()
    if settings.rdID then
        sendNet(settings.rdID, "rdnewLine", "", true)
    end
    print("")
end
function nPrint(text, fgColor, bgColor)
    local offsetY = 7
    local mx = nil
    local my = nil
    local mcx = nil
    local mcy = nil
    if monitor then
        mx,my = monitor.getSize()
        mcx,mcy = monitor.getCursorPos() --Make these all local
    end
    local tx,ty = term.getSize()
    local cx, cy = term.getCursorPos()
    if cy < offsetY then
        term.setCursorPos(cx, offsetY)
    end
    if monitor then
        if mcy < offsetY then
            monitor.setCursorPos(mcx, offsetY)
        end
    end
    cx, cy = term.getCursorPos()
    fillLine(" ", cy, fgColor, bgColor)
    nWrite(text, cx, cy, fgColor, bgColor)
    newLine()
    if waitingForInput then
    cx, cy = term.getCursorPos()
        if isLocked then
            nWrite("Password", 1, cy, "red")
            nWrite(">>", 9, cy, "lightGray")
            setCursorPos(12, cy)
        else
            nWrite("@"..settings.name, 1, cy, "lightGray")
            nWrite(" /" ..shell.dir(), settings.name:len() + 2, cy, "purple")
            nWrite(">>", shell.dir():len() + settings.name:len() + 4, cy, "lightGray")
            setCursorPos(shell.dir():len() + settings.name:len() + 7, cy)
        end
    end
    if not settings.currentRdSession then
        drawStatusBar()
        drawHeader()
    end
end
function nWrite(text, x, y, fgColor, bgColor, align)
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    local mx = nil
    local my = nil
    local mcx = nil
    local mcy = nil
    if monitor then
        mx,my = monitor.getSize()
        mcx,mcy = monitor.getCursorPos() --Make these all local
    end
    if not x then
        x = cx
    end
    if not y then
        y = cy
    end
    if not fgColor or not colors[fgColor] then
        fgColor = settings.console.fg
    end
    if not bgColor or not colors[bgColor] then
        bgColor = settings.console.bg
    end
    if settings.rdID then
        sendNet(settings.rdID, "rdnWrite", {text = text, x = x, y = y, fgColor = fgColor, bgColor = bgColor, align = align}, true)
    end
    term.setCursorPos(x, y)
        if align == "center" then
            term.setCursorPos(math.ceil((tx / 2) - (text:len() / 2)) + 1, y)
        elseif align == "right" then
            term.setCursorPos(math.ceil(tx - text:len()) + 1, y)
        end
    term.setTextColor(colors[fgColor])
    term.setBackgroundColor(colors[bgColor])
    if align == "fill" then
        write(getCharOfLength(text, tx))
    else
        write(text)
    end
    if monitor then
        monitor.setCursorPos(x, y)
        if align == "center" then
            monitor.setCursorPos(math.ceil((mx / 2) - (text:len() / 2)), y)
        elseif align == "right" then
            monitor.setCursorPos(math.ceil(mx - text:len()) + 1, y)
        end
        monitor.setTextColor(colors[fgColor])
        monitor.setBackgroundColor(colors[bgColor])
        if align == "fill" then
            monitor.write(getCharOfLength(text, mx))
        else
            monitor.write(text)
        end
    end
    term.setTextColor(colors[settings.console.fg])
    term.setBackgroundColor(colors[settings.console.bg])
    term.setCursorPos(cx, cy)
    if monitor then
        monitor.setTextColor(colors[settings.console.fg])
        monitor.setBackgroundColor(colors[settings.console.bg])
        monitor.setCursorPos(mcx, mcy)
    end
end
function centerText(text, line, fgColor, bgColor)
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = settings.console.fg
    end
    if bgColor == nil then
        bgColor = settings.console.bg
    end
    nWrite(text, 1, line, fgColor, bgColor, "center")
end
function alignRight(text, line, fgColor, bgColor)
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = settings.console.fg
    end
    if bgColor == nil then
        bgColor = settings.console.bg
    end
    nWrite(text, 1, line, fgColor, bgColor, "right")
end
function fillLine(char, line, fgColor, bgColor)
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = settings.console.fg
    end
    if bgColor == nil then
        bgColor = settings.console.bg
    end
    nWrite(char, 1, line, fgColor, bgColor, "fill")
end
function fillLineWithBorder(bchar, line, fgColor, bgColor)
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = settings.console.fg
    end
    if bgColor == nil then
        bgColor = settings.console.bg
    end
    fillLine(" ", line, fgColor, bgColor)
    nWrite(bchar, 1, line, fgColor, bgColor)
    nWrite(bchar, 1, line, fgColor, bgColor, "right")
end
lastGpsPos = nil
compassString = ""
function drawStatusBar()
    fillLine(" ", 1, settings.console.statusBar.fg, settings.console.statusBar.bg)
    nWrite(settings.name .. "(" .. os.getComputerID() .. ")", 1, 1, settings.console.statusBar.fg, settings.console.statusBar.bg)
    local time = os.time()
    local formattedTime = textutils.formatTime(time, false)
    local offset = formattedTime:len() + 5
    local gpsColor = "black"
    local gpsHex = 0x000000ff
    if devicesConnected["modem"] then
        gpsColor = "red"
        gpsHex = 0xbb0000ff
    end
    local gpsPos = getPosition()
    if gpsPos then
        gpsColor = "lime"
        gpsHex = 0x00bb00ff
    end
    alignRight("GPS" .. getCharOfLength(" ", offset), 1, gpsColor, settings.console.statusBar.bg)
    offset = formattedTime:len() + 1
    local netColor = "black"
    local netHex = 0x000000ff
    if devicesConnected["modem"] then
        netColor = "lightGray"
        netHex = 0x333333ff
    end
    if netInUse then
        netColor = "lime"
        netHex = 0x00bb00ff
    end
    alignRight("NET" .. getCharOfLength(" ", offset), 1, netColor, settings.console.statusBar.bg)
    alignRight(formattedTime, 1, settings.console.statusBar.fg, settings.console.statusBar.bg)
    if (driverData.hud) then
        driverData.hud.time.setText(formattedTime)
        driverData.hud.gps.setColor(gpsHex)
        driverData.hud.net.setColor(netHex)
    end
    if gpsPos and driverData.hud then
        sX = math.floor(gpsPos.x)
        sY = math.floor(gpsPos.y)
        sZ = math.floor(gpsPos.z)
        if not lastGpsPos then 
            lastGpsPos = gpsPos
        end
        local ewString = ""
        if gpsPos.x - 0.1 > lastGpsPos.x then
            ewString = "E"
        elseif gpsPos.x + 0.1 < lastGpsPos.x then
            ewString = "W"
        end
        local nsString = ""
        if gpsPos.z - 0.1 > lastGpsPos.z then
            nsString = "S"
        elseif gpsPos.z + 0.1 < lastGpsPos.z then
            nsString = "N"
        end
        local nCompassString = nsString .. ewString
        if (nCompassString ~= "") then
            compassString = nCompassString
        end
        driverData.hud.title.setText(settings.name .. "(" .. os.getComputerID() .. ")   POS: " .. sX .. ", " .. sY .. ", " .. sZ .. "   Heading: " .. compassString)
        lastGpsPos = gpsPos
        local mobs = getMobs()
        local warnString = "Entities: "
        if mobs and next(mobs) then
            local mobCount = 0
            for _, mob in pairs(mobs) do
                mobCount = mobCount + 1
                local dist = math.floor(getDistance(gpsPos, mob))
                if mobCount == 5 then
                    warnString = warnString .. mob.name .. "(" .. dist .. ")"
                    break
                else
                    warnString = warnString .. mob.name .. "(" .. dist .. ")" .. " - "
                end
            end
        end
        driverData.hud.warning.setText(warnString)
        
    end
end
function drawHeader()
    if isLocked then
        fillLine("*", 2, "white", "red")
        fillLineWithBorder("*", 3, "white", "red")
        fillLineWithBorder("*", 4, "white", "red")
        centerText("LOCKED", 4, "white", "red")
        fillLineWithBorder("*", 5, "white", "red")
        fillLine("*", 6, "white", "red")
    else
        local closestID = getClosestPC()
        
        local gpsPos = getPosition()
        fillLine("*", 2, settings.console.header.fg, settings.console.header.bg)
        fillLineWithBorder("*", 3, settings.console.header.fg, settings.console.header.bg)
        fillLineWithBorder("*", 4, settings.console.header.fg, settings.console.header.bg)
        fillLineWithBorder("*", 5, settings.console.header.fg, settings.console.header.bg)
        fillLine("*", 6, settings.console.header.fg, settings.console.header.bg)
        if closestID then
            local tColor = "orange"
            if pairedPCs[closestID] then
                tColor = "green"
            end
            local dist = 0
            if gpsPos and closestID and localComputers[closestID] and localComputers[closestID].pos then
                dist = math.floor(getDistance(gpsPos, localComputers[closestID].pos))
                centerText(getComputerName(closestID) .. "(" .. closestID .. ") Dist:" .. dist, 3, tColor, settings.console.header.bg)
                local msg = (localComputers[closestID].message or "No System Message")
                centerText("'" .. msg .. "'", 4, "purple", settings.console.header.bg)
            end
        else
            centerText("No Nearby PC", 3, "red", settings.console.header.bg)
        end
        if (navto or navtoid) then
            if gpsPos then
                local ntZ = nil
                local ntX = nil
                local gpX = math.floor(gpsPos.x)
                local gpY = math.floor(gpsPos.y)
                local gpZ = math.floor(gpsPos.z)
                if navtoid and not (localComputers[navtoid] and localComputers[navtoid].pos) then
                    return
                end
                if navtoid then
                    dist = math.floor(getDistance(gpsPos, localComputers[navtoid].pos))
                    ntX = math.floor(localComputers[navtoid].pos.x)
                    ntY = math.floor(localComputers[navtoid].pos.y)
                    ntZ = math.floor(localComputers[navtoid].pos.z)
                else
                    dist = math.floor(getDistance(gpsPos, navto))
                    ntX = math.floor(navto.x)
                    ntY = math.floor(navto.y)
                    ntZ = math.floor(navto.z)
                end
                local headingStr = ""
                if ntZ < gpZ then
                    headingStr = headingStr .. "N"
                elseif ntZ > gpZ then
                    headingStr = headingStr .. "S"
                end
                if ntX < gpX then
                    headingStr = headingStr .. "W"
                elseif ntX > gpX then
                    headingStr = headingStr .. "E"
                end
                if headingStr == "" then
                    if ntY < gpY then
                        headingStr = "Down"
                    elseif ntY > gpY then
                        headingStr = "Up"
                    end
                    if headingStr == "" then
                        headingStr = "Here"
                    end
                end
                navText = "[" .. navname .. "] '" .. headingStr .. "' Dist:" .. dist
                centerText(navText, 5, "white", settings.console.header.bg)
                if driverData.hud then
                    driverData.hud.nav.setText(navText)
                end
            end
        elseif navname ~= "" then
            navText = "Searching for '" .. navname .. "'..."
            centerText(navText, 5, "white", settings.console.header.bg)
            if driverData.hud then
                driverData.hud.nav.setText(navText)
            end
        else
            centerText(" ", 5, "white", settings.console.header.bg)
            if driverData.hud then
                driverData.hud.nav.setText(" ")
            end
        end
    end
end
function getInput()
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    waitingForInput = true
    local inp
    if isLocked then
        if not settings.currentRdSession then
            nWrite("Password", 1, cy, "red")
            nWrite(">>", 9, cy, "lightGray")
            setCursorPos(12, cy)
        end
        inp = read("*")
    else
        if not settings.currentRdSession then
            nWrite("@"..settings.name, 1, cy, "lightGray")
            nWrite(" /" ..shell.dir(), settings.name:len() + 2, cy, "purple")
            nWrite(">>", shell.dir():len() + settings.name:len() + 4, cy, "lightGray")
            setCursorPos(shell.dir():len() + settings.name:len() + 7, cy)
        end
        inp = read()
    end
    if devicesConnected["speaker"] then
        peripherals[devicesConnected["speaker"]].peripheral.playNote("snare", settings.audio.volume, 1)
        peripherals[devicesConnected["speaker"]].peripheral.playNote("snare", settings.audio.volume, 9)
    end
    waitingForInput = false
    return inp
end
---------------------
--Command Functions--
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
function navsend(cId, name, pos)
    local res = sendNet(cId, "navsend", {name = name, pos = pos})
    if res then
        if res == "success" then
            nPrint("Successfully sent location!", "lime")
        end
    else
        nPrint("No response received.", "red")
    end
end

-----------------
--Main Commands--
commands = {}
commands = {
    help = {
        usage = "help <command>",
        details = "Shows this help page.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                params[1] = string.lower(params[1])
                if commands[params[1]] then
                    nPrint(commands[params[1]].usage, "purple")
                    nPrint("   " .. commands[params[1]].details, "lightGray")
                else
                    nPrint("Command not found!", "red")
                end
            else
                local offsetY = 9
                
                local tx,ty = term.getSize()
                local maxLines = ty - offsetY
                local scanHeight = 0
                for comName, details in pairs(commands) do
                    if details.isLocal then
                        nPrint(details.usage, "purple")
                        scanHeight = scanHeight + 1
                        if scanHeight == maxLines then
                            nPrint("Enter for next page..")
                            read("")
                            scanHeight = 0
                        end
                    end
                end
            end
        end
    },
    lock = {
        usage = "lock",
        details = "Locks the computer.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                rednet.send(senderID, {data = "Computer locked.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            clear()
            isLocked = true
            if devicesConnected["speaker"] then
                peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 9)
                os.sleep(0.1)
                peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 4)
                os.sleep(0.1)
                peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 1)
            end
        end
    },
    reboot = {
        usage = "reboot",
        details = "Reboots the computer.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                    rednet.send(senderID, {data = "Rebooting computer.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            os.reboot()
        end
    },
    setname = {
        usage = "setname <name>",
        details = "Sets the computer name.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if params[1] then
                settings.name = params[1]
                if senderID then
                    rednet.send(senderID, {data = "Name set to " .. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Name set to '" .. params[1] .. "'.", "green")
                save(settings, settingsPath)
            else
                nPrint("Usage: " .. "setname <name>", "green")
                if senderID then
                    rednet.send(senderID, {data = "Usage: setname <name>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
            end
        end
    },
    setmsg = {
        usage = "setmsg <msg>",
        details = "Sets the computer message.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if params[1] then
                settings.message = listToString(params)
                if senderID then
                    rednet.send(senderID, {data = "Message set to '" .. settings.message .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Message set to '" .. settings.message .. "'.", "green")
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Usage: setmsg <msg>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Usage: setmsg <msg>", "red")
            end
        end
    },
    setpass = {
        usage = "setpass <pass>",
        details = "Sets the computer password.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                settings.password = params[1]
            else
                settings.password = ""
            end
                if senderID then
                    rednet.send(senderID, {data = "Password set.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Password set.", "green")
                save(settings, settingsPath)
        end
    },
    setpin = {
        usage = "setpin <pin>",
        details = "Sets the computer pairing pin.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            local pin = "0000"
            if params[1] then
                pin = params[1]
            end
            settings.pairPin = pin
            if senderID then
                    rednet.send(senderID, {data = "PIN set.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("PIN set.", "green")
            save(settings, settingsPath)
        end
    },
    master = {
        usage = "master [ComputerID]",
        details = "Sets or logs the master update server's ID.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if isInt(tonumber(params[1])) then
                settings.NodeOSMasterID = tonumber(params[1])
                if senderID then
                    rednet.send(senderID, {data = "Master server set to ".. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Master server set to ".. params[1] .. ".", "green")
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Master server is '".. settings.NodeOSMasterID.. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Master server is '".. settings.NodeOSMasterID.. "'.", "lightGray")
            end
        end
    },
    getpos = {
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
    },
    whois = {
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
    },
    navlist = {
        usage = "navlist",
        details = "Lists all saved nav points.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            nPrint("Nav Points:", "purple")
            local offsetY = 9
            local tx,ty = term.getSize()
            local maxLines = ty - offsetY
            local scanHeight = 0
            for name, lPos in pairs(locations) do
                local dist = "?"
                local gpsPos = getPosition()
                if gpsPos then
                    dist = math.floor(getDistance(gpsPos, lPos))
                end
                nPrint("   " .. name .. " Dist: " .. dist, "green")
                scanHeight = scanHeight + 1
                    if scanHeight == maxLines then
                        nPrint("Enter for next page..")
                        read("")
                        scanHeight = 0
                    end
            end
        end
    },
    pairlist = {
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
    },
    fetch = {
        usage = "fetch <file> <to> [computer]",
        details = "Defaults to nearest computer unless specified.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                if params[2] then
                    if params[3] then
                        local cId = nil
                        if localComputers[params[3]] then
                            cId = tonumber(params[3])
                        else
                            cId = getComputerID(params[3])
                        end
                        if cId then
                            fetchFile(cId, params[1], params[2])
                        else
                            nPrint("Could not connect to PC.", "red")
                        end
                    else
                        local closestID = getClosestPC()
                        if closestID then
                            fetchFile(closestID, params[1], params[2])
                        else
                            nPrint("PC not in range!", "red")
                        end
                    end
                else
                    nPrint("Usage: fetch <file> <to> [computer]", "red")
                end
            else
                nPrint("Usage: fetch <file> <to> [computer]", "red")
            end
        end
    },
    msg = {
        usage = "msg <computer/id/!> <msg> ",
        details = "Send message to computer. Use ! to do closest.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] and params[2] then
                local cId = nil
                if localComputers[tonumber(params[1])] then
                    cId = tonumber(params[1])
                    table.remove(params, 1)
                elseif localComputers[getComputerID(params[1])] then
                    cId = getComputerID(params[1])
                    table.remove(params, 1)
                elseif params[1] == "!" then
                    cId = getClosestPC()
                end
                if cId then
                    local res = sendNet(cId, "msg", {name = settings.name, msg = listToString(params)})
                    if res then
                        nPrint("Message sent!", "green")
                    else
                        nPrint("No response received.", "red")
                    end
                else
                    nPrint("Could not find PC.", "red")
                end
            else
                nPrint("Usage: msg [computer] <msg>", "red")
            end
        end
    },
    pair = {
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
    },
    unpair = {
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
    },
    toggle = {
        usage = "toggle",
        details = "Toggles redstone output.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if settings.redstone.state then
                settings.redstone.state = false
                if senderID then
                    rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Redstone output set to off.", "green")
            else
                settings.redstone.state = true
                if senderID then
                    rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Redstone output set to on.", "green")
            end
            redstone.setOutput(settings.redstone.side, settings.redstone.state)
            save(settings, settingsPath)
        end
    },
    on = {
        usage = "on",
        details = "Turns on redstone output.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                    rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to on.", "green")
            settings.redstone.state = true
            redstone.setOutput(settings.redstone.side, settings.redstone.state)
            save(settings, settingsPath)
        end
    },
    off = {
        usage = "off",
        details = "Turns off redstone output.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                    rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to off.", "green")
            settings.redstone.state = false
            redstone.setOutput(settings.redstone.side, settings.redstone.state)
            save(settings, settingsPath)
        end
    },
    open = {
        usage = "open",
        details = "Turns on redstone output.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to on.", "green")
            settings.redstone.state = true
            redstone.setOutput(settings.redstone.side, settings.redstone.state)
            save(settings, settingsPath)
        end
    },
    close = {
        usage = "close",
        details = "Turns off redstone output.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if senderID then
                    rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to off.", "green")
            settings.redstone.state = false
            redstone.setOutput(settings.redstone.side, settings.redstone.state)
            save(settings, settingsPath)
        end
    },
    pulse = {
        usage = "pulse <seconds>",
        details = "Toggles the redstone output twice with a delay.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if isInt(tonumber(params[1])) then
                if senderID then
                    rednet.send(senderID, {data = "Pulsing for " .. params[1] .. " seconds.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Pulsing for " .. params[1] .. " seconds.", "green")
                local sleeptime = tonumber(params[1])
                if sleeptime <= 0 then
                    sleeptime = 2
                end
                if settings.redstone.state then
                    settings.redstone.state = false
                else
                    settings.redstone.state = true
                end
                redstone.setOutput(settings.redstone.side, settings.redstone.state)
                os.sleep(tonumber(params[1]))
                if settings.redstone.state then
                    settings.redstone.state = false
                else
                    settings.redstone.state = true
                end
                redstone.setOutput(settings.redstone.side, settings.redstone.state)
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Usage: pulse <seconds>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Usage: pulse <seconds>", "red")
            end    
        end
    },
    volume = {
        usage = "volume [vol]",
        details = "Sets or displays volume of computer.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if isInt(tonumber(params[1])) then
                if senderID then
                    rednet.send(senderID, {data = "Volume set to " ..  params[1]  .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Volume set to " ..  params[1]  .. ".", "green")
                settings.audio.volume = tonumber(params[1])
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Volume is " ..  params[1]  .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Volume is '" ..  settings.audio.volume  .. "'.", "lightGray")
            end
        end
    },
    side = {
        usage = "side [side]",
        details = "Sets or logs side that redstone is on.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if params[1] == "top" or params[1] == "bottom" or params[1] == "back" or params[1] == "front" or params[1] == "left" or params[1] == "right" then
                settings.redstone.side = params[1]
                inRangeClients = {}
                nPrint("Redstone side set to " .. params[1] .. ".", "green")
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Redstone side is '" ..  settings.redstone.side  .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Redstone side is '" ..  settings.redstone.side  .. "'.", "lightGray")
            end
        end
    },
    setin = {
        usage = "setin <on,off,toggle,pulse <seconds>>",
        details = "Sets what to do with redstone when paired computer is in range.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if params[1] == "on" or params[1] == "off" or params[1] == "toggle" or params[1] == "pulse" then
                if params[2] then
                    settings.redstone.onInRange = params[1] .. " " .. params[2]
                else
                    settings.redstone.onInRange = params[1]
                end
                inRangeClients = {}
                if senderID then
                    rednet.send(senderID, {data = "In range action set to " .. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("In range action set to " .. params[1] .. ".", "green")
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Usage: setin <on,off,toggle,pulse <seconds>>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Usage: setin <on,off,toggle,pulse <seconds>>", "red")
            end
        end
    },
    setout = {
        usage = "setout <on,off,toggle,pulse <seconds>>",
        details = "Sets what to do with redstone when paired computer is out of range.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if params[1] == "on" or params[1] == "off" or params[1] == "toggle" or params[1] == "pulse" then
                if params[2] then
                    settings.redstone.onLeaveRange = params[1] .. " " .. params[2]
                else
                    settings.redstone.onLeaveRange = params[1]
                end
                inRangeClients = {}
                if senderID then
                    rednet.send(senderID, {data = "Out of range action set to " .. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Out of range action set to " .. params[1] .. ".", "green")
                save(settings, settingsPath)
            else
                if senderID then
                    rednet.send(senderID, {data = "Usage: setout <on,off,toggle,pulse <seconds>>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Usage: setout <on,off,toggle,pulse <seconds>>", "red")
            end
        end
    },
    ver = {
        usage = "ver",
        details = "Check current version of NodeOS.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
                if senderID then
                    rednet.send(senderID, {data = "NodeOS version is " .. ver .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
            nPrint("NodeOS version is " .. ver .. ".", "green")
        end
    },
    installtodisk = {
        usage = "installtodisk",
        details = "Install NodeOS to device/disk in disk drive.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if fs.exists("disk") then
                if fs.exists("disk/startup.lua") then
                    nPrint("Cannot install to disk/device in disk drive. A autostart file already exists.", "red")
                else
                    fs.copy("startup.lua", "disk/startup.lua")
                    term.setTextColor(colors.green)
                    nPrint("NodeOS succesfully installed to disk!", "green")
                    peripheral.find( "drive", function( _, drive ) drive.ejectDisk( ) end )
                end
            else
                nPrint("There is no drive attached to this PC.", "red")
            end
        end
    },
    cls = {
        usage = "cls",
        details = "Clears the screen",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            clear()
        end
    },
    clear = {
        usage = "clear",
        details = "Clears the screen",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            clear()
        end
    },
    rangesound = {
        usage = "rangesound",
        details = "Toggles sound from playing when going in and out of range.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if settings.audio.actuationSound then
                settings.audio.actuationSound = false
                if senderID then
                    rednet.send(senderID, {data = "Actuation sound disabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Actuation sound disabled.", "green")
            else
                settings.audio.actuationSound = true
                if senderID then
                    rednet.send(senderID, {data = "Actuation sound enabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Actuation sound enabled.", "green")
            end
            save(settings, settingsPath)
        end
    },
    range = {
        usage = "range",
        details = "Toggles ranged activation of redstone.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            if isInt(tonumber(params[1])) and tonumber(params[1]) ~= 0 then
                settings.gps.actuationRange = tonumber(params[1])
                inRangeClients = {}
                if senderID then
                        rednet.send(senderID, {data = "Range set to " ..  params[1]  .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Range set to " ..  params[1]  .. ".", "green")
            else
                if settings.redstone.ranged then
                    settings.redstone.ranged = false
                    if senderID then
                        rednet.send(senderID, {data = "Remote ranged redstone disabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    nPrint("Remote ranged redstone disabled.", "green")
                else 
                    settings.redstone.ranged = true
                    if senderID then
                        rednet.send(senderID, {data = "Remote ranged redstone enabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    nPrint("Remote ranged redstone enabled.", "green")
                end
            end
            save(settings, settingsPath)
        end
    },
    navadd = {
        usage = "navadd <locationname>",
        details = "Save current location for later navigation",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                local gpsPos = getPosition()
                if gpsPos then
                    if not isInt(tonumber(params[1])) then
                        if not getComputerID(params[1]) then
                            locations[params[1]] = gpsPos
                            save(locations, locationsPath)
                            nPrint("Location '" .. params[1] .. "' saved.", "green")
                        else
                            nPrint("You cannot name this the same name as a PC name.", "red")
                        end
                    else
                        nPrint("You cannot use numbers for the location name. This is reserved for computer IDs.", "red")
                    end
                else
                    nPrint("No GPS signal available.", "red")
                end
            else
                nPrint("Usage: navadd <locationname>", "red")
            end
        end
    },
    navremove = {
        usage = "navremove <locationname>",
        details = "Remove location.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                if locations[params[1]] then
                    locations[params[1]] = nil
                    save(locations, locationsPath)
                    nPrint("Location '" .. params[1] .. "' removed.", "green")
                else
                    nPrint("Location does not exist.", "red")
                end
            else
                nPrint("Usage: navremove <locationname>", "red")
            end
        end
    },
    navto = {
        usage = "navto <locationname>",
        details = "Navigate to specified location or computer.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                local gpsPos = getPosition()
                if gpsPos then
                    navto = nil
                    navtoid = nil
                    navigatingToBlock = false
                    if localComputers[tonumber(params[1])] and localComputers[tonumber(params[1])].pos then
                        navtoid = tonumber(params[1])
                        navname = localComputers[navtoid].name
                        nPrint("Navigating to computer ID '" .. params[1] .. "'.", "green")
                    elseif localComputers[getComputerID(params[1])] then
                        navtoid = getComputerID(params[1])
                        navname = localComputers[navtoid].name
                        nPrint("Navigating to computer '" .. params[1] .. "'.", "green")
                    elseif locations[params[1]] then
                        navto = locations[params[1]]
                        navname = params[1]
                        nPrint("Navigating to '" .. params[1] .. "'.", "green")
                    else
                        nPrint("Location not found.", "white")
                    end
                else
                    nPrint("No GPS signal available.", "red")
                end
            else
                nPrint("Usage: navto <locationname>", "red")
            end
        end
    },
    find = {
        usage = "find <blockname>",
        details = "Watches for and navigates to a block.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                local gpsPos = getPosition()
                if gpsPos then
                    navto = nil
                    navtoid = nil
                    navigatingToBlock = true
                    getWorldTiles()
                    closestBlock = findClosestBlock(params[1])
                    navname = params[1]
                    navigatingToBlock = true
                    if closestBlock then
                        navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                        nPrint("Navigating to '" .. closestBlock.name .. "'.", "green")
                    else
                        nPrint("Block not found, trying to find '" .. navname .. "'", "white")
                    end
                else
                    nPrint("No GPS signal available.", "red")
                end
            else
                nPrint("Usage: find <blockname>", "red")
            end
        end
    },
    navsend = {
        usage = "navsend <locationname> [computer]",
        details = "Send nav point to nearest computer or specified computer.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                if params[2] then
                    local cId = nil
                    if locations[params[1]] then
                        if localComputers[tonumber(params[2])] then
                            cId = tonumber(params[2])
                        else
                            cId = getComputerID(params[2])
                        end
                        if cId then
                                navsend(cId, params[1], locations[params[1]])
                        else
                            nPrint("Could not find PC.", "red")
                        end
                    else
                        nPrint("This location does not exist.", "red")
                    end
                else
                    local closestID = getClosestPC()
                    if closestID then
                        if locations[params[1]] then
                            navsend(closestID, params[1], locations[params[1]])
                        else
                            nPrint("This location does not exist.", "red")
                        end
                    else
                        nPrint("PC not in range!", "red")
                    end
                end
            else
                nPrint("Usage: navsend <locationname> [computer]", "red")
            end
        end
    },
    rangeunlock = {
        usage = "rangeunlock",
        details = "Unlock in range",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if settings.gps.rangeunlock then
                settings.gps.rangeunlock = false
                nPrint("Remote ranged unlock disabled.", "green")
            else
                settings.gps.rangeunlock = true
                nPrint("Remote ranged unlock enabled.", "green")
            end
            save(settings, settingsPath)
        end
    },
    rangelock = {
        usage = "rangelock",
        details = "Lock out of range",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if settings.gps.rangelock then
                settings.gps.rangelock = false
                nPrint("Remote ranged lock disabled.", "green")
            else
                settings.gps.rangelock = true
                nPrint("Remote ranged lock enabled.", "green")
            end
            save(settings, settingsPath)
        end
    },
    events = {
        usage = "events [computer]",
        details = "Print all computer events.",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            nPrint("Events:", "purple")
                local cId = nil
                local res = nil
                local cLogs = nil
                if params[1] then
                    if params[1] == "!" then
                        cId = getClosestPC()
                    elseif localComputers[tonumber(params[1])] then
                        cId = tonumber(params[1])
                    else
                        cId = getComputerID(params[1])
                    end
                end
                if cId then
                    res = sendNet(cId, "events", nil)
                end
            if res ~= nil then
                cLogs = res
            else
                cLogs = events
            end
            if cLogs then
                local offsetY = 9
                local tx,ty = term.getSize()
                local maxLines = ty - offsetY
                local scanHeight = 0
                for i, event in pairs(cLogs) do
                    if os.getComputerID() == event.id then
                            nPrint(event.name .. "(" .. event.id .. ") Event: " .. event.event, "blue")
                    else
                        if pairedPCs[id] then
                            nPrint(event.name .. "(" .. event.id .. ") Event: " .. event.event, "green")
                        else
                            nPrint(event.name .. "(" .. event.id .. ") Event: " .. event.event, "orange")
                        end
                    end
                scanHeight = scanHeight + 1
                if scanHeight == maxLines then
                    nPrint("Enter for next page..")
                    read("")
                    scanHeight = 0
                end
                    nPrint("   Time:"  .. textutils.formatTime(event.time, false), "lightGray")
                    
                scanHeight = scanHeight + 1
                if scanHeight == maxLines then
                    nPrint("Enter for next page..")
                    read("")
                    scanHeight = 0
                end
                end
            end
        end
    },
    offset = {
        usage = "offset",
        details = "Set the offset of remote computer to your position.",
        isLocal = false,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            local px, py, pz = gps.locate(2)
            if localComputers[senderID] and px then
                if localComputers[senderID].pos then
                    settings.gps.offset.x = localComputers[senderID].pos.x - px
                    settings.gps.offset.y = localComputers[senderID].pos.y - py
                    settings.gps.offset.z = localComputers[senderID].pos.z - pz
                    inRangeClients = {}
                    save(settings, settingsPath)
                rednet.send(senderID, {data = "Offset set.", responseToken = responseToken}, "NodeOSCommandResponse")
                else
                rednet.send(senderID, {data = "Failed to set offset. Please check GPS and try again." , responseToken = responseToken}, "NodeOSCommandResponse")
                end
            else
                rednet.send(senderID, {data = "Failed to set offset. Please check GPS and try again." , responseToken = responseToken}, "NodeOSCommandResponse")
            end
        end
    },
    rd = {
        usage = "rd <computer/id/!>",
        details = "Remotely Display this screen.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            local px, py, pz = gps.locate(1)
            if params[1] then
                local cID = resolveComputer(params[1])
                if cID then
                    local res = sendCommand(cID, "rdConnect", nil)
                    if res == "connected" then
                        settings.rdID = cID
                        settings.currentRdSession = nil
                        save(settings, settingsPath)
                        clear()
                        if senderID then
                            rednet.send(senderID, {data = "Computer '" .. params[1] .. "' connected!", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint("Computer '" .. params[1] .. "' connected!", "green")
                    else
                        if senderID then
                            rednet.send(senderID, {data = res, responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint(res, "blue")
                    end
                else
                        if senderID then
                            rednet.send(senderID, {data = "Computer '" .. params[1] .. "' not found!", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    nPrint("Computer '" .. params[1] .. "' not found!", "red")
                end
            elseif settings.rdID then
                local res = sendCommand(settings.rdID, "rdDisconnect", nil)
                    if res == "disconnected" then
                        settings.rdID = nil
                        settings.currentRdSession = nil
                        save(settings, settingsPath)
                        clear()
                        if senderID then
                            rednet.send(senderID, {data = "RD disconnected.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint("RD disconnected.", "green")
                    else
                        if senderID then
                            rednet.send(senderID, {data = res, responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint(res, "blue")
                    end
            else
                        if senderID then
                            rednet.send(senderID, {data = "Usage: rd <computer/id/!>", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                nPrint("Usage: rd <computer/id/!>", "red")
            end
        end
    },
    rdConnect = {
        usage = "rdConnect",
        details = "Net Responder for rd.",
        isLocal = false,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            settings.rdID = nil
            settings.currentRdSession = senderID
            save(settings, settingsPath)
            rednet.send(senderID, {data = "connected", responseToken = responseToken}, "NodeOSCommandResponse")
        end
    },
    rdDisconnect = {
        usage = "rdDisconnect",
        details = "Net Responder for rd.",
        isLocal = false,
        isRemote = true,
        exec = function (params, responseToken, senderID)
            rednet.send(senderID, {data = "disconnected", responseToken = responseToken}, "NodeOSCommandResponse")
            settings.rdID = nil
            settings.currentRdSession = nil
            save(settings, settingsPath)
            clear()
        end
    },
    startup = {
        usage = "startup [path]",
        details = "Runs the lua program / script at the provided path. Or with no input clears it",
        isLocal = true,
        isRemote = false,
        exec = function (params, responseToken, senderID)
            if params[1] then
                if fs.exists(params[1]) then
                    settings.startup = params[1]
                    nPrint("Startup script set to '" .. settings.startup .. "'.", "green")
                else
                    nPrint("Could not find script '" .. params[1] .. "'!", "red")
                end
            else
                if settings.startup then
                    nPrint("Startup script '" .. settings.startup .. "' removed.", "green")
                    settings.startup = nil
                else
                    nPrint("Startup script is already disabled.", "red")
                end
            end
            save(settings, settingsPath)
        end
    }
}

local netCommands = {
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
    giveDetails = {
        exec = function (senderID, responseToken, data)
            localComputers[senderID] = data
        end
    },
    navsend = {
        exec = function (senderID, responseToken, data)
            rednet.send(senderID, {data = "success", responseToken = responseToken}, "NodeOSNetResponse")
            nPrint("Received nav location '" .. data.name .. "'.", "green")
            locations[data.name] = data.pos
            save(locations, locationsPath)
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
            if devicesConnected["speaker"] and settings.audio.actuationSound then
                peripherals[devicesConnected["speaker"]].peripheral.playNote("guitar", settings.audio.volume, 1)
                sleep(0.2)
                peripherals[devicesConnected["speaker"]].peripheral.playNote("guitar", settings.audio.volume, 9)
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
            filePath = "FileShare/" .. filePath
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
    events = {
        exec = function (senderID, responseToken, data)
            rednet.send(senderID, {data = events, responseToken = responseToken}, "NodeOSNetResponse")
        end
    },
    fsExists = {
        exec = function (senderID, responseToken, path)
            rednet.send(senderID, {data = fs.exists(path), responseToken = responseToken}, "NodeOSNetResponse")
        end
    },
    rdnWrite = {
        exec = function (senderID, responseToken, data)
            if senderID == settings.currentRdSession then
                nWrite(data.text, data.x, data.y, data.fgColor, data.bgColor, data.align)
            end
        end
    },
    rdnewLine = {
        exec = function (senderID, responseToken, data)
            if senderID == settings.currentRdSession then
                newLine()
            end
        end
    },
    rdclear = {
        exec = function (senderID, responseToken, data)
            if senderID == settings.currentRdSession then
                clear()
            end
        end
    },
    rdsetCursorPos = {
        exec = function (senderID, responseToken, data)
            if senderID == settings.currentRdSession then
                setCursorPos(data.x, data.y)
            end
        end
    },
    getWorldTiles = {
        exec = function (senderID, responseToken, data)
            if os.getComputerID() == settings.NodeOSMasterID then
                rednet.send(senderID, {data = worldTiles, responseToken = responseToken}, "NodeOSNetResponse")
            end
        end
    },
    setWorldTiles = {
        exec = function (senderID, responseToken, data)
            if worldTiles and os.getComputerID() == settings.NodeOSMasterID then
                rednet.send(senderID, {data = true, responseToken = responseToken}, "NodeOSNetResponse")
                setWorldTiles(data)
            end
        end
    }
}
function searchBlocks(blockSearch)
    matches = {}
        for x, xList in pairs(worldTiles) do
            for y, yList in pairs(xList) do
                for z, block in pairs(yList) do
                    if string.find(block.name, blockSearch) then
                        table.insert(matches, block)
                    end
                end
            end
        end
    return matches
end

function findClosestBlock(blockSearch)
    
    closestBlock = nil
    closestBlockDistance = nil
    local gpsPos = getPosition()
    if gpsPos then
        matches = searchBlocks(blockSearch)
        for i, block in pairs(matches) do
            dist = getDistance(gpsPos, block)
            if not closestBlockDistance or dist < closestBlockDistance then
                closestBlock = block
                closestBlockDistance = dist
            end
        end
    end
    return closestBlock
end
function setWorldTiles(blocks)
    for i, block in pairs(blocks) do
        local posX = block.x
        local posY = block.y
        local posZ = block.z
        local name = block.name
        if not worldTiles[posX] then
            worldTiles[posX] = {}
        end
        if not worldTiles[posX][posY] then
            worldTiles[posX][posY] = {}
        end
        if not worldTiles[posX][posY][posZ] then
            worldTiles[posX][posY][posZ] = {}
        end
        if name == "minecraft:air" then
            worldTiles[posX][posY][posZ] = nil --shitty map compression lol
            if (not next(worldTiles[posX][posY])) then
                worldTiles[posX][posY] = nil
                if (not next(worldTiles[posX])) then
                    worldTiles[posX] = nil
                end
            end
        else
            worldTiles[posX][posY][posZ] = block
        end
    end
end
---------------------
--Init main threads--
function renderThread()
    while true do
        if not shellRunning then
            if not settings.currentRdSession then
                drawStatusBar()
                drawHeader()
            end
        end
        os.sleep(0.5)
    end
end
function peripheralThread()
    while true do
        scanPeripherals()
        if driverData.neuralInterface then
            if (driverData.neuralInterface.hasModule("plethora:scanner")) then
                local gpsPos = getPosition()
                if gpsPos then
                    local newWorldTiles = {}
                    for _, block in pairs(driverData.neuralInterface.scan()) do
                        block.x = math.floor(gpsPos.x) + block.x
                        block.y = math.floor(gpsPos.y) + block.y
                        block.z = math.floor(gpsPos.z) + block.z
                        nblock = {
                            x = block.x,
                            y = block.y,
                            z = block.z,
                            name = block.name,
                            metadata = block.metadata
                        }
                        table.insert(newWorldTiles, nblock)
                    end
                    setWorldTiles(newWorldTiles)
                    sendNet(settings.NodeOSMasterID, "setWorldTiles", newWorldTiles, true)
                end
            end
        end
        os.sleep(settings.peripherals.pollRate)
    end
end
function getMobs()
    if driverData.neuralInterface then
        local gpsPos = getPosition()
        if (driverData.neuralInterface.hasModule("plethora:sensor")) then
            if gpsPos then
                local newMobs = {}
                for _, entity in pairs(driverData.neuralInterface.sense()) do
                    if entity.name ~= "Item"then
                        local meta = driverData.neuralInterface.getMetaByID(entity.id)
                        if meta and meta.x ~= 0 and meta.z ~= 0 then 
                            meta.x = math.floor(gpsPos.x) + meta.x
                            meta.y = math.floor(gpsPos.y) + meta.y
                            meta.z = math.floor(gpsPos.z) + meta.z
                            nEnt = {
                                x = meta.x,
                                y = meta.y,
                                z = meta.z,
                                name = meta.name,
                                id = entity.id
                            }
                            table.insert(newMobs, nEnt)
                        end
                    end
                end
                return newMobs
            end
        end
    end
    return nil
end
function netExchange()
    while true do
        emitComputerDetails()
        trimLocalComputers()
        scanInRange()
        local gpsPos = getPosition()
        if navigatingToBlock and gpsPos then
            if not navto or getDistance(navto, gpsPos) > 5 then
                closestBlock = findClosestBlock(navname)
                navtoid = nil
                if closestBlock then
                    navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                else
                    navto = nil
                end
            end
        end
        os.sleep(settings.gps.pollRate)
    end
end
local netStack = {}
function netSatisfy()
    while true do
        if netStack[1] then
            netInUse = true
            if not shellRunning then
                if not settings.currentRdSession then
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
                        if netCommands[rec.data.command] then
                            netCommands[rec.data.command].exec(rec.senderID, rec.data.responseToken, rec.data.data)
                        else
                            rednet.send(rec.senderID, {data = false, responseToken = rec.data.responseToken}, "NodeOSNetResponse")
                        end
                        if rec.data.command ~= "giveDetails" then
                            --table.insert(events, {name = cName, id = rec.senderID, event = rec.data.command, time = os.time()})
                            --save(events, eventsPath)
                        end
                    elseif rec.protocol == "NodeOs-Command" then
                        if rec.data.pin == settings.pairPin then
                            if commands[rec.data.command] and commands[rec.data.command].isRemote then
                                commands[rec.data.command].exec(rec.data.data, rec.data.responseToken, rec.senderID)
                            else
                                rednet.send(rec.senderID, {data = "Invalid command!", responseToken = rec.data.responseToken}, "NodeOSCommandResponse")
                            end
                            --table.insert(events, {name = cName, id = rec.senderID, event = rec.data.command, time = os.time()})
                            --save(events, eventsPath)
                        else
                            rednet.send(rec.senderID, {data = "Incorrect pin!", responseToken = rec.data.responseToken}, "NodeOSCommandResponse")
                            --table.insert(events, {name = cName, id = rec.senderID, event = "Incorrect pin!", time = os.time()})
                            --save(events, eventsPath)
                        end
                    else
                        if NetResponseStack[rec.protocol] and rec.data.data ~= nil then
                            NetResponseStack[rec.protocol][rec.data.responseToken] = rec.data.data
                        else
                            nPrint("Invalid protocol '" .. rec.protocol .. "' received from computer '" .. rec.senderID .. "'!", "red")
                        end
                    end
                end
        end
        netStack = {}
        os.sleep(settings.network.pollRate)
        netInUse = false
    end
end
function updateThread()
    while true do
        --save caches
        save(localComputers, localComputersPath)
        
        local gpsPos = getPosition()
        if navigatingToBlock and gpsPos then
            if not navto or getDistance(navto, gpsPos) > 5 then
                getWorldTiles()
            end
        end
        if settings.NodeOSMasterID == os.getComputerID() then
            save(worldTiles, worldTilesPath)
        end
        if checkForUpdate() then
            update()
        end
        os.sleep(10)
    end
end
function netScanThread()
    while true do
        if devicesConnected["modem"] then
            sid, data, protocol = rednet.receive()
            table.insert(netStack, {senderID = sid, data = data, protocol = protocol})
        else
            os.sleep(5)
        end
    end
end
function startup()
    redstone.setOutput(settings.redstone.side, settings.redstone.state)
    nPrint("Startup Complete!", "green")
    sleep(1)
    if devicesConnected["speaker"] then
        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 1)
        sleep(0.2)
        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 6)
        sleep(0.5)
        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 10)
        sleep(0.2)
        peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 18)
    end
    clear()
    if settings.startup then
        shellRun(settings.startup)
    end
end
function shellRun(input)
    shellRunning = true
    if fs.exists(input) or fs.exists(input .. ".lua") then
        shellProg = require(input)
        --unload it after it is done
        shellProg = nil
        package.loaded[input] = nil
    else
        shell.run(input)
    end
    shellRunning = false
end
function osThread()
    --STARTUP--
    while true do
        if settings.password == "" then
            isLocked = false
        end
        fillLine("_", nil, settings.console.seperatorfg, settings.console.seperatorbg)
        newLine()
        local input = getInput()
        if isLocked then
            if settings.password == input then
                isLocked = false
                if devicesConnected["speaker"] then
                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 1)
                    sleep(0.1)
                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", settings.audio.volume, 4)
                end
            end
        else
            local params = getWords(input)
            local command = table.remove(params, 1)
            --table.insert(events, {name = settings.name, id = os.getComputerID(), event = input, time = os.time()})
            --save(events, eventsPath)
            if command then
                if string.sub(input, 1, 2) == "! " then
                    command = table.remove(params, 1)
                    if command then
                        command = string.lower(command)
                        local closestID = getClosestPC()
                        if closestID then
                            local res = sendCommand(closestID, command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        else
                            nPrint("PC not in range!", "red")
                        end
                    else
                        nPrint("Usage: ![pcname/id] <command>", "red")
                    end
                elseif string.sub(input, 1, 1) == "!" then
                    pcName = command:gsub('%!', '')
                    command = table.remove(params, 1)
                    if command then
                        command = string.lower(command)
                        if localComputers[tonumber(pcName)] then
                            local res = sendCommand(tonumber(pcName), command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        elseif localComputers[getComputerID(pcName)] then
                            local res = sendCommand(getComputerID(pcName), command, params)
                            if res then
                                nPrint(res, "blue")
                            else
                                nPrint("No response received!", "red")
                            end
                        else
                            nPrint("Cannot find PC!", "red")
                        end
                    else
                        nPrint("Usage: ![pcname/id] <command>", "red")
                    end
                else
                    if commands[command] then
                        if commands[command].isLocal then
                            commands[command].exec(params)
                        else
                            nPrint("This command can only be run remotely.", "red")
                        end
                    else
                        shellRun(input)
                    end
                end
            end
        end
    end
end
---------
--SETUP--
if not settings.isSetup then
    centerText("SETUP",1,"purple")
    nPrint("Please type a computer name.")
    term.setTextColor(colors["purple"])
    write("PC Name")
    term.setTextColor(colors["lightGray"])
    write(">>")
    local inp = read()
    settings.name = inp
    term.setCursorPos(1, 1)
    term.clear()

    centerText("SETUP",1,"purple")
    nPrint("Please set a password.")
    term.setTextColor(colors["purple"])
    write("Password")
    term.setTextColor(colors["lightGray"])
    write(">>")
    inp = read("*")
    settings.password = inp
    term.setCursorPos(1, 1)
    term.clear()

    centerText("SETUP",1,"purple")
    nPrint("Please set a pairing pin.")
    term.setTextColor(colors["purple"])
    write("PIN")
    term.setTextColor(colors["lightGray"])
    write(">>")
    local inp = read("*")
    if inp == "" then
        inp = "0000"
    end
    settings.pairPin = inp
    term.setCursorPos(1, 1)
    term.clear()
    centerText("SETUP",1,"purple")
    nPrint("Type a message players will see when they are in your computer's range.")
    term.setTextColor(colors["purple"])
    write("Message")
    term.setTextColor(colors["lightGray"])
    write(">>")
    local inp = read()
    settings.message = inp
    term.setCursorPos(1, 1)
    term.clear()

    settings.isSetup = true
    save(settings, settingsPath)
    nPrint("Settings saved!", "green")
    sleep(2)
    os.reboot()
end
drivers = {
    modem = {
        init = function (side)
            rednet.open(side)
        end,
        unInit = function (side) 

        end 
    },
    drive = {
        init = function (side)
        end,
        unInit = function (side) 
        end 
    },
    speaker = {
        init = function (side)
        end,
        unInit = function (side)
        end 
    },
    command = {
        init = function (side)
        end,
        unInit = function (side)
        end 
    },
    neuralInterface = {
        init = function (side)
            driverData.neuralInterface = peripherals[side].peripheral
            if (driverData.neuralInterface and driverData.neuralInterface.hasModule("plethora:glasses")) then
                driverData.hud = {}
                driverData.hud.canvas = driverData.neuralInterface.canvas()
                driverData.hud.canvas.clear()
                -- And add a rectangle
                local cw, ch = driverData.hud.canvas.getSize()
                driverData.hud.statusBarRect = driverData.hud.canvas.addRectangle(0, 0, cw, 15, 0x4444bbaa)
                driverData.hud.title = driverData.hud.canvas.addText({ x = 5, y = 4 }, settings.name .. "(" .. os.getComputerID() .. ")")
                driverData.hud.time = driverData.hud.canvas.addText({ x = cw - 50, y = 4 }, "")
                driverData.hud.gps = driverData.hud.canvas.addText({ x = cw - 75, y = 4 }, "GPS")
                driverData.hud.net = driverData.hud.canvas.addText({ x = cw - 100, y = 4 }, "NET")
                driverData.hud.warningBarRect = driverData.hud.canvas.addRectangle(0, 15, cw, 15, 0x333333aa)
                driverData.hud.warning = driverData.hud.canvas.addText({ x = 5, y = 19 }, "")
                driverData.hud.navBarRect = driverData.hud.canvas.addRectangle(0, 30, cw, 15, 0x333333aa)
                driverData.hud.nav = driverData.hud.canvas.addText({ x = 5, y = 34 }, "")
            end
            commands.runto = {
                usage = "runto <locationname/blockname>",
                details = "Run to specified location or computer.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                    if driverData.neuralInterface.hasModule("plethora:kinetic") then
                        if params[1] then
                            
                            local gpsPos = getPosition()
                            if gpsPos then
                                if localComputers[tonumber(params[1])] and localComputers[tonumber(params[1])].pos then
                                    navto = nil
                                    navtoid = tonumber(params[1])
                                    navname = localComputers[navtoid].name
                                    nPrint("Running to computer ID '" .. params[1] .. "'.", "green")
                                    if senderID then
                                        rednet.send(senderID, {data = "Running to computer ID '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                    end
                                elseif localComputers[getComputerID(params[1])] then
                                    navto = nil
                                    navtoid = getComputerID(params[1])
                                    navname = localComputers[navtoid].name
                                    nPrint("Running to computer '" .. params[1] .. "'.", "green")
                                    if senderID then
                                        rednet.send(senderID, {data = "Running to computer '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                    end
                                elseif locations[params[1]] then
                                    navto = locations[params[1]]
                                    navname = params[1]
                                    navtoid = nil
                                    nPrint("Running to '" .. params[1] .. "'.", "green")
                                    if senderID then
                                        rednet.send(senderID, {data = "Running to '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                    end
                                else
                                    getWorldTiles()
                                    closestBlock = findClosestBlock(params[1])
                                    if closestBlock then
                                        navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                                        navname = params[1]
                                        navtoid = nil
                                        driverData.neuralInterface.walk(closestBlock.x, closestBlock.y, closestBlock.z)
                                        nPrint("Running to '" .. closestBlock.name .. "'.", "green")
                                        if senderID then
                                            rednet.send(senderID, {data = "Location does not exist.", responseToken = responseToken}, "NodeOSCommandResponse")
                                        end
                                    else
                                        nPrint("Location does not exist.", "red")
                                        if senderID then
                                            rednet.send(senderID, {data = "Location does not exist.", responseToken = responseToken}, "NodeOSCommandResponse")
                                        end
                                    end
                                end
                            else
                                nPrint("No GPS signal available.", "red")
                                if senderID then
                                    rednet.send(senderID, {data = "No GPS signal available.", responseToken = responseToken}, "NodeOSCommandResponse")
                                end
                            end
                        else
                            nPrint("Usage: runto <locationname>", "red")
                            if senderID then
                                rednet.send(senderID, {data = "Usage: runto <locationname>", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                        end
                    else
                        nPrint("You need the kinetic augment to use this command.", "red")
                        if senderID then
                        rednet.send(senderID, {data = "You need the kinetic augment to use this command.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    end
                end
            }
        end,
        unInit = function (side)
            driverData.neuralInterface = nil
            if driverData.hud then
                driverData.hud = nil
            end
        end 
    },
    monitor = {
        init = function (side)
            monitor = peripherals[side].peripheral
            monitor.setTextScale(0.5)
            monW, monH = monitor.getSize()
            monitor.setCursorPos(1,1)
            monitor.clear()
        end,
        unInit = function (side) 
        end 
    },
    webdisplay = {
        
            -- commands.sgstate = {
            --     usage = "sgstate",
            --     details = "See current stargate state.",
            --     isLocal = true,
            --     isRemote = true,
            --     exec = function (params, responseToken, senderID)
            --             if senderID then
            --                 rednet.send(senderID, {data = "Current State: " .. math.floor(driverData.stargate.stargateState()), responseToken = responseToken}, "NodeOSCommandResponse")
            --             end
            --         nPrint("Current State: " .. driverData.stargate.stargateState(), "blue")
            --     end
            -- }
    },
    stargate = {
        init = function (side)
            driverData.stargates = {}
            driverData.stargate = peripherals[side].peripheral
            driverData.stargates.stargatesPath = settingsFolder .. "/stargates.dat"
            if not fs.exists(driverData.stargates.stargatesPath) then
                save(driverData.stargates, driverData.stargates.stargatesPath)
            else
                driverData.stargates = load(driverData.stargates.stargatesPath)
            end
            commands.sgdial = {
                usage = "sgdial <address/savedaddress>",
                details = "Dial another stargate.",
        isLocal = true,
        isRemote = true,
        exec = function (params, responseToken, senderID)
                    if params[1] then
                        local address = nil
                        if driverData.stargates[params[1]] then
                            address = driverData.stargates[params[1]]
                        else
                            address = params[1]
                        end
                        if driverData.stargate.energyToDial(address) then
                            if driverData.stargate.energyAvailable() >= driverData.stargate.energyToDial(address) then
                        if senderID then
                                rednet.send(senderID, {data = "Dialing address '" .. params[1] .. "'...", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                                nPrint("Dialing address '" .. params[1] .. "'...", "green")
                                driverData.stargate.dial(address)
                            else
                                if senderID then
                                    rednet.send(senderID, {data = "Not enough energy to dial '" .. params[1] .. "'. " .. "The stargate is charged to '" .. math.ceil(driverData.stargate.energyAvailable()) .. "' but you need at least " .. driverData.stargate.energyToDial(address) .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                                end
                                nPrint("Not enough energy to dial '" .. params[1] .. "'.", "red")
                                nPrint("The stargate is charged to '" .. math.ceil(driverData.stargate.energyAvailable()) .. "' but you need at least " .. driverData.stargate.energyToDial(address) .. ".", "red")
                            end
                        else
                        if senderID then
                                rednet.send(senderID, {data = "Invalid address '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                            nPrint("Invalid address '" .. params[1] .. "'.", "red")
                        end
                    else
                        if senderID then
                                rednet.send(senderID, {data = "Usage: sgdial <address/savedaddress>", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                        nPrint("Usage: sgdial <address/savedaddress>", "red")
                    end
                end
            }
            commands.sgadd = {
                usage = "sgadd <name> <address>",
                details = "Add stargate to address list.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                    if params[1] and params[2] then
                        if not driverData.stargates[params[1]] then
                            if driverData.stargate.energyToDial(params[2]) then
                                driverData.stargates[params[1]] = params[2]
                            if senderID then
                                rednet.send(senderID, {data = "Address '" .. params[2] .. "' stored as '" .. params[1] .. "'", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                                save(driverData.stargates, driverData.stargates.stargatesPath)
                                nPrint("Address '" .. params[2] .. "' stored as '" .. params[1] .. "'", "green")
                            else
                            if senderID then
                                rednet.send(senderID, {data = "Invalid address '" .. params[2] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                                nPrint("Invalid address '" .. params[2] .. "'.", "red")
                            end
                        else
                            if senderID then
                                rednet.send(senderID, {data = "A address is already stored with that name.", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                            nPrint("A address is already stored with that name.", "red")
                        end
                    else
                    if senderID then
                        rednet.send(senderID, {data = "Usage: sgadd <name> <address>", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                        nPrint("Usage: sgadd <name> <address>", "red")
                    end
                end
            }
            commands.sgremove = {
                usage = "sgremove <name>",
                details = "Dial another stargate.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                    if params[1] then
                        if driverData.stargates[params[1]] then
                    if senderID then
                        rednet.send(senderID, {data = "Address '" .. params[1] .. "' removed!", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                            driverData.stargates[params[1]] = nil
                            save(driverData.stargates, driverData.stargates.stargatesPath)
                            nPrint("Address '" .. params[1] .. "' removed!", "green")
                        else
                    if senderID then
                        rednet.send(senderID, {data = "Address not found!", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                            nPrint("Address not found!", "red")
                        end
                    else
                    if senderID then
                        rednet.send(senderID, {data = "Usage: sgremove <address>", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                        nPrint("Usage: sgremove <address>", "red")
                    end
                end
            }
            commands.sgaddress = {
                usage = "sgaddress",
                details = "See current stargate address.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                    if senderID then
                            rednet.send(senderID, {data = "This Startgate's Address: " .. driverData.stargate.localAddress(), responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    nPrint("This Startgate's Address: " .. driverData.stargate.localAddress(), "blue")
                end
            }
            commands.sgstate = {
                usage = "sgstate",
                details = "See current stargate state.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                        if senderID then
                            rednet.send(senderID, {data = "Current State: " .. math.floor(driverData.stargate.stargateState()), responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    nPrint("Current State: " .. driverData.stargate.stargateState(), "blue")
                end
            }
            commands.sgpower = {
                usage = "sgpower",
                details = "See current stargate power.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                        if senderID then
                            rednet.send(senderID, {data = "Available Power: " .. math.floor(driverData.stargate.energyAvailable()), responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    nPrint("Available Power: " .. math.floor(driverData.stargate.energyAvailable()), "lightGray")
                end
            }
            commands.sgdisconnect = {
                usage = "sgdisconnect",
                details = "Disconnect the stargate.",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                        if senderID then
                            rednet.send(senderID, {data = "Stargate disconnected!", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    driverData.stargate.disconnect()
                    nPrint("Stargate disconnected!", "green")
                end
            }
            commands.sgiris = {
                usage = "sgopen",
                details = "Open the iris!",
                isLocal = true,
                isRemote = true,
                exec = function (params, responseToken, senderID)
                    if driverData.stargate.irisState() == "Open" then
                        if senderID then
                            rednet.send(senderID, {data = "Iris closed.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        driverData.stargate.closeIris()
                        nPrint("Iris closed.", "green")
                    else
                        if senderID then
                            rednet.send(senderID, {data = "Iris opened.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        driverData.stargate.openIris()
                        nPrint("Iris opened.", "green")
                    end
                end
            }
        end,
        unInit = function (side)
            driverData.stargate = nil
            driverData.stargates = nil
            commands.sgdial = nil
            commands.sgadd = nil
            commands.sgremove = nil
            commands.sgaddress = nil
            commands.sgstate = nil
            commands.sgpower = nil
            commands.sgdisconnect = nil
            commands.sgiris = nil
        end 
    }
}
--Start the main threads
parallel.waitForAll(renderThread, peripheralThread, netScanThread, netSatisfy, updateThread, netExchange, osThread)
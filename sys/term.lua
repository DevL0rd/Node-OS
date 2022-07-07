waitingForInput = false
lastGpsPos = nil
monitor = nil
compassString = ""
statusBarHeight = 4
term_settings_path = "config/term.dat" 
term_settings = {
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
}
if fs.exists(term_settings_path) then
    term_settings = load(term_settings_path)
else
    save(term_settings, term_settings_path)
end
function terminal_thread()
    while true do
        if not shellRunning then
            if not term_settings.currentRdSession then
                drawStatusBar()
                drawHeader()
            end
        end
        os.sleep(0.2)
    end
end

function clear()
    if term_settings.rdID then
        sendNet(term_settings.rdID, "rdclear", "", true)
    end
    term.clear()
    term.setCursorPos(1,statusBarHeight+1)
    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,statusBarHeight+1)
    end
    if not term_settings.currentRdSession then
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
    if term_settings.rdID then
        sendNet(term_settings.rdID, "rdsetCursorPos", {x = x, y = y}, true)
    end
    term.setCursorPos(x, y)
    if monitor then
        monitor.setCursorPos(x, y)
    end
end

function newLine()
    if term_settings.rdID then
        sendNet(term_settings.rdID, "rdnewLine", "", true)
    end
    print("")
end

function nPrint(text, fgColor, bgColor)
    local offsetY = statusBarHeight+1
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
    if not term_settings.currentRdSession then
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
        fgColor = term_settings.fg
    end
    if not bgColor or not colors[bgColor] then
        bgColor = term_settings.bg
    end
    if term_settings.rdID then
        sendNet(term_settings.rdID, "rdnWrite", {text = text, x = x, y = y, fgColor = fgColor, bgColor = bgColor, align = align}, true)
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
    term.setTextColor(colors[term_settings.fg])
    term.setBackgroundColor(colors[term_settings.bg])
    term.setCursorPos(cx, cy)
    if monitor then
        monitor.setTextColor(colors[term_settings.fg])
        monitor.setBackgroundColor(colors[term_settings.bg])
        monitor.setCursorPos(mcx, mcy)
    end
end

function centerText(text, line, fgColor, bgColor)
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = term_settings.fg
    end
    if bgColor == nil then
        bgColor = term_settings.bg
    end
    nWrite(text, 1, line, fgColor, bgColor, "center")
end

function alignRight(text, line, fgColor, bgColor)
    local cx,cy = term.getCursorPos()
    if line == nil then
        line = cy
    end
    if fgColor == nil then
        fgColor = term_settings.fg
    end
    if bgColor == nil then
        bgColor = term_settings.bg
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
        fgColor = term_settings.fg
    end
    if bgColor == nil then
        bgColor = term_settings.bg
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
        fgColor = term_settings.fg
    end
    if bgColor == nil then
        bgColor = term_settings.bg
    end
    fillLine(" ", line, fgColor, bgColor)
    nWrite(bchar, 1, line, fgColor, bgColor)
    nWrite(bchar, 1, line, fgColor, bgColor, "right")
end

function drawStatusBar()
    fillLine(" ", 1, term_settings.statusBar.fg, term_settings.statusBar.bg)
    nWrite(settings.name .. "(" .. os.getComputerID() .. ")", 1, 1, term_settings.statusBar.fg, term_settings.statusBar.bg)
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
    alignRight("GPS" .. getCharOfLength(" ", offset), 1, gpsColor, term_settings.statusBar.bg)
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
    alignRight("NET" .. getCharOfLength(" ", offset), 1, netColor, term_settings.statusBar.bg)
    alignRight(formattedTime, 1, term_settings.statusBar.fg, term_settings.statusBar.bg)
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
        fillLine("*", 3, "white", "red")
        centerText("LOCKED", 3, "white", "red")
        fillLine("*", 4, "white", "red")
    else
        local closestID = getClosestPC()
        
        local gpsPos = getPosition()
        fillLine(" ", 2, term_settings.header.fg, term_settings.header.bg)
        if closestID then
            local tColor = "orange"
            if pairedPCs[closestID] then
                tColor = "green"
            end
            local dist = 0
            if gpsPos and closestID and localComputers[closestID] and localComputers[closestID].pos then
                dist = math.floor(getDistance(gpsPos, localComputers[closestID].pos))
                centerText(getComputerName(closestID) .. "(" .. closestID .. ") Dist:" .. dist, 2, tColor, term_settings.header.bg)
            end
        else
            centerText("No Nearby PC", 2, "red", term_settings.header.bg)
        end
    end
end
coms.rd = {
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
                    term_settings.rdID = cID
                    term_settings.currentRdSession = nil
                    save(term_settings, term_settings_path)
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
        elseif term_settings.rdID then
            local res = sendCommand(term_settings.rdID, "rdDisconnect", nil)
                if res == "disconnected" then
                    term_settings.rdID = nil
                    term_settings.currentRdSession = nil
                    save(term_settings, term_settings_path)
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
}
coms.rdConnect = {
    usage = "rdConnect",
    details = "Net Responder for rd.",
    isLocal = false,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        term_settings.rdID = nil
        term_settings.currentRdSession = senderID
        save(term_settings, term_settings_path)
        rednet.send(senderID, {data = "connected", responseToken = responseToken}, "NodeOSCommandResponse")
    end
}
coms.rdDisconnect = {
    usage = "rdDisconnect",
    details = "Net Responder for rd.",
    isLocal = false,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        rednet.send(senderID, {data = "disconnected", responseToken = responseToken}, "NodeOSCommandResponse")
        term_settings.rdID = nil
        term_settings.currentRdSession = nil
        save(term_settings, term_settings_path)
        clear()
    end
}
coms.clear = {
    usage = "clear",
    details = "Clears the screen",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        clear()
    end
}
coms.cls = {
    usage = "cls",
    details = "Clears the screen",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        clear()
    end
}
netcoms.rdnWrite = {
    exec = function (senderID, responseToken, data)
        if senderID == term_settings.currentRdSession then
            nWrite(data.text, data.x, data.y, data.fgColor, data.bgColor, data.align)
        end
    end
}
netcoms.rdnewLine = {
    exec = function (senderID, responseToken, data)
        if senderID == term_settings.currentRdSession then
            newLine()
        end
    end
}
netcoms.rdclear = {
    exec = function (senderID, responseToken, data)
        if senderID == term_settings.currentRdSession then
            clear()
        end
    end
}
netcoms.rdsetCursorPos = {
    exec = function (senderID, responseToken, data)
        if senderID == term_settings.currentRdSession then
            setCursorPos(data.x, data.y)
        end
    end
}
function getInput()
    local tx,ty = term.getSize()
    local cx,cy = term.getCursorPos()
    waitingForInput = true
    local inp
    if isLocked then
        if not term_settings.currentRdSession then
            cy = statusBarHeight + 2
            nWrite("Password", 1, cy, "red")
            nWrite(">>", 9, cy, "lightGray")
            setCursorPos(12, cy)
        end
        inp = read("*")
    else
        if not term_settings.currentRdSession then
            nWrite("@"..settings.name, 1, cy, "lightGray")
            nWrite(" /" ..shell.dir(), settings.name:len() + 2, cy, "purple")
            nWrite(">>", shell.dir():len() + settings.name:len() + 4, cy, "lightGray")
            setCursorPos(shell.dir():len() + settings.name:len() + 7, cy)
        end
        inp = read()
    end
    if devicesConnected["speaker"] then
        peripherals[devicesConnected["speaker"]].peripheral.playNote("snare", speaker_settings.volume, 1)
        peripherals[devicesConnected["speaker"]].peripheral.playNote("snare", speaker_settings.volume, 9)
    end
    waitingForInput = false
    return inp
end
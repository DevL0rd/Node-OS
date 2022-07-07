smarthome_settings_path = "config/smarthome.dat" 
smarthome_settings = {
    actuationRange = 10,
    rangeunlock = false,
    rangelock = false,
    actuationSound = true,
    redstone = {
        ranged = false,
        side = "top",
        state = false,
        onInRange = "on",
        onLeaveRange = "off"
    }
}
if fs.exists(smarthome_settings_path) then
    smarthome_settings = load(smarthome_settings_path)
else
    save(smarthome_settings, smarthome_settings_path)
end
inRangeClients = {}
function redstoneOn()
    smarthome_settings.redstone.state = true
    redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
    save(smarthome_settings, smarthome_settings_path)
end

function redstoneOff()
    smarthome_settings.redstone.state = false
    redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
    save(smarthome_settings, smarthome_settings_path)
end
function redstoneToggle()
    if smarthome_settings.redstone.state then
        smarthome_settings.redstone.state = false
    else
        smarthome_settings.redstone.state = true
    end
    redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
    save(smarthome_settings, smarthome_settings_path)
end
function redstonePulse(secs)
    redstoneToggle()
    os.sleep(tonumber(secs))
    redstoneToggle()
end
--TODO move remote red control to new module
function scanInRange(gpsPos)
    if smarthome_settings.redstone.ranged then
        for id, isPaired in pairs(pairedClients) do
            if localComputers[id] then
                if localComputers[id].pos then
                    local dist = getDistance(gpsPos, localComputers[id].pos)
                    if inRangeClients[id] then
                        if dist > smarthome_settings.actuationRange then
                            inRangeClients[id] = nil
                            if not next(inRangeClients) then
                                if smarthome_settings.rangelock and settings.password ~= "" then
                                    isLocked = true
                                    clear()
                                    newLine()
                                end
                                if devicesConnected["speaker"] and smarthome_settings.actuationSound then
                                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", smarthome_settings.volume, 9)
                                    os.sleep(0.2)
                                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", smarthome_settings.volume, 1)
                                end
                                local params = getWords(smarthome_settings.redstone.onLeaveRange)
                                local command = table.remove(params, 1)
                                if smarthome_settings.redstone.onLeaveRange == "on" then
                                    redstoneOn()
                                elseif smarthome_settings.redstone.onLeaveRange == "off" then
                                    redstoneOff()
                                elseif smarthome_settings.redstone.onLeaveRange == "toggle" then
                                    redstoneToggle()
                                elseif command == "pulse" then
                                    redstonePulse(tonumber(params[1]))
                                end
                            end
                        end
                    else
                        if dist <= smarthome_settings.actuationRange then
                            local clientInRange = (next(inRangeClients))
                            inRangeClients[id] = true
                            if not clientInRange then
                                if smarthome_settings.rangeunlock and settings.password ~= "" then
                                    isLocked = false
                                    clear()
                                    newLine()
                                end
                                if devicesConnected["speaker"] and smarthome_settings.actuationSound then
                                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", smarthome_settings.volume, 1)
                                    os.sleep(0.2)
                                    peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", smarthome_settings.volume, 9)
                                end
                                local params = getWords(smarthome_settings.redstone.onInRange)
                                local command = table.remove(params, 1)
                                if smarthome_settings.redstone.onInRange == "on" then
                                    redstoneOn()
                                elseif smarthome_settings.redstone.onInRange == "off" then
                                    redstoneOff()
                                elseif smarthome_settings.redstone.onInRange == "toggle" then
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
table.insert(gps_threads, scanInRange)

coms.close = {
    usage = "close",
    details = "Turns off redstone output.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if senderID then
                rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
        end
        nPrint("Redstone output set to off.", "green")
        smarthome_settings.redstone.state = false
        redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
        save(smarthome_settings, smarthome_settings_path)
    end
}
coms.open = {
    usage = "open",
    details = "Turns on redstone output.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if senderID then
            rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
        end
        nPrint("Redstone output set to on.", "green")
        smarthome_settings.redstone.state = true
        redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
        save(smarthome_settings, smarthome_settings_path)
    end
}

coms.off = {
    usage = "off",
    details = "Turns off redstone output.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if senderID then
                rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
        end
        nPrint("Redstone output set to off.", "green")
        smarthome_settings.redstone.state = false
        redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
        save(smarthome_settings, smarthome_settings_path)
    end
}
coms.on = {
    usage = "on",
    details = "Turns on redstone output.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if senderID then
                rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
        end
        nPrint("Redstone output set to on.", "green")
        smarthome_settings.redstone.state = true
        redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
        save(smarthome_settings, smarthome_settings_path)
    end
}
coms.toggle = {
    usage = "toggle",
    details = "Toggles redstone output.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if smarthome_settings.redstone.state then
            smarthome_settings.redstone.state = false
            if senderID then
                rednet.send(senderID, {data = "Redstone output set to off.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to off.", "green")
        else
            smarthome_settings.redstone.state = true
            if senderID then
                rednet.send(senderID, {data = "Redstone output set to on.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone output set to on.", "green")
        end
        redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
        save(smarthome_settings, smarthome_settings_path)
    end
}
coms.pulse = {
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
            if smarthome_settings.redstone.state then
                smarthome_settings.redstone.state = false
            else
                smarthome_settings.redstone.state = true
            end
            redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
            os.sleep(tonumber(params[1]))
            if smarthome_settings.redstone.state then
                smarthome_settings.redstone.state = false
            else
                smarthome_settings.redstone.state = true
            end
            redstone.setOutput(smarthome_settings.redstone.side, smarthome_settings.redstone.state)
            save(smarthome_settings, smarthome_settings_path)
        else
            if senderID then
                rednet.send(senderID, {data = "Usage: pulse <seconds>", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Usage: pulse <seconds>", "red")
        end    
    end
}

coms.range = {
    usage = "range",
    details = "Toggles ranged activation of redstone.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if isInt(tonumber(params[1])) and tonumber(params[1]) ~= 0 then
            smarthome_settings.actuationRange = tonumber(params[1])
            inRangeClients = {}
            if senderID then
                    rednet.send(senderID, {data = "Range set to " ..  params[1]  .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Range set to " ..  params[1]  .. ".", "green")
        else
            if smarthome_settings.redstone.ranged then
                smarthome_settings.redstone.ranged = false
                if senderID then
                    rednet.send(senderID, {data = "Remote ranged redstone disabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Remote ranged redstone disabled.", "green")
            else 
                smarthome_settings.redstone.ranged = true
                if senderID then
                    rednet.send(senderID, {data = "Remote ranged redstone enabled.", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("Remote ranged redstone enabled.", "green")
            end
        end
        save(smarthome_settings, smarthome_settings_path)
    end
}

coms.rangelock = {
    usage = "rangelock",
    details = "Lock out of range",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if smarthome_settings.rangelock then
            smarthome_settings.rangelock = false
            nPrint("Remote ranged lock disabled.", "green")
        else
            smarthome_settings.rangelock = true
            nPrint("Remote ranged lock enabled.", "green")
        end
        save(smarthome_settings, smarthome_settings_path)
    end
}

coms.rangeunlock = {
    usage = "rangeunlock",
    details = "Unlock in range",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if smarthome_settings.rangeunlock then
            smarthome_settings.rangeunlock = false
            nPrint("Remote ranged unlock disabled.", "green")
        else
            smarthome_settings.rangeunlock = true
            nPrint("Remote ranged unlock enabled.", "green")
        end
        save(smarthome_settings, smarthome_settings_path)
    end
}

coms.rangesound = {
    usage = "rangesound",
    details = "Toggles sound from playing when going in and out of range.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if smarthome_settings.actuationSound then
            smarthome_settings.actuationSound = false
            if senderID then
                rednet.send(senderID, {data = "Actuation sound disabled.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Actuation sound disabled.", "green")
        else
            smarthome_settings.actuationSound = true
            if senderID then
                rednet.send(senderID, {data = "Actuation sound enabled.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Actuation sound enabled.", "green")
        end
        save(smarthome_settings, smarthome_settings_path)
    end
}

coms.setin = {
    usage = "setin <on,off,toggle,pulse <seconds>>",
    details = "Sets what to do with redstone when paired computer is in range.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if params[1] == "on" or params[1] == "off" or params[1] == "toggle" or params[1] == "pulse" then
            if params[2] then
                smarthome_settings.redstone.onInRange = params[1] .. " " .. params[2]
            else
                smarthome_settings.redstone.onInRange = params[1]
            end
            inRangeClients = {}
            if senderID then
                rednet.send(senderID, {data = "In range action set to " .. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("In range action set to " .. params[1] .. ".", "green")
            save(smarthome_settings, smarthome_settings_path)
        else
            if senderID then
                rednet.send(senderID, {data = "Usage: setin <on,off,toggle,pulse <seconds>>", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Usage: setin <on,off,toggle,pulse <seconds>>", "red")
        end
    end
}

coms.setout = {
    usage = "setout <on,off,toggle,pulse <seconds>>",
    details = "Sets what to do with redstone when paired computer is out of range.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if params[1] == "on" or params[1] == "off" or params[1] == "toggle" or params[1] == "pulse" then
            if params[2] then
                smarthome_settings.redstone.onLeaveRange = params[1] .. " " .. params[2]
            else
                smarthome_settings.redstone.onLeaveRange = params[1]
            end
            inRangeClients = {}
            if senderID then
                rednet.send(senderID, {data = "Out of range action set to " .. params[1] .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Out of range action set to " .. params[1] .. ".", "green")
            save(smarthome_settings, smarthome_settings_path)
        else
            if senderID then
                rednet.send(senderID, {data = "Usage: setout <on,off,toggle,pulse <seconds>>", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Usage: setout <on,off,toggle,pulse <seconds>>", "red")
        end
    end
}

coms.side = {
    usage = "side [side]",
    details = "Sets or logs side that redstone is on.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
        if params[1] == "top" or params[1] == "bottom" or params[1] == "back" or params[1] == "front" or params[1] == "left" or params[1] == "right" then
            smarthome_settings.redstone.side = params[1]
            inRangeClients = {}
            nPrint("Redstone side set to " .. params[1] .. ".", "green")
            save(smarthome_settings, smarthome_settings_path)
        else
            if senderID then
                rednet.send(senderID, {data = "Redstone side is '" ..  smarthome_settings.redstone.side  .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
            end
            nPrint("Redstone side is '" ..  smarthome_settings.redstone.side  .. "'.", "lightGray")
        end
    end
}
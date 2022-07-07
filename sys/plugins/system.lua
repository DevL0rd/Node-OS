coms.help = {
    usage = "help <command>",
    details = "Shows this help page.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)

        if params[1] then
            params[1] = string.lower(params[1])
            if coms[params[1]] then
                nPrint(coms[params[1]].usage, "purple")
                nPrint("   " .. coms[params[1]].details, "lightGray")
            else
                nPrint("Command not found!", "red")
            end
        else
            newLine()
            local tx,ty = term.getSize()
            local maxLines = ty - statusBarHeight - 3
            local scanHeight = 0
            for comName, details in pairs(coms) do
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
}
coms.lock = {
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
        statusBarHeight = 4
        if devicesConnected["speaker"] then
            peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", speaker_settings.volume, 9)
            os.sleep(0.1)
            peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", speaker_settings.volume, 4)
            os.sleep(0.1)
            peripherals[devicesConnected["speaker"]].peripheral.playNote("bell", speaker_settings.volume, 1)
        end
    end
}
coms.reboot = {
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
}
coms.setname = {
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
}
coms.setpass = {
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
}
coms.setpin = {
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
}
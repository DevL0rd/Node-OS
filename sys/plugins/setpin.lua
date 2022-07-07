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
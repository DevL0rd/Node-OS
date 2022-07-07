coms.setmsg = {
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
}
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
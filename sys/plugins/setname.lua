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
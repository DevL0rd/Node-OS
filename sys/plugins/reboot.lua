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
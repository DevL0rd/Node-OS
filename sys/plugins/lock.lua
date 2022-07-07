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
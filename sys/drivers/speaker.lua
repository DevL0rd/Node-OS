speaker_settings_path = "config/term.dat" 
speaker_settings = {
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
if fs.exists(speaker_settings_path) then
    speaker_settings = load(speaker_settings_path)
else
    save(speaker_settings, speaker_settings_path)
end
return {
    init = function (side)
        coms.volume = {
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
                    speaker_settings.volume = tonumber(params[1])
                    save(speaker_settings, speaker_settings_path)
                else
                    if senderID then
                        rednet.send(senderID, {data = "Volume is " ..  params[1]  .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    nPrint("Volume is '" ..  speaker_settings.volume  .. "'.", "lightGray")
                end
            end
        }
    end,
    unInit = function (side)
        coms.volume = nil
    end 
}
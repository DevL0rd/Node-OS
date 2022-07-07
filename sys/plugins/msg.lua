coms.msg = {
    usage = "msg <computer/id/!> <msg> ",
    details = "Send message to computer. Use ! to do closest.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] and params[2] then
            local cId = nil
            if localComputers[tonumber(params[1])] then
                cId = tonumber(params[1])
                table.remove(params, 1)
            elseif localComputers[getComputerID(params[1])] then
                cId = getComputerID(params[1])
                table.remove(params, 1)
            elseif params[1] == "!" then
                cId = getClosestPC()
            end
            if cId then
                local res = sendNet(cId, "msg", {name = settings.name, msg = listToString(params)})
                if res then
                    nPrint("Message sent!", "green")
                else
                    nPrint("No response received.", "red")
                end
            else
                nPrint("Could not find PC.", "red")
            end
        else
            nPrint("Usage: msg [computer] <msg>", "red")
        end
    end
}
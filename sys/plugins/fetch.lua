coms.fetch = {
    usage = "fetch <file> <to> [computer]",
    details = "Defaults to nearest computer unless specified.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            if params[2] then
                if params[3] then
                    local cId = nil
                    if localComputers[params[3]] then
                        cId = tonumber(params[3])
                    else
                        cId = getComputerID(params[3])
                    end
                    if cId then
                        fetchFile(cId, params[1], params[2])
                    else
                        nPrint("Could not connect to PC.", "red")
                    end
                else
                    local closestID = getClosestPC()
                    if closestID then
                        fetchFile(closestID, params[1], params[2])
                    else
                        nPrint("PC not in range!", "red")
                    end
                end
            else
                nPrint("Usage: fetch <file> <to> [computer]", "red")
            end
        else
            nPrint("Usage: fetch <file> <to> [computer]", "red")
        end
    end
}
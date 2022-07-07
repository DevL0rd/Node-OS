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
return {
    init = function (side)
        driverData.stargates = {}
        driverData.stargate = peripherals[side].peripheral
        driverData.stargates.stargatesPath = "config/stargates.dat"
        if not fs.exists(driverData.stargates.stargatesPath) then
            save(driverData.stargates, driverData.stargates.stargatesPath)
        else
            driverData.stargates = load(driverData.stargates.stargatesPath)
        end
        coms.sgdial = {
            usage = "sgdial <address/savedaddress>",
            details = "Dial another stargate.",
    isLocal = true,
    isRemote = true,
    exec = function (params, responseToken, senderID)
                if params[1] then
                    local address = nil
                    if driverData.stargates[params[1]] then
                        address = driverData.stargates[params[1]]
                    else
                        address = params[1]
                    end
                    if driverData.stargate.energyToDial(address) then
                        if driverData.stargate.energyAvailable() >= driverData.stargate.energyToDial(address) then
                    if senderID then
                            rednet.send(senderID, {data = "Dialing address '" .. params[1] .. "'...", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                            nPrint("Dialing address '" .. params[1] .. "'...", "green")
                            driverData.stargate.dial(address)
                        else
                            if senderID then
                                rednet.send(senderID, {data = "Not enough energy to dial '" .. params[1] .. "'. " .. "The stargate is charged to '" .. math.ceil(driverData.stargate.energyAvailable()) .. "' but you need at least " .. driverData.stargate.energyToDial(address) .. ".", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                            nPrint("Not enough energy to dial '" .. params[1] .. "'.", "red")
                            nPrint("The stargate is charged to '" .. math.ceil(driverData.stargate.energyAvailable()) .. "' but you need at least " .. driverData.stargate.energyToDial(address) .. ".", "red")
                        end
                    else
                    if senderID then
                            rednet.send(senderID, {data = "Invalid address '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint("Invalid address '" .. params[1] .. "'.", "red")
                    end
                else
                    if senderID then
                            rednet.send(senderID, {data = "Usage: sgdial <address/savedaddress>", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    nPrint("Usage: sgdial <address/savedaddress>", "red")
                end
            end
        }
        coms.sgadd = {
            usage = "sgadd <name> <address>",
            details = "Add stargate to address list.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                if params[1] and params[2] then
                    if not driverData.stargates[params[1]] then
                        if driverData.stargate.energyToDial(params[2]) then
                            driverData.stargates[params[1]] = params[2]
                        if senderID then
                            rednet.send(senderID, {data = "Address '" .. params[2] .. "' stored as '" .. params[1] .. "'", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                            save(driverData.stargates, driverData.stargates.stargatesPath)
                            nPrint("Address '" .. params[2] .. "' stored as '" .. params[1] .. "'", "green")
                        else
                        if senderID then
                            rednet.send(senderID, {data = "Invalid address '" .. params[2] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                            nPrint("Invalid address '" .. params[2] .. "'.", "red")
                        end
                    else
                        if senderID then
                            rednet.send(senderID, {data = "A address is already stored with that name.", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                        nPrint("A address is already stored with that name.", "red")
                    end
                else
                if senderID then
                    rednet.send(senderID, {data = "Usage: sgadd <name> <address>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                    nPrint("Usage: sgadd <name> <address>", "red")
                end
            end
        }
        coms.sgremove = {
            usage = "sgremove <name>",
            details = "Dial another stargate.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                if params[1] then
                    if driverData.stargates[params[1]] then
                if senderID then
                    rednet.send(senderID, {data = "Address '" .. params[1] .. "' removed!", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                        driverData.stargates[params[1]] = nil
                        save(driverData.stargates, driverData.stargates.stargatesPath)
                        nPrint("Address '" .. params[1] .. "' removed!", "green")
                    else
                if senderID then
                    rednet.send(senderID, {data = "Address not found!", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                        nPrint("Address not found!", "red")
                    end
                else
                if senderID then
                    rednet.send(senderID, {data = "Usage: sgremove <address>", responseToken = responseToken}, "NodeOSCommandResponse")
                end
                    nPrint("Usage: sgremove <address>", "red")
                end
            end
        }
        coms.sgaddress = {
            usage = "sgaddress",
            details = "See current stargate address.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                if senderID then
                        rednet.send(senderID, {data = "This Startgate's Address: " .. driverData.stargate.localAddress(), responseToken = responseToken}, "NodeOSCommandResponse")
                end
                nPrint("This Startgate's Address: " .. driverData.stargate.localAddress(), "blue")
            end
        }
        coms.sgstate = {
            usage = "sgstate",
            details = "See current stargate state.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                    if senderID then
                        rednet.send(senderID, {data = "Current State: " .. math.floor(driverData.stargate.stargateState()), responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                nPrint("Current State: " .. driverData.stargate.stargateState(), "blue")
            end
        }
        coms.sgpower = {
            usage = "sgpower",
            details = "See current stargate power.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                    if senderID then
                        rednet.send(senderID, {data = "Available Power: " .. math.floor(driverData.stargate.energyAvailable()), responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                nPrint("Available Power: " .. math.floor(driverData.stargate.energyAvailable()), "lightGray")
            end
        }
        coms.sgdisconnect = {
            usage = "sgdisconnect",
            details = "Disconnect the stargate.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                    if senderID then
                        rednet.send(senderID, {data = "Stargate disconnected!", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                driverData.stargate.disconnect()
                nPrint("Stargate disconnected!", "green")
            end
        }
        coms.sgiris = {
            usage = "sgopen",
            details = "Open the iris!",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                if driverData.stargate.irisState() == "Open" then
                    if senderID then
                        rednet.send(senderID, {data = "Iris closed.", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    driverData.stargate.closeIris()
                    nPrint("Iris closed.", "green")
                else
                    if senderID then
                        rednet.send(senderID, {data = "Iris opened.", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                    driverData.stargate.openIris()
                    nPrint("Iris opened.", "green")
                end
            end
        }
    end,
    unInit = function (side)
        driverData.stargate = nil
        driverData.stargates = nil
        coms.sgdial = nil
        coms.sgadd = nil
        coms.sgremove = nil
        coms.sgaddress = nil
        coms.sgstate = nil
        coms.sgpower = nil
        coms.sgdisconnect = nil
        coms.sgiris = nil
    end 
}
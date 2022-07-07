function getMobs()
    if driverData.neuralInterface then
        local gpsPos = getPosition()
        if (driverData.neuralInterface.hasModule("plethora:sensor")) then
            if gpsPos then
                local newMobs = {}
                for _, entity in pairs(driverData.neuralInterface.sense()) do
                    if entity.name ~= "Item"then
                        local meta = driverData.neuralInterface.getMetaByID(entity.id)
                        if meta and meta.x ~= 0 and meta.z ~= 0 then 
                            meta.x = math.floor(gpsPos.x) + meta.x
                            meta.y = math.floor(gpsPos.y) + meta.y
                            meta.z = math.floor(gpsPos.z) + meta.z
                            nEnt = {
                                x = meta.x,
                                y = meta.y,
                                z = meta.z,
                                name = meta.name,
                                id = entity.id
                            }
                            table.insert(newMobs, nEnt)
                        end
                    end
                end
                return newMobs
            end
        end
    end
    return nil
end

return {
    init = function (side)
        driverData.neuralInterface = peripherals[side].peripheral
        if (driverData.neuralInterface and driverData.neuralInterface.hasModule("plethora:glasses")) then
            driverData.hud = {}
            driverData.hud.canvas = driverData.neuralInterface.canvas()
            driverData.hud.canvas.clear()
            -- And add a rectangle
            local cw, ch = driverData.hud.canvas.getSize()
            driverData.hud.statusBarRect = driverData.hud.canvas.addRectangle(0, 0, cw, 15, 0x4444bbaa)
            driverData.hud.title = driverData.hud.canvas.addText({ x = 5, y = 4 }, settings.name .. "(" .. os.getComputerID() .. ")")
            driverData.hud.time = driverData.hud.canvas.addText({ x = cw - 50, y = 4 }, "")
            driverData.hud.gps = driverData.hud.canvas.addText({ x = cw - 75, y = 4 }, "GPS")
            driverData.hud.net = driverData.hud.canvas.addText({ x = cw - 100, y = 4 }, "NET")
            driverData.hud.warningBarRect = driverData.hud.canvas.addRectangle(0, 15, cw, 15, 0x333333aa)
            driverData.hud.warning = driverData.hud.canvas.addText({ x = 5, y = 19 }, "")
            driverData.hud.navBarRect = driverData.hud.canvas.addRectangle(0, 30, cw, 15, 0x333333aa)
            driverData.hud.nav = driverData.hud.canvas.addText({ x = 5, y = 34 }, "")
        end
        coms.runto = {
            usage = "runto <locationname/blockname>",
            details = "Run to specified location or computer.",
            isLocal = true,
            isRemote = true,
            exec = function (params, responseToken, senderID)
                if driverData.neuralInterface.hasModule("plethora:kinetic") then
                    if params[1] then
                        
                        local gpsPos = getPosition()
                        if gpsPos then
                            if localComputers[tonumber(params[1])] and localComputers[tonumber(params[1])].pos then
                                navto = nil
                                navtoid = tonumber(params[1])
                                navname = localComputers[navtoid].name
                                nPrint("Running to computer ID '" .. params[1] .. "'.", "green")
                                if senderID then
                                    rednet.send(senderID, {data = "Running to computer ID '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                end
                            elseif localComputers[getComputerID(params[1])] then
                                navto = nil
                                navtoid = getComputerID(params[1])
                                navname = localComputers[navtoid].name
                                nPrint("Running to computer '" .. params[1] .. "'.", "green")
                                if senderID then
                                    rednet.send(senderID, {data = "Running to computer '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                end
                            elseif locations[params[1]] then
                                navto = locations[params[1]]
                                navname = params[1]
                                navtoid = nil
                                nPrint("Running to '" .. params[1] .. "'.", "green")
                                if senderID then
                                    rednet.send(senderID, {data = "Running to '" .. params[1] .. "'.", responseToken = responseToken}, "NodeOSCommandResponse")
                                end
                            else
                                getWorldTiles(gpsPos, 16, 16)
                                local closestBlock = findClosestBlock(gpsPos, params[1])
                                if closestBlock then
                                    navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                                    navname = params[1]
                                    navtoid = nil
                                    driverData.neuralInterface.walk(closestBlock.x, closestBlock.y, closestBlock.z)
                                    nPrint("Running to '" .. closestBlock.name .. "'.", "green")
                                    if senderID then
                                        rednet.send(senderID, {data = "Location does not exist.", responseToken = responseToken}, "NodeOSCommandResponse")
                                    end
                                else
                                    nPrint("Location does not exist.", "red")
                                    if senderID then
                                        rednet.send(senderID, {data = "Location does not exist.", responseToken = responseToken}, "NodeOSCommandResponse")
                                    end
                                end
                            end
                        else
                            nPrint("No GPS signal available.", "red")
                            if senderID then
                                rednet.send(senderID, {data = "No GPS signal available.", responseToken = responseToken}, "NodeOSCommandResponse")
                            end
                        end
                    else
                        nPrint("Usage: runto <locationname>", "red")
                        if senderID then
                            rednet.send(senderID, {data = "Usage: runto <locationname>", responseToken = responseToken}, "NodeOSCommandResponse")
                        end
                    end
                else
                    nPrint("You need the kinetic augment to use this command.", "red")
                    if senderID then
                    rednet.send(senderID, {data = "You need the kinetic augment to use this command.", responseToken = responseToken}, "NodeOSCommandResponse")
                    end
                end
            end
        }
    end,
    unInit = function (side)
        driverData.neuralInterface = nil
        if driverData.hud then
            driverData.hud = nil
        end
    end 
}
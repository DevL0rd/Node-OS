local gps = require("/lib/gps")
local net = require("/lib/net")
local util = require("/lib/util")
local file = util.loadModule("file")
local settings = require("/lib/settings").settings

function listen_giveLocalComputerDetails()
    while true do
        local cid, msg = rednet.receive("NodeOS_giveLocalComputerDetails")
        if msg then
            local localComputers = gps.getLocalComputers()
            localComputers[cid] = msg.data
            gps.saveLocalComputers(localComputers)
        end
    end
end

parallel.addOSThread(listen_giveLocalComputerDetails)

function giveLocalComputerDetails_thread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            net.emit("NodeOS_giveLocalComputerDetails", {
                pos = gpsPos,
                name = os.getComputerLabel(),
                id = os.getComputerID(),
                time = os.time()
            })
        end
        sleep(0.5)
    end
end

parallel.addOSThread(giveLocalComputerDetails_thread)


function listen_setOffset()
    while true do
        local cid, msg = rednet.receive("NodeOS_setOffset")
        if msg.pos then
            net.respond(cid, msg.token, { success = gps.setOffset(msg.pos) })
        else
            net.respond(cid, msg.token, { success = false })
        end
    end
end

parallel.addOSThread(listen_setOffset)

if os.getComputerID() == settings.NodeOSMasterID then
    tiles_path = "etc/map/serverTiles.dat"
    serverTiles = {}
    if not fs.exists(tiles_path) then
        file.writeTable(tiles_path, serverTiles)
    else
        serverTiles = file.readTable(tiles_path)
    end
    function listen_getWorldTiles()
        while true do
            local cid, msg = rednet.receive("NodeOS_getWorldTiles")
            local data = msg.data
            if data.all then
                net.respond(cid, msg.token, serverTiles)
            else
                -- for blocks in data.radius
                if data.radius > 31 then
                    data.radius = 31
                end
                local tmpTiles = {}
                data.pos.x = math.floor(data.pos.x)
                data.pos.y = math.floor(data.pos.y)
                data.pos.z = math.floor(data.pos.z)

                local mx = data.pos.x - data.radius
                local my = data.pos.y - data.height
                local mz = data.pos.z - data.radius
                local mx2 = data.pos.x + data.radius
                local my2 = data.pos.y + data.height
                local mz2 = data.pos.z + data.radius
                -- max world height is 320
                -- min world height is -64 ^ 2
                if my > 319 then
                    my = 319
                end
                if my < -63 then
                    my = -63
                end
                if my2 > 319 then
                    my2 = 319
                end
                if my2 < -63 then
                    my2 = -63
                end
                -- round y
                my = math.floor(my)
                my2 = math.floor(my2)
                local width = data.radius * 2 + 1
                --take slices by height
                for posY = my, my2 do
                    local blockSlice = commands.getBlockInfos(mx, posY, mz, mx2, posY, mz2)
                    count = 0
                    for posX = mx, mx2 do
                        for posZ = mz, mz2 do
                            -- x + z*width + y*depth*depth
                            local ix = math.floor(posX - mx)
                            -- local iy = math.floor(posY - my)+1
                            local iz = math.floor(posZ - mz)
                            local index = ix + iz * width + 1
                            -- print(ix .. " " .. iy .. " " .. iz .. " -- " .. index)
                            -- sleep(1)
                            local block = blockSlice[index]
                            local bm = {}
                            if block.name ~= "minecraft:air" then
                                name = block.name
                                -- remove minecraft: from string in name if it is there
                                if string.find(name, "minecraft:") then
                                    name = string.sub(name, string.len("minecraft:") + 1)
                                end
                                count = count + 1
                                if not tmpTiles[posX] then
                                    tmpTiles[posX] = {}
                                end
                                if not tmpTiles[posX][posY] then
                                    tmpTiles[posX][posY] = {}
                                end
                                if not tmpTiles[posX][posY][posZ] then
                                    tmpTiles[posX][posY][posZ] = {}
                                end
                                tmpTiles[posX][posY][posZ] = name
                                if not serverTiles[posX] then
                                    serverTiles[posX] = {}
                                end
                                if not serverTiles[posX][posY] then
                                    serverTiles[posX][posY] = {}
                                end
                                if not serverTiles[posX][posY][posZ] then
                                    serverTiles[posX][posY][posZ] = {}
                                end
                                serverTiles[posX][posY][posZ] = name
                            elseif serverTiles[posX] and serverTiles[posX][posY] and serverTiles[posX][posY][posZ] then
                                serverTiles[posX][posY][posZ] = nil --shitty map compression lol
                                if (not next(serverTiles[posX][posY])) then
                                    serverTiles[posX][posY] = nil
                                    if (not next(serverTiles[posX])) then
                                        serverTiles[posX] = nil
                                    end
                                end
                            end
                        end
                    end
                end
                net.respond(cid, msg.token, tmpTiles)
            end
        end
    end

    parallel.addOSThread(listen_getWorldTiles)

    function saveServerTiles()
        while true do
            file.writeTable(tiles_path, serverTiles)
            sleep(60)
        end
    end

    parallel.addOSThread(saveServerTiles)
end


function trimLocalComputers()
    while true do
        local localComputers = gps.getLocalComputers()
        for id, details in pairs(localComputers) do
            if details.time then
                local timeDiff = os.time() - details.time
                if timeDiff < 0 then
                    timeDiff = -timeDiff
                end
                if timeDiff > 0.5 then
                    localComputers[id] = nil --remove computer from list if it hasn't sent updates recently
                end
            else
                localComputers[id] = nil
            end
        end
        gps.saveLocalComputers(localComputers)
        os.sleep(10)
    end
end

parallel.addOSThread(trimLocalComputers)
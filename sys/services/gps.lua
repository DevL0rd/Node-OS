local worldDepthLimit = -59
function listen_giveLocalComputerDetails()
    while true do
        local cid, msg = rednet.receive("NodeOS_giveLocalComputerDetails")
        if msg then
            local localComputers = gps.getLocalComputers()
            localComputers[cid] = msg.data
        end
    end
end

pm.createProcess(listen_giveLocalComputerDetails, {isService=true, title="listen_giveLocalComputerDetails"})

function giveLocalComputerDetails_thread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            net.emit("NodeOS_giveLocalComputerDetails", {
                pos = gpsPos,
                name = os.getComputerLabel(),
                id = os.getComputerID(),
                isTurtle = turtle ~= nil,
                groups = sets.settings.groups,
                time = os.time()
            })
        end
        sleep(0.5)
    end
end

pm.createProcess(giveLocalComputerDetails_thread, {isService=true, title="service_giveLocalComputerDetails"})


function listen_setOffset()
    while true do
        local cid, msg = rednet.receive("NodeOS_setOffset")
        if msg.data.pos then
            net.respond(cid, msg.token, { success = gps.setOffset(msg.data.pos), message = "Offset set!" })
        else
            net.respond(cid, msg.token, { success = false, message = "No position provided!" })
        end
    end
end

pm.createProcess(listen_setOffset, {isService=true, title="listen_setOffset"})

function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

if os.getComputerID() == sets.settings.master then
    local interestingTilesBlacklist_path = "etc/map/interestingTilesBlacklist.cfg"
    local interestingTilesBlacklist = {
        "minecraft:bedrock",
        "minecraft:cobblestone",
        "minecraft:dirt",
        "minecraft:gravel",
        "minecraft:sand",
        "minecraft:sandstone",
        "minecraft:snow",
        "minecraft:snowblock",
        "minecraft:stone",
        "minecraft:grass_block",
        "minecraft:dirt",
        "minecraft:coarse_dirt",
        "minecraft:podzol",
        "minecraft:oak_leaves",
        "minecraft:spruce_leaves",
        "minecraft:birch_leaves",
        "minecraft:jungle_leaves",
        "minecraft:acacia_leaves",
        "minecraft:dark_oak_leaves",
        "minecraft:sandstone",
        "minecraft:grass",
        "minecraft:tallgrass",
        "minecraft:dead_bush",
        "minecraft:fern",
        "minecraft:end_stone",
        "minecraft:command_block",
        "minecraft:repeating_command_block",
        "minecraft:chain_command_block",
        "minecraft:nether_wart_block",
        "minecraft:water",
        "minecraft:lava",
        "minecraft:bubble_column",
        "minecraft:crimson_nylium",
        "minecraft:warped_nylium",
        "minecraft:cobbled_deepslate",
        "minecraft:deepslate",
        "minecraft:dirt_path"
    }
    if not fs.exists(interestingTilesBlacklist_path) then
        file.writeTable(interestingTilesBlacklist_path, interestingTilesBlacklist)
    else
        interestingTilesBlacklist = file.readTable(interestingTilesBlacklist_path)
    end
    interestingTilesBlacklist = Set(interestingTilesBlacklist)
    local interestingTiles_path = "etc/map/interestingTiles"
    if not fs.exists(interestingTiles_path) then
        fs.makeDir(interestingTiles_path)
    end
    local interestingTiles = {}

    function listen_getWorldTiles()
        while true do
            local cid, msg = rednet.receive("NodeOS_getWorldTiles")
            local data = msg.data
            -- for blocks in data.radius
            if data.radius > 31 then
                data.radius = 31
            end
            local tmpTiles = {}
            data.pos.x = math.floor(data.pos.x)
            data.pos.y = math.floor(data.pos.y)
            data.pos.z = math.floor(data.pos.z)
            print("data.pos.x: " .. data.pos.x)
            print("data.pos.y: " .. data.pos.y)
            print("data.pos.z: " .. data.pos.z)
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
            if my < worldDepthLimit then
                my = worldDepthLimit
            end
            if my2 > 319 then
                my2 = 319
            end
            if my2 < worldDepthLimit then
                my2 = worldDepthLimit
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
                        end
                    end
                end
            end
            net.respond(cid, msg.token, tmpTiles)
        end
    end

    pm.createProcess(listen_getWorldTiles, {isService=true, title="listen_getWorldTiles"})
    -- local getBlockNameFromPartialName_cache = {}
    function getBlockNameFromPartialName(partialName)
        if interestingTiles[partialName] then
            return partialName
        end
        -- if getBlockNameFromPartialName_cache[partialName] then
        --     return getBlockNameFromPartialName_cache[partialName]
        -- end
        for i, v in pairs(interestingTiles) do
            if string.find(i, partialName) then
                -- getBlockNameFromPartialName_cache[partialName] = i
                return i
            end
        end
        return nil
    end

    function listen_getInterestingTiles()
        while true do
            local cid, msg = rednet.receive("NodeOS_getInterestingTiles")
            local data = msg.data
            local blockName = getBlockNameFromPartialName(data.name)
            if data.all then
                if not blockName then
                    net.respond(cid, msg.token, {
                        tiles = {},
                        name = nil
                    })
                elseif interestingTiles[blockName] then
                    net.respond(cid, msg.token, {
                        tiles = interestingTiles[blockName],
                        name = blockName
                    })
                else
                    net.respond(cid, msg.token, {
                        tiles = {},
                        name = blockName
                    })
                end
            else
                -- for blocks in data.radius
                if data.radius > 31 then
                    data.radius = 31
                end
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
                if my < worldDepthLimit then
                    my = worldDepthLimit
                end
                if my2 > 319 then
                    my2 = 319
                end
                if my2 < worldDepthLimit then
                    my2 = worldDepthLimit
                end
                -- round y
                my = math.floor(my)
                my2 = math.floor(my2)
                local width = data.radius * 2 + 1
                local tmpTiles = {}
                --take slices by height
                for posY = my, my2 do
                    local blockSlice = commands.getBlockInfos(mx, posY, mz, mx2, posY, mz2)
                    count = 0
                    for posX = mx, mx2 do
                        for posZ = mz, mz2 do
                            local ix = math.floor(posX - mx)
                            local iz = math.floor(posZ - mz)
                            local index = ix + iz * width + 1
                            local block = blockSlice[index]
                            local bm = {}
                            if block.name ~= "minecraft:air" then
                                if not interestingTilesBlacklist[block.name] then
                                    count = count + 1
                                    --if deepslate_ at begining of name, remove it
                                    if string.find(block.name, "deepslate_") then
                                        block.name = string.sub(block.name, string.len("deepslate_") + 1)
                                    end
                                    if not interestingTiles[block.name] then
                                        interestingTiles[block.name] = {
                                            changed = true
                                        }
                                    end
                                    interestingTiles[block.name].changed = true
                                    if not interestingTiles[block.name][posX] then
                                        interestingTiles[block.name][posX] = {}
                                    end
                                    if not interestingTiles[block.name][posX][posY] then
                                        interestingTiles[block.name][posX][posY] = {}
                                    end
                                    if not interestingTiles[block.name][posX][posY][posZ] then
                                        interestingTiles[block.name][posX][posY][posZ] = 1
                                    end
                                    if not blockName then
                                        if string.find(block.name, data.name) then
                                            blockName = block.name
                                        end
                                    end
                                    -- print("blockName: " .. blockName)
                                    if block.name == blockName then
                                        if not tmpTiles[posX] then
                                            tmpTiles[posX] = {}
                                        end
                                        if not tmpTiles[posX][posY] then
                                            tmpTiles[posX][posY] = {}
                                        end
                                        if not tmpTiles[posX][posY][posZ] then
                                            tmpTiles[posX][posY][posZ] = 1
                                        end
                                    end
                                end
                            elseif blockName then
                                if interestingTiles[blockName] and interestingTiles[blockName][posX] and
                                    interestingTiles[blockName][posX][posY] and
                                    interestingTiles[blockName][posX][posY][posZ] then
                                    interestingTiles[blockName][posX][posY][posZ] = nil --shitty map compression lol
                                    if (not next(interestingTiles[blockName][posX][posY])) then
                                        interestingTiles[blockName][posX][posY] = nil
                                        if (not next(interestingTiles[blockName][posX])) then
                                            interestingTiles[blockName][posX] = nil
                                            if (not next(interestingTiles[blockName])) then
                                                interestingTiles[blockName] = nil
                                                interestingTiles_changed = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                net.respond(cid, msg.token, {
                    tiles = tmpTiles,
                    name = blockName
                })
            end
        end
    end
    pm.createProcess(listen_getInterestingTiles, {isService=true, title="listen_getInterestingTiles"})

    function listen_removeInterestingTile()
        while true do
            local cid, msg = rednet.receive("NodeOS_removeInterestingTile")
            local data = msg.data
            if interestingTiles[data.name] and interestingTiles[data.name][data.pos.x] and
                interestingTiles[data.name][data.pos.x][data.pos.y] and
                interestingTiles[data.name][data.pos.x][data.pos.y][data.pos.z] then
                interestingTiles[data.name][data.pos.x][data.pos.y][data.pos.z] = nil
                interestingTiles[data.name].changed = true
                if (not next(interestingTiles[data.name][data.pos.x][data.pos.y])) then
                    interestingTiles[data.name][data.pos.x][data.pos.y] = nil
                    if (not next(interestingTiles[data.name][data.pos.x])) then
                        interestingTiles[data.name][data.pos.x] = nil
                    end
                end
            end
        end
    end
    pm.createProcess(listen_removeInterestingTile, {isService=true, title="service_removeInterestingTile"})

    function listen_getInterestingTilesBlacklist()
        while true do
            local cid, msg = rednet.receive("NodeOS_getInterestingTilesBlacklist")
            net.respond(cid, msg.token, interestingTilesBlacklist)
        end
    end

    pm.createProcess(listen_getInterestingTilesBlacklist, {isService=true, title="service_getInterestingTilesBlacklist"})

    function saveServerTiles()
        while true do
            for i, v in pairs(interestingTiles) do
                if v.changed then
                    v.changed = false
                    -- replace : with -
                    local fileName = string.gsub(i, ":", "-")
                    local file = fs.open(interestingTiles_path .. "/" .. fileName .. ".dat", "w")
                    file.write(textutils.serialize(v))
                    file.close()
                end
            end
            sleep(60)
        end
    end

    function loadServerTiles()
        --for every .dat file in interestingTiles_path
        for i, v in pairs(fs.list(interestingTiles_path)) do
            if string.find(v, ".dat") then
                local file = fs.open(interestingTiles_path .. "/" .. v, "r")
                local data = textutils.unserialize(file.readAll())
                file.close()
                local key = string.sub(v, 1, -5)
                key = string.gsub(key, "-", ":")
                interestingTiles[key] = data
            end
        end
    end

    loadServerTiles()
    pm.createProcess(saveServerTiles, {isService=true, title="service_saveTiles"})
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

pm.createProcess(trimLocalComputers, {isService=true, title="service_trimLocalComputers"})


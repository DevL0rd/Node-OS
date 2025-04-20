local turtleUtils = require("/lib/turtleUtils")
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

pm.createProcess(listen_giveLocalComputerDetails, { isService = true, title = "listen_giveLocalComputerDetails" })

function giveLocalComputerDetails_thread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            -- local inventory = nil
            -- if turtle then
            --     inventory = turtleUtils.getInventory()
            -- end
            net.emit("NodeOS_giveLocalComputerDetails", {
                pos = gpsPos,
                name = os.getComputerLabel(),
                id = os.getComputerID(),
                isTurtle = turtle ~= nil,
                groups = sets.settings.groups,
                time = os.time(),
                status = gps.status,
                target = gps.target,
                -- inventory = inventory
            })
        end
        sleep(0.5)
    end
end

pm.createProcess(giveLocalComputerDetails_thread, { isService = true, title = "service_giveLocalComputerDetails" })


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

pm.createProcess(listen_setOffset, { isService = true, title = "listen_setOffset" })

function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

if os.getComputerID() == sets.settings.master then
    local interestingTilesBlacklist_path = "etc/map/interestingTilesBlacklist.cfg"
    if not fs.exists(interestingTilesBlacklist_path) then
        file.writeTable(interestingTilesBlacklist_path, {})
    else
        interestingTilesBlacklist = file.readTable(interestingTilesBlacklist_path)
    end
    interestingTilesBlacklist = Set(interestingTilesBlacklist)
    local interestingTiles_path = "etc/map/interestingTiles"
    if not fs.exists(interestingTiles_path) then
        fs.makeDir(interestingTiles_path)
    end
    local interestingTiles = {}
    -- Precompute constants for optimization
    local minecraftPrefix = "minecraft:"
    local deepslatePrefix = "minecraft:deepslate_"
    local minecraftPrefixLen = #minecraftPrefix
    local deepslatePrefixLen = #deepslatePrefix

    function listen_getWorldTiles()
        while true do
            local cid, msg = rednet.receive("NodeOS_getWorldTiles")
            local data = msg.data

            -- Clamp radius
            local radius = math.min(math.floor(data.radius), 10)
            local height_param = math.floor(math.min(data.height, 9) / 2)
            local tmpTiles = {}
            local centerX = math.floor(data.pos.x)
            local centerY = math.floor(data.pos.y)
            local centerZ = math.floor(data.pos.z)

            -- Calculate boundaries, clamping Y (use min/max names like example)
            local min_x = centerX - radius
            local min_y = math.max(worldDepthLimit, math.min(319, math.floor(centerY - height_param)))
            local min_z = centerZ - radius
            local max_x = centerX + radius
            local max_y = math.max(worldDepthLimit, math.min(319, math.floor(centerY + height_param)))
            local max_z = centerZ + radius

            -- Calculate dimensions based on the actual volume queried (matching example variable names)
            local width = max_x - min_x + 1
            local height = max_y - min_y + 1 -- This is the actual height of the volume
            local depth = max_z - min_z + 1

            -- Fetch block info for the entire volume at once
            local blockSlice = commands.getBlockInfos(min_x, min_y, min_z, max_x, max_y, max_z)
            -- Iterate through world coordinates like the example
            -- Loop order matches the index formula structure: Y (slowest), Z (middle), X (fastest)
            for y = min_y, max_y do
                for z = min_z, max_z do
                    for x = min_x, max_x do
                        -- Calculate the index using the exact formula from the example:
                        -- index = (x - min_x) + (z - min_z) * width + (y - min_y) * width * depth + 1
                        local index = (x - min_x) + (z - min_z) * width + (y - min_y) * width * depth + 1

                        -- Access the block data using the calculated index
                        local block = blockSlice[index]

                        -- Process the block if it exists and is not air
                        if block and block.name ~= "minecraft:air" then
                            local blockName = block.name -- Use local variable

                            -- Lazily create nested tables only when needed
                            -- Store using the world coordinates x, y, z
                            if not tmpTiles[x] then
                                tmpTiles[x] = {}
                            end
                            if not tmpTiles[x][y] then
                                tmpTiles[x][y] = {}
                            end
                            tmpTiles[x][y][z] = blockName
                        end
                    end
                end
            end

            net.respond(cid, msg.token, tmpTiles)
        end
    end

    pm.createProcess(listen_getWorldTiles, { isService = true, title = "listen_getWorldTiles" })
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
                -- Handle request for all known tiles of a specific type
                if not blockName then
                    net.respond(cid, msg.token, {
                        tiles = {},
                        name = nil
                    })
                elseif interestingTiles[blockName] then
                    -- Create a copy to avoid sending the 'changed' flag
                    local responseTiles = {}
                    for x, yTable in pairs(interestingTiles[blockName]) do
                        if type(x) == "number" then -- Ensure we only copy coordinate data
                            responseTiles[x] = {}
                            for y, zTable in pairs(yTable) do
                                responseTiles[x][y] = {}
                                for z, val in pairs(zTable) do
                                    responseTiles[x][y][z] = val
                                end
                            end
                        end
                    end
                    net.respond(cid, msg.token, {
                        tiles = responseTiles,
                        name = blockName
                    })
                else
                    net.respond(cid, msg.token, {
                        tiles = {},
                        name = blockName
                    })
                end
            else
                -- Handle request for tiles within a radius
                local radius = math.min(math.floor(data.radius), 10)
                local height_param = math.floor(math.min(data.height, 9) / 2)

                local centerX = math.floor(data.pos.x)
                local centerY = math.floor(data.pos.y)
                local centerZ = math.floor(data.pos.z)

                -- Calculate boundaries, clamping Y (use min/max names like example)
                local min_x = centerX - radius
                local min_y = math.max(worldDepthLimit, math.min(319, math.floor(centerY - height_param)))
                local min_z = centerZ - radius
                local max_x = centerX + radius
                local max_y = math.max(worldDepthLimit, math.min(319, math.floor(centerY + height_param)))
                local max_z = centerZ + radius

                -- Calculate dimensions based on the actual volume queried (matching example variable names)
                local width = max_x - min_x + 1
                local height = max_y - min_y + 1 -- This is the actual height of the volume
                local depth = max_z - min_z + 1

                local tmpTiles = {} -- Tiles matching the specific request within the radius

                -- Fetch block info for the entire volume at once
                local allBlocks = commands.getBlockInfos(min_x, min_y, min_z, max_x, max_y, max_z)


                -- Iterate through world coordinates like the example
                for posY = min_y, max_y do
                    for posZ = min_z, max_z do
                        for posX = min_x, max_x do
                            -- Calculate the index using the exact formula from the example:
                            -- index = (x - min_x) + (z - min_z) * width + (y - min_y) * width * depth + 1
                            local index = (posX - min_x) + (posZ - min_z) * width + (posY - min_y) * width * depth + 1

                            -- Access the block data using the calculated index
                            local block = allBlocks[index]
                            local currentBlockName = nil
                            if block then
                                currentBlockName = block.name
                            end

                            -- Process the block if it exists and is not air
                            if currentBlockName and currentBlockName ~= "minecraft:air" then
                                if not interestingTilesBlacklist[currentBlockName] then
                                    -- Handle deepslate prefix optimization
                                    if string.sub(currentBlockName, 1, deepslatePrefixLen) == deepslatePrefix then
                                        currentBlockName = minecraftPrefix ..
                                            string.sub(currentBlockName, deepslatePrefixLen + 1)
                                    end

                                    -- Update global interestingTiles cache
                                    if not interestingTiles[currentBlockName] then
                                        interestingTiles[currentBlockName] = { changed = true }
                                    end
                                    interestingTiles[currentBlockName].changed = true
                                    if not interestingTiles[currentBlockName][posX] then
                                        interestingTiles[currentBlockName][posX] = {}
                                    end
                                    if not interestingTiles[currentBlockName][posX][posY] then
                                        interestingTiles[currentBlockName][posX][posY] = {}
                                    end
                                    interestingTiles[currentBlockName][posX][posY][posZ] = 1

                                    -- Determine the actual blockName if not already found (only needed if initial data.name was partial)
                                    if not blockName then
                                        if string.find(currentBlockName, data.name) then
                                            blockName = currentBlockName
                                        end
                                    end

                                    -- Add to tmpTiles if it matches the requested blockName
                                    if currentBlockName == blockName then
                                        if not tmpTiles[posX] then
                                            tmpTiles[posX] = {}
                                        end
                                        if not tmpTiles[posX][posY] then
                                            tmpTiles[posX][posY] = {}
                                        end
                                        tmpTiles[posX][posY][posZ] = 1
                                    end
                                end
                            elseif blockName then -- Only check for air removal if we have a specific blockName we are interested in
                                -- Current block is air (or nil), check if we need to remove it from the global cache
                                if interestingTiles[blockName] and interestingTiles[blockName][posX] and
                                    interestingTiles[blockName][posX][posY] and
                                    interestingTiles[blockName][posX][posY][posZ] then
                                    interestingTiles[blockName][posX][posY][posZ] = nil
                                    interestingTiles[blockName].changed = true -- Mark for saving

                                    -- Clean up empty nested tables
                                    if not next(interestingTiles[blockName][posX][posY]) then
                                        interestingTiles[blockName][posX][posY] = nil
                                        if not next(interestingTiles[blockName][posX]) then
                                            interestingTiles[blockName][posX] = nil
                                            -- Check if the entire block type entry is now empty (except 'changed')
                                            local isEmpty = true
                                            for k, _ in pairs(interestingTiles[blockName]) do
                                                if k ~= "changed" then
                                                    isEmpty = false
                                                    break
                                                end
                                            end
                                            if isEmpty then
                                                interestingTiles[blockName] = nil
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

    pm.createProcess(listen_getInterestingTiles, { isService = true, title = "listen_getInterestingTiles" })

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

    pm.createProcess(listen_removeInterestingTile, { isService = true, title = "service_removeInterestingTile" })

    function listen_getInterestingTilesBlacklist()
        while true do
            local cid, msg = rednet.receive("NodeOS_getInterestingTilesBlacklist")
            net.respond(cid, msg.token, interestingTilesBlacklist)
        end
    end

    pm.createProcess(listen_getInterestingTilesBlacklist, {
        isService = true,
        title =
        "service_getInterestingTilesBlacklist"
    })

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
    pm.createProcess(saveServerTiles, { isService = true, title = "service_saveTiles" })
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

pm.createProcess(trimLocalComputers, { isService = true, title = "service_trimLocalComputers" })

function getPlayerPosition(username)
    -- get player entity data which includes position
    local ok, result = commands.exec("data get entity " .. username .. " Pos[0]")
    local resString = result[1] -- Eg Player1 has the following entity data: 2
    local data = string.match(resString, "data: (.*)")
    local x = data
    ok, result = commands.exec("data get entity " .. username .. " Pos[1]")
    resString = result[1] -- Eg Player1 has the following entity data: 2
    data = string.match(resString, "data: (.*)")
    local y = data
    ok, result = commands.exec("data get entity " .. username .. " Pos[2]")
    resString = result[1] -- Eg Player1 has the following entity data: 2
    data = string.match(resString, "data: (.*)")
    local z = data
    -- remove last character for each
    x = string.sub(x, 1, -2)
    y = string.sub(y, 1, -2)
    z = string.sub(z, 1, -2)


    -- -- parse
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)

    return { x = x, y = y, z = z }
end

function getPlayerHealth(username)
    local ok, result = commands.exec("data get entity " .. username .. " Health")
    local resString = result[1] -- Eg Player1 has the following entity data: 2
    local data = string.match(resString, "data: (.*)")
    local health = data
    -- remove last character for each
    health = string.sub(health, 1, -2)
    -- parse
    health = tonumber(health)
    return health
end

function getPlayerFoodlevel(username)
    local ok, result = commands.exec("data get entity " .. username .. " foodLevel")
    local resString = result[1] -- Eg Player1 has the following entity data: 2
    local data = string.match(resString, "data: (.*)")
    -- hunger = string.sub(data, 1, -2) --remove last char
    -- parse
    hunger = tonumber(data)
    return hunger
end

function getPlayerGamemode(username)
    local ok, result = commands.exec("data get entity " .. username .. " playerGameType")
    local resString = result[1] -- Eg Player1 has the following entity data: 2
    local data = string.match(resString, "data: (.*)")
    local gamemode = data
    -- -- remove last character for each
    -- gamemode = string.sub(gamemode, 1, -2)
    -- -- parse
    gamemode = tonumber(gamemode)
    return gamemode
end

function getPlayerSelectedItem(username)
    local ok, result = commands.exec("data get entity " .. username .. " SelectedItem.id")
    local resString = result[1] -- Eg Player1 has the following entity data: {data}

    local data = string.match(resString, "data: \"(.*)\"")
    -- data_parsed = textutils.unserialize(data)
    return data
end

local players_old = {}
local last_player_fetch = 0

function getPlayers()
    if os.time() == last_player_fetch then -- prevent spamming the server on same tick
        return players_old
    end
    last_player_fetch = os.time()
    local ok, result = commands.exec("list")
    -- result[1] EG: "There are 1 of a max of 20 players online: Player1, Player2, Player3"
    if not ok then
        return {}
    end
    local players = {}
    -- match players after : seperated by ", "
    for player in string.gmatch(result[1], ": (.*)") do
        for p in string.gmatch(player, "([^,]+)") do
            players[p] = {
                pos = getPlayerPosition(p),
                health = getPlayerHealth(p),
                food = getPlayerFoodlevel(p),
                gamemode = getPlayerGamemode(p),
                selectedItem = getPlayerSelectedItem(p),
                name = p
            }
        end
    end
    players_old = players
    return players
end

function listen_getPlayers()
    while true do
        local cid, msg = rednet.receive("NodeOS_getPlayers")
        local players = getPlayers()
        net.respond(cid, msg.token, players)
    end
end

pm.createProcess(listen_getPlayers, { isService = true, title = "listen_getPlayers" })

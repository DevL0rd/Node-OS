local turtleUtils = require("/lib/turtleUtils")
local worldDepthLimit = -59

-- Add initialization log for GPS service
nodeos.logging.info("GPSService", "Initializing GPS service")

function listen_giveLocalComputerDetails()
    nodeos.logging.debug("GPSService", "Starting local computer details listener")
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_giveLocalComputerDetails")
        if not msg or not msg.data then
            nodeos.logging.error("GPSService", "Received invalid computer details from #" .. cid)
            nodeos.net.respond(cid, msg and msg.token, {
                success = false,
                message = "Invalid request format"
            })
        else
            local localComputers = nodeos.gps.getLocalComputers()
            localComputers[cid] = msg.data
        end
    end
end

nodeos.createProcess(listen_giveLocalComputerDetails, { isService = true, title = "listen_giveLocalComputerDetails" })

function giveLocalComputerDetails_thread()
    nodeos.logging.debug("GPSService", "Starting local computer details broadcaster")
    while true do
        local gpsPos = nodeos.gps.getPosition()
        if gpsPos then
            -- local inventory = nil
            -- if turtle then
            --     inventory = turtleUtils.getInventory()
            -- end
            nodeos.net.emit("NodeOS_giveLocalComputerDetails", {
                pos = gpsPos,
                name = os.getComputerLabel(),
                id = os.getComputerID(),
                isTurtle = turtle ~= nil,
                groups = nodeos.settings.settings.groups,
                time = os.time(),
                status = nodeos.gps.status,
                target = nodeos.gps.target,
                -- inventory = inventory
            })
        else
            nodeos.logging.warn("GPSService", "No GPS position available for broadcasting")
        end
        sleep(0.5)
    end
end

nodeos.createProcess(giveLocalComputerDetails_thread, { isService = true, title = "service_giveLocalComputerDetails" })


function listen_setOffset()
    nodeos.logging.debug("GPSService", "Starting GPS offset listener")
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_setOffset")
        -- Validate parameters
        if not msg or not msg.data then
            nodeos.logging.error("GPSService", "Received invalid setOffset request format from computer #" .. cid)
            nodeos.net.respond(cid, msg and msg.token, {
                success = false,
                message = "Invalid request format"
            })
        elseif not msg.data.pos then
            nodeos.logging.error("GPSService", "Received setOffset request with no position from computer #" .. cid)
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "No position provided"
            })
        elseif not msg.data.pos.x or not msg.data.pos.y or not msg.data.pos.z then
            nodeos.logging.error("GPSService",
                "Received setOffset request with incomplete position from computer #" .. cid)
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "Position must include x, y, and z coordinates"
            })
        else
            nodeos.logging.info("GPSService",
                "Setting GPS offset to " .. msg.data.pos.x .. "," .. msg.data.pos.y .. "," .. msg.data.pos.z)
            nodeos.net.respond(cid, msg.token, { success = nodeos.gps.setOffset(msg.data.pos), message = "Offset set!" })
        end
    end
end

nodeos.createProcess(listen_setOffset, { isService = true, title = "listen_setOffset" })

function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

if os.getComputerID() == nodeos.settings.settings.master then
    nodeos.logging.info("GPSService", "Initializing master GPS server functionality")
    local interestingBlocksBlacklist_path = "etc/map/interestingBlocksBlacklist.cfg"
    if not fs.exists(interestingBlocksBlacklist_path) then
        nodeos.logging.debug("GPSService", "Creating new interesting blocks blacklist")
        saveTable(interestingBlocksBlacklist_path, {})
    else
        nodeos.logging.debug("GPSService", "Loading existing interesting blocks blacklist")
        interestingBlocksBlacklist = loadTable(interestingBlocksBlacklist_path)
    end
    interestingBlocksBlacklist = Set(interestingBlocksBlacklist)
    local interestingBlocks_path = "etc/map/interestingBlocks"
    if not fs.exists(interestingBlocks_path) then
        nodeos.logging.debug("GPSService", "Creating interesting blocks directory")
        fs.makeDir(interestingBlocks_path)
    end
    local interestingBlocks = {}
    -- Precompute constants for optimization
    local minecraftPrefix = "minecraft:"
    local deepslatePrefix = "minecraft:deepslate_"
    local minecraftPrefixLen = #minecraftPrefix
    local deepslatePrefixLen = #deepslatePrefix

    function listen_getWorldBlocks()
        nodeos.logging.debug("GPSService", "Starting world blocks listener")
        while true do
            local cid, msg = nodeos.net.receive("NodeOS_getWorldBlocks")
            if not msg or not msg.data then
                nodeos.logging.error("GPSService", "Received invalid getWorldBlocks request from #" .. cid)
                nodeos.net.respond(cid, msg and msg.token, {
                    success = false,
                    message = "Invalid request format"
                })
                goto continue
            end

            if not msg.data.pos or not msg.data.radius or not msg.data.height then
                nodeos.logging.error("GPSService", "Missing required parameters in getWorldBlocks request from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Missing required parameters: pos, radius, and height are required"
                })
                goto continue
            end

            if not msg.data.pos.x or not msg.data.pos.y or not msg.data.pos.z then
                nodeos.logging.error("GPSService", "Incomplete position in getWorldBlocks request from #" .. cid)
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "Position must include x, y, and z coordinates"
                })
                goto continue
            end

            local data = msg.data
            nodeos.logging.debug("GPSService", "block req from #" .. cid)

            -- Start timing
            local startTime = os.clock()

            -- Clamp radius
            local radius = math.min(math.floor(data.radius), 10)
            local height_param = math.floor(math.min(data.height, 9) / 2)
            local tmpBlocks = {}
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
                            if not tmpBlocks[x] then
                                tmpBlocks[x] = {}
                            end
                            if not tmpBlocks[x][y] then
                                tmpBlocks[x][y] = {}
                            end
                            tmpBlocks[x][y][z] = blockName
                        end
                    end
                end
            end

            local execTime = os.clock() - startTime
            nodeos.logging.debug("GPSService", "block req completed in " .. execTime .. "s")
            nodeos.net.respond(cid, msg.token,
                {
                    success = true,
                    blocks = tmpBlocks,
                    pos = data.pos,
                    radius = data.radius,
                    height = data.height
                })

            ::continue::
        end
    end

    nodeos.createProcess(listen_getWorldBlocks, { isService = true, title = "listen_getWorldBlocks" })
    -- local getBlockNameFromPartialName_cache = {}
    function getBlockNameFromPartialName(partialName)
        if interestingBlocks[partialName] then
            return partialName
        end
        if not partialName then
            return nil
        end
        -- if getBlockNameFromPartialName_cache[partialName] then
        --     return getBlockNameFromPartialName_cache[partialName]
        -- end
        for i, v in pairs(interestingBlocks) do
            if string.find(i, partialName) then
                -- getBlockNameFromPartialName_cache[partialName] = i
                return i
            end
        end
        return nil
    end

    function listen_getInterestingBlocks()
        nodeos.logging.debug("GPSService", "Starting interesting blocks listener")
        while true do
            local cid, msg = nodeos.net.receive("NodeOS_getInterestingBlocks")
            if not msg or not msg.data then
                nodeos.logging.error("GPSService", "Received invalid getInterestingBlocks request from #" .. cid)
                nodeos.net.respond(cid, msg and msg.token, {
                    success = false,
                    message = "Invalid request format"
                })
                goto continue
            end

            local data = msg.data
            local blockName = nil

            -- Validate different request modes
            if data.all then
                -- All blocks mode
                if not data.name then
                    nodeos.logging.error("GPSService",
                        "Missing name parameter in getInterestingBlocks all request from #" .. cid)
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Missing name parameter for all blocks request"
                    })
                    goto continue
                end

                blockName = getBlockNameFromPartialName(data.name)
            else
                -- Radius mode
                if not data.pos or not data.radius or not data.height or not data.name then
                    nodeos.logging.error("GPSService",
                        "Missing required parameters in getInterestingBlocks radius request from #" .. cid)
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Missing required parameters: pos, radius, height, and name are required"
                    })
                    goto continue
                end

                if not data.pos.x or not data.pos.y or not data.pos.z then
                    nodeos.logging.error("GPSService",
                        "Incomplete position in getInterestingBlocks request from #" .. cid)
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "Position must include x, y, and z coordinates"
                    })
                    goto continue
                end

                blockName = getBlockNameFromPartialName(data.name)
            end

            nodeos.logging.debug("GPSService", "block req from #" .. cid .. " for " .. (blockName or "nil"))

            -- Start timing
            local startTime = os.clock()

            if data.all then
                if not blockName then
                    nodeos.logging.error("GPSService",
                        "No matching block name found in getInterestingBlocks all request from #" .. cid)
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        blocks = {},
                        name = nil
                    })
                    goto continue
                end
                -- Handle request for all known blocks of a specific type
                if interestingBlocks[blockName] then
                    -- Create a copy to avoid sending the 'changed' flag
                    local responseBlocks = {}
                    for x, yTable in pairs(interestingBlocks[blockName]) do
                        if type(x) == "number" then -- Ensure we only copy coordinate data
                            responseBlocks[x] = {}
                            for y, zTable in pairs(yTable) do
                                responseBlocks[x][y] = {}
                                for z, val in pairs(zTable) do
                                    responseBlocks[x][y][z] = val
                                end
                            end
                        end
                    end

                    local execTime = os.clock() - startTime
                    nodeos.logging.debug("GPSService", "All blocks req completed in " .. execTime .. "s")
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        blocks = responseBlocks,
                        name = blockName
                    })
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        blocks = {},
                        name = blockName
                    })
                end
            else
                -- Handle request for blocks within a radius
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

                local tmpBlocks = {} -- Blocks matching the specific request within the radius

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
                                if not interestingBlocksBlacklist[currentBlockName] then
                                    -- Handle deepslate prefix optimization
                                    if string.sub(currentBlockName, 1, deepslatePrefixLen) == deepslatePrefix then
                                        currentBlockName = minecraftPrefix ..
                                            string.sub(currentBlockName, deepslatePrefixLen + 1)
                                    end

                                    -- Update global interestingBlocks cache
                                    if not interestingBlocks[currentBlockName] then
                                        interestingBlocks[currentBlockName] = { changed = true }
                                    end
                                    interestingBlocks[currentBlockName].changed = true
                                    if not interestingBlocks[currentBlockName][posX] then
                                        interestingBlocks[currentBlockName][posX] = {}
                                    end
                                    if not interestingBlocks[currentBlockName][posX][posY] then
                                        interestingBlocks[currentBlockName][posX][posY] = {}
                                    end
                                    interestingBlocks[currentBlockName][posX][posY][posZ] = 1

                                    -- Determine the actual blockName if not already found (only needed if initial data.name was partial)
                                    if not blockName then
                                        if string.find(currentBlockName, data.name) then
                                            blockName = currentBlockName
                                        end
                                    end

                                    -- Add to tmpBlocks if it matches the requested blockName
                                    if currentBlockName == blockName then
                                        if not tmpBlocks[posX] then
                                            tmpBlocks[posX] = {}
                                        end
                                        if not tmpBlocks[posX][posY] then
                                            tmpBlocks[posX][posY] = {}
                                        end
                                        tmpBlocks[posX][posY][posZ] = 1
                                    end
                                end
                            elseif blockName then -- Only check for air removal if we have a specific blockName we are interested in
                                -- Current block is air (or nil), check if we need to remove it from the global cache
                                if interestingBlocks[blockName] and interestingBlocks[blockName][posX] and
                                    interestingBlocks[blockName][posX][posY] and
                                    interestingBlocks[blockName][posX][posY][posZ] then
                                    interestingBlocks[blockName][posX][posY][posZ] = nil
                                    interestingBlocks[blockName].changed = true -- Mark for saving

                                    -- Clean up empty nested tables
                                    if not next(interestingBlocks[blockName][posX][posY]) then
                                        interestingBlocks[blockName][posX][posY] = nil
                                        if not next(interestingBlocks[blockName][posX]) then
                                            interestingBlocks[blockName][posX] = nil
                                            -- Check if the entire block type entry is now empty (except 'changed')
                                            local isEmpty = true
                                            for k, _ in pairs(interestingBlocks[blockName]) do
                                                if k ~= "changed" then
                                                    isEmpty = false
                                                    break
                                                end
                                            end
                                            if isEmpty then
                                                interestingBlocks[blockName] = nil
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                local execTime = os.clock() - startTime
                nodeos.logging.debug("GPSService", "Radius block req completed in " .. execTime .. "s")
                nodeos.net.respond(cid, msg.token, {
                    success = true,
                    blocks = tmpBlocks,
                    pos = data.pos,
                    radius = data.radius,
                    height = data.height,
                    name = blockName
                })
            end

            ::continue::
        end
    end

    nodeos.createProcess(listen_getInterestingBlocks, { isService = true, title = "listen_getInterestingBlocks" })

    function listen_removeInterestingblock()
        nodeos.logging.debug("GPSService", "Starting remove interesting block listener")
        while true do
            local cid, msg = nodeos.net.receive("NodeOS_removeInterestingblock")
            local data = msg.data

            nodeos.logging.debug("GPSService",
                "Received request to remove interesting block from computer #" .. cid .. " for block: " .. data.name)
            if interestingBlocks[data.name] and interestingBlocks[data.name][data.pos.x] and
                interestingBlocks[data.name][data.pos.x][data.pos.y] and
                interestingBlocks[data.name][data.pos.x][data.pos.y][data.pos.z] then
                interestingBlocks[data.name][data.pos.x][data.pos.y][data.pos.z] = nil
                interestingBlocks[data.name].changed = true
                if (not next(interestingBlocks[data.name][data.pos.x][data.pos.y])) then
                    interestingBlocks[data.name][data.pos.x][data.pos.y] = nil
                    if (not next(interestingBlocks[data.name][data.pos.x])) then
                        interestingBlocks[data.name][data.pos.x] = nil
                    end
                end
            end
        end
    end

    nodeos.createProcess(listen_removeInterestingblock, { isService = true, title = "service_removeInterestingblock" })

    function listen_getInterestingBlocksBlacklist()
        nodeos.logging.debug("GPSService", "Starting interesting blocks blacklist listener")
        while true do
            local cid, msg = nodeos.net.receive("NodeOS_getInterestingBlocksBlacklist")
            nodeos.logging.debug("GPSService",
                "Received request for interesting blocks blacklist from computer #" .. cid)
            nodeos.net.respond(cid, msg.token, interestingBlocksBlacklist)
        end
    end

    nodeos.createProcess(listen_getInterestingBlocksBlacklist, {
        isService = true,
        title =
        "service_getInterestingBlocksBlacklist"
    })

    function saveServerBlocks()
        while true do
            for i, v in pairs(interestingBlocks) do
                if v.changed then
                    v.changed = false
                    -- replace : with -
                    local fileName = string.gsub(i, ":", "-")
                    local file = fs.open(interestingBlocks_path .. "/" .. fileName .. ".dat", "w")
                    file.write(textutils.serialize(v))
                    file.close()
                end
            end
            sleep(60)
        end
    end

    function loadServerBlocks()
        nodeos.logging.debug("GPSService", "Loading interesting blocks from disk")
        --for every .dat file in interestingBlocks_path
        for i, v in pairs(fs.list(interestingBlocks_path)) do
            if string.find(v, ".dat") then
                local file = fs.open(interestingBlocks_path .. "/" .. v, "r")
                local data = textutils.unserialize(file.readAll())
                file.close()
                local key = string.sub(v, 1, -5)
                key = string.gsub(key, "-", ":")
                interestingBlocks[key] = data
            end
        end
    end

    loadServerBlocks()
    nodeos.createProcess(saveServerBlocks, { isService = true, title = "service_saveBlocks" })
end


function trimLocalComputers()
    while true do
        local localComputers = nodeos.gps.getLocalComputers()
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
        nodeos.gps.saveLocalComputers(localComputers)
        os.sleep(10)
    end
end

nodeos.createProcess(trimLocalComputers, { isService = true, title = "service_trimLocalComputers" })

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
        local cid, msg = nodeos.net.receive("NodeOS_getPlayers")
        nodeos.logging.debug("GPSService", "Players req from #" .. cid)
        local players = getPlayers()
        nodeos.net.respond(cid, msg.token, players)
    end
end

nodeos.createProcess(listen_getPlayers, { isService = true, title = "listen_getPlayers" })

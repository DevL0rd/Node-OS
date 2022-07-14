local gps = require("/lib/gps")
local net = require("/lib/net")
local util = require("/lib/util")
local file = util.loadModule("file")
local settings = require("/lib/settings").settings
local worldDepthLimit = -59
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
                isTurtle = turtle ~= nil,
                groups = settings.groups,
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
function Set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

if os.getComputerID() == settings.master then
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
    local serverTiles_path = "etc/map/serverTiles.dat"
    local serverTiles = {}
    local serverTiles_changed = false
    if not fs.exists(serverTiles_path) then
        file.writeTable(serverTiles_path, serverTiles)
    else
        serverTiles = file.readTable(serverTiles_path)
    end
    local interestingTiles_path = "etc/map/interestingTiles.dat"
    local interestingTiles = {}
    local interestingTiles_changed = false
    if not fs.exists(interestingTiles_path) then
        file.writeTable(interestingTiles_path, interestingTiles)
    else
        interestingTiles = file.readTable(interestingTiles_path)
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
                serverTiles_changed = true
                net.respond(cid, msg.token, tmpTiles)
            end
        end
    end

    parallel.addOSThread(listen_getWorldTiles)

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
                                    if not interestingTiles[block.name] then
                                        interestingTiles[block.name] = {}
                                    end
                                    if not interestingTiles[block.name][posX] then
                                        interestingTiles[block.name][posX] = {}
                                    end
                                    if not interestingTiles[block.name][posX][posY] then
                                        interestingTiles[block.name][posX][posY] = {}
                                    end
                                    if not interestingTiles[block.name][posX][posY][posZ] then
                                        interestingTiles[block.name][posX][posY][posZ] = 1
                                        interestingTiles_changed = true
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

    parallel.addOSThread(listen_getInterestingTiles)

    function saveServerTiles()
        while true do
            if interestingTiles_changed then
                file.writeTable(interestingTiles_path, interestingTiles)
                interestingTiles_changed = false
            end
            if serverTiles_changed then
                file.writeTable(serverTiles_path, serverTiles)
                serverTiles_changed = false
            end
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
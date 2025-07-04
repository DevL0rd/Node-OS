local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("GPS", "Initializing GPS module")

    local _locate = gps.locate
    local gps = gps
    gps.worldBlocks = {}
    gps.interestingBlocks = {}
    local gps_settings_path = "etc/gps/settings.cfg"
    local localComputers_path = "etc/gps/localComputers.dat"
    gps.settings = loadTable(gps_settings_path)
    gps.isConnected = false
    gps.status = "Idle"
    gps.target = nil

    function gps.setTarget(target)
        nodeos.logging.debug("GPS", "Setting target to: " .. textutils.serialize(target))
        gps.target = target
    end

    function gps.clearTarget()
        nodeos.logging.debug("GPS", "Clearing target")
        gps.target = nil
    end

    function gps.getTarget()
        return gps.target
    end

    function gps.getTargetDistance()
        local gpsPos = gps.getPosition()
        if gpsPos and gps.target then
            return gps.getDistance(gpsPos, gps.target)
        end
        return nil
    end

    function gps.setStatus(status)
        gps.status = status
    end

    function gps.clearStatus()
        gps.status = "Idle"
    end

    function gps.getStatus()
        return gps.status
    end

    function gps.saveSettings(ns)
        saveTable(gps_settings_path, ns)
    end

    function gps.getSettings()
        return gps.settings
    end

    function gps.getLocalComputers()
        return gps.localComputers
    end

    function gps.getComputer(id)
        local localComputers = gps.getLocalComputers()
        if localComputers[id] then
            return localComputers[id]
        end
        return nil
    end

    function gps.saveLocalComputers(computers)
        saveTable(localComputers_path, computers)
    end

    gps.directions = {
        north = 0,
        east = 1,
        south = 2,
        west = 3
    }
    if not gps.settings then
        gps.settings = {
            offset = {
                x = 0,
                y = 0,
                z = 0
            }
        }
        gps.saveSettings(gps.settings)
    end


    gps.localComputers = loadTable(localComputers_path)
    if not gps.localComputers then
        gps.localComputers = {}
        gps.saveLocalComputers(gps.localComputers)
    end

    function Set(list)
        local set = {}
        for _, l in ipairs(list) do set[l] = true end
        return set
    end

    function gps.resolveComputersByString(str, mustBePaired, mustBeTurtle)
        local cIds = {}
        if str == "-" then
            local cPC = gps.getClosestPC(mustBePaired, mustBeTurtle)
            if not cPC then
                return nil
            end
            table.insert(cIds, cPC.id)
        else
            local computers = gps.getComputersInGroup(str, mustBePaired, mustBeTurtle)
            if #computers == 0 then
                local cId = nil
                cId = gps.getComputerID(str)
                if not cId then
                    cId = tonumber(str)
                end
                if not cId then
                    return nil
                end
                table.insert(cIds, cId)
            else
                for i = 1, #computers do
                    table.insert(cIds, computers[i].id)
                end
            end
        end
        return cIds
    end

    function gps.getComputersInGroup(group, mustBePaired, mustBeTurtle)
        local localComputers = gps.getLocalComputers()
        local groupComputers = {}

        if mustBePaired then
            local filteredPCS = {}
            local pairedComputers = nodeos.net.getPairedDevices()
            for id, computer in pairs(localComputers) do
                if pairedComputers[computer.id] then
                    table.insert(filteredPCS, computer)
                end
            end
            localComputers = filteredPCS
        end
        if mustBeTurtle then
            local filteredPCS = {}
            for i, computer in pairs(localComputers) do
                if computer.isTurtle then
                    table.insert(filteredPCS, computer)
                end
            end
            localComputers = filteredPCS
        end
        for i, computer in pairs(localComputers) do
            if computer.groups then
                local compsGroups = Set(computer.groups)
                if compsGroups[group] then
                    table.insert(groupComputers, computer)
                end
            end
        end
        return groupComputers
    end

    function gps.getClosestPC(mustBePaired, mustBeTurtle)
        local gpsPos = gps.getPosition()
        local localComputers = gps.getLocalComputers()
        if gpsPos then
            if mustBePaired then
                local filteredPCS = {}
                local pairedComputers = nodeos.net.getPairedDevices()
                for id, computer in pairs(localComputers) do
                    if pairedComputers[computer.id] then
                        table.insert(filteredPCS, computer)
                    end
                end
                localComputers = filteredPCS
            end
            if mustBeTurtle then
                local filteredPCS = {}
                for i, computer in pairs(localComputers) do
                    if computer.isTurtle then
                        table.insert(filteredPCS, computer)
                    end
                end
                localComputers = filteredPCS
            end
            local closestDist = nil
            local closestPC = nil
            for id, computer in pairs(localComputers) do
                if computer.pos then
                    local dist = gps.getDistance(computer.pos, gpsPos)
                    if closestDist == nil or dist < closestDist then
                        closestDist = dist
                        closestPC = computer
                    end
                end
            end
            return closestPC
        end
        return nil
    end

    local failedgpscount = 0
    local oldPos = nil
    local oldDir = gps.directions.north
    local lastPoll = 0

    function gps.getDirectionTraveled(posFirst, posSecond)
        local deltaX = posSecond.x - posFirst.x
        local deltaZ = posSecond.z - posFirst.z

        -- Determine which axis had the larger change
        if math.abs(deltaX) > math.abs(deltaZ) then
            -- X-axis had larger change
            if deltaX > 0 then
                oldDir = gps.directions.east
            else
                oldDir = gps.directions.west
            end
        elseif math.abs(deltaZ) > math.abs(deltaX) then
            -- Z-axis had larger change (or equal, defaulting to Z)
            if deltaZ > 0 then
                oldDir = gps.directions.south
            else
                oldDir = gps.directions.north
            end
        end
        return oldDir
    end

    function gps.getDirectionString(dir)
        if dir == gps.directions.north then
            return "north"
        elseif dir == gps.directions.east then
            return "east"
        elseif dir == gps.directions.south then
            return "south"
        elseif dir == gps.directions.west then
            return "west"
        end
        return "unknown (" .. dir .. ")"
    end

    function gps.getPosition(roundNumber)
        timeDiff = os.time() - lastPoll
        if timeDiff < 0 then
            timeDiff = -timeDiff
        end
        if timeDiff >= 0.001 then
            lastPoll = os.time() + 0.001
            local px, py, pz = _locate(5)
            if px and (not isNan(px)) then
                px = px + gps.settings.offset.x
                py = py + gps.settings.offset.y
                pz = pz + gps.settings.offset.z
                local d = gps.directions.north
                if oldPos then
                    d = gps.getDirectionTraveled(oldPos, { x = px, y = py, z = pz })
                end
                oldPos = { x = px, y = py, z = pz, d = d }
                gps.isConnected = true
            else
                failedgpscount = failedgpscount + 1
                if failedgpscount > 5 then
                    failedgpscount = 0
                    oldPos = nil
                    gps.isConnected = false
                    nodeos.logging.warn("GPS", "GPS connection lost after multiple failed attempts")
                end
            end
        end
        if roundNumber and oldPos then
            return {
                x = math.floor(oldPos.x),
                y = math.floor(oldPos.y),
                z = math.floor(oldPos.z),
                d = oldPos.d
            }
        else
            return oldPos
        end
    end

    function gps.getDistance(pos1, pos2, roundNumber)
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        local dz = pos1.z - pos2.z
        if roundNumber then
            return math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
        else
            return math.sqrt(dx * dx + dy * dy + dz * dz)
        end
    end

    function gps.setOffset(pos)
        nodeos.logging.info("GPS", "Setting position offset to " .. textutils.serialize(pos))
        local px, py, pz = _locate(5)
        if px and (not isNan(px)) then
            gps.settings.offset.x = pos.x - px
            gps.settings.offset.y = pos.y - py
            gps.settings.offset.z = pos.z - pz
            gps.saveSettings(gps.settings)
            nodeos.logging.info("GPS", "Offset set successfully")
            return true
        else
            nodeos.logging.error("GPS", "Failed to set offset: couldn't get current position")
            return false
        end
    end

    function gps.setWorldBlocks(pos, radius, height, blocks) --very optimized sync
        --emulate get
        local data = {}
        data.pos = pos
        data.radius = math.min(math.floor(radius), 10)
        data.height = math.floor(math.min(height, 9) / 2)

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
        for posX = mx, mx2 do
            for posY = my, my2 do
                for posZ = mz, mz2 do
                    -- print(posX .. " " .. posY .. " " .. posZ .. " " .. name)
                    if blocks[posX] and blocks[posX][posY] and blocks[posX][posY][posZ] then
                        local block = {}
                        block.x = posX
                        block.y = posY
                        block.z = posZ
                        block.name = blocks[posX][posY][posZ]
                        if not gps.worldBlocks[posX] then
                            gps.worldBlocks[posX] = {}
                        end
                        if not gps.worldBlocks[posX][posY] then
                            gps.worldBlocks[posX][posY] = {}
                        end
                        if not gps.worldBlocks[posX][posY][posZ] then
                            gps.worldBlocks[posX][posY][posZ] = {}
                        end
                        gps.worldBlocks[posX][posY][posZ] = block
                    elseif gps.worldBlocks[posX] and gps.worldBlocks[posX][posY] and gps.worldBlocks[posX][posY][posZ] then
                        gps.worldBlocks[posX][posY][posZ] = nil --shitty map compression lol
                        if (not next(gps.worldBlocks[posX][posY])) then
                            gps.worldBlocks[posX][posY] = nil
                            if (not next(gps.worldBlocks[posX])) then
                                gps.worldBlocks[posX] = nil
                            end
                        end
                    end
                end
            end
        end
    end

    function gps.setInterestingBlocks(pos, radius, height, name, blocks) --very optimized sync
        --emulate get
        local data = {}
        data.pos = pos
        data.radius = math.min(math.floor(radius), 10)
        data.height = math.floor(math.min(height, 9) / 2)

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
        for posX = mx, mx2 do
            for posY = my, my2 do
                for posZ = mz, mz2 do
                    if blocks[posX] and blocks[posX][posY] and blocks[posX][posY][posZ] then
                        if not gps.interestingBlocks[name] then
                            gps.interestingBlocks[name] = {}
                        end
                        if not gps.interestingBlocks[name][posX] then
                            gps.interestingBlocks[name][posX] = {}
                        end
                        if not gps.interestingBlocks[name][posX][posY] then
                            gps.interestingBlocks[name][posX][posY] = {}
                        end
                        if not gps.interestingBlocks[name][posX][posY][posZ] then
                            gps.interestingBlocks[name][posX][posY][posZ] = 1
                        end
                    elseif gps.interestingBlocks[name] and gps.interestingBlocks[name][posX] and
                        gps.interestingBlocks[name][posX][posY] and gps.interestingBlocks[name][posX][posY][posZ] then
                        gps.interestingBlocks[name][posX][posY][posZ] = nil --shitty map compression lol
                        if (not next(gps.interestingBlocks[name][posX][posY])) then
                            gps.interestingBlocks[name][posX][posY] = nil
                            if (not next(gps.interestingBlocks[name][posX])) then
                                gps.interestingBlocks[name][posX] = nil
                                if (not next(gps.interestingBlocks[name])) then
                                    gps.interestingBlocks[name] = nil
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- local getBlockNameFromPartialName_cache = {}
    function getBlockNameFromPartialName(partialName)
        if gps.interestingBlocks[partialName] then
            return partialName
        end
        -- if getBlockNameFromPartialName_cache[partialName] then
        --     return getBlockNameFromPartialName_cache[partialName]
        -- end
        for i, v in pairs(gps.interestingBlocks) do
            if string.find(i, partialName) then
                -- getBlockNameFromPartialName_cache[partialName] = i
                return i
            end
        end
        return nil
    end

    function gps.findBlock(name)
        nodeos.logging.debug("GPS", "Searching for block: " .. name)
        local blockName = getBlockNameFromPartialName(name)
        if not blockName then
            nodeos.logging.debug("GPS", "No matching block found for name: " .. name)
            return nil
        end
        if not gps.interestingBlocks then
            nodeos.logging.debug("GPS", "No interesting blocks data available")
            return nil
        end
        local gpsPos = gps.getPosition()
        if not gpsPos then
            nodeos.logging.debug("GPS", "Cannot find block: no GPS position available")
            return nil
        end
        local x = math.floor(gpsPos.x)
        local y = math.floor(gpsPos.y)
        local z = math.floor(gpsPos.z)
        local r = 1
        local maxR = 256
        for r = 1, maxR do
            local x2 = x - r
            local y2 = y - r
            local z2 = z - r
            local x2e = x2 + r * 2
            local y2e = y2 + r * 2
            local z2e = z2 + r * 2
            if y2e < -63 then
                y2e = -63
            end
            for x3 = x2, x2e do
                if gps.interestingBlocks[blockName][x3] then
                    for y3 = y2, y2e do
                        if gps.interestingBlocks[blockName][x3][y3] then
                            for z3 = z2, z2e do
                                if x3 > x2 and x3 < x2e and y3 > y2 and y3 < y2e then -- inside on the x slice
                                    if z3 > z2 then                                   -- inside on the z slice
                                        z3 = z2e
                                    end
                                end
                                if gps.interestingBlocks[blockName][x3][y3][z3] then
                                    local result = { x = x3, y = y3, z = z3, name = blockName }
                                    nodeos.logging.info("GPS",
                                        "Found " .. blockName .. " at " .. result.x .. "," .. result.y .. "," .. result
                                        .z)
                                    return result
                                end
                            end
                        end
                    end
                end
            end
        end
        nodeos.logging.debug("GPS", "No " .. blockName .. " found in search radius")
        return nil
    end

    function gps.isUnderSomething(pos)
        local checkHeight = 5
        if not pos then
            pos = gps.getPosition()
        end
        if not pos then
            return false
        end
        local x = math.floor(pos.x)
        local y = math.floor(pos.y)
        local z = math.floor(pos.z)

        local isUnderSomething = false

        for i = 1, checkHeight do
            if gps.worldBlocks[x] and gps.worldBlocks[x][y + i] and gps.worldBlocks[x][y + i][z] then
                local block = gps.worldBlocks[x][y + i][z]
                if block then
                    -- Check if block name contains glass or leaves
                    local blockName = block.name or ""
                    local isTransparent = string.find(string.lower(blockName), "glass") or
                        string.find(string.lower(blockName), "leaves")

                    if not isTransparent then
                        isUnderSomething = true
                        break
                    end
                end
            end
        end
        return isUnderSomething
    end

    function gps.getWorldBlocks(radius, height, pos)
        nodeos.logging.debug("GPS", "Getting world blocks with radius " .. radius .. " and height " .. height)

        if not pos then
            pos = gps.getPosition()
        end

        if not pos then
            nodeos.logging.warn("GPS", "Cannot get world blocks: no position available")
            return gps.worldBlocks
        end

        local maxRadius = 10
        local maxHeight = 9

        -- Ensure radius and height are numbers and at least 1
        radius = math.max(1, math.floor(tonumber(radius) or 1))
        height = math.max(1, math.floor(tonumber(height) or 1))

        if radius <= maxRadius and height <= maxHeight then
            -- Request fits within limits, proceed as before
            local res = nodeos.net.emit("NodeOS_getWorldBlocks", { radius = radius, height = height, pos = pos },
                nodeos.settings.settings.master)
            if res and res.success then
                gps.setWorldBlocks(pos, radius, height, res.blocks)
            end
        else
            -- Request exceeds limits, split into chunks
            local chunkRadius = maxRadius
            local chunkHeight = maxHeight
            -- Calculate the actual scan dimensions based on how setWorldBlocks interprets radius/height
            local chunkScanRadius = chunkRadius                     -- 10
            local chunkScanHalfHeight = math.floor(chunkHeight / 2) -- 4
            local chunkSpanH = chunkScanRadius * 2 + 1              -- 21 (Horizontal diameter)
            local chunkSpanV = chunkScanHalfHeight * 2 + 1          -- 9 (Vertical span)

            -- Calculate total area bounds based on the *requested* radius and height
            local reqScanHalfHeight = math.floor(height / 2)
            local minX = pos.x - radius
            local maxX = pos.x + radius
            local minY = pos.y - reqScanHalfHeight
            local maxY = pos.y + reqScanHalfHeight
            local minZ = pos.z - radius
            local maxZ = pos.z + radius

            -- Iterate through chunks based on their bottom-south-west corner
            -- The step size is the span of each chunk
            for startY = minY, maxY, chunkSpanV do
                for startX = minX, maxX, chunkSpanH do
                    for startZ = minZ, maxZ, chunkSpanH do
                        -- Calculate the center of this chunk for the request
                        -- The center is the start corner + half the chunk's dimensions
                        local chunkCenterX = startX + chunkScanRadius
                        local chunkCenterY = startY + chunkScanHalfHeight
                        local chunkCenterZ = startZ + chunkScanRadius
                        local chunkPos = { x = chunkCenterX, y = chunkCenterY, z = chunkCenterZ }

                        local res = nodeos.net.emit("NodeOS_getWorldBlocks",
                            { radius = chunkRadius, height = chunkHeight, pos = chunkPos },
                            nodeos.settings.settings.master)

                        if res and res.success then
                            -- Use the chunk's center, radius, and height for setting blocks
                            gps.setWorldBlocks(chunkPos, chunkRadius, chunkHeight, res.blocks)
                        end
                        -- Small sleep to avoid overwhelming the network or target computer
                        os.sleep(0.1)
                    end
                end
            end
        end

        return gps.worldBlocks
    end

    function gps.getInterestingBlocks(radius, height, name, pos)
        if not pos then
            pos = gps.getPosition()
        end

        if not pos then
            -- Cannot proceed without a position
            return gps.interestingBlocks -- Return current data, possibly empty
        end

        local maxRadius = 10
        local maxHeight = 9

        -- Ensure radius and height are numbers and at least 1
        radius = math.max(1, math.floor(tonumber(radius) or 1))
        height = math.max(1, math.floor(tonumber(height) or 1))
        local fullName = name
        if radius <= maxRadius and height <= maxHeight then
            -- Request fits within limits, proceed as before
            local res = nodeos.net.emit("NodeOS_getInterestingBlocks",
                { radius = radius, height = height, name = name, pos = pos },
                nodeos.settings.settings.master)
            if res and res.success then
                gps.setInterestingBlocks(pos, radius, height, res.name, res.blocks)
                fullName = res.name
            end
        else
            -- Request exceeds limits, split into chunks
            local chunkRadius = maxRadius
            local chunkHeight = maxHeight
            -- Calculate the actual scan dimensions based on how setWorldBlocks interprets radius/height
            local chunkScanRadius = chunkRadius                     -- 10
            local chunkScanHalfHeight = math.floor(chunkHeight / 2) -- 4
            local chunkSpanH = chunkScanRadius * 2 + 1              -- 21 (Horizontal diameter)
            local chunkSpanV = chunkScanHalfHeight * 2 + 1          -- 9 (Vertical span)

            -- Calculate total area bounds based on the *requested* radius and height
            local reqScanHalfHeight = math.floor(height / 2)
            local minX = pos.x - radius
            local maxX = pos.x + radius
            local minY = pos.y - reqScanHalfHeight
            local maxY = pos.y + reqScanHalfHeight
            local minZ = pos.z - radius
            local maxZ = pos.z + radius

            -- Iterate through chunks based on their bottom-south-west corner
            -- The step size is the span of each chunk
            for startY = minY, maxY, chunkSpanV do
                for startX = minX, maxX, chunkSpanH do
                    for startZ = minZ, maxZ, chunkSpanH do
                        -- Calculate the center of this chunk for the request
                        -- The center is the start corner + half the chunk's dimensions
                        local chunkCenterX = startX + chunkScanRadius
                        local chunkCenterY = startY + chunkScanHalfHeight
                        local chunkCenterZ = startZ + chunkScanRadius
                        local chunkPos = { x = chunkCenterX, y = chunkCenterY, z = chunkCenterZ }

                        local res = nodeos.net.emit("NodeOS_getInterestingBlocks",
                            { radius = chunkRadius, height = chunkHeight, name = name, pos = chunkPos },
                            nodeos.settings.settings.master)

                        if res and res.success then
                            -- Use the chunk's center, radius, and height for setting blocks
                            gps.setInterestingBlocks(chunkPos, chunkRadius, chunkHeight, res.name, res.blocks)
                            fullName = res.name
                        end

                        -- Small sleep to avoid overwhelming the network or target computer
                        os.sleep(0.1)
                    end
                end
            end
        end

        return {
            name = fullName,
            blocks = gps.interestingBlocks[fullName]
        }
    end

    function gps.getAllInterestingBlocks(name)
        local res = nodeos.net.emit("NodeOS_getInterestingBlocks", { all = true, name = name },
            nodeos.settings.settings.master)
        if res and res.success then
            if not gps.interestingBlocks[res.name] then
                gps.interestingBlocks[res.name] = {}
            end
            gps.interestingBlocks[res.name] = res.blocks
            return res
        end
        return nil
    end

    function gps.getInterestingBlocksBlacklist()
        local res = nodeos.net.emit("NodeOS_getInterestingBlocksBlacklist", {}, nodeos.settings.settings.master)
        if res then
            gps.interestingBlocksBlacklist = res
            return gps.interestingBlocksBlacklist
        end
        return nil
    end

    function gps.removeInterestingblock(name, pos)
        if not gps.interestingBlocks[name] then
            return
        end
        if not gps.interestingBlocks[name][pos.x] then
            return
        end
        if not gps.interestingBlocks[name][pos.x][pos.y] then
            return
        end
        if not gps.interestingBlocks[name][pos.x][pos.y][pos.z] then
            return
        end
        gps.interestingBlocks[name][pos.x][pos.y][pos.z] = nil
        if (not next(gps.interestingBlocks[name][pos.x][pos.y])) then
            gps.interestingBlocks[name][pos.x][pos.y] = nil
            if (not next(gps.interestingBlocks[name][pos.x])) then
                gps.interestingBlocks[name][pos.x] = nil
                if (not next(gps.interestingBlocks[name])) then
                    gps.interestingBlocks[name] = nil
                end
            end
        end
        nodeos.net.emit("NodeOS_removeInterestingblock", {
            name = name,
            pos = pos
        }, nodeos.settings.settings.master, true)
    end

    function gps.getBlocksByDistance(name)
        if not gps.interestingBlocks[name] then
            return nil
        end
        local gpsPos = gps.getPosition()
        if not gpsPos then
            return nil
        end
        local blocks = {}
        for x, v in pairs(gps.interestingBlocks[name]) do
            if x ~= "changed" then
                for y, v2 in pairs(v) do
                    for z, v3 in pairs(v2) do
                        local pos = { x = x, y = y, z = z }
                        local distance = gps.getDistance(gpsPos, pos)
                        table.insert(blocks, { pos = pos, distance = distance })
                    end
                end
            end
        end
        table.sort(blocks, function(a, b) return a.distance < b.distance end)
        return blocks
    end

    function gps.getComputerID(name)
        local lComps = gps.getLocalComputers()
        for i, comp in pairs(lComps) do
            if comp.name == name then
                return comp.id
            end
        end
        return nil
    end

    function gps.getComputerName(id)
        local lComps = gps.getLocalComputers()
        if lComps[id] then
            return lComps[id].name
        end
        return nil
    end

    nodeos.logging.info("GPS", "GPS module initialization complete")
    nodeos.gps = gps
end

return module

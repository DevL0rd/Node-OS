local util = require("/lib/util")
local file = util.loadModule("file")
local net = require("/lib/net")
local settings = require("/lib/settings").settings
require("/lib/misc")
local _locate = gps.locate
local gps = {}
gps.worldTiles = {}
gps.interestingTiles = {}
local gps_settings_path = "etc/gps/settings.cfg"
local localComputers_path = "etc/gps/localComputers.dat"
gps.settings = {
    offset = {
        x = 0,
        y = 0,
        z = 0
    }
}
function gps.getSettings()
    local ns = file.readTable(gps_settings_path)
    if not ns then
        gps.saveSettings(gps.settings)
        return gps.settings
    end
    gps.settings = ns
    return ns
end

function gps.saveSettings(ns)
    file.writeTable(gps_settings_path, ns)
end

gps.getSettings()

gps.localComputers = {}
function gps.getLocalComputers()
    local computers = file.readTable(localComputers_path)
    if not computers then
        gps.saveLocalComputers(gps.localComputers)
        return gps.localComputers
    end
    gps.localComputers = computers
    return gps.localComputers
end

function gps.saveLocalComputers(computers)
    file.writeTable(localComputers_path, computers)
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
        local pairedComputers = net.getPairedDevices()
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
            local pairedComputers = net.getPairedDevices()
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

function round(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

local failedgpscount = 0
local oldPos = nil
local lastPoll = 0
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
            oldPos = { x = px, y = py, z = pz }
        else
            failedgpscount = failedgpscount + 1
            if failedgpscount > 5 then
                failedgpscount = 0
                oldPos = nil
            end
        end
    end
    if roundNumber and oldPos then
        return {
            x = round(oldPos.x),
            y = round(oldPos.y),
            z = round(oldPos.z)
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
        return round(math.sqrt(dx * dx + dy * dy + dz * dz))
    else
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end
end

function gps.setOffset(pos)
    local gpsPos = gps.getPosition()
    if gpsPos then
        gps.settings.offset.x = pos.x - gpsPos.x
        gps.settings.offset.y = pos.y - gpsPos.y
        gps.settings.offset.z = pos.z - gpsPos.z
        gps.saveSettings(gps.settings)
        return true
    else
        return false
    end
end

function gps.setWorldTiles(pos, radius, height, blocks) --very optimized sync
    --emulate get
    local data = {}
    data.pos = pos
    data.radius = radius
    data.height = height

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
                    if not gps.worldTiles[posX] then
                        gps.worldTiles[posX] = {}
                    end
                    if not gps.worldTiles[posX][posY] then
                        gps.worldTiles[posX][posY] = {}
                    end
                    if not gps.worldTiles[posX][posY][posZ] then
                        gps.worldTiles[posX][posY][posZ] = {}
                    end
                    gps.worldTiles[posX][posY][posZ] = block
                elseif gps.worldTiles[posX] and gps.worldTiles[posX][posY] and gps.worldTiles[posX][posY][posZ] then
                    gps.worldTiles[posX][posY][posZ] = nil --shitty map compression lol
                    if (not next(gps.worldTiles[posX][posY])) then
                        gps.worldTiles[posX][posY] = nil
                        if (not next(gps.worldTiles[posX])) then
                            gps.worldTiles[posX] = nil
                        end
                    end
                end
            end
        end
    end
end

function gps.setInterestingTiles(pos, radius, height, name, blocks) --very optimized sync
    --emulate get
    local data = {}
    data.pos = pos
    data.radius = radius
    data.height = height

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
                    if not gps.interestingTiles[name] then
                        gps.interestingTiles[name] = {}
                    end
                    if not gps.interestingTiles[name][posX] then
                        gps.interestingTiles[name][posX] = {}
                    end
                    if not gps.interestingTiles[name][posX][posY] then
                        gps.interestingTiles[name][posX][posY] = {}
                    end
                    if not gps.interestingTiles[name][posX][posY][posZ] then
                        gps.interestingTiles[name][posX][posY][posZ] = 1
                    end
                elseif gps.interestingTiles[name] and gps.interestingTiles[name][posX] and
                    gps.interestingTiles[name][posX][posY] and gps.interestingTiles[name][posX][posY][posZ] then
                    gps.interestingTiles[name][posX][posY][posZ] = nil --shitty map compression lol
                    if (not next(gps.interestingTiles[name][posX][posY])) then
                        gps.interestingTiles[name][posX][posY] = nil
                        if (not next(gps.interestingTiles[name][posX])) then
                            gps.interestingTiles[name][posX] = nil
                            if (not next(gps.interestingTiles[name])) then
                                gps.interestingTiles[name] = nil
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
    if gps.interestingTiles[partialName] then
        return partialName
    end
    -- if getBlockNameFromPartialName_cache[partialName] then
    --     return getBlockNameFromPartialName_cache[partialName]
    -- end
    for i, v in pairs(gps.interestingTiles) do
        if string.find(i, partialName) then
            -- getBlockNameFromPartialName_cache[partialName] = i
            return i
        end
    end
    return nil
end

function gps.findBlock(name)
    local blockName = getBlockNameFromPartialName(name)
    if not blockName then
        return nil
    end
    if not gps.interestingTiles then
        return nil
    end
    local gpsPos = gps.getPosition()
    if not gpsPos then
        return nil
    end
    local x = math.floor(gpsPos.x)
    local y = math.floor(gpsPos.y)
    local z = math.floor(gpsPos.z)
    local r = 1
    local maxR = 256
    local searchCount = 0
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
            if gps.interestingTiles[blockName][x3] then
                for y3 = y2, y2e do
                    if gps.interestingTiles[blockName][x3][y3] then
                        for z3 = z2, z2e do
                            if x3 > x2 and x3 < x2e and y3 > y2 and y3 < y2e then -- inside on the x slice
                                if z3 > z2 then -- inside on the z slice
                                    z3 = z2e
                                end
                            end
                            searchCount = searchCount + 1
                            if gps.interestingTiles[blockName][x3][y3][z3] then
                                return { x = x3, y = y3, z = z3, name = name }
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

function gps.getWorldTiles(radius, height)
    local gpsPos = gps.getPosition()
    if gpsPos then
        local blocks = net.emit("NodeOS_getWorldTiles", { radius = radius, height = height, pos = gpsPos },
            settings.master)
        if blocks then
            gps.setWorldTiles(gpsPos, radius, height, blocks)
        end
    end
    return gps.worldTiles
end

function gps.getInterestingTiles(radius, height, name, gpsPos)
    if not gpsPos then
        gpsPos = gps.getPosition()
    end
    if gpsPos then
        local res = net.emit("NodeOS_getInterestingTiles",
            { radius = radius, height = height, pos = gpsPos, name = name },
            settings.master)
        if res and res.name then
            gps.setInterestingTiles(gpsPos, radius, height, res.name, res.tiles)
            return {
                name = res.name,
                tiles = gps.interestingTiles[res.name]
            }
        end
    end
    return nil
end

function gps.getAllWorldTiles()
    local tiles = net.emit("NodeOS_getWorldTiles", { all = true },
        settings.master)
    if tiles then
        for x, y in pairs(tiles) do
            for y, z in pairs(y) do
                for z, name in pairs(z) do
                    if not gps.worldTiles[x] then
                        gps.worldTiles[x] = {}
                    end
                    if not gps.worldTiles[x][y] then
                        gps.worldTiles[x][y] = {}
                    end
                    if not gps.worldTiles[x][y][z] then
                        gps.worldTiles[x][y][z] = {}
                    end
                    local block = {}
                    block.x = x
                    block.y = y
                    block.z = z
                    block.name = name
                    gps.worldTiles[x][y][z] = block
                end
            end
        end
    end
    return gps.worldTiles
end

function gps.getAllInterestingTiles(name)
    local res = net.emit("NodeOS_getInterestingTiles", { all = true, name = name },
        settings.master)
    if res and res.name then
        if not gps.interestingTiles[res.name] then
            gps.interestingTiles[res.name] = {}
        end
        gps.interestingTiles[res.name] = res.tiles
        return res
    end
    return nil
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

return gps
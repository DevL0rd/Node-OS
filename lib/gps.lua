local util = require("/lib/util")
local file = util.loadModule("file")
local net = require("/lib/net")
local settings = require("/lib/settings").settings
require("/lib/misc")
local _locate = gps.locate
local gps = {}
gps.worldTiles = {}
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
    return computers
end

function gps.saveLocalComputers(computers)
    file.writeTable(localComputers_path, computers)
end

function gps.getClosestPC()
    local gpsPos = gps.getPosition()
    local localComputers = gps.getLocalComputers()
    if gpsPos then
        local closestDist = nil
        local closestID = nil
        for id, details in pairs(localComputers) do
            if details.pos then
                local dist = gps.getDistance(details.pos, gpsPos)
                if closestDist == nil or dist < closestDist then
                    closestDist = dist
                    closestID = id
                end
            end
        end
        return closestID
    end
    return nil
end

local failedgpscount = 0
local oldPos = nil
local lastPoll = 0
function gps.getPosition(round)
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
    if round then
        return {
            x = math.floor(oldPos.x),
            y = math.floor(oldPos.y),
            z = math.floor(oldPos.z)
        }
    else
        return oldPos
    end
end

function gps.getDistance(pos1, pos2, round)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    if round then
        return math.floor(math.sqrt(dx * dx + dy * dy + dz * dz))
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
    local width = data.radius * 2 + 1
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

function gps.findBlock(blockSearch)
    local gpsPos = gps.getPosition()
    if not gpsPos then
        return nil
    end
    if not gps.worldTiles then
        return nil
    end
    local x = math.floor(gpsPos.x)
    local y = math.floor(gpsPos.y)
    local z = math.floor(gpsPos.z)
    local r = 1
    local maxR = 64
    local searchCount = 0
    for r = 1, maxR do
        local x2 = x - r
        local y2 = y - r
        local z2 = z - r
        local x2e = x2 + r * 2
        local y2e = y2 + r * 2
        local z2e = z2 + r * 2
        for x3 = x2, x2e do
            if gps.worldTiles[x3] then
                for y3 = y2, y2e do
                    if gps.worldTiles[x3][y3] then
                        for z3 = z2, z2e do
                            if x3 > x2 and x3 < x2e and y3 > y2 and y3 < y2e then -- inside on the x slice
                                if z3 > z2 then -- inside on the z slice
                                    z3 = z2e
                                end
                            end
                            searchCount = searchCount + 1
                            if gps.worldTiles[x3][y3][z3] then
                                local block = gps.worldTiles[x3][y3][z3]
                                if string.find(block.name, blockSearch) then
                                    -- print(searchCount .. " " .. r)
                                    return block
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
    -- if gps.worldTiles[x2] and gps.worldTiles[x2][y2] and gps.worldTiles[x2][y2][z2] then
    --     local block = gps.worldTiles[x2][y2][z2]
    -- end
end

function gps.getWorldTiles(radius, height)
    local gpsPos = gps.getPosition()
    if gpsPos then
        local blocks = net.emit("NodeOS_getWorldTiles", { radius = radius, height = height, pos = gpsPos },
            settings.NodeOSMasterID)
        if blocks then
            gps.setWorldTiles(gpsPos, radius, height, blocks)
        end
    end
    return gps.worldTiles
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

function gps.getAllWorldTiles()
    local tiles = net.emit("NodeOS_getWorldTiles", { all = true },
        settings.NodeOSMasterID)
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

return gps
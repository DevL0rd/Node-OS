local gps = require("/lib/gps")
local turtleUtils = {}
local directions = {
    north = 0,
    east = 1,
    south = 2,
    west = 3
}
turtleUtils.pos = {
    x = 0,
    y = 0,
    z = 0
}
turtleUtils.direction = directions.north

gps.settings.offset.y = 1
function getDirectionTraveled(posFirst, posSecond)
    local dir = nil
    if posSecond.x > posFirst.x then
        dir = directions.east
    elseif posSecond.x < posFirst.x then
        dir = directions.west
    elseif posSecond.z > posFirst.z then
        dir = directions.south
    elseif posSecond.z < posFirst.z then
        dir = directions.north
    end
    return dir
end

function turtleUtils.calibrate()
    -- gps.settings.offset.z = -1
    calibrated = false
    while not calibrated do
        local gpsPos = gps.getPosition(true)
        if gpsPos then
            turtleUtils.pos = gpsPos
        end
        if gpsPos then
            turtle.dig()
            turtle.forward()
            os.sleep(1)
            local gposPos2 = gps.getPosition(true)
            turtle.back()
            if gposPos2 then
                turtleUtils.direction = getDirectionTraveled(gpsPos, gposPos2)
                calibrated = turtleUtils.direction ~= nil
            end
        end
    end
end

function turtleUtils.getCoordsAhead(ammount)
    local x, y, z = turtleUtils.pos.x, turtleUtils.pos.y, turtleUtils.pos.z
    if turtleUtils.direction == directions.north then
        z = z - ammount
    elseif turtleUtils.direction == directions.east then
        x = x + ammount
    elseif turtleUtils.direction == directions.south then
        z = z + ammount
    elseif turtleUtils.direction == directions.west then
        x = x - ammount
    end
    return { x = x, y = y, z = z }
end

function turtleUtils.dig()
    if turtle.dig() then
        local frontCoords = turtleUtils.getCoordsAhead(1)
        if turtleUtils.trackBlock and gps.interestingTiles[turtleUtils.trackBlock] and
            gps.interestingTiles[turtleUtils.trackBlock][frontCoords.x] and
            gps.interestingTiles[turtleUtils.trackBlock][frontCoords.x][frontCoords.y]
            and
            gps.interestingTiles[turtleUtils.trackBlock][frontCoords.x][frontCoords.y][frontCoords.z] then
            gps.interestingTiles[turtleUtils.trackBlock][frontCoords.x][frontCoords.y][frontCoords.z] = nil
        end
    end
end

function turtleUtils.digUp()
    if turtle.digUp() then
        if turtleUtils.trackBlock and gps.interestingTiles[turtleUtils.trackBlock] and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x] and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y + 1]
            and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y + 1][turtleUtils.pos.z] then
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y + 1][turtleUtils.pos.z] = nil
        end
    end
end

function turtleUtils.digDown()
    if turtle.digDown() then
        if turtleUtils.trackBlock and gps.interestingTiles[turtleUtils.trackBlock] and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x] and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y - 1]
            and
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y - 1][turtleUtils.pos.z] then
            gps.interestingTiles[turtleUtils.trackBlock][turtleUtils.pos.x][turtleUtils.pos.y - 1][turtleUtils.pos.z] = nil
        end
    end
end

function turtleUtils.forward(breakBlocks)
    if breakBlocks then
        turtleUtils.dig()
    end
    if turtle.forward() then
        turtleUtils.pos.x = turtleUtils.pos.x +
            (turtleUtils.direction == directions.east and 1 or turtleUtils.direction == directions.west and -1 or 0)
        turtleUtils.pos.z = turtleUtils.pos.z +
            (turtleUtils.direction == directions.north and -1 or turtleUtils.direction == directions.south and 1 or 0)
    end
end

function turtleUtils.back()
    if turtle.back() then
        turtleUtils.pos.x = turtleUtils.pos.x +
            (turtleUtils.direction == directions.east and -1 or turtleUtils.direction == directions.west and 1 or 0)
        turtleUtils.pos.z = turtleUtils.pos.z +
            (turtleUtils.direction == directions.north and 1 or turtleUtils.direction == directions.south and -1 or 0)
    end
end

function turtleUtils.down(breakBlocks)
    if breakBlocks then
        turtleUtils.digDown()
    end
    if turtle.down() then
        turtleUtils.pos.y = turtleUtils.pos.y - 1
    end
end

function turtleUtils.up(breakBlocks)
    if breakBlocks then
        turtleUtils.digUp()
    end
    if turtle.up() then
        turtleUtils.pos.y = turtleUtils.pos.y + 1
    end
end

function turtleUtils.turnLeft()
    turtle.turnLeft()
    turtleUtils.direction = turtleUtils.direction - 1
    if turtleUtils.direction < 0 then
        turtleUtils.direction = 3
    end
end

function turtleUtils.turnRight(ammount)
    turtle.turnRight()
    turtleUtils.direction = turtleUtils.direction + 1
    if turtleUtils.direction > 3 then
        turtleUtils.direction = 0
    end
end

function turtleUtils.turn(direction)
    if turtleUtils.direction == direction then
        return
    end
    if turtleUtils.direction == directions.north then
        if direction == directions.east then
            turtleUtils.turnRight()
        elseif direction == directions.west then
            turtleUtils.turnLeft()
        elseif direction == directions.south then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.direction == directions.east then
        if direction == directions.north then
            turtleUtils.turnLeft()
        elseif direction == directions.south then
            turtleUtils.turnRight()
        elseif direction == directions.west then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.direction == directions.south then
        if direction == directions.east then
            turtleUtils.turnLeft()
        elseif direction == directions.west then
            turtleUtils.turnRight()
        elseif direction == directions.north then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.direction == directions.west then
        if direction == directions.north then
            turtleUtils.turnRight()
        elseif direction == directions.south then
            turtleUtils.turnLeft()
        elseif direction == directions.east then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    end
end

function turtleUtils.goTo(pos, breakBlocks, trackBlock)
    turtleUtils.trackBlock = trackBlock
    while true do
        -- local gpsPos = gps.getPosition(true)
        -- if gpsPos then
        --     turtleUtils.pos = gpsPos
        -- end
        pos = {
            x = round(pos.x),
            y = round(pos.y),
            z = round(pos.z)
        }
        local dist = gps.getDistance(turtleUtils.pos, pos, true)
        if dist == 0 then
            return
        end
        local isAboveOrBelow = false
        if pos.x > turtleUtils.pos.x then
            turtleUtils.turn(directions.east)
        elseif pos.x < turtleUtils.pos.x then
            turtleUtils.turn(directions.west)
        elseif pos.z > turtleUtils.pos.z then
            turtleUtils.turn(directions.south)
        elseif pos.z < turtleUtils.pos.z then
            turtleUtils.turn(directions.north)
        else
            isAboveOrBelow = true
        end
        if pos.y < turtleUtils.pos.y then
            turtleUtils.down(breakBlocks)
        else
            if isAboveOrBelow and pos.y > turtleUtils.pos.y then
                turtleUtils.up(breakBlocks)
            else
                turtleUtils.forward(breakBlocks)
            end
        end
        -- print("------------------")
        -- print("Target: " .. pos.x .. " " .. pos.y .. " " .. pos.z)
        -- print("Current: " .. turtleUtils.pos.x .. " " .. turtleUtils.pos.y .. " " .. turtleUtils.pos.z)
        -- print("Distance: " .. dist)
    end
end

function turtleUtils.hasNoSlots()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

function turtleUtils.isInvFull()
    for i = 1, 16 do
        if turtle.getItemSpace(i) > 0 then
            return false
        end
    end
    return true
end

return turtleUtils
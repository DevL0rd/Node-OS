local gps = require("/lib/gps")
local turtleUtils = {}
local directions = {
    north = 0,
    east = 1,
    south = 2,
    west = 3
}
turtleUtils.direction = directions.north

function turtleUtils.calibrate()
    local gpsPos = gps.getPosition()
    if gpsPos then
        turtle.forward()
        os.sleep(0.2)
        local gposPos2 = gps.getPosition()
        turtle.back()
        if gposPos2 then
            if gposPos2.x > gpsPos.x then
                turtleUtils.direction = directions.east
            elseif gposPos2.x < gpsPos.x then
                turtleUtils.direction = directions.west
            elseif gposPos2.z > gpsPos.z then
                turtleUtils.direction = directions.south
            elseif gposPos2.z < gpsPos.z then
                turtleUtils.direction = directions.north
            end
        end
    end
end

function turtleUtils.turn(direction)
    if turtleUtils.direction == direction then
        return
    end
    if turtleUtils.direction == directions.north then
        if direction == directions.east then
            turtle.turnRight()
        elseif direction == directions.west then
            turtle.turnLeft()
        elseif direction == directions.south then
            turtle.turnRight()
            turtle.turnRight()
        end
    elseif turtleUtils.direction == directions.east then
        if direction == directions.north then
            turtle.turnLeft()
        elseif direction == directions.south then
            turtle.turnRight()
        elseif direction == directions.west then
            turtle.turnRight()
            turtle.turnRight()
        end
    elseif turtleUtils.direction == directions.south then
        if direction == directions.east then
            turtle.turnLeft()
        elseif direction == directions.west then
            turtle.turnRight()
        elseif direction == directions.north then
            turtle.turnRight()
            turtle.turnRight()
        end
    elseif turtleUtils.direction == directions.west then
        if direction == directions.north then
            turtle.turnRight()
        elseif direction == directions.east then
            turtle.turnLeft()
        elseif direction == directions.south then
            turtle.turnRight()
            turtle.turnRight()
        end
    end

    turtleUtils.direction = direction
end

function turtleUtils.goTo(pos)
    while true do
        local gpsPos = gps.getPosition(true)
        local dist = gps.getDistance(gpsPos, pos, true)
        if dist == 1 then
            return
        end
        if gpsPos then
            if pos.x > gpsPos.x then
                turtleUtils.turn(directions.east)
            elseif pos.x < gpsPos.x then
                turtleUtils.turn(directions.west)
            elseif pos.z > gpsPos.z then
                turtleUtils.turn(directions.south)
            elseif pos.z < gpsPos.z then
                turtleUtils.turn(directions.north)
            end
            turtle.forward()
        end
    end
end

return turtleUtils
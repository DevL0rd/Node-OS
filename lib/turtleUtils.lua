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
    -- gps.settings.offset.y = 1
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
    return turtle.dig()
end

function turtleUtils.digUp()
    return turtle.digUp()
end

function turtleUtils.digDown()
    return turtle.digDown()
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
        return true
    end
    return false
end

function turtleUtils.back()
    if turtle.back() then
        turtleUtils.pos.x = turtleUtils.pos.x +
            (turtleUtils.direction == directions.east and -1 or turtleUtils.direction == directions.west and 1 or 0)
        turtleUtils.pos.z = turtleUtils.pos.z +
            (turtleUtils.direction == directions.north and 1 or turtleUtils.direction == directions.south and -1 or 0)
        return true
    end
    return false
end

function turtleUtils.down(breakBlocks)
    if breakBlocks then
        turtleUtils.digDown()
    end
    if turtle.down() then
        turtleUtils.pos.y = turtleUtils.pos.y - 1
        return true
    end
    return false
end

function turtleUtils.up(breakBlocks)
    if breakBlocks then
        turtleUtils.digUp()
    end
    if turtle.up() then
        turtleUtils.pos.y = turtleUtils.pos.y + 1
        return true
    end
    return false
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

function turtleUtils.isAboveOrBelowPos(pos)
    return not pos.x or not pos.y or not pos.z or
        pos.x == turtleUtils.pos.x and pos.z == turtleUtils.pos.z and pos.y ~= turtleUtils.pos.y
end

function turtleUtils.goTo(pos, breakBlocks, targetDistance)
    local fixingDirectionWE = false
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
        if dist == targetDistance then
            return
        end

        if fixingDirectionWE then
            if pos.x > turtleUtils.pos.x then
                turtleUtils.turn(directions.east)
            elseif pos.x < turtleUtils.pos.x then
                turtleUtils.turn(directions.west)
            end
        else
            if pos.z > turtleUtils.pos.z then
                turtleUtils.turn(directions.south)
            elseif pos.z < turtleUtils.pos.z then
                turtleUtils.turn(directions.north)
            end
        end
        fixingDirectionWE = not fixingDirectionWE
        if dist <= targetDistance then
            if targetDistance == 1 then
                if pos.x > turtleUtils.pos.x then
                    turtleUtils.turn(directions.east)
                    turtleUtils.forward()
                elseif pos.x < turtleUtils.pos.x then
                    turtleUtils.turn(directions.west)
                    turtleUtils.forward()
                end
                if pos.z > turtleUtils.pos.z then
                    turtleUtils.turn(directions.south)
                    turtleUtils.forward()
                elseif pos.z < turtleUtils.pos.z then
                    turtleUtils.turn(directions.north)
                    turtleUtils.forward()
                end
                if pos.y < turtleUtils.pos.y then
                    turtleUtils.down()
                elseif pos.y > turtleUtils.pos.y then
                    turtleUtils.up()
                end
                if pos.x > turtleUtils.pos.x then
                    turtleUtils.turn(directions.east)
                elseif pos.x < turtleUtils.pos.x then
                    turtleUtils.turn(directions.west)
                elseif pos.z > turtleUtils.pos.z then
                    turtleUtils.turn(directions.south)
                elseif pos.z < turtleUtils.pos.z then
                    turtleUtils.turn(directions.north)
                end
            end
            return true
        end
        if breakBlocks then
            if pos.y < turtleUtils.pos.y then
                turtleUtils.down(breakBlocks)
            else
                if turtleUtils.isAboveOrBelowPos(pos) and pos.y > turtleUtils.pos.y then
                    turtleUtils.up(breakBlocks)
                else
                    turtleUtils.forward(breakBlocks)
                end
            end
        else
            local canMove = false
            if turtleUtils.pos.x ~= pos.x or turtleUtils.pos.z ~= pos.z then
                if turtleUtils.forward() then
                    canMove = true
                end
            end
            if pos.y < turtleUtils.pos.y then
                if turtleUtils.down() then
                    canMove = true
                end
            elseif pos.y > turtleUtils.pos.y then
                if turtleUtils.up() then
                    canMove = true
                end
            end
            if not canMove then
                return false
            end
        end
        -- print("------------------")
        -- print("Target: " .. pos.x .. " " .. pos.y .. " " .. pos.z)
        -- print("Current: " .. turtleUtils.pos.x .. " " .. turtleUtils.pos.y .. " " .. turtleUtils.pos.z)
        -- print("Distance: " .. dist)
    end
end

function turtleUtils.getInventory()
    local inventory = {}
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            inventory[i] = turtle.getItemDetail()
        end
    end
    return inventory
end

function turtleUtils.getInventoryByNames()
    local inventory = {}
    for i = 1, 16 do
        turtle.select(i)
        if turtle.getItemCount() > 0 then
            local item = turtle.getItemDetail()
            if inventory[item.name] then
                inventory[item.name].count = inventory[item.name].count + item.count
            else
                inventory[item.name] = item
                inventory[item.name].slots = {}
            end
            table.insert(inventory[item.name].slots, i)
        end
    end
    return inventory
end

function turtleUtils.dumpItems(dumpList)
    local items = turtleUtils.getInventoryByNames()
    for k, item in pairs(items) do
        if dumpList[item.name] then
            for i = 1, #item.slots do
                turtle.select(item.slots[i])
                turtle.dropDown()
            end
        end
    end
end

function turtleUtils.dumpItem(itemName)
    local items = turtleUtils.getInventoryByNames()
    if not items[itemName] then
        return false
    end
    for i = 1, #items[itemName].slots do
        turtle.select(items[itemName].slots[i])
        turtle.dropDown()
    end
end

function turtleUtils.dumpAll()
    for i = 1, 16 do
        turtle.select(i)
        turtle.dropDown()
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
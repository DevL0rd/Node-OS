local turtleUtils = {}
turtleUtils.pos = {
    x = 0,
    y = 0,
    z = 0,
    d = nodeos.gps.directions.north
}
turtleUtils.replaceBlocksBehindDisabledDepth = 50

local function blockToBrokenBlock(block)
    if block == "minecraft:stone" then
        return "minecraft:cobblestone"
    elseif block == "minecraft:grass" then
        return "minecraft:dirt"
    end
    return block
end

function turtleUtils.calibrate()
    -- nodeos.gps.settings.offset.y = 1
    --get the current position and direction, after this turtle can track it's self.
    local tGps = nodeos.gps.getPosition(true)
    turtleUtils.pos.x = tGps.x
    turtleUtils.pos.y = tGps.y
    turtleUtils.pos.z = tGps.z
    turtle.dig()
    turtle.forward()
    os.sleep(1)
    tGps = nodeos.gps.getPosition(true)
    turtleUtils.pos.d = tGps.d
    turtle.back()
end

function turtleUtils.getCoordsAhead(ammount)
    local x, y, z = turtleUtils.pos.x, turtleUtils.pos.y, turtleUtils.pos.z
    if turtleUtils.pos.d == nodeos.gps.directions.north then
        z = z - ammount
    elseif turtleUtils.pos.d == nodeos.gps.directions.east then
        x = x + ammount
    elseif turtleUtils.pos.d == nodeos.gps.directions.south then
        z = z + ammount
    elseif turtleUtils.pos.d == nodeos.gps.directions.west then
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

-- Initialize a list to track blocks
turtleUtils.blockList = {}
turtleUtils.targetBlockName = "notset"

function turtleUtils.getItemSlot(itemName)
    -- convert some names to the correct name ie can't hold grass so convert to dirt
    -- use not exact match to allow for different types of the same item
    if string.find(itemName, "grass") then
        itemName = "dirt"
    end
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        -- not exat match
        if item and string.find(item.name, itemName) then
            return i
        end
    end
    return nil
end

-- Places a block forward by its name
function turtleUtils.placeBlock(blockName)
    local slot = turtleUtils.getItemSlot(blockName)
    if slot then
        turtle.select(slot)
        return turtle.place()
    end
    return false -- Block not found or placement failed
end

function turtleUtils.placeBlockDown(blockName)
    local slot = turtleUtils.getItemSlot(blockName)
    if slot then
        turtle.select(slot)
        return turtle.placeDown()
    end
    return false -- Block not found or placement failed
end

function turtleUtils.placeBlockUp(blockName)
    local slot = turtleUtils.getItemSlot(blockName)
    if slot then
        turtle.select(slot)
        return turtle.placeUp()
    end
    return false -- Block not found or placement failed
end

-- Move forward while managing block replacement
function turtleUtils.forward(breakBlocks)
    -- Step 1: Take out the oldest block in the list if length is 2
    if breakBlocks then
        if #turtleUtils.blockList == 2 then
            local blockToPlace = blockToBrokenBlock(table.remove(turtleUtils.blockList, 1)) -- Oldest block
            -- if air or target block string is not in the name
            local shouldReplace = turtleUtils.pos.y > turtleUtils.replaceBlocksBehindDisabledDepth
            if blockToPlace ~= "minecraft:air" and shouldReplace and turtleUtils.getItemSlot(blockToPlace) then
                -- Turn around and place the block
                turtle.turnLeft()
                turtle.turnLeft()
                turtleUtils.placeBlock(blockToPlace)
                turtle.turnLeft()
                turtle.turnLeft()
            end
        end

        -- Step 2: Inspect the block ahead and add it to the list
        local success, block = turtle.inspect()
        if success and not string.find(block.name, turtleUtils.targetBlockName) then
            table.insert(turtleUtils.blockList, block.name) -- Add the block to the list                                    -- Break the block
        else
            table.insert(turtleUtils.blockList, "minecraft:air")
        end
        turtle.dig()
    end
    -- Step 3: Move forward
    if turtle.forward() then
        -- Update position
        turtleUtils.pos.x = turtleUtils.pos.x +
            (turtleUtils.pos.d == nodeos.gps.directions.east and 1 or turtleUtils.pos.d == nodeos.gps.directions.west and -1 or 0)
        turtleUtils.pos.z = turtleUtils.pos.z +
            (turtleUtils.pos.d == nodeos.gps.directions.north and -1 or turtleUtils.pos.d == nodeos.gps.directions.south and 1 or 0)
        return true
    end

    return false -- Move failed
end

function turtleUtils.down(breakBlocks)
    if breakBlocks then
        if #turtleUtils.blockList == 2 then
            local blockToPlace = blockToBrokenBlock(table.remove(turtleUtils.blockList, 1)) -- Oldest block
            if blockToPlace ~= "minecraft:air" then
                turtleUtils.placeBlockUp(blockToPlace)
            end
        end
        local success, block = turtle.inspectDown()
        if success and not string.find(block.name, turtleUtils.targetBlockName) then
            table.insert(turtleUtils.blockList, block.name)
        else
            table.insert(turtleUtils.blockList, "minecraft:air")
        end
        turtle.digDown()
    end
    if turtle.down() then
        turtleUtils.pos.y = turtleUtils.pos.y - 1
        return true
    end
    return false
end

function turtleUtils.up(breakBlocks)
    if breakBlocks then
        if #turtleUtils.blockList == 2 then
            local blockToPlace = blockToBrokenBlock(table.remove(turtleUtils.blockList, 1)) -- Oldest block
            if blockToPlace ~= "minecraft:air" then
                turtleUtils.placeBlockDown(blockToPlace)
            end
        end
        local success, block = turtle.inspectUp()
        if success and not string.find(block.name, turtleUtils.targetBlockName) then
            table.insert(turtleUtils.blockList, block.name)
        else
            table.insert(turtleUtils.blockList, "minecraft:air")
        end
        turtle.digUp()
    end
    if turtle.up() then
        turtleUtils.pos.y = turtleUtils.pos.y + 1
        return true
    end
    return false
end

function turtleUtils.back()
    if turtle.back() then
        turtleUtils.pos.x = turtleUtils.pos.x +
            (turtleUtils.pos.d == nodeos.gps.directions.east and -1 or turtleUtils.pos.d == nodeos.gps.directions.west and 1 or 0)
        turtleUtils.pos.z = turtleUtils.pos.z +
            (turtleUtils.pos.d == nodeos.gps.directions.north and 1 or turtleUtils.pos.d == nodeos.gps.directions.south and -1 or 0)
        return true
    end
    if #turtleUtils.blockList > 0 then
        local blockToPlace = blockToBrokenBlock(table.remove(turtleUtils.blockList, 1)) -- Oldest block
        local shouldReplace = turtleUtils.pos.y > turtleUtils.replaceBlocksBehindDisabledDepth
        if blockToPlace ~= "minecraft:air" and shouldReplace and turtleUtils.getItemSlot(blockToPlace) then
            turtleUtils.placeBlock(blockToPlace)
        end
    end
    return false
end

function turtleUtils.turnLeft()
    turtle.turnLeft()
    turtleUtils.pos.d = turtleUtils.pos.d - 1
    if turtleUtils.pos.d < 0 then
        turtleUtils.pos.d = 3
    end
end

function turtleUtils.turnRight(ammount)
    turtle.turnRight()
    turtleUtils.pos.d = turtleUtils.pos.d + 1
    if turtleUtils.pos.d > 3 then
        turtleUtils.pos.d = 0
    end
end

function turtleUtils.turn(direction)
    if turtleUtils.pos.d == direction then
        return
    end
    if turtleUtils.pos.d == nodeos.gps.directions.north then
        if direction == nodeos.gps.directions.east then
            turtleUtils.turnRight()
        elseif direction == nodeos.gps.directions.west then
            turtleUtils.turnLeft()
        elseif direction == nodeos.gps.directions.south then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.pos.d == nodeos.gps.directions.east then
        if direction == nodeos.gps.directions.north then
            turtleUtils.turnLeft()
        elseif direction == nodeos.gps.directions.south then
            turtleUtils.turnRight()
        elseif direction == nodeos.gps.directions.west then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.pos.d == nodeos.gps.directions.south then
        if direction == nodeos.gps.directions.east then
            turtleUtils.turnLeft()
        elseif direction == nodeos.gps.directions.west then
            turtleUtils.turnRight()
        elseif direction == nodeos.gps.directions.north then
            turtleUtils.turnRight()
            turtleUtils.turnRight()
        end
    elseif turtleUtils.pos.d == nodeos.gps.directions.west then
        if direction == nodeos.gps.directions.north then
            turtleUtils.turnRight()
        elseif direction == nodeos.gps.directions.south then
            turtleUtils.turnLeft()
        elseif direction == nodeos.gps.directions.east then
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
    turtleUtils.blockList = {}
    pos = {
        x = math.floor(pos.x),
        y = math.floor(pos.y),
        z = math.floor(pos.z),
        d = pos.d
    }
    while true do
        -- local gpsPos = nodeos.gps.getPosition(true)
        -- if gpsPos then
        --     turtleUtils.pos = gpsPos
        -- end
        local dist = nodeos.gps.getDistance(turtleUtils.pos, pos, true)
        if dist == targetDistance then
            if pos.d ~= nil then
                turtleUtils.turn(pos.d)
            end
            return true
        end
        if pos.x > turtleUtils.pos.x then
            turtleUtils.turn(nodeos.gps.directions.east)
        elseif pos.x < turtleUtils.pos.x then
            turtleUtils.turn(nodeos.gps.directions.west)
        elseif pos.z > turtleUtils.pos.z then
            turtleUtils.turn(nodeos.gps.directions.south)
        elseif pos.z < turtleUtils.pos.z then
            turtleUtils.turn(nodeos.gps.directions.north)
        end
        if dist <= targetDistance then
            if targetDistance == 1 then
                if pos.x > turtleUtils.pos.x then
                    turtleUtils.turn(nodeos.gps.directions.east)
                    turtleUtils.forward()
                elseif pos.x < turtleUtils.pos.x then
                    turtleUtils.turn(nodeos.gps.directions.west)
                    turtleUtils.forward()
                end
                if pos.z > turtleUtils.pos.z then
                    turtleUtils.turn(nodeos.gps.directions.south)
                    turtleUtils.forward()
                elseif pos.z < turtleUtils.pos.z then
                    turtleUtils.turn(nodeos.gps.directions.north)
                    turtleUtils.forward()
                end
                if pos.y < turtleUtils.pos.y then
                    turtleUtils.down()
                elseif pos.y > turtleUtils.pos.y then
                    turtleUtils.up()
                end
                if pos.x > turtleUtils.pos.x then
                    turtleUtils.turn(nodeos.gps.directions.east)
                elseif pos.x < turtleUtils.pos.x then
                    turtleUtils.turn(nodeos.gps.directions.west)
                elseif pos.z > turtleUtils.pos.z then
                    turtleUtils.turn(nodeos.gps.directions.south)
                elseif pos.z < turtleUtils.pos.z then
                    turtleUtils.turn(nodeos.gps.directions.north)
                end
            end
            if pos.d ~= nil then
                turtleUtils.turn(pos.d)
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

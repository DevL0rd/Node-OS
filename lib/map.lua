local termUtils = require("/lib/termUtils")
require("/lib/misc")
local map = {}
map.worldTiles = {}
map.tileGraphics = {}
-- Reduce render depth to be closer to the vertical fetch range (12)
map.worldRenderDepth = 100
map.running = true
map.pos = { x = 0, y = 0, z = 0 }
map.rx, map.ry = 1, 1
map.rw, map.rh = 50, 50
map.targetPos = nil
map.orientation = gps.directions.north -- 0, 1, 2, 3

function map.loadMapTiles(path)
    if not path then
        path = "/sys/map/tileGraphics.cfg"
    end
    map.tileGraphicsPath = path
    if not fs.exists(path) then
        file.writeTable(path, map.tileGraphics)
    else
        map.tileGraphics = file.readTable(path)
    end
end

function map.saveTileGraphics(path)
    if not path then
        path = "/sys/map/tileGraphics.cfg"
    end
    file.writeTable(path, map.tileGraphics)
end

function map.renderTile(screenX, screenY, worldX, worldZ, startY, depth)
    local success = false
    local i = 0
    local visualTile = nil

    -- Find the top visible tile
    while i < depth do
        local checkY = math.floor(startY - i)
        if map.worldTiles[worldX] and map.worldTiles[worldX][checkY] and map.worldTiles[worldX][checkY][worldZ] then
            local tile = map.worldTiles[worldX][checkY][worldZ]
            if not map.tileGraphics[tile.name] then
                map.tileGraphics[tile.name] = {}
                map.tileGraphics[tile.name].char = "?"
                map.tileGraphics[tile.name].fgColor = "magenta"
                map.tileGraphics[tile.name].bgColor = "black"
                map.saveTileGraphics()
            end

            visualTile = tile
            success = true
            i = depth
        end
        i = i + 1
    end

    -- If we found a tile, render it
    if visualTile then
        local bgColor = map.tileGraphics[visualTile.name].bgColor

        -- If background is transparent, search deeper for a solid background
        if bgColor == "transparent" then
            local bgDepth = 0
            local maxBgDepth = 100
            local foundBg = false

            while bgDepth < maxBgDepth do
                local bgCheckY = math.floor(startY - bgDepth)
                if map.worldTiles[worldX] and map.worldTiles[worldX][bgCheckY] and map.worldTiles[worldX][bgCheckY][worldZ] then
                    local bgTile = map.worldTiles[worldX][bgCheckY][worldZ]
                    local tileBgColor = map.tileGraphics[bgTile.name].bgColor

                    if tileBgColor and tileBgColor ~= "transparent" then
                        bgColor = tileBgColor
                        foundBg = true
                        break
                    end
                end
                bgDepth = bgDepth + 1
            end

            -- If we couldn't find a solid background, default to black
            if not foundBg then
                bgColor = "black"
            end
        end

        -- Render the tile with appropriate background
        termUtils.write(
            map.tileGraphics[visualTile.name].char,
            screenX,
            screenY,
            map.tileGraphics[visualTile.name].fgColor,
            bgColor
        )
    end

    return success
end

function isEven(number)
    return (number % 2 == 0)
end

-- Simple line drawing function within map boundaries
function map.drawLine(x1, y1, x2, y2, char, color)
    local dx = math.abs(x2 - x1)
    local dy = -math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx + dy
    local e2

    while true do
        -- Check bounds before drawing
        if x1 >= map.rx and x1 < map.rx + map.rw and y1 >= map.ry and y1 < map.ry + map.rh then
            -- Use a character for the line, ensure background doesn't overwrite map
            termUtils.write(char, x1, y1, "white", color)
        end

        if x1 == x2 and y1 == y2 then break end
        e2 = 2 * err
        if e2 >= dy then
            err = err + dy
            x1 = x1 + sx
        end
        if e2 <= dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
end

-- Rotates coordinates based on orientation
function map.rotateCoordinates(x, z, orientation)
    if orientation == gps.directions.north then
        return x, z   -- No rotation
    elseif orientation == gps.directions.east then
        return -z, x  -- 90° clockwise
    elseif orientation == gps.directions.south then
        return -x, -z -- 180°
    elseif orientation == gps.directions.west then
        return z, -x  -- 270° clockwise
    end
    return x, z       -- Default if orientation is invalid
end

function map.render()
    local cx = map.rx
    local cy = map.ry
    local mx = map.rx + map.rw - 1
    local my = map.ry + map.rh - 1

    -- Center of the map view in world coordinates
    local mapCenterXWorld = math.floor(map.pos.x)
    local mapCenterZWorld = math.floor(map.pos.z)

    -- Calculate the size of half the map
    local halfWidth = math.ceil(map.rw / 2)
    local halfHeight = math.ceil(map.rh / 2)
    local isUnderSomething = gps.isUnderSomething(map.pos)
    local mapDepth = isUnderSomething and 1 or map.worldRenderDepth
    local yOffset = isUnderSomething and 0 or 25
    while cx <= mx do
        cy = map.ry
        while cy <= my do
            -- Calculate the offset from center in screen space
            local screenOffsetX = cx - (map.rx + halfWidth)
            local screenOffsetY = cy - (map.ry + halfHeight)

            -- Rotate these offsets based on orientation
            local worldOffsetX, worldOffsetZ = map.rotateCoordinates(screenOffsetX, screenOffsetY, map.orientation)

            -- Calculate actual world coordinates
            local worldX = mapCenterXWorld + worldOffsetX
            local worldZ = mapCenterZWorld + worldOffsetZ
            if not map.renderTile(cx, cy, worldX, worldZ, map.pos.y + yOffset, mapDepth) then
                if isEven(cx + cy) then
                    termUtils.write(" ", cx, cy, "black", "black")
                else
                    termUtils.write(" ", cx, cy, "gray", "gray")
                end
            end
            cy = cy + 1
        end
        cx = cx + 1
    end

    local uiCenterX = map.rx + halfWidth
    local uiCenterY = map.ry + halfHeight

    -- Draw target line if target exists
    if map.targetPos then
        -- Calculate target's position relative to the player's world position
        local deltaX = map.targetPos.x - map.pos.x
        local deltaZ = map.targetPos.z - map.pos.z

        -- Rotate the delta coordinates based on orientation
        local rotatedDeltaX, rotatedDeltaZ = map.rotateCoordinates(deltaX, deltaZ, map.orientation)
        local targetScreenX, targetScreenY = 0, 0
        -- Calculate target's screen position relative to the center of the UI
        if map.orientation == gps.directions.east or map.orientation == gps.directions.west then
            targetScreenX = uiCenterX - math.floor(rotatedDeltaX)
            targetScreenY = uiCenterY - math.floor(rotatedDeltaZ)
        else
            targetScreenX = uiCenterX + math.floor(rotatedDeltaX)
            targetScreenY = uiCenterY + math.floor(rotatedDeltaZ)
        end
        local lineChar = "*"
        -- if target y is above or below pos the use ^ or v, have a padding of 1 so it is not finicky
        if map.targetPos.y > map.pos.y + 1 then
            lineChar = "^"
        elseif map.targetPos.y < map.pos.y - 1 then
            lineChar = "v"
        end
        map.drawLine(uiCenterX, uiCenterY, targetScreenX, targetScreenY, lineChar, "lightBlue")
        -- if target is on screen, replace tile with red bg white fg X
        if targetScreenX >= map.rx and targetScreenX < map.rx + map.rw and
            targetScreenY >= map.ry and targetScreenY < map.ry + map.rh then
            termUtils.write("X", targetScreenX, targetScreenY, "white", "red")
        end
    end

    termUtils.write("^", uiCenterX, uiCenterY, "white", "blue")

    if map.triggerRenderUI then
        map.triggerRenderUI()
    end

    termUtils.triggerPaint()
end

function map.renderThread()
    while map.running do
        if not map.inputingColor then
            map.render()
        end
        os.sleep(0.1)
    end
end

map.lastFetchPosition = nil
function map.updateThread()
    while map.running do
        if map.triggerUpdate then
            map.triggerUpdate()
        end
        if not map.lastFetchPosition or gps.getDistance(map.lastFetchPosition, map.pos) > 3 then
            map.worldTiles = gps.getWorldTiles((map.rw / 2) + 1, 10, map.pos)
            map.lastFetchPosition = map.pos
        end
        os.sleep(0.5)
    end
end

function map.init(x, y, w, h, onRenderUI, onUpdate, tileGraphicsPath)
    if not fs.exists("etc/map") then
        fs.makeDir("etc/map")
    end
    map.running = true
    map.setRenderPosition(x, y, w, h)
    map.onRenderUI(onRenderUI)
    map.onUpdate(onUpdate)
    map.loadMapTiles(tileGraphicsPath)
    parallel.waitForAny(map.renderThread, map.updateThread)
end

function map.onRenderUI(onRenderUI)
    map.triggerRenderUI = onRenderUI
end

function map.onUpdate(onUpdate)
    map.triggerUpdate = onUpdate
end

function map.setRenderPosition(x, y, w, h)
    map.rx = x
    map.ry = y
    map.rw = w
    map.rh = h
end

function map.uninit()
    map.running = false
    map.worldTiles = {}
end

function map.setPosition(x, y, z)
    map.pos = { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
end

function map.setTarget(targetPos)
    if targetPos then
        map.targetPos = { x = math.floor(targetPos.x), y = math.floor(targetPos.y), z = math.floor(targetPos.z) }
    else
        map.targetPos = nil
    end
end

function map.setOrientation(orientation)
    map.orientation = orientation
end

function map.getTargetDistance()
    if map.targetPos then
        return gps.getDistance(map.pos, map.targetPos)
    end
    return nil
end

function map.clearTarget()
    map.targetPos = nil
end

return map

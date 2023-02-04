local termUtils = require("/lib/termUtils")
require("/lib/misc")
local locations = {}
local navigatingToBlock = false
local navto = nil
local navtoid = nil
local navname = ""
local worldTiles = {}
local markedTiles = {}
local computerTiles = {}
local oldComputerDetails = {}
local tileGraphics = {}
local tileGraphicsPath = "etc/map/tileGraphics.cfg"
local worldRenderDepth = 100
local inputingColor = false

if not fs.exists("etc/map") then
    fs.makeDir("etc/map")
end
tiles_path = "etc/map/serverTiles.dat"

if not fs.exists(tileGraphicsPath) then
    file.writeTable(tileGraphicsPath, tileGraphics)
else
    tileGraphics = file.readTable(tileGraphicsPath)
end

locationsPath = "etc/map/map_locations.cfg"
if not fs.exists(locationsPath) then
    file.writeTable(locationsPath, locations)
else
    locations = file.readTable(locationsPath)
end
statusBarHeight = 0
function renderTopMenu()
    if navto or navtoid then
        statusBarHeight = 1
        termUtils.fillLine(" ", 1, "white", "gray")
        local localComputers = gps.getLocalComputers()
        local gpsPos = gps.getPosition()
        if gpsPos then
            local ntZ = nil
            local ntX = nil
            local gpX = math.floor(gpsPos.x)
            local gpY = math.floor(gpsPos.y)
            local gpZ = math.floor(gpsPos.z)
            if navtoid and not (localComputers[navtoid] and localComputers[navtoid].pos) then
                return
            end
            if navtoid then
                dist = math.floor(gps.getDistance(gpsPos, localComputers[navtoid].pos))
                ntX = math.floor(localComputers[navtoid].pos.x)
                ntY = math.floor(localComputers[navtoid].pos.y)
                ntZ = math.floor(localComputers[navtoid].pos.z)
            else
                dist = math.floor(gps.getDistance(gpsPos, navto))
                ntX = math.floor(navto.x)
                ntY = math.floor(navto.y)
                ntZ = math.floor(navto.z)
            end
            local headingStr = ""
            if ntZ < gpZ then
                headingStr = headingStr .. "N"
            elseif ntZ > gpZ then
                headingStr = headingStr .. "S"
            end
            if ntX < gpX then
                headingStr = headingStr .. "W"
            elseif ntX > gpX then
                headingStr = headingStr .. "E"
            end
            if headingStr == "" then
                if ntY < gpY then
                    headingStr = "Down"
                elseif ntY > gpY then
                    headingStr = "Up"
                end
                if headingStr == "" then
                    headingStr = "Here"
                end
            end
            navText = "[" .. navname .. "] '" .. headingStr .. "' Dist:" .. dist
            termUtils.centerText(navText, 1, "white", "gray")
            -- if driverData.hud then
            --     driverData.hud.nav.setText(navText)
            -- end
        end
    elseif navname ~= "" then
        statusBarHeight = 1
        termUtils.fillLine(" ", 1, "gray", "gray")
        navText = "Searching for '" .. navname .. "'..."
        termUtils.centerText(navText, 1, "white", "gray")
        -- if driverData.hud then
        --     driverData.hud.nav.setText(navText)
        -- end
    end
end

function getMapChar(block)
    inputingColor = true
    term.clear()
    renderTopMenu()
    termUtils.print("Please give block '" .. block .. "' a map character.", "purple")
    local nChar = read()
    if not nChar or nChar == "" or nChar:len() > 1 then
        nChar = " "
    end
    inputingColor = false
    return nChar
end

function getMapCharFG(block)
    inputingColor = true
    local gotColor = false
    local color = nil
    while not color do
        term.clear()
        renderTopMenu()
        termUtils.print("Please give block '" .. block .. "' a forground color.", "purple")
        local cIn = read()
        if colors[cIn] then
            color = cIn
        end
    end
    inputingColor = false
    return color
end

function getMapCharBG(block)
    inputingColor = true
    local gotColor = false
    local color = nil
    while not color do
        term.clear()
        renderTopMenu()
        termUtils.print("Please give block '" .. block .. "' a background color.", "purple")
        local cIn = read()
        if colors[cIn] then
            color = cIn
        end
    end
    inputingColor = false
    return color
end

function renderWorldTile(rx, ry, cX, cY, cZ, depth)
    local success = false
    local i = 0
    while i < depth do
        -- print(cX .. "," .. cY - i .. "," .. cZ)
        if worldTiles[cX] and worldTiles[cX][cY - i] and worldTiles[cX][cY - i][cZ] then
            if not tileGraphics[worldTiles[cX][cY - i][cZ].name] then
                tileGraphics[worldTiles[cX][cY - i][cZ].name] = {}
                tileGraphics[worldTiles[cX][cY - i][cZ].name].char = getMapChar(worldTiles[cX][cY - i][cZ].name)
                tileGraphics[worldTiles[cX][cY - i][cZ].name].fgColor = getMapCharFG(worldTiles[cX][cY - i][cZ].name)
                tileGraphics[worldTiles[cX][cY - i][cZ].name].bgColor = getMapCharBG(worldTiles[cX][cY - i][cZ].name)
                file.writeTable(tileGraphicsPath, tileGraphics)
                term.clear()
            end
            termUtils.write(tileGraphics[worldTiles[cX][cY - i][cZ].name].char, rx, ry,
                tileGraphics[worldTiles[cX][cY - i][cZ].name].fgColor,
                tileGraphics[worldTiles[cX][cY - i][cZ].name].bgColor)
            success = true
            i = depth
        end
        i = i + 1
    end
    return success
end

function isEven(number)
    return (number % 2 == 0)
end

function renderMap(x, y)
    localOffset = statusBarHeight + 1
    local renderWidth, renderHeight = term.getSize()
    if monitor then
        renderWidth, renderHeight = monitor.getSize()
    end
    renderWidth = renderWidth
    renderHeight = renderHeight
    x = x - math.ceil(renderWidth / 2)
    y = y - math.ceil(renderHeight / 2)
    local rx = 1
    local ry = localOffset
    local gpsPos = gps.getPosition()
    while ry < renderHeight do
        while rx < renderWidth + 1 do
            local cX = rx + x - 2
            local cY = 64
            if gpsPos then
                cY = math.floor(gpsPos.y) + 2
            end
            local cZ = ry + y - 3
            if computerTiles[cX] and computerTiles[cX][cZ] then
                termUtils.write(computerTiles[cX][cZ].char, rx, ry, "white", computerTiles[cX][cZ].color)
                if computerTiles[cX][cZ].name then
                    --termUtils.write(" " .. computerTiles[cX][cZ].name, rx + 1, ry - 1, computerTiles[cX][cZ].color, "lightGray")
                end
            elseif worldTiles and renderWorldTile(rx, ry, cX, cY, cZ, worldRenderDepth) then
                -- do nothing
            else
                if isEven(ry) then
                    if isEven(rx) then
                        termUtils.write(" ", rx, ry, "white", "white")
                    else
                        termUtils.write(" ", rx, ry, "purple", "purple")
                    end
                else
                    if isEven(rx) then
                        termUtils.write(" ", rx, ry, "purple", "purple")
                    else
                        termUtils.write(" ", rx, ry, "white", "white")
                    end
                end
            end
            rx = rx + 1
        end
        rx = 1
        ry = ry + 1
    end
    local midY = localOffset + math.ceil((renderHeight - localOffset - 1) / 2)
    termUtils.centerText(" N ", localOffset, "red", "black")
    termUtils.alignRight(" ", midY - 1, "white", "black")
    termUtils.alignRight("E", midY, "white", "black")
    termUtils.alignRight(" ", midY + 1, "white", "black")
    termUtils.centerText(" S ", renderHeight - 1, "white", "black")
    termUtils.write(" ", 1, midY - 1, "white", "black")
    termUtils.write("W", 1, midY, "white", "black")
    termUtils.write(" ", 1, midY + 1, "white", "black")
    termUtils.fillLine(" ", renderHeight, "white", "gray")
    termUtils.write("Press 'E' to close map.", 1, renderHeight, "white", "gray")
    termUtils.triggerPaint()
end

oldComputerDetails = deepcopy(localComputers)
function getMovedComputers()
    local mComputers = {}
    for id, details in pairs(localComputers) do
        if oldComputerDetails[id] then
            if (oldComputerDetails[id].pos and details.pos) and
                (
                oldComputerDetails[id].pos.x ~= details.pos.x or oldComputerDetails[id].pos.y ~= details.pos.y or
                    oldComputerDetails[id].pos.z ~= details.pos.z) then
                mComputers[id] = details
            end
        else
            mComputers[id] = details
        end
    end
    oldComputerDetails = deepcopy(localComputers)
    return mComputers
end

function generateMovingTiles()
    for id, details in pairs(getMovedComputers()) do
        if details.pos then
            local posX = math.floor(details.pos.x)
            local posY = math.floor(details.pos.z) -- Y axis on screen is Worlds z axis because of top down view
            if not computerTiles[posX] then
                computerTiles[posX] = {}
            end
            computerTiles[posX][posY] = { char = "C", color = "purple", name = details.name }
        end
    end
end

function generateComputerTiles()
    computerTiles = {}
    for id, details in pairs(localComputers) do
        if details.pos then
            local posX = math.floor(details.pos.x)
            local posY = math.floor(details.pos.z) -- Y axis on screen is world's z axis because of top down view
            if posX and posY then
                if not computerTiles[posX] then
                    computerTiles[posX] = {}
                end
                local mColor = "orange"
                if pairedPCs[id] then
                    mColor = "lime"
                end
                computerTiles[posX][posY] = { char = "C", color = mColor, name = details.name }
            end
        end
    end
end

function liveMapThread()
    while true do
        if not inputingColor then
            renderTopMenu()
            -- generateComputerTiles()
            -- generateMovingTiles()
            computerTiles = {}
            local gpsPos = gps.getPosition()
            if gpsPos then
                local posX = math.floor(gpsPos.x)
                local posY = math.floor(gpsPos.z) -- Y axis on screen is world's z axis because of top down view
                local posZ = math.floor(gpsPos.y)
                if not computerTiles[posX] then
                    computerTiles[posX] = {}
                end
                computerTiles[posX][posY] = { char = "X", color = "blue" }
                renderMap(posX, posY)
            else
                renderMap(1, 1)
            end
        end
        os.sleep(0.1)
    end
end

function inputThread()
    while true do
        local event, param = os.pullEvent()
        if not inputingColor then
            if event == "key_" then
                print(param)
            end
            if event == "key" and param == 87 then -- W
            elseif event == "key" and param == 65 then -- A
            elseif event == "key" and param == 83 then -- S
            elseif event == "key" and param == 68 then -- D
            elseif event == "key" and param == 69 then -- E
                statusBarHeight = 2
                term.clear()
                term.setCursorPos(1, 1)
                return
            end
        end
    end
end

local lastFetchPosition = nil
function worldTilesUpdateThread()
    while true do
        local gpsPos = gps.getPosition()
        if gpsPos then
            if not lastFetchPosition or gps.getDistance(lastFetchPosition, gpsPos) > 6 then
                worldTiles = gps.getWorldTiles(12, 12, gpsPos)
                lastFetchPosition = gpsPos
            end
        end
        sleep(0.5)
    end
end

function findBlockThread()
    while true do
        if navigatingToBlock then
            local closestBlock = gps.findBlock(navname)
            if closestBlock then
                navto = { x = closestBlock.x, y = closestBlock.y, z = closestBlock.z }
            else
                navto = nil
            end
        end
        sleep(5)
    end
end

function startMap()
    parallel.waitForAny(liveMapThread, inputThread, worldTilesUpdateThread, findBlockThread)
end

usage = "map [navadd <name> | navto <name> | navremove <name> | navlist | find <block>]"
local args = { ... }
if args[1] then
    if args[1] == "navadd" then
        if args[2] then
            if not tonumber(args[2]) then
                if not gps.getComputerID(args[2]) then
                    locations[args[2]] = gps.getPosition()
                    file.writeTable(locationsPath, locations)
                    termUtils.print("Location '" .. args[2] .. "' saved.", "green")
                else
                    termUtils.print("You cannot name this the same name as a PC name.", "red")
                end
            else
                termUtils.print("You cannot use numbers for the location name. This is reserved for computer IDs.", "red")
            end
        else
            termUtils.print("No location name specified.", "red")
        end
    elseif args[1] == "navremove" then
        if args[2] then
            if locations[args[2]] then
                locations[args[2]] = nil
                file.writeTable(locationsPath, locations)
                termUtils.print("Location '" .. args[2] .. "' removed.", "green")
            else
                termUtils.print("Location does not exist.", "red")
            end
        else
            termUtils.print("No location name specified.", "red")
        end
    elseif args[1] == "navlist" then
        termUtils.print("Navigation locations:", "green")
        local gpsPos = gps.getPosition()
        for name, lPos in pairs(locations) do
            local dist = "?"
            if gpsPos then
                dist = math.floor(gps.getDistance(gpsPos, lPos))
            end
            termUtils.print("   " .. name .. " Dist: " .. dist, "green")
        end
    elseif args[1] == "navto" then
        if args[2] then
            if tonumber(args[2]) then
                local localComputers = gps.getLocalComputers()
                if localComputers[tonumber(args[2])] and localComputers[tonumber(args[2])].pos then
                    navtoid = tonumber(args[2])
                    navname = localComputers[navtoid].name
                    startMap()
                else
                    termUtils.print("Computer ID not found.", "red")
                end
            else
                local cid = gps.getComputerID(args[2])
                if cid then
                    navtoid = cid
                    navname = args[2]
                    startMap()
                else
                    if locations[args[2]] then
                        navto = locations[args[2]]
                        navname = args[2]
                        startMap()
                    else
                        termUtils.print("Location not found.", "red")
                    end
                end
            end
        else
            termUtils.print("No location name specified.", "red")
        end
    elseif args[1] == "find" then
        if args[2] then
            local gpsPos = gps.getPosition()
            if gpsPos then
                navto = nil
                navtoid = nil
                navname = args[2]
                navigatingToBlock = true
                startMap()
            else
                termUtils.print("No GPS signal available.", "red")
            end
        else
            termUtils.print("No block name specified.", "red")
        end
    else
        termUtils.print(usage, "red")
    end
else
    startMap()
end
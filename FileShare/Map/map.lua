
M = {} -- define the module
markedTiles = {}
computerTiles = {}
mapTiles = {}
oldComputerDetails = {}
tileGraphics = {}
tileGraphicsPath = settingsFolder .. "/tileGraphics.dat"
worldRenderDepth = 256
inputingColor = false
if not fs.exists(tileGraphicsPath) then
    save(tileGraphics, tileGraphicsPath)
else
    tileGraphics = load(tileGraphicsPath)
end

mapVer = 0
if fs.exists("settings/mapVer.txt") then
    local file = fs.open("settings/mapVer.txt","r")
    mapVer = file.readAll()
    file.close()
end

function map_checkForUpdate()
    nVer = fetchFile(settings.NodeOSMasterID, "Map/mapVer.txt", "settings/mapVer.txt", true)
    if nVer then
        if nVer ~= mapVer then
            return true
        else
            return false
        end
    end
end
function tileGraphicsUpdate()
    fetchFile(settings.NodeOSMasterID, "Map/tileGraphics.dat", "settings/tileGraphics.dat", true)
end
function map_update() 
    newLine()        
    nPrint("Updating Map...", "gray")
    fetchFile(settings.NodeOSMasterID, "Map/map.lua", "map.lua", true)
    newLine()
    nPrint("Map update complete!", "green")
    os.sleep(1)
end
function renderTopMenu()
                    fillLine(" ", 7, "lightGray", "lightGray")
                    fillLine(" ", 8, "lightGray", "lightGray")
                    fillLine(" ", 9, "lightGray", "lightGray")
                    fillLine(" ", 10, "lightGray", "lightGray")
                    fillLine(" ", 11, "lightGray", "lightGray")
                    setCursorPos(1, 7)
end
function getMapChar(block)
                    inputingColor = true
                    clear()
                    renderTopMenu()
                    nWrite("Please give block '" .. block .. "' a map character.", nil, nil, "purple", "lightGray")
                    setCursorPos(1, 10)
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
                        clear()
                        renderTopMenu()
                        nWrite("Please give block '" .. block .. "' a foreground color.", nil, nil, "purple", "lightGray")
                        setCursorPos(1, 10)
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
                        clear()
                        renderTopMenu()
                        nWrite("Please give block '" .. block .. "' a background color.", nil, nil, "purple", "lightGray")
                        setCursorPos(1, 10)
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
            if worldTiles[cX] and worldTiles[cX][cY - i] and worldTiles[cX][cY - i][cZ] then
                if not tileGraphics[worldTiles[cX][cY - i][cZ].name] then
                    tileGraphics[worldTiles[cX][cY - i][cZ].name] = {}
                    tileGraphics[worldTiles[cX][cY - i][cZ].name].char = getMapChar(worldTiles[cX][cY - i][cZ].name)
                    tileGraphics[worldTiles[cX][cY - i][cZ].name].fgColor = getMapCharFG(worldTiles[cX][cY - i][cZ].name)
                    tileGraphics[worldTiles[cX][cY - i][cZ].name].bgColor = getMapCharBG(worldTiles[cX][cY - i][cZ].name)
                    save(tileGraphics, tileGraphicsPath)
                    clear()
                end
                nWrite(tileGraphics[worldTiles[cX][cY - i][cZ].name].char, rx, ry, tileGraphics[worldTiles[cX][cY - i][cZ].name].fgColor, tileGraphics[worldTiles[cX][cY - i][cZ].name].bgColor)
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
    localOffset = 7
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
    local gpsPos = getPosition()
    while ry < renderHeight do
        while rx < renderWidth + 1 do
            local cX = rx + x - 2
            local cY = 64
            if gpsPos then
                cY = math.floor(gpsPos.y) + 1
            end
            local cZ = ry + y - 3
            if computerTiles[cX] and computerTiles[cX][cZ] then
                nWrite(computerTiles[cX][cZ].char, rx, ry, "white", computerTiles[cX][cZ].color)
                if computerTiles[cX][cZ].name then
                    --nWrite(" " .. computerTiles[cX][cZ].name, rx + 1, ry - 1, computerTiles[cX][cZ].color, "lightGray")
                end
            elseif worldTiles and renderWorldTile(rx, ry, cX, cY, cZ, worldRenderDepth) then
                -- do nothing
            elseif markedTiles[cX] and markedTiles[cX][cZ] then
                nWrite(markedTiles[cX][cZ].char, rx, ry, "white", markedTiles[cX][cZ].color)
            else
                if isEven(ry) then
                    if isEven(rx) then
                        nWrite(" ", rx, ry, "white", "white")
                    else
                        nWrite(" ", rx, ry, "purple", "purple")
                    end
                else
                    if isEven(rx) then
                        nWrite(" ", rx, ry, "purple", "purple")
                    else
                        nWrite(" ", rx, ry, "white", "white")
                    end
                end
                
                
            end
            rx = rx + 1
        end
        rx = 1
        ry = ry + 1
    end
    local midY = localOffset + math.ceil((renderHeight - localOffset - 1) / 2)
    centerText(" N ", localOffset, "red", "black")
    alignRight(" ", midY  - 1, "white", "black")
    alignRight("E", midY, "white", "black")
    alignRight(" ", midY + 1, "white", "black")
    centerText(" S ", renderHeight - 1, "white", "black")
    nWrite(" ", 1, midY - 1, "white", "black")
    nWrite("W", 1, midY, "white", "black")
    nWrite(" ", 1, midY + 1, "white", "black")
    fillLine(" ", renderHeight, "white", "gray")
    nWrite("Press 'E' to close map.", 1, renderHeight, "white", "gray")
end
oldComputerDetails = deepcopy(localComputers)
function getMovedComputers()
    local mComputers = {}
        for id, details in pairs(localComputers) do
            if oldComputerDetails[id] then
                if (oldComputerDetails[id].pos and details.pos) and (oldComputerDetails[id].pos.x ~= details.pos.x or oldComputerDetails[id].pos.y ~= details.pos.y or oldComputerDetails[id].pos.z ~= details.pos.z) then
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
                computerTiles[posX][posY] = {char = "C", color = "purple", name = details.name}
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
                    computerTiles[posX][posY] = {char = "C", color = mColor, name = details.name}
                end
            end
        end
end
function liveMapThread()
    while true do
        if not inputingColor then
            generateComputerTiles()
            generateMovingTiles()
            local gpsPos = getPosition()
            if gpsPos then
                local posX = math.floor(gpsPos.x)
                local posY = math.floor(gpsPos.z) -- Y axis on screen is world's z axis because of top down view
                local posZ = math.floor(gpsPos.y)
                if not markedTiles[posX] then
                    markedTiles[posX] = {}
                end
                markedTiles[posX][posY] = {char = " ", color = "red"}
                if not computerTiles[posX] then
                    computerTiles[posX] = {}
                end
                computerTiles[posX][posY] = {char = "X", color = "blue"}
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
            if event == "key" and param == 17 then -- W
            elseif event == "key" and param == 30 then -- A
            elseif event == "key" and param == 31 then -- S
            elseif event == "key" and param == 32 then -- D
            elseif event == "key" and param == 18 then -- E
                clear()
                return
            end
        end
    end
end
function worldTilesUpdateThread()
    while true do
        getWorldTiles()
        sleep(2)
    end
end
if map_checkForUpdate() then
    map_update()
end

shellRunning = false
parallel.waitForAny(liveMapThread, inputThread, worldTilesUpdateThread)
return M
locations = {}
navigatingToBlock = false
navto = nil
navtoid = nil
navname = ""
worldTiles = {}
markedTiles = {}
computerTiles = {}
mapTiles = {}
oldComputerDetails = {}
tileGraphics = {}
tileGraphicsPath = "sys/storage/tileGraphics.dat"
worldRenderDepth = 100
inputingColor = false
if not fs.exists(tileGraphicsPath) then
    save(tileGraphics, tileGraphicsPath)
else
    tileGraphics = load(tileGraphicsPath)
end

locationsPath = "config/gps_locations.dat"
if not fs.exists(locationsPath) then
    save(locations, locationsPath)
else
    locations = load(locationsPath)
end
function renderTopMenu()
    
    if navto or navtoid then
        statusBarHeight = 3
        fillLine(" ", 3, term_settings.header.fg, term_settings.header.bg)
        local gpsPos = getPosition()
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
                dist = math.floor(getDistance(gpsPos, localComputers[navtoid].pos))
                ntX = math.floor(localComputers[navtoid].pos.x)
                ntY = math.floor(localComputers[navtoid].pos.y)
                ntZ = math.floor(localComputers[navtoid].pos.z)
            else
                dist = math.floor(getDistance(gpsPos, navto))
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
            centerText(navText, 3, "white", term_settings.header.bg)
            if driverData.hud then
                driverData.hud.nav.setText(navText)
            end
        end
    elseif navname ~= "" then
        statusBarHeight = 3
        fillLine(" ", 3, term_settings.header.fg, term_settings.header.bg)
        navText = "Searching for '" .. navname .. "'..."
        centerText(navText, 3, "white", term_settings.header.bg)
        if driverData.hud then
            driverData.hud.nav.setText(navText)
        end
    else
        if driverData.hud then
            driverData.hud.nav.setText(" ")
        end
    end
end
function getMapChar(block)
                    inputingColor = true
                    clear()
                    renderTopMenu()
                    nWrite("Please give block '" .. block .. "' a map character.", nil, nil, "purple", "gray")
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
                        nWrite("Please give block '" .. block .. "' a foreground color.", nil, nil, "purple", "gray")
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
                        nWrite("Please give block '" .. block .. "' a background color.", nil, nil, "purple", "gray")
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
            -- print(cX .. "," .. cY - i .. "," .. cZ)
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
    local gpsPos = getPosition()
    while ry < renderHeight do
        while rx < renderWidth + 1 do
            local cX = rx + x - 2
            local cY = 64
            if gpsPos then
                cY = math.floor(gpsPos.y) + 2
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
            renderTopMenu()
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
            if event == "key_" then
                print(param)
            end
            if event == "key" and param == 87 then -- W
            elseif event == "key" and param == 65 then -- A
            elseif event == "key" and param == 83 then -- S
            elseif event == "key" and param == 68 then -- D
            elseif event == "key" and param == 69 then -- E
                statusBarHeight = 2
                clear()
                return
            end
        end
    end
end

function setWorldTiles(pos, radius, height, blocks) --very optimized sync
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
                    if not worldTiles[posX] then
                        worldTiles[posX] = {}
                    end
                    if not worldTiles[posX][posY] then
                        worldTiles[posX][posY] = {}
                    end
                    if not worldTiles[posX][posY][posZ] then
                        worldTiles[posX][posY][posZ] = {}
                    end
                    worldTiles[posX][posY][posZ] = block
                elseif worldTiles[posX] and worldTiles[posX][posY] and worldTiles[posX][posY][posZ] then
                    worldTiles[posX][posY][posZ] = nil --shitty map compression lol
                    if (not next(worldTiles[posX][posY])) then
                        worldTiles[posX][posY] = nil
                        if (not next(worldTiles[posX])) then
                            worldTiles[posX] = nil
                        end
                    end
                end
            end
        end
    end
end

function findClosestBlock(gpsPos, blockSearch)
    if not worldTiles then
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
            if worldTiles[x3] then
                for y3 = y2, y2e do
                    if worldTiles[x3][y3] then
                        for z3 = z2, z2e do
                            if x3 > x2 and x3 < x2e and y3 > y2 and y3 < y2e then -- inside on the x slice
                                if z3 > z2 then -- inside on the z slice
                                    z3 = z2e
                                end
                            end
                            searchCount = searchCount + 1
                            if worldTiles[x3][y3][z3] then
                                local block = worldTiles[x3][y3][z3]
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
    -- if worldTiles[x2] and worldTiles[x2][y2] and worldTiles[x2][y2][z2] then
    --     local block = worldTiles[x2][y2][z2]
    -- end
end
function getWorldTiles(pos, radius, height)
    local blocks = sendNet(settings.NodeOSMasterID, "getWorldTiles", {radius = radius, height=height, pos=pos})
    if blocks then
        setWorldTiles(pos, radius, height, blocks)
    end
end
netcoms.getWorldTiles = {
    exec = function (senderID, responseToken, data)
        if os.getComputerID() == settings.NodeOSMasterID then
            -- for blocks in data.radius
            if data.radius > 31 then
                data.radius = 31
            end
            local tempTiles = {}
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
            print(mx .. " " .. my .. " " .. mz .. " -- " .. mx2 .. " " .. my2 .. " " .. mz2)
            --take slices by height
            for posY = my, my2 do
                local blockSlice = commands.getBlockInfos(mx, posY, mz, mx2, posY, mz2)
                count = 0
                for posX = mx, mx2 do
                    for posZ = mz, mz2 do
                        -- x + z*width + y*depth*depth
                        local ix = math.floor(posX - mx)
                        -- local iy = math.floor(posY - my)+1
                        local iz = math.floor(posZ - mz)
                        local index = ix + iz * width + 1
                        -- print(ix .. " " .. iy .. " " .. iz .. " -- " .. index)
                        -- sleep(1)
                        local block = blockSlice[index]
                        local bm = {}
                        if block.name ~= "minecraft:air" then
                            name = block.name
                            -- remove minecraft: from string in name if it is there
                            if string.find(name, "minecraft:") then
                                name = string.sub(name, string.len("minecraft:") + 1)
                            end
                            count = count + 1
                            if not tempTiles[posX] then
                                tempTiles[posX] = {}
                            end
                            if not tempTiles[posX][posY] then
                                tempTiles[posX][posY] = {}
                            end
                            if not tempTiles[posX][posY][posZ] then
                                tempTiles[posX][posY][posZ] = {}
                            end
                            -- print(block.name)
                            tempTiles[posX][posY][posZ] = name
                            -- print(name)
                        end
                    end
                end
            end
            rednet.send(senderID, {data = tempTiles, responseToken = responseToken}, "NodeOSNetResponse")
        end
    end
}
function navsend(cId, name, pos)
    local res = sendNet(cId, "navsend", {name = name, pos = pos})
    if res then
        if res == "success" then
            nPrint("Successfully sent location!", "lime")
        end
    else
        nPrint("No response received.", "red")
    end
end
coms.navsend = {
    usage = "navsend <locationname> [computer]",
    details = "Send nav point to nearest computer or specified computer.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            if params[2] then
                local cId = nil
                if locations[params[1]] then
                    if localComputers[tonumber(params[2])] then
                        cId = tonumber(params[2])
                    else
                        cId = getComputerID(params[2])
                    end
                    if cId then
                            navsend(cId, params[1], locations[params[1]])
                    else
                        nPrint("Could not find PC.", "red")
                    end
                else
                    nPrint("This location does not exist.", "red")
                end
            else
                local closestID = getClosestPC()
                if closestID then
                    if locations[params[1]] then
                        navsend(closestID, params[1], locations[params[1]])
                    else
                        nPrint("This location does not exist.", "red")
                    end
                else
                    nPrint("PC not in range!", "red")
                end
            end
        else
            nPrint("Usage: navsend <locationname> [computer]", "red")
        end
    end
}
coms.navadd = {
    usage = "navadd <locationname>",
    details = "Save current location for later navigation",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            local gpsPos = getPosition()
            if gpsPos then
                if not isInt(tonumber(params[1])) then
                    if not getComputerID(params[1]) then
                        locations[params[1]] = gpsPos
                        save(locations, locationsPath)
                        nPrint("Location '" .. params[1] .. "' saved.", "green")
                    else
                        nPrint("You cannot name this the same name as a PC name.", "red")
                    end
                else
                    nPrint("You cannot use numbers for the location name. This is reserved for computer IDs.", "red")
                end
            else
                nPrint("No GPS signal available.", "red")
            end
        else
            nPrint("Usage: navadd <locationname>", "red")
        end
    end
}
coms.navlist = {
    usage = "navlist",
    details = "Lists all saved nav points.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        nPrint("Nav Points:", "purple")
        local offsetY = 9
        local tx,ty = term.getSize()
        local maxLines = ty - offsetY
        local scanHeight = 0
        for name, lPos in pairs(locations) do
            local dist = "?"
            local gpsPos = getPosition()
            if gpsPos then
                dist = math.floor(getDistance(gpsPos, lPos))
            end
            nPrint("   " .. name .. " Dist: " .. dist, "green")
            scanHeight = scanHeight + 1
                if scanHeight == maxLines then
                    nPrint("Enter for next page..")
                    read("")
                    scanHeight = 0
                end
        end
    end
}
coms.navremove = {
    usage = "navremove <locationname>",
    details = "Remove location.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            if locations[params[1]] then
                locations[params[1]] = nil
                save(locations, locationsPath)
                nPrint("Location '" .. params[1] .. "' removed.", "green")
            else
                nPrint("Location does not exist.", "red")
            end
        else
            nPrint("Usage: navremove <locationname>", "red")
        end
    end
}
coms.navto = {
    usage = "navto <locationname>",
    details = "Navigate to specified location or computer.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            local gpsPos = getPosition()
            if gpsPos then
                navto = nil
                navtoid = nil
                navigatingToBlock = false
                if localComputers[tonumber(params[1])] and localComputers[tonumber(params[1])].pos then
                    navtoid = tonumber(params[1])
                    navname = localComputers[navtoid].name
                    startMap()
                elseif localComputers[getComputerID(params[1])] then
                    navtoid = getComputerID(params[1])
                    navname = localComputers[navtoid].name
                    startMap()
                elseif locations[params[1]] then
                    navto = locations[params[1]]
                    navname = params[1]
                    startMap()
                else
                    nPrint("Location not found.", "white")
                end
            else
                nPrint("No GPS signal available.", "red")
            end
        else
            nPrint("Usage: navto <locationname>", "red")
        end
    end
}
netcoms.navsend = {
    exec = function (senderID, responseToken, data)
        rednet.send(senderID, {data = "success", responseToken = responseToken}, "NodeOSNetResponse")
        nPrint("Received nav location '" .. data.name .. "'.", "green")
        locations[data.name] = data.pos
        save(locations, locationsPath)
    end
}
function worldTilesUpdateThread()
    while true do
        local gpsPos = getPosition()
        if gpsPos then
            getWorldTiles(gpsPos, 16, 16)
        end
        sleep(0.2)
    end
end
function findBlockThread()
    while true do
        if navigatingToBlock then
            local gpsPos = getPosition()
            if gpsPos then
                local closestBlock = findClosestBlock(gpsPos, navname)
                if closestBlock then
                    navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                else
                    navto = nil
                end
            end
        end
        sleep(5)
    end
end
function startMap()
    parallel.waitForAny(liveMapThread, inputThread, worldTilesUpdateThread, findBlockThread)
end
coms.map = {
    usage = "map",
    details = "Shows the map.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        startMap()
    end
}
coms.find = {
    usage = "find <blockname>",
    details = "Watches for and navigates to a block.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if params[1] then
            local gpsPos = getPosition()
            if gpsPos then
                navto = nil
                navtoid = nil
                navigatingToBlock = true
                getWorldTiles(gpsPos, 16, 16)
                local closestBlock = findClosestBlock(gpsPos, params[1])
                navname = params[1]
                navigatingToBlock = true
                if closestBlock then
                    navto = {x = closestBlock.x, y = closestBlock.y, z = closestBlock.z}
                end
                startMap()
            else
                nPrint("No GPS signal available.", "red")
            end
        else
            nPrint("Usage: find <blockname>", "red")
        end
    end
}
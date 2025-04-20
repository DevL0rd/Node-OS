local map = require("/lib/map")
local termUtils = require("/lib/termUtils")

local locationsFile = "/etc/map/map_locations.cfg"
local locations = {}
local currentTargetName = nil
local isFindMode = false
local isFollowMode = false
local followId = nil
-- create map folder if it doesn't exist
if not fs.exists("/etc/map") then
    fs.makeDir("/etc/map")
end
-- Function to load locations from file using file.readTable
local function loadLocations()
    if not fs.exists(locationsFile) then
        file.writeTable(locationsFile, {})
        locations = {}
    else
        local loadedData = file.readTable(locationsFile)
        if type(loadedData) == "table" then
            locations = loadedData
        else
            locations = {}
            file.writeTable(locationsFile, {})
        end
    end
end

-- Function to save locations to file using file.writeTable
local function saveLocations()
    file.writeTable(locationsFile, locations)
end
local lastpos = nil
local lastDeepScanPos = nil
local debugtext = ""
function doUpdate()
    local currentPos = gps.getPosition()
    if isFindMode and currentTargetName and (not map.getTargetDistance() or map.getTargetDistance() < 5) then
        if not lastpos or gps.getDistance(currentPos, lastpos) > 5 then
            lastpos = currentPos
            local res = gps.getInterestingTiles(10, 9, currentTargetName)
        end
        local block = gps.findBlock(currentTargetName)
        if block then
            map.setTarget(block)
        else
            map.clearTarget()
            if not lastDeepScanPos or gps.getDistance(currentPos, lastDeepScanPos) > 250 then
                debugtext = "Here"
                lastDeepScanPos = currentPos
                local res = gps.getInterestingTiles(128, 128, currentTargetName)
            end
        end
    end
end

function drawUI()
    local w, h = term.getSize()
    if monitor then
        w, h = monitor.getSize()
    end
    map.setRenderPosition(1, 3, w, h - 2)
    termUtils.fillLine(" ", 1, "black", "black")
    termUtils.fillLine(" ", 2, "black", "black")
    termUtils.alignLeft("X: " .. string.format("%.1f", map.pos.x), 1)
    termUtils.centerText("Y: " .. string.format("%.1f", map.pos.y), 1)
    termUtils.alignRight("Z: " .. string.format("%.1f", map.pos.z), 1)
    local currentPos = gps.getPosition()
    if not isFollowMode and currentPos then
        map.setPosition(currentPos.x, currentPos.y, currentPos.z)
        map.setOrientation(currentPos.d)
    end
    if isFindMode and currentTargetName and not map.getTargetDistance() then
        local targetStr = "Deep scanning, this may take a while..."
        termUtils.centerText(targetStr, 2, "white", "black")
    elseif isFollowMode and followId then
        local computer = gps.getComputer(followId)
        if computer and computer.pos then
            local targetStr = computer.name .. "(" .. followId .. "): " .. computer.status
            termUtils.centerText(targetStr, 2, "white", "black")
            map.setPosition(computer.pos.x, computer.pos.y, computer.pos.z)
            map.setOrientation(computer.pos.d)
            map.setTarget(computer.target)
        else
            termUtils.centerText("Target not found", 2, "white", "black")
        end
    elseif currentTargetName and map.getTargetDistance() then
        local targetDistance = map.getTargetDistance()
        local targetStr = "Target: " .. currentTargetName .. " Dist: " .. string.format("%.1f", targetDistance)
        termUtils.centerText(targetStr, 2, "white", "black")
    else
        termUtils.centerText("No target set", 2, "white", "black")
    end
    termUtils.centerText(debugtext, 3, "red", "black")
end

local w, h = term.getSize()
if monitor then
    w, h = monitor.getSize()
end

local args = { ... }
loadLocations()
function printHelp()
    termUtils.print("Usage: map <command> <arguments>")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  save <name> - Saves the current position with the given name.")
    termUtils.print("  delete <name> - Deletes the saved position with the given name.")
    termUtils.print("  find <name> - Finds the closest block with the given name.")
    termUtils.print("  follow <-/id/name> - Sets the target to the saved position with the given name.")
    termUtils.print("  <name> - Sets the target to the saved position with the given name.")
end

if #args > 0 then
    local command = args[1]
    local name = args[2]
    -- don't allow setting name to "help" or "delete" or navto
    if name == "help" or name == "delete" or name == "find" or name == "follow" then
        termUtils.print("Name cannot be 'help', 'delete', 'find', or 'follow'")
        return
    end

    if command == "help" then
        printHelp()
        return
    elseif command == "save" and name then
        local currentPos = gps.getPosition()
        if currentPos then
            locations[name] = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
            saveLocations()
        end
        return
    elseif command == "delete" and name then
        if locations[name] then
            locations[name] = nil
            saveLocations()
        end
        return
    elseif command == "find" and name then
        currentTargetName = name
        isFindMode = true
        gps.getAllInterestingTiles(name)
    elseif command == "follow" and name then
        local cIds = gps.resolveComputersByString(args[2])
        if not cIds then
            termUtils.print("Computer not found!", "red")
            return
        end
        currentTargetName = gps.getComputerName(cIds[1]) .. "(" .. cIds[1] .. ")"
        followId = cIds[1]
        isFollowMode = true
    elseif #args == 1 then
        local targetName = args[1]
        if locations[targetName] then
            local targetPos = locations[targetName]
            map.setTarget(targetPos)
            currentTargetName = targetName
        end
    end
end

map.init(1, 3, w, h - 2, drawUI, doUpdate)

local map = require("/lib/map")


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
-- Function to load locations from file using loadTable
local function loadLocations()
    if not fs.exists(locationsFile) then
        saveTable(locationsFile, {})
        locations = {}
    else
        local loadedData = loadTable(locationsFile)
        if type(loadedData) == "table" then
            locations = loadedData
        else
            locations = {}
            saveTable(locationsFile, {})
        end
    end
end

-- Function to save locations to file using saveTable
local function saveLocations()
    saveTable(locationsFile, locations)
end
local lastpos = nil
local lastDeepScanPos = nil
local debugtext = ""
function doUpdate()
    local currentPos = nodeos.gps.getPosition()
    if isFindMode and currentTargetName and (not map.getTargetDistance() or map.getTargetDistance() < 5) then
        if not lastpos or nodeos.gps.getDistance(currentPos, lastpos) > 5 then
            lastpos = currentPos
            local res = nodeos.gps.getInterestingBlocks(10, 9, currentTargetName)
        end
        local block = nodeos.gps.findBlock(currentTargetName)
        if block then
            map.setTarget(block)
        else
            map.clearTarget()
            if not lastDeepScanPos or nodeos.gps.getDistance(currentPos, lastDeepScanPos) > 250 then
                debugtext = "Here"
                lastDeepScanPos = currentPos
                local res = nodeos.gps.getInterestingBlocks(128, 128, currentTargetName)
            end
        end
    end
end

function drawUI()
    local w, h = term.getSize()
    map.setRenderPosition(1, 3, w, h - 2)
    nodeos.graphics.fillLine(" ", 1, "black", "black")
    nodeos.graphics.fillLine(" ", 2, "black", "black")
    nodeos.graphics.alignLeft("X: " .. string.format("%.1f", map.pos.x), 1)
    nodeos.graphics.centerText("Y: " .. string.format("%.1f", map.pos.y), 1)
    nodeos.graphics.alignRight("Z: " .. string.format("%.1f", map.pos.z), 1)
    local currentPos = nodeos.gps.getPosition()
    if not isFollowMode and currentPos then
        map.setPosition(currentPos.x, currentPos.y, currentPos.z)
        map.setOrientation(currentPos.d)
    end
    if isFindMode and currentTargetName and not map.getTargetDistance() then
        local targetStr = "Deep scanning, this may take a while..."
        nodeos.graphics.centerText(targetStr, 2, "white", "black")
    elseif isFollowMode and followId then
        local computer = nodeos.gps.getComputer(followId)
        if computer and computer.pos then
            local targetStr = computer.status
            nodeos.graphics.centerText(targetStr, 2, "white", "black")
            map.setPosition(computer.pos.x, computer.pos.y, computer.pos.z)
            map.setOrientation(computer.pos.d)
            if computer.target then
                map.setTarget(computer.target)
            end
        else
            nodeos.graphics.centerText("Target not found", 2, "white", "black")
        end
    elseif currentTargetName and map.getTargetDistance() then
        local targetDistance = map.getTargetDistance()
        local targetStr = "Target: " .. currentTargetName .. " Dist: " .. string.format("%.1f", targetDistance)
        nodeos.graphics.centerText(targetStr, 2, "white", "black")
    else
        nodeos.graphics.centerText("No target set", 2, "white", "black")
    end
    nodeos.graphics.centerText(debugtext, 3, "red", "black")
end

local w, h = term.getSize()
local args = { ... }
loadLocations()
function printHelp()
    nodeos.graphics.print("Usage: map <command> <arguments>")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  save <name> - Saves the current position with the given name.")
    nodeos.graphics.print("  delete <name> - Deletes the saved position with the given name.")
    nodeos.graphics.print("  find <name> - Finds the closest block with the given name.")
    nodeos.graphics.print("  follow <-/id/name> - Sets the target to the saved position with the given name.")
    nodeos.graphics.print("  <name> - Sets the target to the saved position with the given name.")
end

if #args > 0 then
    local command = args[1]
    local name = args[2]
    -- don't allow setting name to "help" or "delete" or navto
    if name == "help" or name == "delete" or name == "find" or name == "follow" then
        nodeos.graphics.print("Name cannot be 'help', 'delete', 'find', or 'follow'")
        return
    end

    if command == "help" then
        printHelp()
        return
    elseif command == "save" and name then
        local currentPos = nodeos.gps.getPosition()
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
        nodeos.gps.getAllInterestingBlocks(name)
    elseif command == "follow" and name then
        local cIds = nodeos.gps.resolveComputersByString(args[2])
        if not next(cIds) then
            nodeos.graphics.print("Computer not found!", "red")
            return
        end
        local comname = nodeos.gps.getComputerName(cIds[1]) or "Unknown"
        currentTargetName = comname .. "(" .. cIds[1] .. ")"
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

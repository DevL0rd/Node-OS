local turtleUtils = require("/lib/turtleUtils")
local butler_settings_path = "etc/butler/settings.cfg"
local butler_settings = {
    home = nil,
    status = "idle",
    navtoid = nil,
    navname = "",
    pointsTraveled = 0,
    canBreakBlocks = true,
    blockList = {}
}
local isSaving = false

function saveButler()
    if not isSaving then
        isSaving = true
        saveTable(butler_settings_path, butler_settings)
        isSaving = false
    end
end

function getDisplayName(fullName)
    if type(fullName) == "string" and fullName:find(":") then
        return fullName:match(".-:(.*)")
    end
    return fullName
end

if fs.exists(butler_settings_path) then
    butler_settings = loadTable(butler_settings_path)
    turtleUtils.blockList = butler_settings.blockList or {}
else
    saveButler()
end
if butler_settings.home then
    turtleUtils.replaceBlocksBehindDisabledDepth = butler_settings.home.y - 20
end
local lastblockUpdatePosition = nil
local updatingBlocks = false

function blockUpdateThread()
    updatingBlocks = true
    while true do
        if butler_settings.status == "findingBlocks" then
            if not lastblockUpdatePosition then
                updatingBlocks = true
                local res = nodeos.gps.getAllInterestingBlocks(butler_settings.navname)
                if res then
                    butler_settings.navname = res.name
                end
                local res = nodeos.gps.getInterestingBlocks(32, 32, butler_settings.navname)
                if res then
                    lastblockUpdatePosition = deepcopy(turtleUtils.pos)
                    butler_settings.navname = res.name
                end
                saveButler()
            else
                local distanceFromLastCheck = nodeos.gps.getDistance(lastblockUpdatePosition, turtleUtils.pos)
                if distanceFromLastCheck > 7 then
                    updatingBlocks = true
                    local res = nodeos.gps.getInterestingBlocks(10, 9, butler_settings.navname)
                    if res then
                        lastblockUpdatePosition = deepcopy(turtleUtils.pos)
                    end
                end
            end
            updatingBlocks = false
        end
        sleep(0.1)
    end
end

local chests = {}

function findBlocks_step()
    if turtleUtils.hasNoSlots() or
        (butler_settings.gatherCount and butler_settings.pointsTraveled == butler_settings.gatherCount) then
        butler_settings.status = "returning"
        saveButler()
        return
    end
    local gatherCountString = ""
    if butler_settings.gatherCount then
        gatherCountString = " (" .. butler_settings.pointsTraveled .. "/" .. butler_settings.gatherCount .. ")"
    else
        gatherCountString = " (" .. butler_settings.pointsTraveled .. "/Inf)"
    end
    if updatingBlocks then
        nodeos.gps.setStatus("Scanning for '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        return
    end
    nodeos.gps.setStatus("Finding '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
    local closestBlock = nodeos.gps.findBlock(butler_settings.navname)
    nodeos.gps.clearStatus()
    if not closestBlock then
        nodeos.gps.setStatus("Deep scanning for '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        local res = nodeos.gps.getInterestingBlocks(128, 128, butler_settings.navname)
        nodeos.gps.clearStatus()
        if res then
            lastblockUpdatePosition = deepcopy(turtleUtils.pos)
            butler_settings.navname = res.name
        end
        nodeos.gps.setStatus("Finding '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        closestBlock = nodeos.gps.findBlock(butler_settings.navname)
        nodeos.gps.clearStatus()
    end
    if closestBlock then
        nodeos.gps.removeInterestingblock(closestBlock.name, closestBlock)
        turtleUtils.targetBlockName = closestBlock.name
        nodeos.gps.setTarget(closestBlock)
        nodeos.gps.setStatus("Navigating to " .. getDisplayName(closestBlock.name) .. gatherCountString)
        turtleUtils.goTo(closestBlock, butler_settings.canBreakBlocks, 0)
        nodeos.gps.clearStatus()
        nodeos.gps.clearTarget()
        turtleUtils.targetBlockName = "notset"
        butler_settings.pointsTraveled = butler_settings.pointsTraveled + 1
    else
        butler_settings.status = "returning"
        saveButler()
    end
end

function storeBlocks_step()
    -- if you have things in your inventory
    -- local inventory = turtleUtils.getInventoryByNames()
    -- if next(inventory) ~= nil then
    --     butler_settings.navname = "minecraft:chest"
    --     lastblockUpdatePosition = nil
    --     sleep(0.5)
    --     while updatingBlocks do
    --         sleep(0.5)
    --     end
    --     local chests = nodeos.gps.getBlocksByDistance("minecraft:chest")
    --     if chests then
    --         for _, item in pairs(inventory) do
    --             local currentItem = item.name
    --             for i, v in ipairs(chests) do
    --                 local key = v.pos.x .. "," .. v.pos.y .. "," .. v.pos.z
    --                 if chests[key] then
    --                     if chests[key] == currentItem then
    --                         for i = 1, #item.slots do
    --                             chest.pushItems("minecraft:chest_0", item.slots[i])
    --                         end
    --                         break
    --                     end
    --                 else
    --                     -- goto chest and see what first item is

    --                     turtleUtils.goTo(v.pos, false, 1)
    --                     local chest = peripheral.wrap("minecraft:chest_0")
    --                     local cItem = chest.getItemDetail(1)
    --                     if cItem then
    --                         chests[key] = cItem.name
    --                         if cItem.name == currentItem then
    --                             for i = 1, #item.slots do
    --                                 chest.pushItems("minecraft:chest_0", item.slots[i])
    --                             end
    --                             break
    --                         end
    --                     else
    --                         chests[key] = currentItem
    --                         for i = 1, #item.slots do
    --                             chest.pushItems("minecraft:chest_0", item.slots[i])
    --                         end
    --                         break
    --                     end


    --                     print(("%s (%s)"):format(item.displayName, item.name))
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- local nodeos.gps.getChests
end

function follow_step()
    local navToComputer = nodeos.gps.getComputer(butler_settings.navtoid)
    if navToComputer then
        local computerString = navToComputer.name .. "(" .. butler_settings.navtoid .. ")"
        navToComputer.pos.y = navToComputer.pos.y - 2
        nodeos.gps.setTarget({
            x = navToComputer.pos.x,
            y = navToComputer.pos.y,
            z = navToComputer.pos.z,
            name = computerString
        })
        nodeos.gps.setStatus("Following " .. computerString)
        turtleUtils.goTo(navToComputer.pos, butler_settings.canBreakBlocks, 2)
        nodeos.gps.clearTarget()
    end
end

function dumpItems()
    if nodeos.gps.interestingBlocksBlacklist then
        turtleUtils.dumpItems(nodeos.gps.interestingBlocksBlacklist)
        turtle.select(1)
    end
end

function butlerThread()
    turtleUtils.calibrate()
    nodeos.gps.getInterestingBlocksBlacklist()
    while true do
        if butler_settings.status == "storeblocks" then
            storeBlocks_step()
        elseif butler_settings.status == "returning" then
            nodeos.gps.setTarget({
                x = butler_settings.home.x,
                y = butler_settings.home.y,
                z = butler_settings.home.z,
                name = "Home"
            })
            nodeos.gps.setStatus("Returning home...")
            turtleUtils.goTo(butler_settings.home, butler_settings.canBreakBlocks, 0)
            nodeos.gps.clearTarget()
            nodeos.gps.clearStatus()
            butler_settings.status = "storeblocks"
            resetState()
            saveButler()
        elseif butler_settings.status == "findingBlocks" then
            findBlocks_step()
            dumpItems()
        elseif butler_settings.status == "following" then
            follow_step()
        end
        sleep(0.2)
    end
end

if turtle then
    nodeos.createProcess(blockUpdateThread, { isService = true, title = "blockUpdateThread" })
    nodeos.createProcess(butlerThread, { isService = true, title = "service_butler" })
end

function listen_find()
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_butlerFind")
        if not msg or not msg.data then
            nodeos.logging.error("ButlerService", "Received invalid butlerFind request from #" .. cid)
            nodeos.net.respond(cid, msg and msg.token, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        if not msg.data.name then
            nodeos.logging.error("ButlerService", "Missing name parameter in butlerFind request from #" .. cid)
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "Missing required parameter: name"
            })
            goto continue
        end

        local pairedClients = nodeos.net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    local data = msg.data
                    resetState()
                    nodeos.gps.getInterestingBlocksBlacklist()
                    if not turtleUtils.hasNoSlots() then
                        butler_settings.navname = data.name
                        if data.count then
                            if type(data.count) ~= "number" or data.count <= 0 then
                                nodeos.logging.warn("ButlerService",
                                    "Invalid count parameter from #" .. cid .. ": " .. tostring(data.count))
                                nodeos.net.respond(cid, msg.token, {
                                    success = false,
                                    message = "Count must be a positive number"
                                })
                                goto continue
                            end
                            butler_settings.gatherCount = data.count
                        end
                        butler_settings.status = "findingBlocks"
                        saveButler()
                        nodeos.net.respond(cid, msg.token, {
                            success = true
                        })
                    else
                        nodeos.net.respond(cid, msg.token, {
                            success = false,
                            message = "Inventory full!"
                        })
                    end
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_find, { isService = true, title = "listen_find" })

function listen_sethome()
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_setHome")
        if not msg then
            nodeos.logging.error("ButlerService", "Received invalid setHome request from #" .. cid)
            nodeos.net.respond(cid, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        local pairedClients = nodeos.net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                local gpsPos = nodeos.gps.getPosition(true)
                if gpsPos then
                    butler_settings.home = gpsPos
                    turtleUtils.replaceBlocksBehindDisabledDepth = butler_settings.home.y - 20
                    resetState()
                    butler_settings.status = "home"
                    saveButler()
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = "Home set to " .. gpsPos.x .. "," .. gpsPos.y .. "," .. gpsPos.z
                    })
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "No nodeos.gps signal!"
                    })
                end
            else
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_sethome, { isService = true, title = "listen_sethome" })

function listen_return()
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_return")
        if not msg then
            nodeos.logging.error("ButlerService", "Received invalid return request from #" .. cid)
            nodeos.net.respond(cid, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        local pairedClients = nodeos.net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    nodeos.gps.getInterestingBlocksBlacklist()
                    butler_settings.status = "returning"
                    local data = msg.data or {}
                    if data.canBreakBlocks ~= nil then
                        if type(data.canBreakBlocks) ~= "boolean" then
                            nodeos.logging.warn("ButlerService", "Invalid canBreakBlocks parameter from #" .. cid)
                            nodeos.net.respond(cid, msg.token, {
                                success = false,
                                message = "canBreakBlocks parameter must be a boolean"
                            })
                            goto continue
                        end
                        butler_settings.canBreakBlocks = data.canBreakBlocks
                    end
                    saveButler()
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = "Going home... (canBreakBlocks: " .. tostring(butler_settings.canBreakBlocks) .. ")"
                    })
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_return, { isService = true, title = "listen_return" })

function listen_follow()
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_follow")
        if not msg then
            nodeos.logging.error("ButlerService", "Received invalid follow request from #" .. cid)
            nodeos.net.respond(cid, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        local pairedClients = nodeos.net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    butler_settings.navtoid = cid
                    butler_settings.status = "following"
                    local data = msg.data or {}
                    if data.canBreakBlocks ~= nil then
                        if type(data.canBreakBlocks) ~= "boolean" then
                            nodeos.logging.warn("ButlerService", "Invalid canBreakBlocks parameter from #" .. cid)
                            nodeos.net.respond(cid, msg.token, {
                                success = false,
                                message = "canBreakBlocks parameter must be a boolean"
                            })
                            goto continue
                        end
                        butler_settings.canBreakBlocks = data.canBreakBlocks
                    end
                    saveButler()
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = "Following computer '" ..
                            cid .. "'. (canBreakBlocks: " .. tostring(butler_settings.canBreakBlocks) .. ")"
                    })
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_follow, { isService = true, title = "listen_follow" })

function listen_toggleBreaking()
    while true do
        local cid, msg = nodeos.net.receive("NodeOS_toggleBreaking")
        if not msg then
            nodeos.logging.error("ButlerService", "Received invalid toggleBreaking request from #" .. cid)
            nodeos.net.respond(cid, nil, {
                success = false,
                message = "Invalid request format"
            })
            goto continue
        end

        local pairedClients = nodeos.net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    butler_settings.canBreakBlocks = not butler_settings.canBreakBlocks
                    saveButler()
                    nodeos.net.respond(cid, msg.token, {
                        success = true,
                        message = "Breaking blocks is now " .. tostring(butler_settings.canBreakBlocks) .. "."
                    })
                else
                    nodeos.net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                nodeos.net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            nodeos.net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end

        ::continue::
    end
end

nodeos.createProcess(listen_toggleBreaking, { isService = true, title = "listen_toggleBreaking" })

function resetState()
    butler_settings.status = "idle"
    butler_settings.navtoid = nil
    butler_settings.navname = nil
    butler_settings.pointsTraveled = 0
    butler_settings.gatherCount = nil
    lastblockUpdatePosition = nil
end

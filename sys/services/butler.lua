local termUtils = require("/lib/termUtils")
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
        file.writeTable(butler_settings_path, butler_settings)
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
    butler_settings = file.readTable(butler_settings_path)
    turtleUtils.blockList = butler_settings.blockList or {}
else
    saveButler()
end
if butler_settings.home then
    turtleUtils.replaceBlocksBehindDisabledDepth = butler_settings.home.y - 20
end
local lastTileUpdatePosition = nil
local updatingTiles = false

function tileUpdateThread()
    updatingTiles = true
    while true do
        if butler_settings.status == "findingBlocks" then
            if not lastTileUpdatePosition then
                updatingTiles = true
                local res = gps.getAllInterestingTiles(butler_settings.navname)
                if res then
                    butler_settings.navname = res.name
                end
                local res = gps.getInterestingTiles(32, 32, butler_settings.navname)
                if res then
                    lastTileUpdatePosition = deepcopy(turtleUtils.pos)
                    butler_settings.navname = res.name
                end
                saveButler()
            else
                local distanceFromLastCheck = gps.getDistance(lastTileUpdatePosition, turtleUtils.pos)
                if distanceFromLastCheck > 7 then
                    updatingTiles = true
                    local res = gps.getInterestingTiles(10, 9, butler_settings.navname)
                    if res then
                        lastTileUpdatePosition = deepcopy(turtleUtils.pos)
                    end
                end
            end
            updatingTiles = false
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
    if updatingTiles then
        gps.setStatus("Scanning for '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        return
    end
    gps.setStatus("Finding '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
    local closestBlock = gps.findBlock(butler_settings.navname)
    gps.clearStatus()
    if not closestBlock then
        gps.setStatus("Deep scanning for '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        local res = gps.getInterestingTiles(128, 128, butler_settings.navname)
        gps.clearStatus()
        if res then
            lastTileUpdatePosition = deepcopy(turtleUtils.pos)
            butler_settings.navname = res.name
        end
        gps.setStatus("Finding '" .. getDisplayName(butler_settings.navname) .. "'" .. gatherCountString)
        closestBlock = gps.findBlock(butler_settings.navname)
        gps.clearStatus()
    end
    if closestBlock then
        gps.removeInterestingTile(closestBlock.name, closestBlock)
        turtleUtils.targetBlockName = closestBlock.name
        gps.setTarget(closestBlock)
        gps.setStatus("Navigating to " .. getDisplayName(closestBlock.name) .. gatherCountString)
        turtleUtils.goTo(closestBlock, butler_settings.canBreakBlocks, 0)
        gps.clearStatus()
        gps.clearTarget()
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
    --     lastTileUpdatePosition = nil
    --     sleep(0.5)
    --     while updatingTiles do
    --         sleep(0.5)
    --     end
    --     local chests = gps.getTilesByDistance("minecraft:chest")
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
    -- local gps.getChests
end

function follow_step()
    local navToComputer = gps.getComputer(butler_settings.navtoid)
    if navToComputer then
        local computerString = navToComputer.name .. "(" .. butler_settings.navtoid .. ")"
        navToComputer.pos.y = navToComputer.pos.y - 2
        gps.setTarget({
            x = navToComputer.pos.x,
            y = navToComputer.pos.y,
            z = navToComputer.pos.z,
            name = computerString
        })
        gps.setStatus("Following " .. computerString)
        turtleUtils.goTo(navToComputer.pos, butler_settings.canBreakBlocks, 2)
        gps.clearTarget()
    end
end

function dumpItems()
    if gps.interestingTilesBlacklist then
        turtleUtils.dumpItems(gps.interestingTilesBlacklist)
        turtle.select(1)
    end
end

function butlerThread()
    turtleUtils.calibrate()
    gps.getInterestingTilesBlacklist()
    while true do
        if butler_settings.status == "storeblocks" then
            storeBlocks_step()
        elseif butler_settings.status == "returning" then
            gps.setTarget({
                x = butler_settings.home.x,
                y = butler_settings.home.y,
                z = butler_settings.home.z,
                name = "Home"
            })
            gps.setStatus("Returning home...")
            turtleUtils.goTo(butler_settings.home, butler_settings.canBreakBlocks, 0)
            gps.clearTarget()
            gps.clearStatus()
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
    pm.createProcess(tileUpdateThread, { isService = true, title = "tileUpdateThread" })
    pm.createProcess(butlerThread, { isService = true, title = "service_butler" })
end

function listen_find()
    while true do
        local cid, msg = rednet.receive("NodeOS_butlerFind")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    local data = msg.data
                    resetState()
                    gps.getInterestingTilesBlacklist()
                    if not turtleUtils.hasNoSlots() then
                        butler_settings.navname = data.name
                        if data.count then
                            butler_settings.gatherCount = data.count
                        end
                        butler_settings.status = "findingBlocks"
                        saveButler()
                        net.respond(cid, msg.token, {
                            success = true
                        })
                    else
                        net.respond(cid, msg.token, {
                            success = false,
                            message = "Inventory full!"
                        })
                    end
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

pm.createProcess(listen_find, { isService = true, title = "listen_find" })

function listen_sethome()
    while true do
        local cid, msg = rednet.receive("NodeOS_setHome")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                local gpsPos = gps.getPosition(true)
                if gpsPos then
                    butler_settings.home = gpsPos
                    turtleUtils.replaceBlocksBehindDisabledDepth = butler_settings.home.y - 20
                    resetState()
                    butler_settings.status = "home"
                    saveButler()
                    net.respond(cid, msg.token, {
                        success = true,
                        message = "Home set to " .. gpsPos.x .. "," .. gpsPos.y .. "," .. gpsPos.z
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = "No gps signal!"
                    })
                end
            else
                net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

pm.createProcess(listen_sethome, { isService = true, title = "listen_sethome" })

function listen_return()
    while true do
        local cid, msg = rednet.receive("NodeOS_return")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    gps.getInterestingTilesBlacklist()
                    butler_settings.status = "returning"
                    local data = msg.data
                    if data.canBreakBlocks then
                        butler_settings.canBreakBlocks = data.canBreakBlocks
                    else
                        if data.canBreakBlocks == false then
                            butler_settings.canBreakBlocks = false
                        end
                    end
                    saveButler()
                    net.respond(cid, msg.token, {
                        success = true,
                        message = "Going home... (canBreakBlocks: " .. tostring(butler_settings.canBreakBlocks) .. ")"
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

pm.createProcess(listen_return, { isService = true, title = "listen_return" })

function listen_follow()
    while true do
        local cid, msg = rednet.receive("NodeOS_follow")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    butler_settings.navtoid = cid
                    butler_settings.status = "following"
                    local data = msg.data
                    if data.canBreakBlocks then
                        butler_settings.canBreakBlocks = data.canBreakBlocks
                    else
                        if data.canBreakBlocks == false then
                            butler_settings.canBreakBlocks = false
                        end
                    end
                    saveButler()
                    net.respond(cid, msg.token, {
                        success = true,
                        message = "Following computer '" ..
                            cid .. "'. (canBreakBlocks: " .. tostring(butler_settings.canBreakBlocks) .. ")"
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

pm.createProcess(listen_follow, { isService = true, title = "listen_follow" })

function listen_toggleBreaking()
    while true do
        local cid, msg = rednet.receive("NodeOS_toggleBreaking")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    butler_settings.canBreakBlocks = not butler_settings.canBreakBlocks
                    saveButler()
                    net.respond(cid, msg.token, {
                        success = true,
                        message = "Breaking blocks is now " .. tostring(butler_settings.canBreakBlocks) .. "."
                    })
                else
                    net.respond(cid, msg.token, {
                        success = false,
                        message = "No home set! Please set a home location with the sethome command."
                    })
                end
            else
                net.respond(cid, msg.token, {
                    success = false,
                    message = "This is not a turtle!"
                })
            end
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

pm.createProcess(listen_toggleBreaking, { isService = true, title = "listen_toggleBreaking" })

function resetState()
    butler_settings.status = "idle"
    butler_settings.navtoid = nil
    butler_settings.navname = nil
    butler_settings.pointsTraveled = 0
    butler_settings.gatherCount = nil
    lastTileUpdatePosition = nil
end

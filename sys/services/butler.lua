local termUtils = require("/lib/termUtils")
local turtleUtils = require("/lib/turtleUtils")
local net = require("/lib/net")
local gps = require("/lib/gps")
local util = require("/lib/util")
local file = util.loadModule("file")

local butler_settings_path = "etc/butler/settings.cfg"
local butler_settings = {
    home = nil,
    status = "idle",
    navtoid = nil,
    navname = "",
    pointsTraveled = 0,
    canBreakBlocks = false,
}
local statusMessage = "Waiting for command..."
local isSaving = false
function saveButler()
    if not isSaving then
        isSaving = true
        file.writeTable(butler_settings_path, butler_settings)
        isSaving = false
    end
end

if fs.exists(butler_settings_path) then
    butler_settings = file.readTable(butler_settings_path)
else
    saveButler()
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
                    for i, v in ipairs(res.tiles) do
                        print(i)
                    end
                    butler_settings.navname = res.name
                end
                saveButler()
            else
                local distanceFromLastCheck = gps.getDistance(lastTileUpdatePosition, turtleUtils.pos)
                if distanceFromLastCheck > 12 then
                    updatingTiles = true
                    local res = gps.getInterestingTiles(16, 16, butler_settings.navname)
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
        statusMessage = "Inventory full, returning to home."
        butler_settings.status = "returning"
        saveButler()
        return
    end
    if updatingTiles then
        statusMessage = "Scanning new tiles..."
        return
    end
    statusMessage = "Looking for '" .. butler_settings.navname .. "'..."
    local closestBlock = gps.findBlock(butler_settings.navname)
    if closestBlock then
        local gpsPos = gps.getPosition()
        local dist = "?"
        if gpsPos then
            dist = gps.getDistance(gpsPos, closestBlock, true)
        end
        statusMessage = "Navigating to " ..
            closestBlock.name ..
            ". Distance: " .. dist
        gps.removeInterestingTile(closestBlock.name, closestBlock)
        turtleUtils.goTo(closestBlock, butler_settings.canBreakBlocks, 0)
        butler_settings.pointsTraveled = butler_settings.pointsTraveled + 1

    else
        statusMessage = "Can't find block, returning home."
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
    local localComputers = gps.getLocalComputers()
    local navToComputer = localComputers[butler_settings.navtoid]
    if navToComputer then
        statusMessage = "Following computer '" .. navToComputer.name .. "'."
        navToComputer.pos.y = navToComputer.pos.y - 2
        turtleUtils.goTo(navToComputer.pos, butler_settings.canBreakBlocks, 2)
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
        if butler_settings.status == "home" then
            storeBlocks_step()
        elseif butler_settings.status == "returning" then
            turtleUtils.goTo(butler_settings.home, butler_settings.canBreakBlocks, 0)
            butler_settings.status = "home"
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
    parallel.addOSThread(tileUpdateThread)
    parallel.addOSThread(butlerThread)
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
                        statusMessage = "Looking for '" .. data.name .. "'..."
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

parallel.addOSThread(listen_find)


function listen_sethome()
    while true do
        local cid, msg = rednet.receive("NodeOS_setHome")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                local gpsPos = gps.getPosition(true)
                if gpsPos then
                    butler_settings.home = gpsPos
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

parallel.addOSThread(listen_sethome)

-- NodeOS_return
function listen_return()
    while true do
        local cid, msg = rednet.receive("NodeOS_return")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    gps.getInterestingTilesBlacklist()
                    statusMessage = "Going home..."
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

parallel.addOSThread(listen_return)

function listen_follow()
    while true do
        local cid, msg = rednet.receive("NodeOS_follow")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                if butler_settings.home then
                    resetState()
                    statusMessage = "Following computer '" .. cid .. "'."
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

parallel.addOSThread(listen_follow)
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

parallel.addOSThread(listen_toggleBreaking)

-- NodeOS_butlerStatus
function listen_status()
    while true do
        local cid, msg = rednet.receive("NodeOS_butlerStatus")
        local pairedClients = net.getPairedClients()
        if pairedClients[cid] then
            if turtle then
                net.respond(cid, msg.token, {
                    success = true,
                    status = statusMessage
                })
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

parallel.addOSThread(listen_status)

function resetState()
    statusMessage = "Waiting for command..."
    butler_settings.status = "idle"
    butler_settings.navtoid = nil
    butler_settings.navname = nil
    butler_settings.pointsTraveled = 0
    butler_settings.gatherCount = nil
    lastTileUpdatePosition = nil
end
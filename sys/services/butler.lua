local termUtils = require("/lib/termUtils")
local turtleUtils = require("/lib/turtleUtils")
local net = require("/lib/net")
local gps = require("/lib/gps")
local util = require("/lib/util")
local file = util.loadModule("file")

local butler_settings_path = "etc/butler/settings.cfg"
local butler_settings = {
    home = {
        x = 0,
        y = 0,
        z = 0
    },
    status = "idle",
    navto = nil,
    navtoid = nil,
    navname = "",
    pointsTraveled = 0,
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
                local res = gps.getInterestingTiles(32, 32, butler_settings.navname)
                if res then
                    lastTileUpdatePosition = deepcopy(turtleUtils.pos)
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
        sleep(0.5)
    end
end

local gatherCount = nil
function butlerThread()
    turtleUtils.calibrate()
    while true do
        if butler_settings.status == "findingBlocks" and turtleUtils.hasNoSlots() or
            (gatherCount and butler_settings.pointsTraveled == gatherCount) then
            statusMessage = "Inventory full, returning to home."
            butler_settings.status = "returning"
            butler_settings.navto = butler_settings.home
            saveButler()
        end
        if butler_settings.status == "findingBlocks" then
            statusMessage = "Scanning for blocks..."
            while updatingTiles do
                sleep(0.5)
            end
            local closestBlock = gps.findBlock(butler_settings.navname)
            if closestBlock then
                statusMessage = "Block found! Navigating to " ..
                    closestBlock.name ..
                    " at " .. closestBlock.x .. "," .. closestBlock.y .. "," .. closestBlock.z .. "."
                butler_settings.navto = { x = closestBlock.x, y = closestBlock.y, z = closestBlock.z }
            else
                statusMessage = "Can't find block, returning home."
                butler_settings.status = "returning"
                butler_settings.navto = butler_settings.home
                saveButler()
            end
        elseif butler_settings.navtoid then
            local localComputers = gps.getLocalComputers()
            local navToComputer = localComputers[butler_settings.navtoid]
            if navToComputer then
                statusMessage = "Following computer '" .. navToComputer.name .. "'."
                butler_settings.navto = navToComputer.pos
                saveButler()
            end
        end
        if butler_settings.navto then
            turtleUtils.goTo(butler_settings.navto, true, butler_settings.navname)
            butler_settings.pointsTraveled = butler_settings.pointsTraveled + 1
            butler_settings.navto = nil
            statusMessage = "Waiting for command..."
            saveButler()
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
        if not turtle then
            net.respond(cid, msg.token, {
                success = false,
                message = "This is not a turtle!"
            })
        end
        if pairedClients[cid] then
            local data = msg.data
            resetState()
            if data.name then
                butler_settings.navname = data.name
                if data.count then
                    butler_settings.gatherCount = data.count
                end
                butler_settings.status = "findingBlocks"
                statusMessage = "Looking for '" .. data.name .. "'..."
                net.respond(cid, msg.token, {
                    success = true
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
        if not turtle then
            net.respond(cid, msg.token, {
                success = false,
                message = "This is not a turtle!"
            })
        end
        if pairedClients[cid] then
            local gpsPos = gps.getPosition(true)
            if gpsPos then
                butler_settings.home = gpsPos
                saveButler()
                net.respond(cid, msg.token, {
                    success = false,
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
        if not turtle then
            net.respond(cid, msg.token, {
                success = false,
                message = "This is not a turtle!"
            })
        end
        if pairedClients[cid] then
            resetState()
            statusMessage = "Going home..."
            butler_settings.status = "returning"
            butler_settings.navto = butler_settings.home
            --saveButler()
            net.respond(cid, msg.token, {
                success = true
            })
        else
            net.respond(cid, msg.token, {
                success = false,
                message = "You are not paired with this computer!"
            })
        end
    end
end

parallel.addOSThread(listen_return)
-- NodeOS_butlerStatus
function listen_status()
    while true do
        local cid, msg = rednet.receive("NodeOS_butlerStatus")
        local pairedClients = net.getPairedClients()
        if not turtle then
            net.respond(cid, msg.token, {
                success = false,
                message = "This is not a turtle!"
            })
        end
        if pairedClients[cid] then
            net.respond(cid, msg.token, {
                success = true,
                status = statusMessage
            })
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
    butler_settings.navto = nil
    butler_settings.navtoid = nil
    butler_settings.navname = ""
    butler_settings.pointsTraveled = 0
    butler_settings.gatherCount = nil
end
local termUtils = require("/lib/termUtils")
local turtleUtils = require("/lib/turtleUtils")
local gps = require("/lib/gps")
local worldTiles = {}
local navigatingToBlock = false
local navto = nil
local navtoid = nil
local navname = ""

function worldTilesUpdateThread()
    while true do
        gps.getWorldTiles(16, 16)
        sleep(5)
    end
end

function butlerThread()
    while true do
        turtleUtils.goTo(navto)
        local closestBlock = gps.findBlock(navname)
        if closestBlock then
            navto = { x = closestBlock.x, y = closestBlock.y, z = closestBlock.z }
        end
        sleep(0.5)
    end
end

function start()
    turtleUtils.calibrate()
    parallel.waitForAny(butlerThread, worldTilesUpdateThread)
end

-- usage
-- butler find <block>
-- butler goto <block,computer>

local args = { ... }
if args[1] == "find" then
    if args[2] then
        local gpsPos = gps.getPosition()
        if gpsPos then
            navto = nil
            navtoid = nil
            navname = args[2]
            navigatingToBlock = true
            worldTiles = gps.getAllWorldTiles()
            worldTiles = gps.getWorldTiles(16, 16)
            local closestBlock = gps.findBlock(navname)
            if closestBlock then
                navto = { x = closestBlock.x, y = closestBlock.y, z = closestBlock.z }
                start()
            else
                termUtils.print("Can't find block. This is just a test anyway. Will travel later.", "red")
                navto = nil
            end
        else
            termUtils.print("No GPS signal available.", "red")
        end
    else
        termUtils.print("No block name specified.", "red")
    end
end
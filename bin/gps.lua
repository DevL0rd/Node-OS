local args = { ... }

function printHelp()
    nodeos.graphics.print("Usage: nodeos.gps <command> <arguments>")
    nodeos.graphics.print("  You can use '-' in place of id to get closest computer.")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  positions|pos - Gets the current position.")
    nodeos.graphics.print("  setoffset <computergroup|name|id|-> - Remotely set the offset of target pc to current pc.")
end

if #args == 0 then
    printHelp()
    return
end

if args[1] == "setoffset" then
    local cIds = nodeos.gps.resolveComputersByString(args[2], true)
    if not cIds then
        nodeos.graphics.print("No paired computer found!", "red")
        return
    end
    local gpsPos = nodeos.gps.getPosition()
    if gpsPos then
        for i, cId in ipairs(cIds) do
            local res = nodeos.net.emit("NodeOS_setOffset", {
                pos = gpsPos
            }, cId)
            if res then
                if res.success then
                    nodeos.graphics.print(res.message, "green")
                else
                    nodeos.graphics.print(res.message, "red")
                end
            else
                nodeos.graphics.print("Failed to connect!", "red")
            end
        end
    else
        nodeos.graphics.print("No GPS position available!", "red")
    end
elseif args[1] == "position" or args[1] == "pos" then
    local gpsPos = nodeos.gps.getPosition()
    if gpsPos then
        local direction = nodeos.gps.getDirectionString(gpsPos.d)
        nodeos.graphics.print(gpsPos.x .. "," .. gpsPos.y .. "," .. gpsPos.z .. " " .. direction, "green")
    else
        nodeos.graphics.print("No GPS position available!", "red")
    end
else
    printHelp()
end

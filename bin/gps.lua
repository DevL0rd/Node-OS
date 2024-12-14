local termUtils = require("/lib/termUtils")
local args = { ... }

function printHelp()
    termUtils.print("Usage: gps <command> <arguments>")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  positions|pos - Gets the current position.")
    termUtils.print("  setoffset <computergroup|name|id|-> - Remotely set the offset of target pc to current pc.")
end

if #args == 0 then
    printHelp()
    return
end

if args[1] == "setoffset" then
    local cIds = gps.resolveComputersByString(args[2], true)
    if not cIds then
        termUtils.print("No paired computer found!", "red")
        return
    end
    local gpsPos = gps.getPosition()
    if gpsPos then
        for i, cId in ipairs(cIds) do
            local res = net.emit("NodeOS_setOffset", {
                pos = gpsPos
            }, cId)
            if res then
                if res.success then
                    termUtils.print(res.message, "green")
                else
                    termUtils.print(res.message, "red")
                end
            else
                termUtils.print("Failed to connect!", "red")
            end
        end
    else
        termUtils.print("No GPS position available!", "red")
    end
elseif args[1] == "position" or args[1] == "pos" then
    local gpsPos = gps.getPosition()
    if gpsPos then
        local direction = gps.getDirectionString(gpsPos.d)
        termUtils.print(gpsPos.x .. "," .. gpsPos.y .. "," .. gpsPos.z .. " " .. direction, "green")
    else
        termUtils.print("No GPS position available!", "red")
    end
else
    printHelp()
end

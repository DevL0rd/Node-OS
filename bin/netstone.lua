local termUtils = require("/lib/termUtils")
local netstone = require("/lib/netstone")
netstone.getSettings()

function printHelp()
    termUtils.print("Usage: netstone computergroup|name|id|- <command> <arguments>")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  on - Turns on.")
    termUtils.print("  off - Turns off.")
    termUtils.print("  pulse <id> <time> - Pulses a netstone.")
    termUtils.print("  setin <on/off/pulse> - Sets a action on in range.")
    termUtils.print("  setout <value> - Sets a action on out of range.")
    termUtils.print("  setside <side> - Sets the redstone side.")
    termUtils.print("  setrange <range> - Sets the range.")
    termUtils.print("  enable - Enables ranged mode.")
    termUtils.print("  disable - Disables ranged mode.")
end

local args = { ... }

if #args == 0 then
    printHelp()
    return
end
--usage
local cIds = gps.resolveComputersByString(args[1], true)

if not cIds then
    termUtils.print("No computer found!", "red")
    return
end

if args[2] == "open" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "open"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "close" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "close"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "toggle" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "toggle"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "on" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "on"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "off" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "off"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "pulse" then
    if not tonumber(args[3]) then
        termUtils.print("Invalid pulse duration.", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "pulse",
                params = {
                    args[3]
                }
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "setin" then
    if args[3] == "on" or args[3] == "off" or args[3] == "toggle" or
        args[3] == "pulse" then
        if args[3] == "pulse" and args[4] ~= nil and not tonumber(args[4]) then
            termUtils.print("Invalid pulse duration.", "red")
            return
        end
        for i, cId in ipairs(cIds) do
            local res = net.emit("NodeOS_netstoneCommand",
                {
                    command = "setin",
                    params = {
                        args[3],
                        args[4]
                    }
                }, cId)
            if res then
                if res.success then
                    termUtils.print(res.message, "green")
                else
                    termUtils.print(res.message, "red")
                end
            else
                termUtils.print("Failed to connect to " .. cId .. ".", "red")
            end
        end
    else
        termUtils.print("Invalid argument: " .. args[3] .. ".", "red")
    end
elseif args[2] == "setout" then
    if args[3] == "on" or args[3] == "off" or args[3] == "toggle" or
        args[3] == "pulse" then
        if args[3] == "pulse" and args[4] ~= nil and not tonumber(args[4]) then
            termUtils.print("Invalid pulse duration.", "red")
            return
        end
        for i, cId in ipairs(cIds) do
            local res = net.emit("NodeOS_netstoneCommand",
                {
                    command = "setout",
                    params = {
                        args[3],
                        args[4]
                    }
                }, cId)
            if res then
                if res.success then
                    termUtils.print(res.message, "green")
                else
                    termUtils.print(res.message, "red")
                end
            else
                termUtils.print("Failed to connect to " .. cId .. ".", "red")
            end
        end
    else
        termUtils.print("Invalid argument: " .. args[3] .. ".", "red")
    end
elseif args[2] == "setside" then
    if args[3] == "top" or args[3] == "bottom" or args[3] == "back" or args[3] == "front" or
        args[3] == "left" or args[3] == "right" then
        for i, cId in ipairs(cIds) do
            local res = net.emit("NodeOS_netstoneCommand",
                {
                    command = "setside",
                    params = {
                        args[3]
                    }
                }, cId)
            if res then
                if res.success then
                    termUtils.print(res.message, "green")
                else
                    termUtils.print(res.message, "red")
                end
            else
                termUtils.print("Failed to connect to " .. cId .. ".", "red")
            end
        end
    else
        termUtils.print("Invalid side.", "red")
    end
elseif args[2] == "setrange" then
    -- if arg 3 not int error
    if not tonumber(args[3]) then
        termUtils.print("Range must be an integer.", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "setrange",
                params = {
                    args[3]
                }
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "enable" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "enable"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "disable" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_netstoneCommand",
            {
                command = "disable"
            }, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
else
    printHelp()
end
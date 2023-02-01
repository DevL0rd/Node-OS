local net = require("/lib/net")
local gps = require("/lib/gps")
local termUtils = require("/lib/termUtils")

function printHelp()
    termUtils.print("Usage: butler computergroup|name|id|- <command> <arguments>")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  find <block> [ammount] - Finds a block.")
    termUtils.print("    If ammount is not specified, it will find until inventory is full.")
    termUtils.print("  sethome - Sets the home.")
    termUtils.print("  return   <canBreakBlock>- Returns to the home.")
    termUtils.print("  follow <canBreakBlock> - Follow computer issuing the command.")
    termUtils.print("  toggleBreaking - Toggle block breaking.")
    termUtils.print("  status - Prints the status.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

local cIds = gps.resolveComputersByString(args[1], true, true) -- must be paired and be a turtle

if not cIds then
    termUtils.print("No paired turtle found!", "red")
    return
end

if args[2] == "find" then
    if args[3] then
        local name = args[3]
        local gatherCount = nil
        if args[4] then -- if the user specified a count
            gatherCount = tonumber(args[4])
        end
        for i, cId in ipairs(cIds) do
            local res = net.emit("NodeOS_butlerFind", {
                name = name,
                count = gatherCount
            }, cId)
            if res then
                if res.success then
                    termUtils.print("Turtle sent!", "green")
                else
                    termUtils.print(res.message, "red")
                end
            else
                termUtils.print("Failed to connect to " .. cId .. ".", "red")
            end
        end
    else
        termUtils.print("No block name specified.", "red")
    end
elseif args[2] == "sethome" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_setHome", nil, cId)
        if res then
            if res.success then
                termUtils.print("Home set!", "green")
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "return" then
    for i, cId in ipairs(cIds) do
        local res
        if args[3] then
            res = net.emit("NodeOS_return", { canBreakBlocks = (string.lower(args[3]) == "true") }, cId)
        else
            res = net.emit("NodeOS_return", { canBreakBlocks = false }, cId)
        end
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
elseif args[2] == "follow" then
    for i, cId in ipairs(cIds) do
        local res
        if args[3] then
            res = net.emit("NodeOS_follow", { canBreakBlocks = (string.lower(args[3]) == "true") }, cId)
        else
            res = net.emit("NodeOS_follow", { canBreakBlocks = false }, cId)
        end
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
elseif args[2] == "toggleBreaking" then
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_toggleBreaking", nil, cId)
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
elseif args[2] == "status" then
    local lastStatus = ""
    while true do
        local res = net.emit("NodeOS_butlerStatus", nil, cIds[1])
        if res then
            if res.success then
                if res.status ~= lastStatus then
                    termUtils.print(res.status)
                    lastStatus = res.status
                end
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect to " .. cIds[1] .. ".", "red")
        end
        sleep(0.2)
    end
else
    printHelp()
end
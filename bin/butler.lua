function printHelp()
    nodeos.graphics.print("Usage: butler computergroup|name|id|- <command> <arguments>")
    nodeos.graphics.print("  You can use '-' in place of id to get closest computer.")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  find <block> [ammount] - Finds a block.")
    nodeos.graphics.print("    If ammount is not specified, it will find until inventory is full.")
    nodeos.graphics.print("  sethome - Sets the home.")
    nodeos.graphics.print("  return   <canBreakBlock>- Returns to the home.")
    nodeos.graphics.print("  follow <canBreakBlock> - Follow computer issuing the command.")
    nodeos.graphics.print("  toggleBreaking - Toggle block breaking.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

local cIds = nodeos.gps.resolveComputersByString(args[1], true, true) -- must be paired and be a turtle
if not cIds then
    nodeos.graphics.print("No paired turtle found!", "red")
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
            local res = nodeos.net.emit("NodeOS_butlerFind", {
                name = name,
                count = gatherCount
            }, cId)
            if res then
                if res.success then
                    nodeos.graphics.print("Turtle sent!", "green")
                else
                    nodeos.graphics.print(res.message, "red")
                end
            else
                nodeos.graphics.print("Failed to connect to " .. cId .. ".", "red")
            end
        end
    else
        nodeos.graphics.print("No block name specified.", "red")
    end
elseif args[2] == "sethome" then
    for i, cId in ipairs(cIds) do
        local res = nodeos.net.emit("NodeOS_setHome", nil, cId)
        if res then
            if res.success then
                nodeos.graphics.print("Home set!", "green")
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "return" then
    for i, cId in ipairs(cIds) do
        local res
        if args[3] then
            res = nodeos.net.emit("NodeOS_return", { canBreakBlocks = (string.lower(args[3]) == "true") }, cId)
        else
            res = nodeos.net.emit("NodeOS_return", { canBreakBlocks = true }, cId)
        end
        if res then
            if res.success then
                nodeos.graphics.print(res.message, "green")
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "follow" then
    for i, cId in ipairs(cIds) do
        local res
        if args[3] then
            res = nodeos.net.emit("NodeOS_follow", { canBreakBlocks = (string.lower(args[3]) == "true") }, cId)
        else
            res = nodeos.net.emit("NodeOS_follow", { canBreakBlocks = false }, cId)
        end
        if res then
            if res.success then
                nodeos.graphics.print(res.message, "green")
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
elseif args[2] == "toggleBreaking" then
    for i, cId in ipairs(cIds) do
        local res = nodeos.net.emit("NodeOS_toggleBreaking", nil, cId)
        if res then
            if res.success then
                nodeos.graphics.print(res.message, "green")
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect to " .. cId .. ".", "red")
        end
    end
else
    printHelp()
end

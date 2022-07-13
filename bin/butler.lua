local net = require("/lib/net")
local gps = require("/lib/gps")
local termUtils = require("/lib/termUtils")


local args = { ... }

local cId = nil
if args[1] == "-" then
    cId = gps.getClosestPC(true) -- get closest turtle only
else
    cId = gps.getComputerID(args[2])
    if not cId then
        cId = tonumber(args[2])
    end
end
if not cId then
    termUtils.print("No turtle found!", "red")
    return
end
if args[2] == "find" then
    if args[3] then
        local name = args[3]
        local gatherCount = nil
        if args[4] then -- if the user specified a count
            gatherCount = tonumber(args[4])
        end
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
    else
        termUtils.print("No block name specified.", "red")
    end
elseif args[2] == "sethome" then
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
elseif args[2] == "return" then
    local res = net.emit("NodeOS_return", nil, cId)
    if res then
        if res.success then
            termUtils.print("Turtle returning to home...", "green")
        else
            termUtils.print(res.message, "red")
        end
    else
        termUtils.print("Failed to connect to " .. cId .. ".", "red")
    end
elseif args[2] == "status" then
    local lastStatus = ""
    while true do
        local res = net.emit("NodeOS_butlerStatus", nil, cId)
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
            termUtils.print("Failed to connect to " .. cId .. ".", "red")
        end
        sleep(0.2)
    end
else
    termUtils.print("Usage: butler find <block>", "red")
    termUtils.print("Usage: butler goto <block,computer>", "red")
    termUtils.print("Usage: butler sethome", "red")
    termUtils.print("Usage: butler return", "red")
end
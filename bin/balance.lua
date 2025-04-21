function printHelp()
    -- get balance
    res = nodeos.net.emit("NodeOS_getBalance", {}, nodeos.settings.settings.master)
    if res then
        if res.success then
            if res.forwarding then
                nodeos.graphics.print("Connected to: " .. res.forwarding, "orange")
            end
            nodeos.graphics.print("Your balance: $" .. res.balance, "green")
        else
            nodeos.graphics.print(res.message, "red")
        end
    else
        nodeos.graphics.print("Failed to connect to Server!", "red")
    end

    nodeos.graphics.newLine()
    nodeos.graphics.print("Usage: balance connect <name|id|->")
    nodeos.graphics.print("  You can use '-' in place of id to get closest computer.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

if args[1] == "connect" then
    local cIds = nodeos.gps.resolveComputersByString(args[2], false, false)

    if not cIds then
        nodeos.graphics.print("Computer not found!", "red")
        return
    end

    local cId = cIds[1]
    local res = nodeos.net.emit("NodeOS_connectBalance", {
        id = cId
    }, nodeos.settings.settings.master)
    if res then
        if res.success then
            nodeos.graphics.print("Balance connected to " .. cId .. "!", "green")
        else
            nodeos.graphics.print(res.message, "red")
        end
    else
        nodeos.graphics.print("Failed to connect to Server!", "red")
    end
else
    printHelp()
end

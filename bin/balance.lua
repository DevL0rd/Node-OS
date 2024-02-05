local termUtils = require("/lib/termUtils")

function printHelp()
    -- get balance
    res = net.emit("NodeOS_getBalance", {}, sets.settings.master)
    if res then
        if res.success then
            if res.forwarding then
                termUtils.print("Connected to: " .. res.forwarding, "orange")
            end
            termUtils.print("Your balance: $" .. res.balance, "green")
        else
            termUtils.print(res.message, "red")
        end
    else
        termUtils.print("Failed to connect to Server!", "red")
    end

    termUtils.newLine()
    termUtils.print("Usage: balance connect <name|id|->")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

if args[1] == "connect" then
    local cIds = gps.resolveComputersByString(args[2], false, false)

    if not cIds then
        termUtils.print("Computer not found!", "red")
        return
    end

    local cId = cIds[1]
    local res = net.emit("NodeOS_connectBalance", {
        id = cId
    }, sets.settings.master)
    if res then
        if res.success then
            termUtils.print("Balance connected to " .. cId .. "!", "green")
        else
            termUtils.print(res.message, "red")
        end
    else
        termUtils.print("Failed to connect to Server!", "red")
    end
else
    printHelp()
end
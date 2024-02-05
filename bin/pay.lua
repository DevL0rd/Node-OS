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
    termUtils.print("Usage: pay name|id|- <ammount>")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

local cIds = gps.resolveComputersByString(args[1], false, false)

if not cIds then
    termUtils.print("Computer not found!", "red")
    return
end


if args[2] then
    local ammount = tonumber(args[2])
    if not ammount or ammount <= 0 then
        termUtils.print("Invalid ammount!", "red")
        return
    end
    local cId = cIds[1]
    local res = net.emit("NodeOS_transfer", {
        id = cId,
        amount = ammount
    }, sets.settings.master)
    if res then
        if res.success then
            if res.forwarding then
                termUtils.print("Connected to: " .. res.forwarding, "orange")
            end
            termUtils.print("Sent " .. ammount .. " to " .. cId .. "!", "green")
            termUtils.print("New balance: $" .. res.balance, "green")
        else
            termUtils.print(res.message, "red")
        end
    else
        termUtils.print("Failed to connect to Server!", "red")
    end
else
    printHelp()
end
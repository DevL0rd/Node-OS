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
    nodeos.graphics.print("Usage: pay name|id|- <ammount>")
    nodeos.graphics.print("  You can use '-' in place of id to get closest computer.")
end

local args = { ... }


if #args == 0 then
    printHelp()
    return
end

local cIds = nodeos.gps.resolveComputersByString(args[1], false, false)

if not cIds then
    nodeos.graphics.print("Computer not found!", "red")
    return
end


if args[2] then
    local ammount = tonumber(args[2])
    if not ammount or ammount <= 0 then
        nodeos.graphics.print("Invalid ammount!", "red")
        return
    end
    local cId = cIds[1]
    local res = nodeos.net.emit("NodeOS_transfer", {
        id = cId,
        amount = ammount
    }, nodeos.settings.settings.master)
    if res then
        if res.success then
            if res.forwarding then
                nodeos.graphics.print("Connected to: " .. res.forwarding, "orange")
            end
            nodeos.graphics.print("Sent " .. ammount .. " to " .. cId .. "!", "green")
            nodeos.graphics.print("New balance: $" .. res.balance, "green")
        else
            nodeos.graphics.print(res.message, "red")
        end
    else
        nodeos.graphics.print("Failed to connect to Server!", "red")
    end
else
    printHelp()
end

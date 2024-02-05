local termUtils = require("/lib/termUtils")
local args = { ... }

function printHelp()
    termUtils.print("Usage: net <command> <arguments>")
    termUtils.print("  You can use '-' in place of id to get closest computer.")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  pair <computergroup|name|id|-> <pin> - Pairs a computer.")
    termUtils.print("  unpair <computergroup|name|id|-> <pin> - Unpairs a computer.")
    termUtils.print("  list - Lists all computers on network.")
    termUtils.print("  addgroup <group> - Add group tag, ie homebase.lights, and lights.")
    termUtils.print("  delgroup <group> - Remove the group tag.")
    termUtils.print("  listgroups - List groups associated with this computer.")
end

if #args == 0 then
    printHelp()
    return
end

if args[1] == "pair" then
    if not args[2] or not args[3] then
        termUtils.print("usage: pairing pair <id> <pin>", "red")
        return
    end
    local cIds = gps.resolveComputersByString(args[2])

    if not cIds then
        termUtils.print("Computer not found!", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local pin = args[3]
        local res = net.emit("NodeOS_pair", pin, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
                local pairedDevices = net.getPairedDevices()
                pairedDevices[cId] = true
                net.savePairedDevices(pairedDevices)
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect!", "red")
        end
    end
elseif args[1] == "unpair" then
    if not args[2] then
        termUtils.print("usage: pairing unpair <id>", "red")
        return
    end
    local cIds = gps.resolveComputersByString(args[2], true)

    if not cIds then
        termUtils.print("No paired computer found!", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local res = net.emit("NodeOS_unpair", nil, cId)
        if res then
            if res.success then
                termUtils.print(res.message, "green")
                local pairedDevices = net.getPairedDevices()
                pairedDevices[cId] = nil
                net.savePairedDevices(pairedDevices)
            else
                termUtils.print(res.message, "red")
            end
        else
            termUtils.print("Failed to connect!", "red")
        end
    end
elseif args[1] == "list" then
    termUtils.print("Computer List:", "purple")
    local range = nil
    if args[1] and isInt(tonumber(args[1])) then
        range = tonumber(args[1])
    end

    local localComputers = gps.getLocalComputers()
    for id, details in pairs(localComputers) do
        local dist = "?"
        local gpsPos = gps.getPosition()
        if gpsPos and localComputers[id].pos then
            dist = math.floor(gps.getDistance(gpsPos, localComputers[id].pos))
        end
        local pairdDevices = net.getPairedDevices()
        if dist ~= "?" and range then
            if dist <= range then
                if (net.ping(id)) then
                    if pairdDevices[id] then
                        termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                    else
                        termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                    end
                else
                    termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
                end
            end
        else
            if (net.ping(id)) then
                if pairdDevices[id] then
                    termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                else
                    termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                end
            else
                termUtils.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
            end
        end
    end
elseif args[1] == "addgroup" then
    local group = args[2]
    if not group then
        termUtils.print("You must specify a group.", "red")
        return
    end
    if not sets.settings.groups then
        sets.settings.groups = {}
    end
    if not sets.settings.groups[group] then
        table.insert(sets.settings.groups, group)
        settings.saveSettings()
        termUtils.print("Group '" .. group .. "' added! A reboot is required for network to get changes.", "yellow")
    else
        termUtils.print("Group '" .. group .. "' already exists.", "yellow")
    end
elseif args[1] == "delgroup" then
    local group = args[2]
    if not group then
        termUtils.print("You must specify a group.", "red")
        return
    end
    if sets.settings.groups[group] then
        sets.settings.groups[group] = nil
        settings.saveSettings()
        termUtils.print("Group '" .. group .. "' deleted. A reboot is required for network to get changes.", "yellow")
    else
        termUtils.print("Group '" .. group .. "' does not exist.", "red")
    end
elseif args[1] == "listgroups" then
    for i, group in ipairs(sets.settings.groups) do
        termUtils.print(group)
    end
else
    printHelp()
end
local args = { ... }

function printHelp()
    nodeos.graphics.print("Usage: nodeos.net <command> <arguments>")
    nodeos.graphics.print("  You can use '-' in place of id to get closest computer.")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  pair <computergroup|name|id|-> <pin> - Pairs a computer.")
    nodeos.graphics.print("  unpair <computergroup|name|id|-> <pin> - Unpairs a computer.")
    nodeos.graphics.print("  list - Lists all computers on network.")
    nodeos.graphics.print("  addgroup <group> - Add group tag, ie homebase.lights, and lights.")
    nodeos.graphics.print("  delgroup <group> - Remove the group tag.")
    nodeos.graphics.print("  listgroups - List groups associated with this computer.")
end

if #args == 0 then
    printHelp()
    return
end

if args[1] == "pair" then
    if not args[2] or not args[3] then
        nodeos.graphics.print("usage: pairing pair <id> <pin>", "red")
        return
    end
    local cIds = nodeos.gps.resolveComputersByString(args[2])

    if not cIds then
        nodeos.graphics.print("Computer not found!", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local pin = args[3]
        local res = nodeos.net.emit("NodeOS_pair", pin, cId)
        if res then
            if res.success then
                nodeos.graphics.print(res.message, "green")
                local pairedDevices = nodeos.net.getPairedDevices()
                pairedDevices[cId] = true
                nodeos.net.savePairedDevices(pairedDevices)
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect!", "red")
        end
    end
elseif args[1] == "unpair" then
    if not args[2] then
        nodeos.graphics.print("usage: pairing unpair <id>", "red")
        return
    end
    local cIds = nodeos.gps.resolveComputersByString(args[2], true)

    if not cIds then
        nodeos.graphics.print("No paired computer found!", "red")
        return
    end
    for i, cId in ipairs(cIds) do
        local res = nodeos.net.emit("NodeOS_unpair", nil, cId)
        if res then
            if res.success then
                nodeos.graphics.print(res.message, "green")
                local pairedDevices = nodeos.net.getPairedDevices()
                pairedDevices[cId] = nil
                nodeos.net.savePairedDevices(pairedDevices)
            else
                nodeos.graphics.print(res.message, "red")
            end
        else
            nodeos.graphics.print("Failed to connect!", "red")
        end
    end
elseif args[1] == "list" then
    nodeos.graphics.print("Computer List:", "purple")
    local range = nil
    if args[1] and isInt(tonumber(args[1])) then
        range = tonumber(args[1])
    end

    local localComputers = nodeos.gps.getLocalComputers()
    for id, details in pairs(localComputers) do
        local dist = "?"
        local gpsPos = nodeos.gps.getPosition()
        if gpsPos and localComputers[id].pos then
            dist = math.floor(nodeos.gps.getDistance(gpsPos, localComputers[id].pos))
        end
        local pairdDevices = nodeos.net.getPairedDevices()
        if dist ~= "?" and range then
            if dist <= range then
                if (nodeos.net.ping(id)) then
                    if pairdDevices[id] then
                        nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                    else
                        nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                    end
                else
                    nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
                end
            end
        else
            if (nodeos.net.ping(id)) then
                if pairdDevices[id] then
                    nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "green")
                else
                    nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "orange")
                end
            else
                nodeos.graphics.print("   " .. details.name .. "@" .. id .. " Dist: " .. dist, "red")
            end
        end
    end
elseif args[1] == "addgroup" then
    local group = args[2]
    if not group then
        nodeos.graphics.print("You must specify a group.", "red")
        return
    end
    if not nodeos.settings.settings.groups then
        nodeos.settings.settings.groups = {}
    end
    if not nodeos.settings.settings.groups[group] then
        table.insert(nodeos.settings.settings.groups, group)
        settings.saveSettings()
        nodeos.graphics.print("Group '" .. group .. "' added! A reboot is required for network to get changes.", "yellow")
    else
        nodeos.graphics.print("Group '" .. group .. "' already exists.", "yellow")
    end
elseif args[1] == "delgroup" then
    local group = args[2]
    if not group then
        nodeos.graphics.print("You must specify a group.", "red")
        return
    end
    if nodeos.settings.settings.groups[group] then
        nodeos.settings.settings.groups[group] = nil
        settings.saveSettings()
        nodeos.graphics.print("Group '" .. group .. "' deleted. A reboot is required for network to get changes.",
            "yellow")
    else
        nodeos.graphics.print("Group '" .. group .. "' does not exist.", "red")
    end
elseif args[1] == "listgroups" then
    for i, group in ipairs(nodeos.settings.settings.groups) do
        nodeos.graphics.print(group)
    end
else
    printHelp()
end

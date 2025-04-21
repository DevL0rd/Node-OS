local args = { ... }

local function printHelp()
    nodeos.graphics.print("Usage: command <command>")
    nodeos.graphics.print("Commands:")
    nodeos.graphics.print("  help - Prints this help message.")
    nodeos.graphics.print("  <command> - Some minecraft command to run.")
end

if #args == 0 then
    printHelp()
    return
end

if args[1] == "help" then
    printHelp()
    return
end

local command = table.concat(args, " ")

local res = nodeos.net.emit("NodeOS_minecraftCommand", {
    command = command
}, nodeos.settings.settings.master)

if res then
    if res.success then
        nodeos.graphics.print(res.message, "white")
    else
        nodeos.graphics.print(res.message, "red")
    end
else
    nodeos.graphics.print("Failed to connect!", "red")
end

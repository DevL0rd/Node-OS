local termUtils = require("/lib/termUtils")
local args = { ... }

local function printHelp()
    termUtils.print("Usage: command <command>")
    termUtils.print("Commands:")
    termUtils.print("  help - Prints this help message.")
    termUtils.print("  <command> - Some minecraft command to run.")
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

local res = net.emit("NodeOS_minecraftCommand", {
    command = command
}, sets.settings.master)

if res then
    if res.success then
        termUtils.print(res.message, "white")
    else
        termUtils.print(res.message, "red")
    end
else
    termUtils.print("Failed to connect!", "red")
end

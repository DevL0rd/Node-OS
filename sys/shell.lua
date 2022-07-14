local utils = require("util")
local file = utils.loadModule("file")
local history_path = "etc/shell/history.dat"
local history = {}
if fs.exists(history_path) then
    history = file.readTable(history_path)
end
function addHistory(cmd)
    table.insert(history, cmd)
    if #history > 100 then
        table.remove(history, 1)
    end
    file.writeTable(history_path, history)
end

term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell
local paths = file.readTable("/etc/paths.cfg")
for i = 1, #paths do
    shell.setPath(shell.path() .. ":" .. paths[i])
end
shell.run("cd /home")
local currentDir = "home"
while true do
    local dir = shell.dir()
    if dir == "" then
        dir = "/"
    end
    --if home at beginning of path, replace with ~
    if string.sub(dir, 1, 4) == "home" then
        dir = "~" .. string.sub(dir, 5)
    end

    term.setTextColor(colors.lime)
    term.write(os.getComputerLabel())
    term.write("@")
    term.write(os.getComputerID())
    term.setTextColor(colors.white)
    term.write(":" .. dir)
    term.setTextColor(colors.white)
    term.write("$")

    local input = read(nil, history)
    input = string.gsub(input, "~", "/home")
    addHistory(input)
    shell.run("cd /" .. currentDir)
    shell.run(input)
    currentDir = shell.dir()
end
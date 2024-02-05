local termUtils = require("/lib/termUtils")
term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell
local paths = file.readTable("/etc/paths.cfg")
for i = 1, #paths do
    shell.setPath(paths[i] .. ":" .. shell.path())
end
shell.run("cd /home")
local function main()
    shell.run("shell.lua")
end
local function clear()
    local file = fs.open("sys/ver.txt", "r")
    ver = tonumber(file.readAll())
    file.close()
    termUtils.fillLine("-", 1, "cyan", "black")
    termUtils.centerText("[ NodeOS Ver: " .. ver .. " ]", 1, "cyan", "black")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(7, 2)
end
parallel.waitForAll(main, clear)

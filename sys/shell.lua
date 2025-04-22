term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell
local paths = loadTable("/etc/paths.cfg")
for i = 1, #paths do
    shell.setPath(paths[i] .. ":" .. shell.path())
end
shell.run("cd /home")
-- local test = 0 / somtinhsd -- test error
local function main()
    shell.run("shell.lua")
end
local function clear()
    local file = fs.open("sys/ver.txt", "r")
    ver = tonumber(file.readAll())
    file.close()
    nodeos.graphics.fillLine("-", 1, "cyan", "black")
    nodeos.graphics.centerText("[ NodeOS Ver: " .. ver .. " ]", 1, "cyan", "black")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(7, 2)
end
nodeos.waitForAll("Shell", main, clear) -- Added "Shell" as the process name

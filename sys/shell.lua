term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell
local paths = file.readTable("/etc/paths.cfg")
for i = 1, #paths do
    shell.setPath(paths[i] .. ":" .. shell.path())
end
shell.run("cd /home")
-- shell.run("shell.lua")
-- open the shell but clear the screen
shell.run("shell.lua")
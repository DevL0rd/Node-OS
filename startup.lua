if not term.isColor() then
    printError("Please use a color terminal.")
    return false
end
term.clear()
term.setCursorPos(1, 1)
--Install to PC if inserted into disk drive.
if fs.exists("disk/startup.lua") and fs.exists("disk/sys/ver.txt") then
    if fs.exists("startup.lua") then
        term.setTextColor(colors.red)
        print("NodeOS cannot be installed on this system. A Startup file already exists!")
        term.setTextColor(colors.lightGray)
        print("Press enter to reboot.")
        read("")
        peripheral.find("drive", function(_, drive) drive.ejectDisk() end)
        os.reboot()
    else
        fs.copy("disk/startup.lua", "startup.lua")
        fs.copy("disk/bin", "bin")
        fs.copy("disk/sys", "sys")
        fs.copy("disk/lib", "lib")
        term.setTextColor(colors.green)
        print("NodeOS succesfully installed from disk!")
        os.sleep(2)
        peripheral.find("drive", function(_, drive) drive.ejectDisk() end)
        os.reboot()
    end
end
term.clear()
term.setCursorPos(1, 1)
if fs.exists("/disk/startup") or fs.exists("/disk/startup.lua") then
    write("Press any key to boot from disk")

    parallel.waitForAny(function()
        os.pullEvent("char")
        if fs.exists("/disk/startup") then
            shell.run('/disk/startup')
        elseif fs.exists("/disk/startup.lua") then
            shell.run('/disk/startup')
        else
            print("\nFailed to boot to disk. Is the disk still inserted?")
            sleep(1)
        end
    end, function()
        for i = 1, 3 do
            write(".")
            sleep(1)
        end
    end)
end

if fs.exists("tmp") then
    fs.delete("tmp")
end
fs.makeDir("tmp")
if not fs.exists("home") then
    fs.makeDir("home")
end
if not fs.exists("home/bin") then
    fs.makeDir("home/bin")
end
if not fs.exists("/home/services") then
    fs.makeDir("/home/services")
end
if not fs.exists("/home/drivers") then
    fs.makeDir("/home/drivers")
end
if not fs.exists("/home/startup") then
    fs.makeDir("/home/startup")
end

if not fs.exists("home/Documents") then
    fs.makeDir("home/Documents")
end
if not fs.exists("home/Downloads") then
    fs.makeDir("home/Downloads")
end
if not fs.exists("home/Pictures") then
    fs.makeDir("home/Pictures")
end
if not fs.exists("home/Music") then
    fs.makeDir("home/Music")
end
if not fs.exists("home/Public") then
    fs.makeDir("home/Public")
end

if not fs.exists("/etc/menu/pinned.cfg") then
    local file = fs.open("/etc/menu/pinned.cfg", "w")
    file.write(textutils.serialize({
        {
            path = "sys/shell.lua",
            title = "Shell",
            insettings = {
                height = 17,
                title = "Shell",
                width = 40,
            },
        },
        {
            path = "/bin/map.lua",
            title = "Map",
            insettings = {
                height = 17,
                title = "Map",
                width = 40,
            },
        },
        {
            path = "/sys/ui/tskmgr.lua",
            title = "Task Manager",
            insettings = {
                height = 17,
                title = "Task Manager",
                width = 40,
            },
        },
        {
            path = "/sys/ui/settings.lua",
            title = "Settings",
            insettings = {
                height = 17,
                title = "Settings",
                width = 40,
            },
        },
        {
            path = "/sys/ui/about.lua",
            title = "About",
            insettings = {
                height = 10,
                title = "About NodeOS",
                width = 29,
            },
        },
    }))
    file.close()
end
if not fs.exists("/etc/paths.cfg") then
    local file = fs.open("/etc/paths.cfg", "w")
    file.write(textutils.serialize({
        "/home/bin",
        "/bin"
    }))
    file.close()
end
if not fs.exists("/etc/libs.cfg") then
    local file = fs.open("/etc/libs.cfg", "w")
    file.write(textutils.serialize({
        "/lib/?.lua",
        "/lib/?/init.lua"
    }))
    file.close()
end
if not fs.exists("/etc/theme.cfg") then
    local file = fs.open("/etc/theme.cfg", "w")
    file.write(textutils.serialize({
        currentTheme = "/sys/themes/dark.theme",
    }))
    file.close()
end

local settings = require("/lib/settings")
term.clear()
local completeSetupPassword = false
while not completeSetupPassword do
    if not settings.settings.password then
        print("Please input a password:")
        print("Typing nothing will not set a password.")
        local sha256 = require("/lib/sha256")
        settings.settings.password = read("*")
        if settings.settings.password ~= "" then
            print("Please confirm your password:")
            local pass2 = read("*")
            if pass2 == settings.settings.password then
                settings.settings.password = sha256(settings.settings.password)
                completeSetupPassword = true
            else
                print("Passwords do not match!")
                settings.settings.password = nil
            end
        end
    else
        completeSetupPassword = true
    end
end

while not os.getComputerLabel() do
    print("Please input a computer name:")
    os.setComputerLabel(read())
end
while not settings.settings.pin do
    print("Please input a SECURE pairing pin:")
    settings.settings.pin = read("*")
end
while settings.settings.consoleOnly == nil do
    print("Will this computer be console only? (y/n)")
    instr = string.lower(read())
    if instr == "y" then
        settings.settings.consoleOnly = true
    elseif instr == "n" then
        settings.settings.consoleOnly = false
    end
end
term.clear()
settings.saveSettings(settings.settings)
local w, h = term.getSize()
local fail = false

function yield()
    os.queueEvent("randomEvent")
    os.pullEvent("randomEvent")
end

term.setBackgroundColor(colors.black)
term.clear()

-- Function DeviceDetect
function detectDevice(DeviceName)
    local DeviceSide = nil
    for k, v in pairs(redstone.getSides()) do
        if peripheral.getType(v) == DeviceName then
            DeviceSide = v
            break
        end
    end
    return DeviceSide
end

-- Usage:
local MonitorSide = detectDevice("monitor")
if MonitorSide then
    local monitor = peripheral.wrap(MonitorSide)
    monitor.setTextScale(0.5)
    term.clear()
    print("Please use this console for input:")
    shell.run(
        "monitor " .. MonitorSide .. " /sys/kernel.lua"
    )
else
    shell.run(
        "/sys/kernel.lua"
    )
end

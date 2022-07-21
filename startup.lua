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
            path = "/sys/ui/tskmgr.lua",
            title = "Task Manager",
            insettings = {
                height = 17,
                title = "Task Manager",
                width = 30,
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
term.clear()
settings.saveSettings(settings.settings)
local w, h = term.getSize()
local fail = false

function yield()
    os.queueEvent("randomEvent")
    os.pullEvent("randomEvent")
end

if not term.isColor() then
    printError("Please use a color terminal")
    return false
end

-- local function animate()
--     local frames = {
--         { i = false, c = "\129" },
--         { i = false, c = "\130" },
--         { i = false, c = "\136" },
--         { i = true, c = "\159" },
--         { i = false, c = "\144" },
--         { i = false, c = "\132" },
--     }

--     local function drawFrame(frame)
--         term.setBackgroundColor(colors.gray)
--         term.setTextColor(colors.white)
--         if frame.i then
--             term.setBackgroundColor(colors.white)
--             term.setTextColor(colors.gray)
--         end
--         write(frame.c)
--     end

--     term.setCursorPos(w / 2 - string.len("Starting NodeOS") / 2 + 1, h / 2 + 2)
--     term.write("Starting NodeOS")

--     while true do
--         for i, frame in pairs(frames) do
--             if fail then while true do sleep(1) end end
--             term.setCursorPos(w / 2, h / 2)
--             drawFrame(frame)
--             sleep(0.25)
--         end
--     end
-- end

term.setBackgroundColor(colors.black)
term.clear()
shell.run(
    "/sys/kernel.lua"
)
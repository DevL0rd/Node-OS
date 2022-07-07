if ccemux then
    ccemux.attach("left", "wireless_modem", {
        -- The range of this modem
        range = 64,

        -- Whether this is an ender modem
        interdimensional = false,

        -- The current world's name. Sending messages between worlds requires an interdimensional modem
        world = "main",

        -- The position of this wireless modem within the world
        posX = 0, posY = 0, posZ = 0,
    })
end
term.setCursorPos(1, 1)
term.clear()
--Install to PC if inserted into disk drive.
if fs.exists("disk/startup.lua") then
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
        fs.copy("disk/sys", "sys")
        term.setTextColor(colors.green)
        print("NodeOS succesfully installed from disk!")
        os.sleep(2)
        peripheral.find("drive", function(_, drive) drive.ejectDisk() end)
        os.reboot()
    end
end

if not fs.exists("config") then
    fs.makeDir("config")
end
if fs.exists("temp") then
    fs.delete("temp")
end
fs.makeDir("temp")
require 'sys.lib.require'
require 'fstools'
require 'misc'
coms = {}
require 'sys.update'
require 'sys.net'
require 'sys.gps'
require 'sys.term'
require 'sys.shell'
require 'sys.peripherals'
require 'sys.settings'
require.tree("sys/plugins")


--Start the main threads
parallel.waitForAll(terminal_thread, peripheralThread, netRx_thread, netExec_thread, update_thread, gps_thread,
    shell_thread)
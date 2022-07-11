if fs.exists("disk") then
    if fs.exists("disk/startup.lua") then
        print("Cannot install to disk/device in disk drive. A autostart file already exists.")
    else
        fs.copy("startup.lua", "disk/startup.lua")
        fs.copy("bin", "disk/bin")
        fs.copy("sys", "disk/sys")
        fs.copy("lib", "disk/lib")
        term.setTextColor(colors.green)
        print("NodeOS succesfully installed to disk!")
        peripheral.find("drive", function(_, drive) drive.ejectDisk() end)
    end
else
    print("There is no drive attached to this PC.")
end
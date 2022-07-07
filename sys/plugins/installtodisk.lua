coms.installtodisk = {
    usage = "installtodisk",
    details = "Install NodeOS to device/disk in disk drive.",
    isLocal = true,
    isRemote = false,
    exec = function (params, responseToken, senderID)
        if fs.exists("disk") then
            if fs.exists("disk/startup.lua") then
                nPrint("Cannot install to disk/device in disk drive. A autostart file already exists.", "red")
            else
                fs.copy("startup.lua", "disk/startup.lua")
                term.setTextColor(colors.green)
                nPrint("NodeOS succesfully installed to disk!", "green")
                peripheral.find( "drive", function( _, drive ) drive.ejectDisk( ) end )
            end
        else
            nPrint("There is no drive attached to this PC.", "red")
        end
    end
}
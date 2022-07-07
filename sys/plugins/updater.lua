czip = require("czip")
ver = 0
if not fs.exists("sys/ver.txt") then
    local file = fs.open("sys/ver.txt", "w")
    file.write(ver)
    file.close()
else
    local file = fs.open("sys/ver.txt", "r")
    ver = tonumber(file.readAll())
    file.close()
end
function packNodeOS()
    if fs.exists("temp/updater") then
        fs.delete("temp/updater")
    end
    fs.makeDir("temp/updater")
    czip.compress("sys", "temp/updater/NodeOS.czip")
    czip.add("startup.lua", "temp/updater/NodeOS.czip")
end
local isPublishing = false
coms.publishupdate = {
    usage = "pushupdate",
    details = "Package and publish nodeos as update.",
    isLocal = true,
    exec = function(params, responseToken, senderID)
        isPublishing = true
        ver = ver + 1
        local file = fs.open("sys/ver.txt", "w")
        file.write(ver)
        file.close()
        if os.getComputerID() == settings.NodeOSMasterID then
            packNodeOS()
            fs.copy("temp/updater/NodeOS.czip", "share/NodeOS-" .. ver .. ".czip")
            nPrint("NodeOS updated to version " .. ver .. "!", "green")
            return
        elseif not pairedPCs[settings.NodeOSMasterID] then
            nPrint("Master PC is not paired!", "red")
            return
        end
        nPrint("Packing NodeOS...")
        packNodeOS()
        nPrint("Publishing NodeOS...")
        local file = fs.open("temp/updater/NodeOS.czip", "r")
        local data = file.readAll()
        file.close()

        res = sendNet(settings.NodeOSMasterID, "publishupdate", {
            data = data,
            ver = ver
        })
        if res then
            nPrint("Update published to master PC!", "green")
        else
            nPrint("Update failed to published to master PC!", "red")
        end
        isPublishing = false
    end
}

if os.getComputerID() == settings.NodeOSMasterID then
    netcoms.publishupdate = {
        exec = function(senderID, responseToken, data)
            if not pairedClients[senderID] then
                return
            end
            rednet.send(senderID, { data = "success", responseToken = responseToken }, "NodeOSNetResponse")
            local path = "share/NodeOS-" .. data.ver .. ".czip"
            local file = fs.open(path, "w")
            file.write(data.data)
            file.close()
            czip.decompress("", path)
            nPrint("NodeOS updated to version " .. data.ver .. "!", "green")
            os.reboot()
        end
    }
    netcoms.getUpdate = {
        exec = function(senderID, responseToken, data)
            local path = "share/NodeOS-" .. ver .. ".czip"
            if fs.exists(path) then
                local file = fs.open(path, "rb")
                data = file.readAll()
                file.close()
                rednet.send(senderID, { data = {
                    success = true,
                    data = data
                }, responseToken = responseToken }, "NodeOSNetResponse")
            else
                rednet.send(senderID, { data = {
                    success = false,
                    data = "Update file not found!"
                }, responseToken = responseToken }, "NodeOSNetResponse")
            end
        end
    }
    netcoms.getVer = {
        exec = function(senderID, responseToken, data)
            rednet.send(senderID, { data = {
                data = ver
            }, responseToken = responseToken }, "NodeOSNetResponse")
        end
    }
else
    function checkForUpdates()
        if isPublishing then
            return
        end
        res = sendNet(settings.NodeOSMasterID, "getVer")
        if res then
            if res.data ~= ver then
                nPrint("Update available! NodeOS version is " .. res.data .. ".", "green")
                nPrint("Downloading update...")
                res = sendNet(settings.NodeOSMasterID, "getUpdate")
                if res then
                    if res.success then
                        nPrint("Installing update...")
                        local file = fs.open("temp/updater/NodeOS.czip", "wb")
                        file.write(res.data)
                        file.close()
                        czip.decompress("", "temp/updater/NodeOS.czip")
                        nPrint("Update installed!", "green")
                        os.reboot()
                    else
                        nPrint(res.data, "red")
                    end
                end
            end
        end
    end
    
    table.insert(update_threads, checkForUpdates)
end

coms.ver = {
    usage = "ver",
    details = "Check current version of NodeOS.",
    isLocal = true,
    isRemote = true,
    exec = function(params, responseToken, senderID)
        if senderID then
            rednet.send(senderID, { data = "NodeOS version is " .. ver .. ".", responseToken = responseToken },
                "NodeOSCommandResponse")
        end
        nPrint("NodeOS version is " .. ver .. ".", "green")
    end
}
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
                fs.copy("sys", "disk/sys")
                term.setTextColor(colors.green)
                nPrint("NodeOS succesfully installed to disk!", "green")
                peripheral.find( "drive", function( _, drive ) drive.ejectDisk( ) end )
            end
        else
            nPrint("There is no drive attached to this PC.", "red")
        end
    end
}
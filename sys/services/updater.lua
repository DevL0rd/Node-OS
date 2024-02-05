local czip = require("czip")
-- local net = require("net")
local ver = 0
if not fs.exists("sys/ver.txt") then
    local file = fs.open("sys/ver.txt", "w")
    file.write(ver)
    file.close()
else
    local file = fs.open("sys/ver.txt", "r")
    ver = tonumber(file.readAll())
    file.close()
end

if os.getComputerID() == sets.settings.master then

    function listen_publishUpdate()
        while true do
            local senderID, msg = rednet.receive("NodeOS_publishUpdate")
            if net.getPairedClients()[senderID] then
                net.respond(senderID, msg.token, {
                    success = true
                })
                local path = "etc/updater/NodeOS-" .. msg.data.ver .. ".czip"
                local file = fs.open(path, "w")
                file.write(msg.data.data)
                file.close()
                czip.decompress("", path)
                print("NodeOS updated to version " .. msg.data.ver .. "!")
                os.reboot()
            end
        end
    end

    pm.createProcess(listen_publishUpdate, {isService=true, title="listen_publishUpdate"})

    function listen_getUpdate()
        while true do
            local senderID, msg = rednet.receive("NodeOS_getUpdate")
            local path = "etc/updater/NodeOS-" .. ver .. ".czip"
            if fs.exists(path) then
                local file = fs.open(path, "rb")
                data = file.readAll()
                file.close()
                net.respond(senderID, msg.token, {
                    success = true,
                    data = data
                })
            else
                net.respond(senderID, msg.token, {
                    success = false,
                    data = "Update file not found!"
                })
            end
        end
    end

    pm.createProcess(listen_getUpdate, {isService=true, title="listen_getUpdate"})

    function listen_getVer()
        while true do
            local file = fs.open("sys/ver.txt", "r")
            ver = tonumber(file.readAll())
            file.close()
            local senderID, msg = rednet.receive("NodeOS_getVer")
            net.respond(senderID, msg.token, {
                data = ver
            })
        end
    end

    pm.createProcess(listen_getVer, {isService=true, title="listen_getVer"})

else
    function checkForUpdates()
        while true do
            if isPublishing then
                return
            end
            res = net.emit("NodeOS_getVer", nil, sets.settings.master)
            if res then
                local file = fs.open("sys/ver.txt", "r")
                ver = tonumber(file.readAll())
                file.close()
                if res.data ~= ver then
                    print("Update available! NodeOS version is " .. res.data .. ".")
                    print("Downloading update...")
                    res = net.emit("NodeOS_getUpdate", nil, sets.settings.master)
                    if res then
                        if res.success then
                            print("Installing update...")
                            local file = fs.open("tmp/updater/NodeOS.czip", "w")
                            file.write(res.data)
                            file.close()
                            czip.decompress("", "tmp/updater/NodeOS.czip")
                            print("Update installed!")
                            os.reboot()
                        else
                            print(res.data)
                        end
                    end
                end
            end
            sleep(10)
        end
    end

    pm.createProcess(checkForUpdates, {isService=true, title="checkForUpdates"})
end
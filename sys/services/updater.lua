local czip = require("czip")
-- local nodeos.net = require("nodeos.net")
local ver = 0

-- Add initialization log for Updater service
nodeos.logging.info("UpdaterService", "Initializing updater service")

if not fs.exists("sys/ver.txt") then
    nodeos.logging.info("UpdaterService", "Version file not found, creating with version 0")
    local file = fs.open("sys/ver.txt", "w")
    file.write(ver)
    file.close()
else
    local file = fs.open("sys/ver.txt", "r")
    ver = tonumber(file.readAll())
    file.close()
    nodeos.logging.info("UpdaterService", "Current NodeOS version: " .. ver)
end

if os.getComputerID() == nodeos.settings.settings.master then
    nodeos.logging.info("UpdaterService", "Initializing master update server")

    function listen_publishUpdate()
        nodeos.logging.debug("UpdaterService", "Starting publish update listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_publishUpdate")
            if nodeos.net.getPairedClients()[senderID] then
                nodeos.logging.info("UpdaterService",
                    "Received update v" .. msg.data.ver .. " from #" .. senderID)
                nodeos.net.respond(senderID, msg.token, {
                    success = true
                })
                local path = "etc/updater/NodeOS-" .. msg.data.ver .. ".czip"
                nodeos.logging.debug("UpdaterService", "Saving update to " .. path)
                local file = fs.open(path, "w")
                file.write(msg.data.data)
                file.close()
                nodeos.logging.info("UpdaterService", "Decompressing update archive")
                czip.decompress("", path)
                nodeos.logging.info("UpdaterService", "NodeOS updated to v" .. msg.data.ver .. "! Rebooting...")
                print("NodeOS updated to version " .. msg.data.ver .. "!")
                os.reboot()
            else
                nodeos.logging.warn("UpdaterService",
                    "Unpaired computer #" .. senderID .. " attempted to publish an update")
            end
        end
    end

    nodeos.createProcess(listen_publishUpdate, { isService = true, title = "listen_publishUpdate" })

    function listen_getUpdate()
        nodeos.logging.debug("UpdaterService", "Starting get update listener")
        while true do
            local senderID, msg = nodeos.net.receive("NodeOS_getUpdate")
            nodeos.logging.info("UpdaterService", "#" .. senderID .. " requested update")
            local path = "etc/updater/NodeOS-" .. ver .. ".czip"
            if fs.exists(path) then
                nodeos.logging.debug("UpdaterService", "Sending update file: " .. path)
                local file = fs.open(path, "rb")
                data = file.readAll()
                file.close()
                nodeos.net.respond(senderID, msg.token, {
                    success = true,
                    data = data
                })
            else
                nodeos.logging.warn("UpdaterService", "Update file not found: " .. path)
                nodeos.net.respond(senderID, msg.token, {
                    success = false,
                    data = "Update file not found!"
                })
            end
        end
    end

    nodeos.createProcess(listen_getUpdate, { isService = true, title = "listen_getUpdate" })

    function listen_getVer()
        nodeos.logging.debug("UpdaterService", "Starting version request listener")
        while true do
            local file = fs.open("sys/ver.txt", "r")
            ver = tonumber(file.readAll())
            file.close()
            local senderID, msg = nodeos.net.receive("NodeOS_getVer")
            nodeos.net.respond(senderID, msg.token, {
                data = ver
            })
        end
    end

    nodeos.createProcess(listen_getVer, { isService = true, title = "listen_getVer" })
else
    nodeos.logging.info("UpdaterService", "Initializing client update service")

    function checkForUpdates()
        nodeos.logging.debug("UpdaterService", "Starting update check thread")
        while true do
            if isPublishing then
                nodeos.logging.debug("UpdaterService", "Update check skipped - publishing in progress")
                return
            end
            res = nodeos.net.emit("NodeOS_getVer", nil, nodeos.settings.settings.master)
            if res then
                local file = fs.open("sys/ver.txt", "r")
                ver = tonumber(file.readAll())
                file.close()
                if res.data ~= ver then
                    nodeos.logging.info("UpdaterService",
                        "Update found! v" .. ver .. " -> v" .. res.data)
                    nodeos.notifications.push("Installing Update", "NodeOS is updating to version " .. res.data .. ".")
                    print("Update available! NodeOS version is " .. res.data .. ".")
                    nodeos.logging.info("UpdaterService", "Downloading update...")
                    print("Downloading update...")
                    res = nodeos.net.emit("NodeOS_getUpdate", nil, nodeos.settings.settings.master)
                    if res then
                        if res.success then
                            nodeos.logging.info("UpdaterService", "Update downloaded, installing...")
                            print("Installing update...")
                            local file = fs.open("tmp/updater/NodeOS.czip", "w")
                            file.write(res.data)
                            file.close()
                            czip.decompress("", "tmp/updater/NodeOS.czip")
                            nodeos.logging.info("UpdaterService", "Update installed! Rebooting...")
                            print("Update installed!")
                            os.reboot()
                        else
                            nodeos.logging.error("UpdaterService", "Update download failed: " .. res.data)
                            print(res.data)
                        end
                    else
                        nodeos.logging.error("UpdaterService", "Failed to contact master server for update download")
                    end
                end
            else
                nodeos.logging.warn("UpdaterService", "Failed to contact master server for version check")
            end
            sleep(10)
        end
    end

    nodeos.createProcess(checkForUpdates, { isService = true, title = "checkForUpdates" })
end

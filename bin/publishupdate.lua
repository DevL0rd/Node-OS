local czip = require("/lib/czip")
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

function packNodeOS()
    if fs.exists("tmp/updater") then
        fs.delete("tmp/updater")
    end
    fs.makeDir("tmp/updater")
    czip.compress("bin", "tmp/updater/NodeOS.czip")
    czip.add("sys", "tmp/updater/NodeOS.czip")
    czip.add("lib", "tmp/updater/NodeOS.czip")
    czip.add("startup.lua", "tmp/updater/NodeOS.czip")
end

isPublishing = true
ver = ver + 1
local file = fs.open("sys/ver.txt", "w")
file.write(ver)
file.close()
if os.getComputerID() == sets.settings.master then
    packNodeOS()
    fs.copy("tmp/updater/NodeOS.czip", "etc/updater/NodeOS-" .. ver .. ".czip")
    print("NodeOS updated to version " .. ver .. "!")
    return
elseif not net.getPairedDevices()[sets.settings.master] then
    print("Master PC is not paired!")
    return
end
print("Packing NodeOS...")
packNodeOS()
print("Publishing NodeOS...")
local file = fs.open("tmp/updater/NodeOS.czip", "r")
local data = file.readAll()
file.close()

res = net.emit("NodeOS_publishUpdate", {
    data = data,
    ver = ver
}, sets.settings.master)

if res and res.success then
    print("Update published to master PC!")
else
    print("Update failed to published to master PC!")
end
isPublishing = false
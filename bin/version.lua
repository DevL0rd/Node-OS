local file = fs.open("sys/ver.txt", "r")
ver = tonumber(file.readAll())
file.close()

print("Current NodeOS version: " .. ver)
local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    local files = fs.list("/sys/services")
    for i, v in pairs(files) do
        v = "/sys/services/" .. v
        if v:sub(-4) == ".lua" then
            --remove the .lua
            v = v:sub(1, -5)
            require(v:gsub("/", "."))
        end
    end
    files = fs.list("/home/services")
    for i, v in pairs(files) do
        v = "/home/services/" .. v
        if v:sub(-4) == ".lua" then
            --remove the .lua
            v = v:sub(1, -5)
            require(v:gsub("/", "."))
        end
    end
end

return module

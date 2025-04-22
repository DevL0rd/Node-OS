local module = {}

function module.init(nodeos, native, termWidth, termHeight)
    nodeos.logging.info("Services", "Initializing services module")

    -- Load system services
    local systemServices = fs.list("/sys/services")
    nodeos.logging.info("Services", "Found " .. #systemServices .. " system services")

    for i, v in pairs(systemServices) do
        local servicePath = "/sys/services/" .. v
        if servicePath:sub(-4) == ".lua" then
            nodeos.logging.debug("Services", "Loading system service: " .. v)
            --remove the .lua
            local requirePath = servicePath:sub(1, -5)
            local status, err = pcall(function()
                require(requirePath:gsub("/", "."))
            end)

            if not status then
                nodeos.logging.error("Services", "Failed to load service " .. v .. ": " .. tostring(err))
            else
                nodeos.logging.debug("Services", "Successfully loaded system service: " .. v)
            end
        end
    end

    -- Load user services
    if fs.exists("/home/services") then
        local userServices = fs.list("/home/services")
        nodeos.logging.info("Services", "Found " .. #userServices .. " user services")

        for i, v in pairs(userServices) do
            local servicePath = "/home/services/" .. v
            if servicePath:sub(-4) == ".lua" then
                nodeos.logging.debug("Services", "Loading user service: " .. v)
                --remove the .lua
                local requirePath = servicePath:sub(1, -5)
                local status, err = pcall(function()
                    require(requirePath:gsub("/", "."))
                end)

                if not status then
                    nodeos.logging.error("Services", "Failed to load user service " .. v .. ": " .. tostring(err))
                else
                    nodeos.logging.debug("Services", "Successfully loaded user service: " .. v)
                end
            end
        end
    else
        nodeos.logging.debug("Services", "No user services directory found")
    end

    nodeos.logging.info("Services", "Services module initialization complete")
end

return module

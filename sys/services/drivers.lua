local nodeos = _G.nodeos
local peripherals = {}
local devicesConnected = {}
local driverData = {}
local drivers = {}

-- Add service initialization log
nodeos.logging.info("DriversService", "Initializing drivers service")

files = fs.list("/sys/drivers")
drivers = {}
for i, v in pairs(files) do
    if v:sub(-4) == ".lua" then
        local name = v:sub(1, -5)
        local path = "drivers/" .. name
        nodeos.logging.debug("DriversService", "Loading driver: " .. name)
        drivers[name] = require(path:gsub("/", "."))
    end
end
function scanPeripherals()
    local lstSides = { "left", "right", "top", "bottom", "front", "back" };
    for i, side in pairs(lstSides) do
        if (peripheral.isPresent(side)) then
            --Perihperal found
            local type = peripheral.getType(side)
            if peripherals[side] then
                --Peripheral side exists
            else
                --New perihperal
                if drivers[type] then
                    if devicesConnected[type] == nil then
                        devicesConnected[type] = side
                    end
                    devicesConnected[type] = side
                    peripherals[side] = { type = type, peripheral = peripheral.wrap(side) };
                    nodeos.logging.info("DriversService", type .. " connected on " .. side)
                    drivers[type].init(side)
                end
            end
        else
            --Peripheral not found
            if peripherals[side] then
                local type = peripherals[side].type
                --But is registered
                if drivers[type] then
                    nodeos.logging.info("DriversService", type .. " disconnected from " .. side)
                    drivers[type].unInit(side)
                end
                peripherals[side] = nil
                devicesConnected[type] = nil
            end
        end
    end
end

---------------------
--Init main threads--
function drivers_service()
    nodeos.logging.info("DriversService", "Starting drivers service thread")
    while true do
        scanPeripherals()
        sleep(0.5)
    end
end

nodeos.createProcess(drivers_service, { isService = true, title = "service_drivers" })
nodeos.logging.info("DriversService", "Drivers service initialized")

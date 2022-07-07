peripherals = {}
devicesConnected = {}
driverData = {}
drivers = {}
peripherals_settings_path = "config/term.dat" 
peripherals_settings = {
    fg = "lightGray",
    bg = "black",
    seperatorfg = "lightGray",
    seperatorbg = "black",
    header = {
        bg = "gray",
        fg = "blue"
    },
    statusBar = {
        bg = "blue",
        fg = "white"
    }
}
if fs.exists(peripherals_settings_path) then
    peripherals_settings = load(peripherals_settings_path)
else
    save(peripherals_settings, peripherals_settings_path)
end
drivers = require.tree("sys/drivers")
function scanPeripherals()
    local lstSides = {"left","right","top","bottom","front","back"};
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
                    peripherals[side] = {type = type, peripheral = peripheral.wrap(side)};
                    drivers[type].init(side)
                else
                    nPrint("No driver found for device '" .. type .. "'!")
                end
                
            end
        else
            --Peripheral not found
            if peripherals[side] then
                local type = peripherals[side].type
                --But is registered
                if drivers[type] then
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
function peripheralThread()
    while true do
        scanPeripherals()
        os.sleep(peripherals_settings.pollRate)
    end
end
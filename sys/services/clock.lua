function service_clock()
    while true do
        sleep(1)
        os.queueEvent("clock_tick")
    end
end

pm.createProcess(service_clock, {isService=true, title="service_clock"})